# adtstack.github.io

[adtstack.github.io](https://adtstack.github.io) — 공개 프로젝트 포트폴리오 사이트.

## 구조

- `index.html` — 랜딩 페이지 (프로젝트 카드 + 상태 뱃지)
- `projects/<이름>/index.html` — 프로젝트별 상세 페이지
  (briefcal, forktail, kinflow, kaos, us-news-rag)
- `assets/style.css` — 공통 스타일시트
- `assets/diagrams/` — kaos 아키텍처 다이어그램 (원본: kaos 저장소 `engineering/diagrams`)

빌드 단계 없는 정적 HTML이며 GitHub Pages가 `main` 브랜치 루트에서 바로 게시한다.

## 수정 방법

- 프로젝트 설명 변경: 해당 `projects/*/index.html`만 고쳐 커밋하면 자동 재배포된다.
- 카드 요약·상태 뱃지: `index.html`의 카드와 상세 페이지의 뱃지를 함께 맞춘다.
- 카피 원칙: 기능 소개 중심(테스트 개수 같은 통계 숫자는 쓰지 않음), 미완성 상태는
  정직한 뱃지로 표기. 프로젝트 내용 원문은 각 저장소 README를 기준으로 요약한다.
