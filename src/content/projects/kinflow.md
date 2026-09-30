---
title: "KinFlow"
description: "둘이 사는 집의 집안일 관리. '이번 주만 당번 바꾸기' 같은 현실적인 예외 상황을 정확하게 처리하는 가족 협업 모바일 앱."
category: "모바일 앱"
tags: ["Flutter", "Dart", "Supabase", "Mobile"]
badges: ["2026.05 시작", "베타 테스트"]
pubDate: 2026-05-10
githubUrl: "https://github.com/adtstack/KinFlow"
featured: true
order: 3
---

## 프로젝트 개요

가족 혹은 룸메이트 간의 집안일 분담 앱을 사용하다 보면, 고정된 반복 규칙만으로는 일상에서 발생하는 잦은 변수(야근, 출장, 컨디션 난조 등)에 대응하기 어렵습니다.

**KinFlow**는 규칙을 엄격하게 강제하기보다는, "이번 주만 내가 대신할게", "이번 턴만 건너뛰기" 등 유연한 예외 처리 모델을 1급 시민(first-class citizen)으로 설계한 협업 모바일 앱입니다.

### 주요 기능
- **유연한 스케줄링 엔진**: 기본 당번 룰 + 1회성 스왑(Swap) 및 유예(Defer) 처리.
- **실시간 상태 동기화**: 구성원이 완료 표시 시 즉각적인 푸시 및 알림.
- **공평성 피드백**: 한 사람에게 업무가 편중되지 않도록 통계 기반 밸런스 시각화.

### 기술 스택
- **Client**: Flutter, Dart
- **Backend / Realtime**: Supabase (PostgreSQL, Realtime, Row Level Security)
- **Deployment**: Android APK / iOS TestFlight
