---
title: "KAOS"
description: "0BSD 오픈소스인 YAOS를 기반으로 포크(Fork)하여, 내 인프라(Cloudflare)와 사용 패턴에 맞춰 신뢰성과 복구 메커니즘을 전면 재설계한 Obsidian 실시간 동기화 플러그인."
category: "실시간 동기화 / 인프라"
tags: ["TypeScript", "Obsidian", "Yjs", "CRDT", "Cloudflare Workers", "Durable Objects", "Cloudflare R2"]
badges: ["0BSD License", "오픈소스 Fork"]
pubDate: 2026-04-01
githubUrl: "https://github.com/adtstack/kaos"
featured: true
order: 1
---

> **GitHub 저장소**: [github.com/adtstack/kaos](https://github.com/adtstack/kaos)

## 프로젝트 개요

[KAOS](https://github.com/adtstack/kaos)는 Kavin Sood가 공개한 0BSD 오픈소스 프로젝트 **YAOS를 기반으로 포크(Fork)**하여, 내가 직접 소유한 인프라(Cloudflare Workers / Durable Objects / R2) 위에서 안전하고 매끄럽게 동작하도록 발전시켜 나가고 있는 **Obsidian 실시간 동기화 시스템**입니다.

Obsidian 볼트의 마크다운 및 Base(`.base`) 문서를 디스크 상의 일반 텍스트 파일로 온전히 유지하면서, 기기 간 텍스트 편집을 **Yjs CRDT(Conflict-free Replicated Data Types)**를 통해 실시간으로 병합합니다.

---

## 오픈소스 포크 및 계보 (Lineage)

오픈소스 생태계의 가장 큰 미덕은 **‘우수한 토대 위에 서서 각자의 필요에 맞게 개선하고 발전시켜 나간다’**는 점입니다. KAOS는 바닥부터 혼자 만든 척(Clean-room)하지 않고, 원작의 토대를 정직하게 밝히고 존중하는 방향을 택했습니다.

- **출발점**: Kavin Sood의 [YAOS](https://github.com/adtstack/kaos) (0BSD 라이선스)
- **독자적 발전 방향**: 원작의 핵심 아이디어를 계승하되, 실제 일상에서 매일 쓰며 마주한 문제들을 해결하기 위해 다음과 같은 영역을 전면 재설계하고 독립적으로 확장했습니다.
  - **인프라 전환**: 개인 Cloudflare 계정에서 구동되는 Durable Object 기반의 동기화 룸 구축
  - **파일시스템 브리지 안정화**: 시간(TTL) 기반 추측을 걷어내고 I/O Backpressure(Dirty-Set Drain Loop)와 직렬화 락을 적용하여 VFS와 CRDT 간의 상태 찢김 및 자기 반향 루프 원천 차단
  - **복구 도구 및 툴링**: R2 기반 온디맨드/정기 스냅샷, 세션 다이어그노스틱, 충돌 가드, Nuclear Reset 등 복구 우선 아키텍처
  - **테스트 하네스**: Cloudflare 배포 없이도 로컬에서 여러 기기를 시뮬레이션할 수 있는 멀티 디바이스 QA 환경

---

## 라이선스 (License)

KAOS는 원작의 라이선스를 그대로 승계하여 **0BSD License (Free Public License / Zero-Clause BSD)** 하에 배포됩니다.

- **라이선스**: **0BSD (Zero-Clause BSD)**
- **원본 저작권**: `Copyright (C) 2026 by Kavin Sood`
- **허용 범위**: 수수료 유무나 목적(상업적/비상업적)을 불문하고 자유로운 사용, 복제, 수정, 배포가 허용되는 가장 자유로운 형태의 퍼블릭 라이선스입니다.
- **상표권 고지**: KAOS는 독립적인 오픈소스 프로젝트이며, Obsidian(Dynalist Inc.)과 공식적인 제휴나 후원 관계가 아닙니다.

---

## 핵심 설계 원칙

1. **로컬 파일은 로컬 파일로 남아야 한다 (Local files stay real)**  
   볼트를 원격 데이터베이스나 전용 에디터 포맷으로 가두지 않습니다. 디스크에 존재하는 마크다운 폴더 구조를 그대로 유지하며 동기화합니다.
2. **진정한 실시간 텍스트 동기화 (Live text sync)**  
   마크다운 편집을 CRDT 연산으로 처리하므로, 여러 기기에서 동일한 문서를 동시에 수정하더라도 '충돌 사본(Conflicted copy)' 파일이 분열되어 생기지 않고 글자 단위로 자연스럽게 병합됩니다.
3. **내 서버는 내가 소유한다 (Infrastructure you own)**  
   동기화 룸(Sync Room)은 사용자의 개인 Cloudflare 계정에서 실행되는 Durable Object입니다. 중앙 서비스의 약관 변경이나 서버 다운타임에 영향을 받지 않습니다.
4. **운영 부담 없는 셋업 (Zero-ops setup)**  
   복잡한 서버 설정 없이 `Deploy to Cloudflare` 원클릭 버튼과 Claim Secret을 통해 배포하고, QR 코드나 셋업 링크로 볼트를 즉시 페어링할 수 있습니다.
5. **복구가 곧 제품의 핵심이다 (Recovery is part of sync)**  
   동기화 시스템은 현실 세계의 다양한 네트워크/I/O 예외 상황을 마주합니다. KAOS는 R2 기반 스냅샷, 서버 수신 상태(Receipt) 관리, 진단 데이터 내보내기, Nuclear Reset 등 강력한 복구 도구를 기본 제공합니다.

---

## 심층 기술 아키텍처

### 1. 단일 Vault 모놀리식 Y.Doc (Monolithic Vault CRDT)

KAOS는 전체 볼트의 파일 메타데이터, 폴더 계층 구조, 블롭 참조, 마크다운 `Y.Text` 인스턴스를 **단일 공유 `Y.Doc`** 내에서 통합 관리합니다.

- **원자적 ACID 트랜잭션**: 50개의 마크다운 파일이 포함된 폴더의 이름을 바꿀 때, 단일 `ydoc.transact()` 블록으로 묶여 실행됩니다. 50개 파일이 모두 이동하거나 전혀 이동하지 않으므로 볼트 구조가 찢어지는 현상(State Tearing)이 원천 방지됩니다.
- **실용적 트레이드오프**: 무한한 확장성을 위해 단순한 파일 단위 디바운스 동기화(외부 변경 충돌 팝업 유발)를 택한 상용 도구와 달리, KAOS는 **순수 마크다운 기준 약 40~50MB** 규모의 개인/소규모 팀 볼트에서 극상의 실시간 협업과 트랜잭션 일관성을 보장하도록 설계되었습니다.

### 2. 파일시스템 브리지 (The Filesystem Bridge)

플러그인 구현에서 가장 까다로운 지점은 **Obsidian VFS(가상 파일 시스템)의 비인과적이고 시끄러운 파일 이벤트**와 **Yjs의 엄격한 인과적 상태 머신**을 양방향으로 중계하는 것입니다.

KAOS는 취약한 시간(TTL/디바운스) 기반 추측 대신 **I/O Backpressure & State Acknowledgment** 아키텍처로 이를 해결했습니다:

- **Inbound (Disk → CRDT) - Dirty-Set Drain Loop**: 파일 시스템 이벤트를 즉각 처리하지 않고 dirty-set에 모아둔 뒤, 실제 디스크 I/O 속도에 맞춰 순차 드레인합니다. 내가 쓴 내용이 파일 이벤트로 되돌아와 다시 CRDT를 오염시키는 **자기 반향 루프(Self-echo loop)**를 원천 차단합니다.
- **Outbound (CRDT → Disk) - Per-Path Serialization**: CRDT에서 디스크로의 쓰기는 경로별 프로미스 체인 락을 통해 직렬화되어, 동시 네트워크 동기화로 인한 파일 덮어쓰기 레이스를 방지합니다.

### 3. 첨부파일 및 스냅샷 분리 (Cloudflare R2)

이미지나 PDF 같은 무거운 바이너리 에셋은 CRDT 힙 메모리를 불필요하게 낭비하지 않도록, 콘텐츠 주소 지정(Content-addressed) 방식의 Cloudflare R2 스토리지로 분리 전송됩니다. 마크다운 본문은 R2 없이도 즉시 동기화되며, 필요 시 R2를 연결하여 첨부파일 동기화 및 정기 볼트 스냅샷 복구 기능을 활성화할 수 있습니다.

---

## 기술 스택 요약

- **Frontend / Client**: TypeScript, Obsidian Plugin API, CodeMirror 6, Yjs, IndexedDB
- **Backend / Sync Room**: Cloudflare Workers, Durable Objects, WebSockets
- **Storage / Recovery**: Cloudflare R2 (Content-addressed Blobs, Vault Snapshots)
- **License**: 0BSD License (Copyright © 2026 Kavin Sood)

상세한 엔지니어링 노트와 소스 코드는 [KAOS GitHub 저장소](https://github.com/adtstack/kaos)에서 확인하실 수 있습니다.
