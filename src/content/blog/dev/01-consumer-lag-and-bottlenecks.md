---
title: "Kafka의 기본 구조와 Consumer Lag, 병목 현상 이해하기"
description: "Consumer를 늘리면 처리량도 늘어날까? SQS를 사용했던 경험에서 출발해 Kafka의 Partition과 Consumer Lag, SNS·SQS의 메시지 전달 구조와 병목을 살펴봤다."
pubDate: 2026-10-18
tags: ["개발 노트", "Kafka", "AWS", "SQS", "SNS", "비동기 처리"]
featured: true
---

*Kafka #1 — Consumer를 늘린다고 처리량이 무조건 증가할까?*

## Kafka를 공부하게 된 이유

백엔드 시스템을 개발하다 보면 요청을 비동기로 처리해야 하는 상황이 생긴다.

예를 들어 주문이 완료된 뒤에는 재고를 반영하고, 출고 작업을 생성하고, 알림을 전송하는 등의 후속 작업이 필요하다. 서비스의 요구사항에 따라 다르지만, 이런 작업을 모두 하나의 HTTP 요청 안에서 동기적으로 처리하면 응답이 늦어지고 후속 작업의 장애가 주문 요청에도 영향을 줄 수 있다.

메시지 기반 비동기 처리는 이러한 작업을 분리하는 방법 중 하나다. 요청을 받는 시스템은 이벤트를 발행하고, 후속 작업을 담당하는 시스템은 그 이벤트를 받아 처리한다.

메시징 서비스를 직접 사용해 본 경험은 AWS SQS뿐이다. Kafka는 사용해 보지 않았고, SNS를 활용하면 비슷한 구조를 만들 수 있다는 이야기를 들은 적이 있다. 그렇다면 어떤 부분이 비슷하고, 어디에서 차이가 나는지도 궁금했다.

Kafka도 메시지를 전달하는 기술이라고는 알고 있었지만, Consumer를 어떻게 확장하는지, 처리가 밀릴 때 무엇을 확인해야 하는지는 설명하기 어려웠다.

특히 다음 질문이 궁금했다.

> 이벤트가 많이 들어와 처리가 밀린다면, Consumer를 늘리면 되는 것 아닐까?

이번에는 이 질문을 출발점으로 Kafka의 기본 구조와 Consumer Lag, 그리고 병목을 살펴봤다.

이 글은 공식 문서와 가상의 상황을 바탕으로 정리한 학습 기록이다. 아래 수치는 이해를 돕기 위한 예시이며, 직접 Kafka를 운영하거나 장애를 재현해 측정한 결과는 아니다. Partition을 Consumer에게 나누어 할당하는 일반적인 Consumer Group을 기준으로 설명한다.

## Consumer를 이해하려면 Partition부터 알아야 했다

Kafka는 이벤트를 발행하고 저장하며, 여러 애플리케이션이 이를 읽을 수 있도록 하는 분산 이벤트 스트리밍 플랫폼이다. 먼저 기본 구성 요소를 정리했다.

| 구성 요소 | 역할 |
| --- | --- |
| Producer | Kafka에 이벤트를 발행하는 애플리케이션이다. |
| Broker | 이벤트를 저장하고 Producer와 Consumer의 요청을 처리하는 Kafka 서버다. |
| Topic | 이벤트를 논리적으로 구분하는 단위다. |
| Partition | Topic을 나누어 저장하는 단위이며, 병렬 소비와 기록 순서의 기준이 된다. |
| Consumer | Kafka에 저장된 이벤트를 읽는 애플리케이션이다. 읽은 이벤트로 비즈니스 작업을 수행할 수 있다. |
| Consumer Group | Partition을 나누어 맡으며 협력하는 Consumer들의 그룹이다. |
| Offset | Partition 안에서 각 레코드의 위치를 나타내는 값이다. |

예를 들어 주문 이벤트를 `orders`라는 Topic에 저장하고, 이를 세 개의 Partition으로 나눌 수 있다. Consumer는 자신에게 할당된 Partition에서 이벤트를 읽는다.

