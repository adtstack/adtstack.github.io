---
title: "알고 있다고 생각했던 것들 — Spring Transaction을 안다고 생각했다"
description: "내부 호출은 헷갈렸고, 롤백 결과는 맞혔지만 이유를 설명하지 못했다. Spring 트랜잭션 문답에서 발견한 이해의 빈틈과 실패 로그 설계를 통해 다시 배운 것들."
pubDate: 2026-10-16
tags: ["알고 있다고 생각했던 것들", "Spring", "트랜잭션", "학습회고"]
featured: true
---

Spring은 개발을 시작하고 가장 많이 사용한 프레임워크다. 그중에서도 `@Transactional`은 자주 사용했다. 데이터를 저장하거나 수정할 때 필요하면 붙였고, 특별한 문제가 없다면 더 깊게 생각하지 않았다.

트랜잭션이 무엇인지, 왜 필요한지는 알고 있다고 생각했다.

GPT와 기술 문답을 진행하자, 질문의 조건이 바뀔 때마다 설명이 막혔다. 틀린 답도 있었고, 결과는 맞혔지만 이유를 설명하지 못한 답도 있었다. 이번에는 그 과정을 정리해 보려고 한다.

아래 코드는 문답의 핵심을 보여 주는 서비스 코드 일부다. Spring의 기본 프록시 방식과 롤백 규칙을 사용하며, 같은 스레드·트랜잭션 매니저에서 동작한다고 가정한다. 외부 호출은 Spring 빈의 프록시를 거친다.

## 내부 호출은 트랜잭션이 적용되지 않는다고 생각했다

첫 질문은 다음 코드의 트랜잭션이 어떻게 동작하는지였다.

```java
// OrderService
@Transactional
public void createOrder() {
    saveOrder();
    decreaseStock();
}

private void saveOrder() {
    // 주문 저장
}

private void decreaseStock() {
    // 재고 차감
}
```

나는 같은 클래스 내부의 호출은 프록시를 거치지 않으므로, `createOrder()`를 제외한 메서드에는 트랜잭션이 잘 적용되지 않을 것 같다고 답했다. 실제로 내부 호출 때문에 `@Transactional`이 적용되지 않았던 경험도 있었다.

하지만 이 답변은 틀렸다. `createOrder()`가 프록시를 통해 호출되어 트랜잭션이 시작됐다면, 내부 메서드의 DB 작업도 그 트랜잭션 안에서 실행된다. 메서드를 나누거나 `private`으로 선언했다고 기존 트랜잭션에서 벗어나는 것은 아니다.

내가 기억하고 있던 Self-invocation 문제는 다음과 같은 경우였다.

```java
// OrderService: 클래스에는 @Transactional이 없고,
// 호출 시점에도 기존 트랜잭션이 없는 경우
public void createOrder() {
    saveOrder();
}

@Transactional
public void saveOrder() {
    // 주문 저장
}
```

