---
title: "Astro와 Tailwind CSS로 블로그를 재구성한 이유"
description: "무거운 SPA 프레임워크 대신 콘텐츠 중심의 정적 사이트 제너레이터(SSG)를 선택해 0ms 로딩과 개발 생산성을 모두 잡은 경험."
pubDate: 2026-09-15
tags: ["Astro", "TailwindCSS", "웹개발"]
featured: false
---

## 블로그에는 React 런타임이 필요 없다

기존에 많은 개발 블로그들이 Next.js나 Gatsby 같은 React 기반 프레임워크를 많이 사용해왔습니다. 물론 풍부한 인터랙션과 컴포넌트 생태계의 이점이 있지만, 본질적으로 읽기 전용인 기술 블로그에서 클라이언트로 수백 킬로바이트의 JavaScript 런타임을 전송하고 하이드레이션(Hydration)을 거치는 것은 낭비에 가깝습니다.

### Astro를 선택한 이유

1. **Zero JS by Default**: 기본적으로 빌드 시 순수 HTML과 CSS만 생성됩니다. 인터랙티브한 위젯이 필요한 곳에만 아일랜드 아키텍처(Islands Architecture)를 적용할 수 있습니다.
2. **콘텐츠 컬렉션(Content Layer)**: `src/content/` 디렉터리에 Zod 스키마를 붙여 마크다운과 MDX 파일의 frontmatter를 엄격하게 타입 검증(type-safe)할 수 있습니다.
3. **완벽한 GitHub Pages 궁합**: 빌드 결과물이 `dist/`에 완전한 정적 파일로 떨어지므로 GitHub Actions를 통한 무료 배포가 매우 간결합니다.

### Tailwind CSS와의 시너지

Tailwind CSS v4의 초고속 컴파일러와 조합하여 다크 모드, 타이포그래피, 반응형 그리드를 스타일시트 분리 없이 선언적으로 작성할 수 있었습니다. 특히 OS의 다크 모드 설정과 사용자 토글 상태를 자연스럽게 동기화하는 데 큰 도움이 되었습니다.
