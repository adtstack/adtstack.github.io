---
title: "US News RAG"
description: "미국 증시 주요 금융·기업 뉴스를 실시간 수집 및 벡터 임베딩하여, 종목별 핵심 이슈와 시장 영향도를 질의응답할 수 있는 RAG 파이프라인."
category: "AI / RAG"
tags: ["Python", "FastAPI", "LangChain", "ChromaDB", "LLM"]
badges: ["PoC 완료"]
pubDate: 2026-03-01
githubUrl: "https://github.com/adtstack/us-news-rag"
featured: false
order: 5
---

## 프로젝트 개요

방대한 양의 미국 증시 및 경제 뉴스를 매일 수동으로 읽고 분석하는 데에는 많은 시간이 소요됩니다. 단순 키워드 검색을 넘어 특정 기업이나 거시 경제 지표에 관련된 최근 맥락을 파악하기 위해 구축한 RAG (Retrieval-Augmented Generation) 파이프라인입니다.

### 주요 파이프라인
1. **뉴스 수집 크롤러**: SEC 공시, 주요 경제 뉴스 피드 RSS를 준실시간으로 파싱.
2. **Chunking & 임베딩**: 금융 도메인 특화 청킹 전략 적용 후 벡터 DB에 저장.
3. **하이브리드 검색 (BM25 + Dense Vector)**: 종목 티커(예: AAPL, NVDA) 정확도와 의미론적 검색을 결합.
4. **LLM 기반 요약 및 질의응답**: 사용자의 질문에 대한 출처 기사 인용과 함께 분석 제공.

### 기술 스택
- **Language**: Python 3.11+
- **Backend**: FastAPI
- **LLM Orchestration**: LangChain
- **Vector DB**: ChromaDB
