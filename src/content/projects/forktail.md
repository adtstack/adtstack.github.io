---
title: "Forktail"
description: "파일이 어디가 다른지, 충돌을 어떻게 직관적으로 합칠지. 매일 쓰는 파일 비교 및 머지 도구가 아쉬워 직접 만든 경량 데스크톱 도구."
category: "데스크톱 도구"
tags: ["TypeScript", "Tauri", "Rust", "Desktop"]
badges: ["2026.06 시작", "Phase 1 개발 중"]
pubDate: 2026-06-15
githubUrl: "https://github.com/adtstack/Forktail"
featured: true
order: 2
---

## 프로젝트 개요

대규모 Git merge 충돌 해결이나 복잡한 텍스트 파일 간의 diff를 비교할 때, 기존 무거운 GUI 툴이나 터미널 도구들 사이의 간극을 메우고자 시작된 도구입니다.

**Forktail**은 Rust 기반 Tauri 프레임워크를 활용해 극도로 가볍고 빠른 실행 속도와 모던한 3-way diff/merge UI를 제공합니다.

### 주요 기능
- **초고속 구동**: Rust 백엔드와 가벼운 웹 프론트엔드로 0.1초 내 빠른 실행.
- **Side-by-side & Inline diff**: 토큰 단위(word-level) 및 신택스 하이라이팅 지원.
- **직관적인 3-way Merge**: 충돌 구간 선택 및 한 클릭 적용.
- **Git 통합 CLI 지원**: `git mergetool` 및 `git difftool` 기본 도구로 손쉽게 등록 가능.

### 기술 스택
- **Core / Backend**: Rust, Tauri
- **Frontend**: TypeScript, Vite, Tailwind CSS
- **Algorithm**: Myers diff algorithm 기반 맞춤 토큰화
