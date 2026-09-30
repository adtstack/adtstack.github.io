---
title: "KAOS"
description: "내가 직접 소유한 인프라(Cloudflare Workers & Durable Objects)에서 구동되는 Obsidian 실시간 동기화 플러그인. Yjs CRDT 기반 동시 편집과 R2 분리 동기화."
category: "실시간 동기화 / 인프라"
tags: ["TypeScript", "Obsidian", "Yjs", "CRDT", "Cloudflare Workers", "Durable Objects", "Cloudflare R2"]
badges: ["0-BSD License", "활성 개발 중"]
pubDate: 2026-04-01
githubUrl: "https://github.com/adtstack/kaos"
featured: true
order: 1
---

> **GitHub 저장소**: [github.com/adtstack/kaos](https://github.com/adtstack/kaos)

## 프로젝트 개요

[KAOS](https://github.com/adtstack/kaos)는 제3자 상용 클라우드나 유료 구독 서비스에 종속되지 않고, **사용자가 직접 소유한 인프라(Cloudflare Workers / Durable Objects / R2)** 위에서 동작하는 **Obsidian 실시간 동기화 시스템**입니다.

Obsidian 플러그인과 경량 Cloudflare Worker 동기화 서버로 구성되며, 볼트의 마크다운 및 Base(`.base`) 파일들을 디스크 상의 일반 텍스트 파일로 온전히 보존하면서, 기기 간 텍스트 편집을 **Yjs CRDT(Conflict-free Replicated Data Types)**를 통해 실시간으로 매끄럽게 병합합니다.

Kavin Sood의 YAOS(0BSD 라이선스)에서 출발하였으며, 독자적인 Cloudflare Durable Object 룸 아키텍처, I/O Backpressure 기반 파일시스템 브리지, 원클릭 배포 파이프라인, 포괄적인 복구 및 진단 툴링, 로컬 멀티 디바이스 QA 하네스를 갖춘 독립적인 프로젝트로 발전해 왔습니다.

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

## 시스템 아키텍처 다이어그램

#### 1. 파일시스템 브리지 제어 루프 및 불변식 (Disk ↔ CRDT)
![파일시스템 브리지 제어 루프](/diagrams/filesystem-bridge-control-loops.webp)

#### 2. 단일 Vault 모놀리식 Y.Doc vs 샤딩 모델 비교
![단일 Vault 구조](/diagrams/single-vault-monolithic-y-doc.webp)

#### 3. R2 첨부파일 업로드 및 수명 주기
![첨부파일 업로드 라이프사이클](/diagrams/attachment-upload-lifecycle.webp)

#### 4. 배포 버튼 복원력 (Cloudflare Deploy Resiliency)
![배포 버튼 복원력](/diagrams/deploy-button-resilience.webp)

#### 5. 블록 청킹을 배제한 아키텍처적 근거
![블록 청킹 배제 근거](/diagrams/why-no-block-chunking.webp)

---

## 기술 스택 요약

- **Frontend / Client**: TypeScript, Obsidian Plugin API, CodeMirror 6, Yjs, IndexedDB
- **Backend / Sync Room**: Cloudflare Workers, Durable Objects, WebSockets
- **Storage / Recovery**: Cloudflare R2 (Content-addressed Blobs, Vault Snapshots)
- **License**: 0BSD License

상세한 엔지니어링 노트와 소스 코드는 [KAOS GitHub 저장소](https://github.com/adtstack/kaos)에서 확인하실 수 있습니다.
