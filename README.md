# adtstack.github.io

[adtstack.github.io](https://adtstack.github.io) — **만든 것과 배운 것을 기록합니다.**

필요한 소프트웨어를 만들고, 개발하며 마주친 문제와 배운 내용을 정리합니다.

블로그에는 문제를 확인하고 이해해 가는 과정을, 프로젝트 페이지에는 만든 도구의 목적과 기능, 현재 상태를 남깁니다.

## 기술 스택

- **프레임워크**: Astro 7, 정적 사이트 생성
- **스타일링**: Tailwind CSS v4, Pretendard Variable, Atkinson
- **테마**: 라이트 / 다크 모드, 시스템 설정 감지 및 선택 저장
- **콘텐츠**: Markdown / MDX, Astro Content Collections와 Zod 스키마
- **배포**: GitHub Actions, GitHub Pages

## 프로젝트 구조

```text
├── .github/workflows/deploy.yml # GitHub Pages 자동 배포 액션
├── src/
│   ├── assets/                  # 이미지, 폰트 에셋
│   ├── components/              # Header, Footer, ThemeToggle, BaseHead 등
│   ├── content/
│   │   ├── blog/                # 기술 블로그 글 마크다운 (.md, .mdx)
│   │   └── projects/            # 프로젝트 소개 마크다운 (.md, .mdx)
│   ├── layouts/                 # BlogPost, ProjectPost 레이아웃
│   ├── pages/                   # 사이트 라우트 (/, /blog, /projects, /about, /rss.xml)
│   ├── styles/global.css        # Tailwind v4 및 전역 스타일
│   ├── consts.ts                # 사이트 이름, 공통 제목과 설명
│   └── content.config.ts        # Content Collections Zod 스키마 정의
├── public/                      # favicon 등 정적 파일
├── astro.config.mjs             # Astro 설정 파일
└── package.json
```

## 콘텐츠 작성

### 블로그 글

`src/content/blog/` 디렉터리에 새로운 `.md` 또는 `.mdx` 파일을 생성합니다.
이 디렉터리의 글은 별도의 초안 필터 없이 배포 대상에 포함됩니다. 기존 글의 본문 수정도 배포 시 그대로 반영됩니다.

첫 페이지의 최신 글과 블로그 목록은 `pubDate` 내림차순으로 표시합니다. 발행일이 같으면 파일 이름의 역순을 사용해, 연재 번호가 큰 글이 먼저 나오도록 합니다.

`tags`에 적은 태그는 첫 페이지, 글 상단, 블로그 목록에서 해당 태그의 글 모아보기로 연결됩니다. 태그별 페이지는 빌드 시 생성되며, 목록의 `전체` 링크로 모든 글을 볼 수 있습니다.

```markdown
---
title: "새 글 제목"
description: "글 요약 설명"
pubDate: 2026-10-01
tags: ["Astro", "회고"]
featured: true
---

본문 내용을 마크다운으로 자유롭게 작성합니다.
```

#### 연재: 알고 있다고 생각했던 것들

익숙한 기술의 기초를 다시 확인하고 이해의 빈틈을 채워 가는 연재입니다.

- **폴더**: `src/content/blog/thought-i-knew/`
- **파일 이름**: `00-starting-again.md`처럼 두 자리 발행 순서와 영문 소문자·하이픈으로 작성합니다. `00`은 프롤로그입니다.
- **이전·다음 글**: 같은 폴더의 글을 파일 이름 순서로 연결합니다. 하위 폴더에 속하지 않는 글은 발행일 순서로 연결합니다.
- **글 제목**: `알고 있다고 생각했던 것들 — 개별 글 제목` 형식을 사용합니다.
- **공통 태그**: `알고 있다고 생각했던 것들`을 모든 글에 넣고, 글별 기술 태그를 추가합니다.
- **글의 흐름**: 기존의 이해 → 설명하다 막힌 질문 → 코드·실행 결과·원문 자료로 확인한 과정 → 달라진 이해와 남은 의문.
- **검증 기록**: 기술 글에는 재현에 필요한 실행 환경과 참고 자료 링크를 남기고, 직접 확인한 결과와 추측을 구분합니다.

프롤로그 「개발 10년 차, 그런데 나는 왜 이직이 불안할까?」는 [`00-starting-again.md`](src/content/blog/thought-i-knew/00-starting-again.md)에 있습니다.

### 프로젝트

`src/content/projects/` 디렉터리에 새로운 `.md` 파일을 생성합니다.

```markdown
---
title: "프로젝트 이름"
description: "프로젝트 한 줄 설명"
category: "데스크톱 도구"
tags: ["Rust", "Tauri"]
badges: ["개발 중"]
pubDate: 2026-10-01
githubUrl: "https://github.com/adtstack/..."
demoUrl: "https://..."
featured: true
order: 1
---

## 프로젝트 개요

만든 이유와 현재 상태를 설명합니다.

### 주요 기능

- **기능 이름**: 실제 동작하는 내용을 설명합니다.

### 기술 스택

- **Client**: 사용한 언어와 프레임워크
- **Backend**: 서버 구성과 저장소
```

프로젝트의 시작일과 상태는 `badges`로 표시하고, `order`로 목록 순서를 지정합니다. 확인한 기능과 개발 중인 기능을 구분해 작성합니다.

## 로컬 실행

Node.js 22.12.0 이상이 필요합니다.

```bash
# 의존성 설치
npm ci

# 로컬 개발 서버 실행 (기본: http://localhost:4321)
npm run dev

# 프로덕션 빌드 (dist/ 생성)
npm run build

# 빌드 결과물 로컬 미리보기
npm run preview
```

## 배포

`main` 브랜치에 코드를 커밋하고 푸시하면 GitHub Actions (`.github/workflows/deploy.yml`)가 자동으로 실행되어 `adtstack.github.io`에 정적 사이트가 게시됩니다.
(GitHub 저장소의 `Settings` -> `Pages` -> `Source`가 **GitHub Actions**로 설정되어 있는지 확인하세요.)
