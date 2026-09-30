---
title: "BriefCal"
description: "회의 전에 챙길 것, 끝나고 할 일. 캘린더에 메모하는 자리가 없어서 아쉬운 부분을 챙겨주는 일정 앱. TODO와 캘린더 일정의 실험적 결합."
category: "macOS 앱"
tags: ["Swift", "EventKit", "macOS", "Local-first"]
badges: ["2026.07 시작", "로컬 테스트 빌드"]
pubDate: 2026-07-01
githubUrl: "https://github.com/adtstack/BriefCal"
featured: true
order: 1
---

## 프로젝트 개요

기존 macOS 캘린더 앱들은 일정을 시간 블록으로 관리하는 데에는 훌륭하지만, 정작 **회의 직전에 확인해야 할 아젠다 메모**나 **회의 직후 발생한 액션 아이템(TODO)**을 캘린더와 유기적으로 엮어내지 못한다는 불편함이 있었습니다.

**BriefCal**은 이러한 아쉬움을 해결하기 위해 직접 만든 local-first macOS 캘린더 & 메모 통합 애플리케이션입니다.

### 주요 기능
- **EventKit 네이티브 연동**: 기존 macOS 시스템 캘린더 데이터를 그대로 읽고 씁니다. 별도 클라우드 가입 불필요.
- **캘린더 인라인 메모 & 액션 아이템**: 일정 블록마다 준비 사항과 후속 TODO를 한눈에 정리.
- **Local-first 데이터 보관**: 모든 메모와 상태는 기기 로컬에 안전하게 보관됩니다.
- **경량 네이티브 메뉴바 UI**: 상단 메뉴바에서 원클릭으로 오늘 남은 일정과 할 일을 체크.

### 기술 스택
- **Language**: Swift
- **Framework**: SwiftUI, AppKit
- **System**: EventKit, CoreData