여기서 중요한 점은 **같은 Consumer Group 안에서 하나의 Partition은 한 번에 하나의 Consumer에 할당된다는 것**이다. 하나의 Consumer가 여러 Partition을 맡을 수는 있다. ([Confluent: Consumer Group과 Partition 할당](https://docs.confluent.io/kafka/design/consumer-design.html#consumer-groups-and-group-ids))

하나의 Topic만 구독하고, 모든 Consumer가 동일한 조건으로 참여한다고 가정하면 다음과 같이 생각할 수 있다.

| Partition 수 | Consumer 수 | 할당 예시 |
| --- | --- | --- |
| 3개 | 1개 | Consumer 하나가 Partition 세 개를 모두 맡는다. |
| 3개 | 3개 | Consumer마다 Partition 하나씩 맡는다. |
| 3개 | 10개 | 세 Consumer가 하나씩 맡고, 나머지 일곱은 할당받지 못한다. |

Consumer를 열 개 실행했더라도 이 Topic을 나누어 읽는 Consumer는 최대 세 개다. 여기서 세는 Consumer는 그룹에 참여하는 Consumer 인스턴스이며, 애플리케이션 서버 한 대에서 여러 Consumer를 실행할 수도 있다.

또한 이 할당 규칙은 **같은 그룹 안에서** 적용된다. 출고와 알림처럼 서로 다른 작업이 주문 이벤트를 각각 받아야 한다면 별도의 Consumer Group으로 구성할 수 있다. 같은 그룹으로 묶으면 이벤트를 나누어 받으므로, 두 작업이 각 이벤트를 모두 받는 구조가 되지는 않는다. ([Apache Kafka: Consumer Group과 구독](https://kafka.apache.org/41/javadoc/org/apache/kafka/clients/consumer/KafkaConsumer.html))

Kafka는 동일 Partition 안에서 기록된 순서대로 이벤트를 읽도록 보장하지만, 서로 다른 Partition 사이의 전역 순서는 보장하지 않는다. 읽은 뒤 애플리케이션에서 작업을 병렬로 실행한다면, 처리 완료 순서도 따로 고려해야 한다. ([Apache Kafka: 기본 개념](https://kafka.apache.org/intro/))

따라서 순서가 중요한 이벤트는 어떤 Key를 기준으로 같은 Partition에 모을지부터 생각해야 한다.

## SNS와 SQS로도 비슷한 구조를 만들 수 있을까

여기까지 살펴보니, SNS를 사용하면 비슷한 구조를 만들 수 있다는 이야기도 연결해서 생각해 볼 수 있었다.

주문 이벤트 하나를 출고와 알림 서비스가 각각 받아 처리하는 요구사항이라면, SNS와 SQS를 조합한 Fan-out 구조로 구현할 수 있다. SNS Topic에 이벤트를 발행하고, 서비스별 SQS Queue가 해당 Topic을 구독하도록 구성하는 방식이다. 아래는 구독 필터 없이 두 Queue가 모두 같은 이벤트를 받도록 설계한 예시다. ([AWS: SNS의 Fan-out 구조](https://docs.aws.amazon.com/sns/latest/dg/welcome.html))

```text
주문 서비스
    │ 주문 완료 이벤트 발행
    ▼
SNS Topic
    ├── 출고용 SQS Queue ── 출고 작업자들
    └── 알림용 SQS Queue ── 알림 작업자들
```

이 구조에서 SNS는 하나의 이벤트를 여러 구독 대상에 전달하고, SQS는 각 서비스가 처리할 메시지를 보관한다. 출고 처리가 느려지더라도 알림 서비스는 자신의 Queue에서 메시지를 받아 처리할 수 있다. 다만 두 서비스가 같은 DB처럼 공통 자원을 사용한다면 그 자원의 부하는 서로에게 영향을 줄 수 있다.

같은 출고 작업을 여러 작업자가 나누어 처리하고 싶다면 출고용 Queue를 읽는 작업자를 늘릴 수 있다. 반면 출고와 알림이 이벤트를 각각 받아야 한다면 위 예시처럼 Queue를 분리한다. SQS Standard Queue는 여러 작업자가 작업을 나누어 처리하는 데 사용할 수 있지만, 중복 전달이 발생할 수 있고 엄격한 순서도 보장하지 않는다. 따라서 중복 처리를 견딜 수 있도록 설계해야 한다. ([AWS: SQS Standard Queue](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/standard-queues.html))

**하나의 이벤트를 여러 서비스가 각각 처리한다는 요구사항은 Kafka의 여러 Consumer Group과 SNS·SQS 조합으로 모두 구현할 수 있다.** 이 지점에서 두 구조를 비교해 볼 수 있다고 이해했다.

다만 Kafka의 Partition과 Consumer 할당 규칙을 SQS Queue에 그대로 적용할 수는 없다. SQS Standard Queue 하나를 여러 작업자가 함께 읽을 수 있으므로, Queue가 세 개라고 작업자도 최대 세 개만 동작하는 것은 아니다. 순서가 필요해 FIFO Queue를 사용한다면 Message Group에 따른 처리 제약도 따로 살펴봐야 한다.

처리가 밀리는 현상을 살펴보는 지표에도 차이가 있다. SQS에서는 Kafka의 Offset 차이 대신, 수신 가능한 메시지 수인 `ApproximateNumberOfMessagesVisible`, 수신 후 아직 삭제되지 않은 메시지 수인 `ApproximateNumberOfMessagesNotVisible`, 오래된 메시지의 나이를 나타내는 `ApproximateAgeOfOldestMessage` 등을 함께 볼 수 있다. 이 지표들은 추정값이며 Kafka의 Consumer Lag과 동일한 지표는 아니다. ([AWS: SQS CloudWatch 지표](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-available-cloudwatch-metrics.html))

이를 바탕으로 생각해 보면, 처리 지연을 넣어 메시지가 쌓이는 상황이나 DB가 느려 작업자를 늘려도 처리량이 늘지 않는 상황은 SNS·SQS 구성에서도 실험해 볼 수 있을 것이다. Kafka의 Partition 할당이나 Partition별 Lag을 확인하려면 Kafka 환경에서 별도로 실험해야 한다.

SNS는 아직 직접 사용해 보지 않았다. 이 비교 역시 실제 구성해 확인한 결과가 아니라, SQS를 사용했던 경험에서 출발해 문서로 살펴본 내용이다.

## Consumer를 늘리는 데에도 조건이 있었다

다음과 같은 상황을 가정해 봤다.

| 항목 | 가정한 수치 |
| --- | --- |
| 평소 이벤트 유입량 | 초당 300건 |
| 이벤트 급증 후 유입량 | 초당 5,000건 |
| 현재 Consumer Group의 전체 처리량 | 초당 1,000건 |

이벤트 한 건을 작업 하나로 처리하고, 재시도나 중복 처리는 없으며, 유입량과 처리량이 일정하다고 단순화하면 대기 작업은 초당 약 4,000건씩 늘어난다.

```text
대기 작업 증가량 ≈ 유입량 - 처리량
                 = 5,000 - 1,000
                 = 초당 4,000건
```

이때 Consumer를 추가하는 방법은 먼저 떠올릴 만하다. 다만 처리량이 증가하려면 몇 가지 조건이 맞아야 한다.

첫째, 새 Consumer에게 나누어 줄 Partition이 있어야 한다. 이미 모든 Partition을 서로 다른 Consumer가 맡고 있다면, Consumer만 추가해서는 더 나눌 수 없다.

둘째, Consumer에 작업이 실제로 분산되어야 한다. Partition이 충분해도 이벤트 대부분이 하나의 Partition으로 들어온다면 다른 Consumer의 여유를 활용하기 어렵다.

셋째, 후속 시스템도 늘어난 요청을 감당할 수 있어야 한다. Consumer가 이벤트를 읽은 뒤 DB에 저장하거나 외부 API를 호출한다면, 전체 처리량은 해당 시스템의 처리 능력에도 영향을 받는다.

예를 들어 Consumer 하나가 초당 1,000건을 처리한다고 해서 여섯 개가 반드시 초당 6,000건을 처리하는 것은 아니다. Partition 분포, Consumer가 사용하는 자원, DB와 외부 API의 여유가 함께 뒷받침되어야 한다.

또한 처리량을 유입량과 같은 초당 5,000건까지 높여도 이미 쌓인 작업은 줄어들지 않는다. 밀린 작업까지 해소하려면 일정 기간은 유입량보다 더 많이 처리해야 한다.

Consumer의 개수와 시스템의 처리량을 바로 연결해서 생각했던 부분을 다시 보게 됐다.

## Consumer Lag은 무엇을 보여 주는가

Consumer Lag은 Consumer가 최신 이벤트를 얼마나 뒤처져 읽고 있는지 살펴보는 지표다. 여기서는 Consumer Group이 **커밋한 Offset을 기준으로 한 Lag**을 다룬다.

일반적인 Consumer Group 조회 도구에서는 Partition별로 다음 차이를 확인한다.

```text
Consumer Lag = Log End Offset - Committed Offset
```

예를 들어 다음과 같은 값이 있다고 가정하자.

| 구분 | 값 | 의미 |
| --- | --- | --- |
| Log End Offset | 10,000 | 로그 끝의 다음 기록 위치 |
| Committed Offset | 7,000 | 재시작 시 읽기를 재개할 위치로 커밋한 값 |
| Consumer Lag | 3,000 | 두 위치 사이의 Offset 차이 |

Committed Offset이 7,000이라는 것은 마지막으로 처리한 레코드의 Offset이 7,000이라는 뜻이 아니다. 재개할 위치를 7,000으로 기록했다는 뜻이다. 실제로 어디까지 비즈니스 처리를 마쳤는지는 커밋 방식에 따라 달라질 수 있다. ([Confluent: Consumer Offset과 재개 위치](https://docs.confluent.io/kafka/design/consumer-design.html#consumer-position-illustrated))

처음에는 Lag이 3,000이면 미처리 작업이 정확히 3,000개라고 생각하기 쉬웠다. 하지만 둘은 항상 일치하지 않는다.

- 작업은 끝났지만 아직 Offset을 커밋하지 않았다면, 완료된 작업도 Lag에 포함될 수 있다.
- 작업을 끝내기 전에 Offset을 커밋했다면, Lag이 작아도 실제 작업이 남아 있을 수 있다.
- 로그 압축이나 트랜잭션 등으로 Offset 사이에 빈 구간이 있을 수 있어, Offset 차이와 읽을 레코드 수가 정확히 같지 않을 수 있다.

Consumer가 현재 읽고 있는 위치와 커밋한 위치는 별개다. 이 차이를 구분해야 Lag을 비즈니스 작업의 완료 여부로 오해하지 않을 수 있다. ([Apache Kafka: Offset과 Consumer 위치](https://kafka.apache.org/41/javadoc/org/apache/kafka/clients/consumer/KafkaConsumer.html))

모니터링할 때는 Lag의 숫자 하나만 보기보다 계속 증가하는지, 트래픽이 줄어든 뒤 다시 감소하는지, 이벤트가 실제로 처리되기까지 얼마나 걸리는지도 함께 확인해야 한다. 도구마다 Lag을 계산하는 기준이 다를 수 있으므로, 커밋 위치 기준인지 읽기 위치 기준인지도 확인할 필요가 있다. ([Confluent: Consumer Lag 모니터링](https://docs.confluent.io/cloud/current/monitoring/monitor-lag.html))

## 가상 시나리오 1: Consumer를 늘렸는데 처리량은 그대로라면

Partition이 여섯 개이고, 이벤트도 비교적 고르게 들어오는 상황을 가정해 보자. Consumer를 두 개에서 네 개로 늘리고, 재할당이 끝난 뒤에도 다음 상태가 유지된다고 가정한다.

| 항목 | 확장 전 | 확장 후 |
| --- | --- | --- |
| Consumer | 2개 | 4개 |
| 그룹 전체 처리량 | 1,000건/초 | 1,000건/초 |
| DB CPU | 95% | 95% |
| Consumer Lag | 증가 | 계속 증가 |

Partition이 부족해 새 Consumer가 유휴 상태가 된 경우는 제외했다. 그런데도 처리량은 늘지 않았다.

이때 DB CPU 95%라는 수치는 DB 병목을 의심할 단서다. DB가 이미 처리 한계에 가까워졌다면 Consumer를 추가해도 전체 처리량이 증가하지 않을 수 있다. 동시 요청이 늘면서 대기나 경합이 더 심해질 가능성도 있다.

그렇다고 CPU 사용률만 보고 DB가 원인이라고 확정할 수는 없다. 내가 이 상황을 확인한다면 다음 순서로 살펴볼 것이다.

1. **이벤트 처리시간을 구간별로 나눈다.** Consumer 내부 연산, DB 호출, 외부 API 호출 중 어느 구간에서 오래 걸리는지 확인한다. DB에서는 쿼리 응답시간과 처리량, 락 대기, I/O 대기 등을 함께 본다.
2. **시간을 많이 쓰는 쿼리를 찾는다.** MySQL이라면 Slow Query Log나 APM 등을 활용할 수 있다. 느린 쿼리뿐 아니라 짧은 쿼리를 지나치게 자주 호출하는지도 살펴본다. ([MySQL: Slow Query Log](https://dev.mysql.com/doc/refman/8.4/en/slow-query-log.html))
3. **실행계획과 호출 방식을 확인한다.** `EXPLAIN`으로 인덱스 사용과 데이터 접근 방식을 살펴보고, 불필요한 스캔이나 반복 조회를 줄일 수 있는지 검토한다. ([MySQL: EXPLAIN을 이용한 쿼리 분석](https://dev.mysql.com/doc/refman/8.4/en/using-explain.html))
4. **개선 전후를 같은 조건에서 비교한다.** 유입량과 이벤트 특성을 맞추고, 쿼리 응답시간뿐 아니라 Consumer의 실제 작업 완료 처리량과 Lag 추이가 함께 개선되는지 확인한다.

이 시나리오에서 정리한 것은 Kafka 뒤에서 수행하는 작업까지 살펴봐야 한다는 점이다. Kafka에서 이벤트를 빠르게 읽어 와도 DB 저장이 끝나지 않는다면, 서비스가 원하는 처리는 여전히 지연된다.

## 가상 시나리오 2: 특정 Partition에서만 Lag이 높다면

이번에는 여섯 Partition의 Lag이 다음과 같다고 가정해 보자.

| Partition | Lag |
| --- | ---: |
| P0 | 100 |
| P1 | 200 |
| P2 | 150 |
| P3 | 50,000 |
| P4 | 100 |
| P5 | 200 |

P3의 Lag이 유독 높다. 하지만 이 표만으로 현재도 Lag이 늘고 있는지, 무엇이 원인인지는 알 수 없다. 과거에 쌓인 작업을 빠르게 해소하는 중일 수도 있으므로 시간에 따른 변화부터 확인해야 한다.

P3의 Lag이 계속 증가한다면 크게 두 가지를 구분해 볼 수 있다. **다른 Partition보다 많이 들어오는가, 아니면 들어온 이벤트를 느리게 처리하는가.**

### 특정 Key에 이벤트가 몰리는 경우

`warehouseId`를 메시지 Key로 사용한다고 가정하자. Partition 수와 분배 방식이 유지되는 조건에서 같은 Key를 같은 Partition으로 보내면, 특정 물류센터의 이벤트가 하나의 Partition에 집중될 수 있다. ([Apache Kafka: 이벤트 Key와 Partition](https://kafka.apache.org/intro/))

이 물류센터에서 다른 센터보다 훨씬 많은 주문이 발생한다면, 해당 Partition의 Consumer만 처리 한계를 넘을 수 있다. 이렇게 이벤트가 불균형하게 분포하는 현상을 Partition Skew라고 하고, 부하가 집중된 Partition을 Hot Partition이라고 부르기도 한다.

이 경우 Consumer를 추가해도 P3를 여러 Consumer가 나누어 맡지는 않는다. Partition 수를 늘리더라도 같은 Key를 하나의 Partition으로 보내는 정책을 유지한다면, 그 Key 자체의 부하는 여러 Partition으로 나뉘지 않는다.

그렇다면 Key를 더 잘게 나누면 될까? 먼저 어떤 범위의 순서가 필요한지 확인해야 한다. 물류센터 전체의 이벤트 순서가 필요한지, 같은 주문 안의 순서만 필요한지에 따라 선택이 달라진다.

Key 설계나 Partition 수를 바꾸면 새 이벤트가 기존과 다른 Partition으로 갈 수 있다. 기존 이벤트와 새 이벤트 사이의 처리 순서까지 검토해야 한다. ([Confluent: Partition 수 선택과 변경 시 주의점](https://docs.confluent.io/kafka/operations-tools/partition-determination.html))

### 유입량은 비슷하지만 처리가 느린 경우

P3에 이벤트가 더 많이 들어오는 것이 아니라, P3의 이벤트를 처리하는 데 시간이 오래 걸리는 상황일 수도 있다.

예를 들어 P3에 포함된 이벤트가 느린 쿼리를 실행하거나 외부 API의 응답을 기다릴 수 있다. 특정 이벤트에서 오류가 발생하고, 그 이벤트가 성공할 때까지 같은 Partition의 처리를 멈추는 재시도 방식을 사용한다면 뒤의 이벤트도 밀릴 수 있다.

반복 실패가 어떤 범위의 처리를 막는지는 애플리케이션과 프레임워크의 오류 처리 방식에 따라 달라진다. Consumer 하나가 여러 Partition을 순차 처리하는 구조라면 다른 Partition에도 영향을 줄 수 있다.

따라서 확인하고 싶은 정보는 다음과 같다.

- Partition별 이벤트 유입량과 Lag의 변화
- Partition별 작업 완료 처리량과 처리시간
- 각 Partition의 Consumer 할당 상태와 해당 Consumer의 자원 사용량
- 반복 실패 로그, 재시도 횟수, DB와 외부 API의 응답시간

Partition별 유입량이 다른지, 이벤트 한 건의 처리 비용이 다른지, 특정 Consumer 자체가 느린지를 나누어 봐야 대응 방향을 정할 수 있다. 그 밖에도 Broker나 네트워크 문제, 잦은 재할당 등이 영향을 줄 수 있으므로 이 두 경우만으로 모든 원인을 설명할 수는 없다.

## 이번 학습으로 달라진 생각

처음에는 이벤트 처리가 밀리면 Consumer를 늘리는 방식으로 해결할 수 있다고 단순하게 생각했다.

기본 구조를 살펴보니 Consumer를 추가하기 전에 확인해야 할 질문이 생겼다. 새 Consumer가 맡을 Partition이 있는가. 이벤트가 고르게 분산되는가. 실제 처리시간은 어디에서 쓰이는가. DB와 외부 API에 요청을 더 보낼 여유가 있는가.

Consumer Lag을 보는 관점도 달라졌다. Lag은 중요한 관찰 지표지만, 그 값만으로 원인이나 비즈니스 작업의 완료 여부를 확정할 수는 없다. 커밋 방식과 시간에 따른 변화, 실제 작업 처리시간을 함께 봐야 한다.

SQS를 사용했던 경험과 연결해 보니, SNS와 SQS를 조합해 하나의 이벤트를 여러 서비스에 전달할 수 있다는 점도 이해할 수 있었다. 비슷한 요구사항을 구현할 수 있어도, 작업을 나누는 방식과 지연을 관찰하는 지표는 각 기술의 구조에 맞춰 이해해야 했다.

아직 이런 상황을 직접 재현해서 확인하지는 못했다. 다음에는 Partition 수와 Consumer 수를 바꾸거나 처리 지연을 추가하면서, 예상한 대로 처리량과 Lag이 달라지는지 확인해 보고 싶다.

그다음에는 작업을 완료하고 Offset을 커밋하기 전에 장애가 발생하면 어떻게 되는지, 반대로 커밋한 뒤 작업이 실패하면 어떤 문제가 생기는지도 공부해 보려고 한다.
