# adtstack.github.io

[https://adtstack.github.io](https://adtstack.github.io) — **만들어서 직접 씁니다.**  
필요한 소프트웨어를 직접 설계하고 제작하며, 일상에서 매일 사용하는 개발자의 기술 블로그 & 프로젝트 포트폴리오 사이트입니다.

---

## 🛠 기술 스택

- **프레임워크**: [Astro 5](https://astro.build/) (Zero-JS SSG, 정적 사이트 제너레이터)
- **스타일링**: [Tailwind CSS v4](https://tailwindcss.com/) & Pretendard Variable Font
- **테마 지원**: 다크 모드 / 라이트 모드 실시간 토글 (OS 선호도 자동 감지 및 로컬 스토리지 유지)
- **콘텐츠 관리**: Astro Content Collections (`src/content/`) 기반 Type-safe 스키마 검증
- **배포**: GitHub Actions 기반 [GitHub Pages](https://pages.github.com/) 자동 빌드 및 배포

---

## 📂 프로젝트 구조

```text
├── .github/workflows/deploy.yml # GitHub Pages 자동 배포 액션
├── src/
│   ├── assets/                  # 이미지, 폰트 에셋
│   ├── components/              # Header, Footer, ThemeToggle, BaseHead 등
│   ├── content/
│   │   ├── blog/                # 기술 블로그 글 마크다운 (.md, .mdx)
│   │   └── projects/            # 프로젝트 쇼케이스 마크다운 (.md, .mdx)
│   ├── layouts/                 # BlogPost, ProjectPost 레이아웃
│   ├── pages/                   # 사이트 라우트 (/, /blog, /projects, /about, /rss.xml)
│   ├── styles/global.css        # Tailwind v4 및 전역 스타일
│   ├── consts.ts                # 전역 사이트 상수 (TITLE, DESCRIPTION 등)
│   └── content.config.ts        # Content Collections Zod 스키마 정의
├── public/                      # favicon 등 정적 파일
├── astro.config.mjs             # Astro 설정 파일
└── package.json
```

---

## ✍️ 콘텐츠 작성 가이드

### 1. 새 블로그 글 추가하기
`src/content/blog/` 디렉터리에 새로운 `.md` 또는 `.mdx` 파일을 생성합니다.

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

### 2. 새 프로젝트 추가하기
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

## 프로젝트 개요 및 상세 설명...
```

---

## 💻 로컬 개발 환경

```bash
# 의존성 설치
npm install

# 로컬 개발 서버 실행 (기본: http://localhost:4321)
npm run dev

# 프로덕션 빌드 (dist/ 생성)
npm run build

# 빌드 결과물 로컬 미리보기
npm run preview
```

---

## 🚀 배포

`main` 브랜치에 코드를 커밋하고 푸시하면 GitHub Actions (`.github/workflows/deploy.yml`)가 자동으로 실행되어 `adtstack.github.io`에 정적 사이트가 게시됩니다.
(GitHub 저장소의 `Settings` -> `Pages` -> `Source`가 **GitHub Actions**로 설정되어 있는지 확인하세요.)
