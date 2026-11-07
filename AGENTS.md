# dementor

퇴사자의 AI 메모리·인수인계 패키지(영혼)를 ID 폴더 하나에 보존하는 비공개 레포다.
인계자는 같은 레포를 클론한 뒤 트리거 한 줄로 전임자 폴더를 읽고, 자기 로컬 AI 메모리에 포인터를 심는다.
이 파일은 Claude Code 와 Codex 가 공용으로 읽는 진입점이다. 실제 절차는 `prompts/` 아래 파일에 있다.

## 폴더 규칙

- 최상위 폴더 하나가 사람 하나다. 폴더명(ID)은 회사 이메일의 `@` 앞부분 그대로다(예: `jane.doe`, `j.kim`). 정규식 `^[a-z0-9]+(\.[a-z0-9]+)*$` 에 맞아야 한다.
- 예약된 최상위 이름(ID 로 쓸 수 없음): `AGENTS.md` `CLAUDE.md` `README.md` `SECURITY.md` `LICENSE` `prompts` `scripts` `.claude` `.github` `.dementorrc`
- ID 폴더 안: `handoff.md` · `persona.md` · `appendix/01~18` · `memory-export/<원본 디렉터리명>/` · `memory-export/_config/` · `inherit/<인계자id>-YYYY-MM-DD.md` · `_raw/`(선택, 수집 스크립트 `.sh`·`.py` 만 추적)
- 회사 도메인(이하 `<회사도메인>`): 레포 루트 `.dementorrc` 의 `COMPANY_DOMAIN` 값이다. `sed -n 's/^COMPANY_DOMAIN=//p' "$(git rev-parse --show-toplevel)/.dementorrc" | head -n 1 | tr -d "[:space:]\"'"` 로 읽는다(기억이나 추측으로 정하지 않는다). 값이 비었거나 `example.com` 이면 설정 전이므로 멈추고 "`.dementorrc` 의 `COMPANY_DOMAIN` 을 회사 이메일 도메인으로 바꿔 `main` 에 커밋하세요" 라고 알린다.
- 자기 ID 결정(업로드·인계 공통): Claude 세션이면 시스템 프롬프트의 `userEmail`, 없으면 `git config user.email`, 둘 다 없으면 사용자에게 묻는다. 어느 출처든 도메인이 `<회사도메인>` 이 아니면(개인 메일·`users.noreply.github.com` 등) 다음 출처로 폴백하지 않고 멈춰서 회사 이메일을 묻는다. 출처가 `git config` 이면 쓰기 전에 "ID = `<id>` (출처: git config) 로 진행할까요?" 를 한 번 묻는다. `@` 앞부분을 그대로 쓰고, 정규식에 안 맞으면 멈추고 묻는다.

## 트리거

| 흐름 | 트리거 예시 | 할 일 |
|---|---|---|
| 업로드(퇴사자) | "나 퇴사 예정", "영혼 업로드", "페르소나 업로드", "인수인계 패키지 만들어", `/dementor-upload` | `prompts/upload.md` 를 읽고 끝까지 수행 |
| 인계(인계자) | "OOO 인수인계 받…", "OOO 인계받…", "OOO 상속", "OOO 메모리 가져와", `/dementor-inherit OOO` | `prompts/inherit.md` 를 읽고 끝까지 수행(OOO = 전임자 ID) |

두 흐름의 판별은 동사로 한다: 받…/인계받…/상속/가져와 → 인계, 업로드/만들어/퇴사 예정 → 업로드. 타인 ID 와 업로드 동사가 함께 있으면 어느 흐름인지 묻는다.

트리거 문장에서 전임자 ID 를 뽑는 규칙:

- 이메일이 있으면 `@` 앞부분.
- 폴더명 그대로(예: `jane.doe`)면 그대로.
- 한글 이름만 있으면(예: "홍길동") 레포 루트를 `ls` 해 ID 폴더 목록을 보여주고 고르게 한다. 추측해서 고르지 않는다.

## 안전 규칙(모든 절차 공통)

- 수집은 read-only. 쓰기·코멘트·설정 변경·재인증 시도 금지.
- 시크릿 값·토큰·비밀번호·개인 연락처는 어디에도 기록하지 않는다(이름·경로·만료일만).
- 사적 DM·개인 프로젝트·가족·커리어 메모리는 제외한다.
- 원본 메모리는 수정하지 않는다. 업로드는 복사만 하고, 인계가 쓰는 곳은 인계자 자신의 메모리 끝에 붙이는 포인터 절과 `inherited_<id>_` 접두어 사본뿐이다.
- 타인의 `<id>/` 폴더는 수정하지 않는다. 자기 폴더, 그리고 인계 때 만드는 `<전임자id>/inherit/<내id>-*.md` 만 쓴다.
- `main` 에 직접 푸시하지 않는다. 항상 브랜치 + PR.
- 공개(public) 레포에는 패키지를 올리지 않는다. `<id>/` 아래 파일을 푸시하기 전에 `gh repo view "$(git config --get remote.origin.url | sed -E 's#\.git$##; s#.*[:/]([^/]+/[^/]+)$#\1#')" --json visibility -q .visibility` 를 확인해 `PUBLIC` 이면 멈춘다(공개 템플릿의 포크는 공개다 — 비공개 레포를 새로 만들어야 한다). origin 호스트가 github.com 이 아니면(GitHub Enterprise) 명령 앞에 `GH_HOST=<호스트>` 를 붙인다. `gh` 가 없거나 조회가 실패하면 비공개 레포인지 사용자에게 묻고, 답을 받은 뒤에만 진행한다.
- 지어내지 않는다. 모든 사실에 원문 경로나 URL 근거를 단다. 확신이 없으면 `(확인 필요)` 로 표기한다.

## Claude 와 Codex 의 차이

슬래시 커맨드(`/dementor-upload`, `/dementor-inherit`)는 `.claude/commands/` 에 있으므로 Claude Code 전용이다. Codex 는 위 표의 자연어 트리거로 같은 `prompts/*.md` 를 읽으면 된다. 서브에이전트가 없는 환경에서는 수집기를 순차로 돌린다.
인계 절차에서 상속 절을 어디에 붙일지(Claude 자동 메모리 `<메모리 루트>/<slug>/memory/MEMORY.md` 인지 `$CODEX_HOME/AGENTS.md` 인지)의 세션 판별은 `prompts/inherit.md` §0 을 따른다. 메모리 루트는 세션이 알려주는 경로에서 읽고, Codex 홈은 `CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"` 로 정한다. 둘 다 하드코딩하지 않는다.
