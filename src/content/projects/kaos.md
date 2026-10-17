---
title: "KAOS"
description: "기기를 옮겨도 이어지는 노트 편집. 직접 운영하는 Cloudflare 인프라에서 매일 사용하는 Obsidian 실시간 동기화 플러그인."
category: "실시간 동기화 / 인프라"
tags: ["TypeScript", "Obsidian", "Yjs", "CRDT", "Cloudflare"]
badges: ["2026.04 시작", "직접 운영 · 일상 사용"]
pubDate: 2026-04-01
githubUrl: "https://github.com/adtstack/kaos"
featured: true
order: 1
---

## 프로젝트 개요

여러 기기에서 같은 Obsidian 볼트를 사용하면서, 편집 내용이 이전 상태로 돌아가거나 동기화가 멈춰 작업 흐름이 끊기는 불편함이 있었습니다. 로컬 파일을 그대로 유지하면서 기기를 옮겨 자연스럽게 작업을 이어갈 수 있는 동기화 환경이 필요했습니다.

**KAOS**는 직접 운영하는 Cloudflare 인프라 위에서 동작하는 Obsidian 실시간 동기화 플러그인입니다. Kavin Sood의 [YAOS](https://github.com/kavinsood/yaos)를 포크해 편집 중인 내용의 보호, 오래 열린 탭의 상태 조정, 충돌 검토와 복구 기능을 발전시켰습니다.

현재는 일상에서 동기화를 별도로 신경 쓰지 않고 노트를 작성하고 있습니다. 직접 매일 사용하며 발견한 문제를 개선하고, 같은 문제가 반복되지 않도록 재현 회귀 테스트를 유지하고 있습니다.

### 주요 기능

- **실시간 텍스트 동기화**: 마크다운과 Obsidian Base(`.base`) 문서를 일반 로컬 파일로 유지하면서 Yjs CRDT로 기기 간 편집을 병합. 오프라인 변경은 재접속 후 동기화.
- **편집 내용 보호와 상태 조정**: 편집기·디스크·CRDT의 기준 상태를 비교해 오래된 내용의 재전파를 방지. 외부 파일 변경은 병합 가능한 범위에서 반영하고, 입력 중이거나 판단 근거가 부족하면 자동 적용을 보류.
- **충돌 검토와 복구**: 대시보드에서 동기화 상태와 충돌 내용을 확인하고 병합 결과를 검토해 적용. 파일별 서버 상태 복원과 R2 기반 파일 이력·볼트 스냅샷 지원.
- **직접 운영하는 인프라와 기기별 인증**: 개인 Cloudflare 계정에서 동기화 서버를 운영. 기기별 P-256 키와 소유자 승인으로 접근 권한을 관리.
- **헤드리스 동기화**: Obsidian을 실행하지 않는 서버에서도 같은 동기화 엔진을 사용해 스크립트·에이전트의 마크다운 작업을 연결.

### 기술 스택

- **Client**: TypeScript, Obsidian Plugin API, CodeMirror 6
- **Sync / Local Storage**: Yjs CRDT, IndexedDB
- **Backend / Realtime**: Cloudflare Workers, Durable Objects, WebSocket
- **Storage / Recovery**: Cloudflare R2 (첨부파일, 파일 이력, 볼트 스냅샷)
- **License**: 0BSD (저작권 고지 유지)
