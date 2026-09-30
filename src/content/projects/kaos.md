---
title: "KAOS"
description: "Obsidian 마크다운 노트를 유료 클라우드 없이 개인 홈 서버와 실시간 E2E 암호화(AES-GCM)로 동기화하는 자체 호스팅 분산 시스템."
category: "분산 시스템"
tags: ["Go", "WebSocket", "SQLite", "AES-GCM", "Obsidian"]
badges: ["안정화 운용 중"]
pubDate: 2026-04-01
githubUrl: "https://github.com/adtstack/kaos"
featured: true
order: 4
---

## 프로젝트 개요

지식 관리 도구로 Obsidian을 애용하지만, 민감한 개인 기록을 제3자 클라우드에 평문으로 올리고 싶지 않았고, 공식 동기화 구독 없이도 여러 기기(노트북, 데스크톱, 스마트폰)에서 0.5초 내로 실시간 반영되는 시스템이 필요했습니다.

**KAOS**는 WebSocket과 파일 변경 감지(fsnotify)를 결합하여 만든 경량 자체 호스팅 동기화 데몬입니다.

### 아키텍처 및 보안
- **클라이언트 측 암호화 (E2E)**: 모든 파일은 전송 전 AES-256-GCM 알고리즘으로 암호화되어 서버로 전송됩니다. 서버 관리자도 노트 내용을 읽을 수 없습니다.
- **WebSocket 기반 양방향 변경 전파**: 파일 수정 발생 시 즉시 변경 diff를 전파하여 거의 즉각적으로 동기화됩니다.
- **충돌 방지 (Conflict Resolution)**: 타임스탬프와 벡터 클록(Vector Clocks)을 결합하여 동시 수정 시 데이터 유실을 방지하고 충돌 사본을 안전하게 격리 보관합니다.

### 기술 스택
- **Language**: Go
- **Protocol**: WebSockets (TLS 암호화 채널)
- **Database**: SQLite (메타데이터 및 버전 트래킹)
- **Security**: AES-256-GCM, PBKDF2 키 파생

### 시스템 아키텍처 다이어그램

#### 1. 파일시스템 브리지 제어 루프
![파일시스템 브리지 제어 루프](/diagrams/filesystem-bridge-control-loops.webp)

#### 2. 첨부파일 업로드 라이프사이클
![첨부파일 업로드 라이프사이클](/diagrams/attachment-upload-lifecycle.webp)

#### 3. 단일 Vault 구조
![단일 Vault 구조](/diagrams/single-vault-monolithic-y-doc.webp)