자기 자신의 메서드를 직접 호출하면 프록시를 거치지 않아, `saveOrder()`의 트랜잭션 설정이 적용되지 않는다. 이 호출로 서비스의 트랜잭션이 시작되지는 않는다는 뜻이다. ([Spring 공식 문서: 프록시와 내부 호출](https://docs.spring.io/spring-framework/reference/data-access/transaction/declarative/annotations.html))

**이미 시작된 트랜잭션 안에서 실행되는 것과, 호출한 메서드의 트랜잭션 설정이 적용되는 것은 다른 문제였다.**

나는 이 차이를 구분하지 못한 채, ‘같은 클래스 내부 호출은 트랜잭션에 문제가 있다’고 기억하고 있었다.

## 예외를 잡았는데도 롤백되는 이유를 설명하지 못했다

다음에는 예외 처리에 관한 질문이 이어졌다.

첫 번째 예제의 `decreaseStock()`에서 `RuntimeException`을 던지면 주문은 롤백된다고 답했다. `createOrder()` 안에서 그 예외를 잡고 정상적으로 반환하면 커밋될 수 있다고도 답했다. 별도로 롤백 대상으로 표시되지 않았다는 조건에서는 맞는 답이었다. ([Spring 공식 문서: 롤백 규칙](https://docs.spring.io/spring-framework/reference/data-access/transaction/declarative/rolling-back.html))

그런데 재고 차감을 별도 서비스로 옮기자 이유를 설명하지 못했다.

```java
// StockService: 별도의 Spring 빈
@Transactional
public void decreaseStock() {
    throw new RuntimeException("재고 부족");
}

// OrderService
@Transactional
public void createOrder() {
    orderRepository.save(new Order());

    try {
        stockService.decreaseStock();
    } catch (RuntimeException e) {
        System.out.println("재고 차감 실패");
    }
}
```

나는 롤백된다고 답했다. 결과는 맞았지만, 예외가 상위로 전달되기 때문이라고 설명했다. 그런데 예외는 이미 `catch`에서 처리하고 있었다.

기본 전파 옵션인 `REQUIRED`는 기존 트랜잭션이 있으면 그 트랜잭션에 참여한다. 위 코드에서는 주문과 재고가 같은 물리적 트랜잭션을 공유한다. 재고 서비스의 프록시가 밖으로 전달된 `RuntimeException`을 처리하면서 공유 트랜잭션을 `rollback-only`로 표시한다.

주문 서비스에서 예외를 잡아도 그 표시는 취소되지 않는다. 이후 정상 반환해 커밋을 시도하면 롤백되고, `UnexpectedRollbackException`이 발생한다. ([Spring 공식 문서: `REQUIRED`와 rollback-only](https://docs.spring.io/spring-framework/reference/data-access/transaction/declarative/tx-propagation.html#tx-propagation-required))

그렇다면 재고 서비스에 `REQUIRES_NEW`를 적용하면 어떨까?

```java
@Transactional(propagation = Propagation.REQUIRES_NEW)
public void decreaseStock() {
    throw new RuntimeException("재고 부족");
}
```

이번에는 주문이 저장될 수 있다고 답했다. `REQUIRES_NEW`는 기존 트랜잭션을 일시 중단하고 독립적인 물리적 트랜잭션을 사용한다. 주문 서비스가 예외를 잡으면 재고 트랜잭션은 롤백되고, 다른 문제가 없는 주문 트랜잭션은 커밋할 수 있다. ([Spring 공식 문서: `REQUIRES_NEW`](https://docs.spring.io/spring-framework/reference/data-access/transaction/declarative/tx-propagation.html#tx-propagation-requires_new))

질문에서 달라진 조건을 정리하면 다음과 같다. 모두 재고 처리 중 `RuntimeException`이 발생하고, 그 외 DB 오류나 별도의 롤백 표시는 없다는 가정이다.

| 재고 처리 방식 | 주문 서비스의 예외 처리 | 주문 결과 |
| --- | --- | --- |
| 같은 클래스의 일반 메서드 | 처리하지 않고 전파 | 롤백 |
| 같은 클래스의 일반 메서드 | 내부에서 잡고 정상 반환 | 커밋 |
| 다른 빈의 `REQUIRED` 메서드 | 잡고 정상 반환 | 롤백, `UnexpectedRollbackException` |
| 다른 빈의 `REQUIRES_NEW` 메서드 | 잡고 정상 반환 | 커밋 |

**예외를 잡았는지만 볼 것이 아니라, 그 전에 어떤 트랜잭션 경계를 지났는지 봐야 했다.**

나는 전파 옵션의 뜻은 알고 있었지만, 프록시와 예외 처리까지 연결해서 설명하지는 못하고 있었다.

## 실패 로그를 남기는 요구사항에서도 실수했다

다음 질문은 실행 결과 예측에서 설계로 넘어갔다.

> 주문 저장과 재고 차감은 함께 성공하거나 실패해야 한다. 하지만 실패 로그는 DB에 남겨야 한다.

나는 주문과 재고에 `REQUIRED`를 사용하고, 예외를 잡아 로그를 저장하면 된다고 답했다. 그런데 로그도 같은 트랜잭션에 저장하면 주문과 함께 롤백된다. 예외를 삼키는 것 역시 주문과 재고의 원자성을 보장하는 방법이 아니었다.

여기에 앞에서 배운 `REQUIRES_NEW`를 적용할 수 있었다.

```java
// ErrorLogService: 별도의 Spring 빈
@Transactional(propagation = Propagation.REQUIRES_NEW)
public void saveError(String message) {
    errorLogRepository.save(new ErrorLog(message));
}

// OrderService
@Transactional
public void createOrder() {
    try {
        orderRepository.save(new Order());
        stockService.decreaseStock(); // REQUIRED로 주문 트랜잭션에 참여
    } catch (RuntimeException e) {
        errorLogService.saveError(e.getMessage());
        throw e;
    }
}
```

별도 빈의 프록시를 거쳐 실패 로그를 독립적으로 커밋하고, 원래 예외는 다시 던져 주문과 재고를 롤백하는 방식이다. 같은 클래스에 로그 메서드를 만들고 `REQUIRES_NEW`만 붙였다면 앞서 혼동했던 내부 호출 문제가 다시 생겼을 것이다.

물론 이 예제가 모든 실패를 기록하는 것은 아니다. 로그 저장 자체가 실패할 수 있고, 주문 메서드가 반환된 뒤 프록시에서 발생한 커밋 오류는 메서드 내부의 `catch`로 잡을 수 없다. 여기서는 메서드 본문에서 발생한 예외를 기록하는 흐름을 다뤘다.

**어떤 작업이 함께 롤백되어야 하고, 어떤 작업은 독립적으로 남아야 하는지 먼저 판단해야 했다.** 전파 옵션을 알고 있는 것과 요구사항에 맞춰 선택하는 것 사이에도 빈틈이 있었다.

## 정답을 맞힌 것만으로 이해했다고 생각하지 않으려 한다

이번 문답에서 모든 질문을 틀린 것은 아니다. 결과를 정확하게 예상한 경우도 많았다. 하지만 `rollback-only` 질문처럼 결과는 맞히고 이유는 잘못 설명한 경우가 있었다.

실무에서도 이전 경험을 떠올려 문제를 해결한 적이 많았다. 그 경험은 도움이 됐다. 다만 조건이 조금 달라졌을 때도 같은 방법이 통하는지 판단하려면, 무엇이 그 결과를 만드는지 이해할 필요가 있었다.

이번에는 답하는 과정이 그 빈틈을 드러냈다. 내부 호출을 잘못 예상했고, 롤백의 이유를 설명하지 못했고, 배운 개념을 실패 로그 설계에 바로 적용하지도 못했다. 설명을 읽기만 했다면 어디까지 알고 있는지 확인하기 어려웠을 것 같다.

그래서 앞으로는 이해했다고 판단하기 전에 세 가지를 확인하려고 한다.

1. 왜 그렇게 동작하는지 내 말로 설명할 수 있는가.
2. 조건이 바뀌면 결과가 어떻게 달라질지 예상할 수 있는가.
3. 요구사항에 맞는 방법을 선택하고 그 이유를 설명할 수 있는가.

10년 동안 익숙하게 사용한 기술에서 이해의 빈틈을 발견하니 여전히 불안하다. 그래도 무엇을 잘못 알고 있었고, 무엇을 더 확인해야 하는지 조금은 명확해졌다.
