# 인계 절차 — 전임자의 영혼을 내 로컬 AI 메모리에 연결한다 (인계자용)

실행 주체·시점: 인계자가 **dementor 클론 루트**에서 전임자 폴더가 머지된 뒤 실행한다(Claude 는 `/dementor-inherit <id>`, Codex 는 이 파일을 읽혀 수행).
인자: 첫 인자 = 전임자 `<id>`(회사 이메일 @ 앞부분, 예: `jane.doe`). 아래에서 `<id>` 는 전임자, `<me>` 는 인계자 id 다.
소요: 10~20분(매핑에서 묻는 횟수에 따라 다름). 쓰는 파일은 `<id>/inherit/<me>-YYYY-MM-DD.md` 와 내 메모리 디렉터리의 `MEMORY.md`(Codex 경로는 `$CODEX_HOME/AGENTS.md`, 기본 `~/.codex/AGENTS.md`), 그리고 레포 루트 아래 `.dementor-work/`(`.gitignore` 됨) 작업 파일뿐이다.

안전 규칙(공통): 수집은 read-only. `git fetch`·네트워크 호출 금지. 시크릿 값·토큰·개인 연락처를 어떤 파일에도 쓰지 않는다. 사적 DM·개인 프로젝트·가족·커리어 관련 메모리는 제외한다(요약과 6단계 사본에 옮기지 않고, 인계자 머신의 비회사 레포는 짝 후보에서 뺀다). 전임자 원본(`<id>/memory-export/`, `<id>/handoff.md`, `<id>/appendix/`)은 수정하지 않는다. `<id>/` 안에서 내가 쓰는 파일은 `inherit/` 아래 내 요약 파일 하나뿐이다. `main` 에 직접 푸시하지 않는다. 지어내지 않고 모든 항목에 원문 경로 근거를 단다. 확신이 없으면 `(확인 필요)` 로 적는다.

## 0. 공통 규칙 — 먼저 결정하고 시작한다

- **`<회사도메인>`**: 레포 루트 `.dementorrc` 의 `COMPANY_DOMAIN` 값. `sed -n 's/^COMPANY_DOMAIN=//p' "$(git rev-parse --show-toplevel)/.dementorrc" | head -n 1 | tr -d "[:space:]\"'"` 로 읽는다. 비었거나 `example.com` 이면 설정 전이므로 멈추고 "`.dementorrc` 의 `COMPANY_DOMAIN` 을 회사 이메일 도메인으로 바꿔 `main` 에 커밋하세요" 라고 알린다.
- **`<me>` 결정**: 회사 이메일(도메인 `<회사도메인>`)의 @ 앞부분 그대로. Claude 세션이면 시스템 프롬프트의 `userEmail`, 없으면 `git config user.email`, 둘 다 없으면 사용자에게 묻는다. **어느 출처든** 도메인이 `<회사도메인>` 이 아니면(`users.noreply.github.com`·개인 메일 등) 그 값을 쓰지 않고 다음 출처로 폴백하지도 않는다 — 멈추고 회사 이메일을 묻는다. 정규식 `^[a-z0-9]+(\.[a-z0-9]+)*$` 에 안 맞으면 멈추고 묻는다. 출처가 `git config` 이면 파일을 쓰기 전에 "ID = `<me>` (출처: git config) 로 진행할까요?" 를 한 번 묻고 승인 뒤에만 진행한다.
- **오늘 날짜**: `date +%F` 실측값을 `<YYYY-MM-DD>` 로 쓴다(기억으로 쓰지 않는다).
- **실행 위치**: 이 절차는 **메인 세션에서 직접** 수행하고 서브에이전트(Task 등)에 위임하지 않는다 — 서브에이전트 프롬프트에는 메모리 경로가 없어 아래 세션 판별이 틀린다.
- **Codex 홈**: `CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"`. Codex CLI 는 `CODEX_HOME` 이 설정돼 있으면 그 아래 `AGENTS.md`·`config.toml` 을 읽는다(Orca 등은 `~/.codex` 가 아닌 곳을 가리키며, 그때 `~/.codex/AGENTS.md` 가 따로 있어도 실행 중인 Codex 는 읽지 않는다). `~/.codex` 를 하드코딩하지 않는다.
- **세션 판별**(먼저 내가 무엇인지로 가르고, 환경변수는 그 다음이다):
  1. **내가 Claude Code 세션**(시스템 프롬프트가 Claude Code 의 것이고 `CLAUDECODE` 환경변수가 있음)이고 시스템 프롬프트에 persistent file-based memory 경로(`.../<slug>/memory/` 꼴)가 있으면 **Claude 자동 메모리 경로** — 4·5·6단계를 수행한다. Claude 세션은 `$CODEX_HOME` 디렉터리가 있어도 Codex 경로로 가지 않는다(Orca 등은 Claude 세션에도 `CODEX_HOME` 을 넣어 둔다).
  2. **내가 Codex 세션**이고 `CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"; [ -d "$CODEX_HOME" ]` 이면 **Codex 경로** — 4단계 대신 `$CODEX_HOME/AGENTS.md` 끝에 상속 절(요약 파일 한 줄)을 붙인다. 5단계의 표 보고는 수행하되(포인터 = AGENTS.md 절 1개) 복사 제안 고정 문구와 6단계는 생략한다.
  3. 그 외(메모리 경로가 없는 Claude 세션 = 자동 메모리 꺼짐·서브에이전트, 또는 Codex 인데 `$CODEX_HOME` 디렉터리 없음)는 1~3단계와 요약 파일 커밋까지만 하고 "포인터를 심을 메모리 위치를 찾지 못했습니다. 메모리 루트 경로를 알려주세요(`~/.claude/projects` 가 있으면 그것인지 확인)" 라고 묻고 멈춘다. 사용자가 `<root>` 를 주면 Claude 경로로 계속하되 요약 §0 과 5단계 보고에 `(확인 필요)` 를 단다. `$CODEX_HOME`·`~/.claude/projects` 를 새로 만들지 않는다.
- **메모리 루트 `<root>` 역산**: 시스템 프롬프트가 알려준 내 메모리 경로 `P` 가 `<root>/<slug>/memory/` 꼴일 때만 `memory/` 의 두 단계 위가 `<root>` 다(`dirname "$(dirname "$P")"`). 이 꼴은 기본 설정에서만 참이다 — `autoMemoryDirectory` 설정 등으로 메모리 디렉터리를 바꾼 머신에서는 `<slug>/memory` 가 붙지 않는 **평평한 경로**가 오고, 그때 `dirname` 역산은 엉뚱한 상위 폴더가 된다(4단계가 그 아래에 Claude 가 읽지 않는 `MEMORY.md` 를 만든다). 그래서 역산 전에 모양을 검증한다 — 이 절차는 dementor 루트 `$ROOT` 에서 실행되므로 세션의 메모리 경로는 `slug "$ROOT"` 아래여야 한다(`slug` 는 아래 함수, `$ROOT` 는 1단계). 이 블록은 1단계 1 이 `.dementor-work/env.sh` 를 만든 뒤, 4단계 1 에서 실행한다:
  ```bash
  . "$(git rev-parse --show-toplevel)/.dementor-work/env.sh"; P='<시스템 프롬프트의 메모리 경로>'; P=${P%/}
  [ "$(basename "$P")" = memory ] && [ "$(basename "$(dirname "$P")")" = "$(slug "$ROOT")" ] && echo "<root>=$(dirname "$(dirname "$P")")" || echo "메모리 경로가 <root>/<slug>/memory/ 꼴이 아님(커스텀 autoMemoryDirectory?)"
  ```
  두 가지 실패를 구분한다. (1) `basename "$P"` 가 `memory` 인데 부모 슬러그가 `slug "$ROOT"` 와 다르면 레이아웃은 표준이고 **세션이 dementor 루트에서 시작되지 않은 것**(하위 폴더 또는 심링크 경로)이다 — 평평한 경로로 취급하지 말고 "dementor 클론 루트에서 세션을 다시 시작하세요" 라고 멈춘다. (2) `basename "$P"` 가 `memory` 가 아닐 때만 **커스텀 메모리 디렉터리(평평한 경로)** 로 본다: `<root>` 를 역산하지 않고, 4단계 5(dementor 자체 절)는 그 디렉터리 `$P/MEMORY.md` 에 붙이며, 레포별 포인터(4단계 1~4)는 세션 판별 3 처럼 `<root>` 를 사용자에게 묻고 `(확인 필요)` 를 단다(사용자가 모르면 레포별 포인터는 생략하고 5단계 보고에 적는다). `~/.claude/projects` 가 아닐 수 있다(별도 프로필 등). **하드코딩 금지**.
- **slug 규칙**: 로컬 레포 절대경로에서 `[A-Za-z0-9]` 이외의 모든 **문자**를 하이픈 하나로 바꾼 것. 예: `/Users/x/.paperclip/a` → `-Users-x--paperclip-a`. 비ASCII 1문자 = 하이픈 1개(전임자 예: `2026-05_해외사업부/shop-cs` → `-2026-05-------shop-cs`, 하이픈 7 = `_` + 한글 5 + `/`; NFD 분해된 경로는 자모 수만큼). 계산은 문자 단위로 한다 — `LC_ALL=C sed` 는 바이트 단위라 한글 1자가 하이픈 3개가 되어 틀린다:
  ```bash
  slug() { python3 -c 'import re,sys; print(re.sub(r"[^A-Za-z0-9]", "-", sys.argv[1]))' "$1"; }   # python3 이 없으면 node -e 'console.log(process.argv[1].replace(/[^A-Za-z0-9]/g,"-"))' "$1"
  ```
  이 정의는 1단계 1 의 `.dementor-work/env.sh` 에 넣어 두고 모든 코드 블록 첫 줄에서 읽어 들인다(셸 함수·변수는 도구 호출 사이에 유지되지 않는다).
- **메모리 디렉터리 찾기(기존 디렉터리 우선)**: 레포 `R` 의 내 메모리 디렉터리는 순서대로 — (1) `S=$(slug "$R")`; `[ -d "<root>/$S" ]` 이면 그것(정확 일치). (2) 없고 `R` 이 ASCII 만이면(`printf '%s' "$R" | LC_ALL=C grep -q '[^ -~]'` 가 실패) `mkdir -p "<root>/$S/memory"`. (3) `R` 에 비ASCII 가 있으면 **만들지 않는다**: `B=$(slug "$(basename "$R")")`, `PB=$(slug "$(basename "$(dirname "$R")")")` 로 `ls <root> | grep -- "-${B}\$"` 후보를 뽑아, 정확히 하나이고 `-${PB}-${B}` 로 끝나면 그것을 쓰되 `(확인 필요)` 를 달고, 아니면 후보를 보여 주고 묻는다. 꼬리만 같은 다른 프로젝트(예: `~/code/agents` 에 `...-acme-agents`)를 자동 채택하지 않기 위해서다.

## 1단계 — 위치 확인과 읽기

1. 위치와 전제: `ROOT=$PWD` 로 두고 `[ "$(pwd -P)" = "$(git rev-parse --show-toplevel)" ] && [ -f "$ROOT/AGENTS.md" ]` 여야 한다(현재 디렉터리가 곧 클론 루트. `$ROOT` 는 논리 경로를 유지해야 Claude 메모리 슬러그와 맞는다). 아니면 "dementor 클론 루트에서 실행하세요" 라고 멈춘다. 이어서 `git rev-parse --verify -q main >/dev/null && git cat-file -e "main:<id>/handoff.md" 2>/dev/null` 이 아니면 "전임자 폴더가 `main` 에 머지된 뒤 실행하세요(현재 `main` 없음 또는 `<id>/` 미커밋)" 라고 멈춘다.
   셸 변수와 함수는 도구 호출 사이에 유지되지 않는다. 먼저 `W="$(git rev-parse --show-toplevel)/.dementor-work"; rm -rf "$W"; mkdir -p "$W"` 로 작업 폴더를 비워 만든다(이전 실행의 잔여 파일이 3단계 매핑에 섞이지 않게). 아래 다섯 줄을 `$W/env.sh` 로 저장하고(Write 도구로 만든다, `<id>` 와 `<클론 루트 절대경로>` 는 실측값), **이후 모든 코드 블록 첫 줄에서 `. "$(git rev-parse --show-toplevel)/.dementor-work/env.sh"` 로 읽어 들인다**:
   ```bash
   ID='<id>'
   ROOT='<클론 루트 절대경로>'
   W="$ROOT/.dementor-work"
   CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
   slug() { python3 -c 'import re,sys; print(re.sub(r"[^A-Za-z0-9]", "-", sys.argv[1]))' "$1"; }
   ```
2. `$ROOT/<id>/` 가 없으면 `ls "$ROOT" | grep -E '^[a-z0-9]+(\.[a-z0-9]+)*$' | grep -vxE 'prompts|scripts'` 로 ID 폴더 목록을 보여 주고 어느 전임자인지 묻는다(basename 기준이라 클론 경로에 `/.`·`/scripts` 가 있어도 안전하다).
3. 읽는다(읽기 전용):
   - `<id>/handoff.md` 전체. 실제 절 제목은 `grep "^## " <id>/handoff.md` 로 확인한다(예: `## 3. 🔴 계정 비활성화 시 깨지는 자산 목록`, `## 4. 🔴 진행 중·미완 작업`, `## 5. 반복 운영 업무`, `## 8. 함정·교훈`).
   - `<id>/persona.md`. 없으면 요약 파일 §5 에 "persona.md 없음 — handoff §10 으로 대체" 라고 표시하고 §10 을 쓴다.
   - `<id>/memory-export/*/MEMORY.md` 전부. `MEMORY.md` 가 없는 디렉터리(빈 디렉터리)는 읽지 않고 §6·§7 에 "색인 없음" 으로 적는다.
   - `<id>/appendix/03-local-repos.md`. 표 머리글을 보고 **경로별 `origin` 열이 있는지** 확인한다(`grep -n '^| # | 경로' <id>/appendix/03-local-repos.md`). 현행 `upload.md` 로 만든 패키지는 `## 전체 레포 표` 의 앞 네 열이 `| # | 경로 | 종류 | origin |` 순서다. origin 값은 `org/repo` 축약형일 수 있고, 경로 열은 머리글에 적힌 기준 폴더(예: `경로(02_code/ 하위)`)의 상대경로일 수 있다.
4. MEMORY.md 한 줄 색인 형식을 그대로 기억해 둔다(4단계에서 같은 형식으로 붙인다): `- [제목](파일명.md) — 한 줄 요약`.
5. 브랜치: 요약 파일을 쓰기 **전에** `inherit/<me>-<id>` 로 옮긴다 — `git checkout inherit/<me>-<id> 2>/dev/null || git checkout -b inherit/<me>-<id>` (`git fetch` 금지, 로컬 기준). 체크아웃이 실패하면(미커밋 변경·untracked 파일 충돌 등) `stash`·`-f`·현 브랜치 커밋으로 우회하지 말고 멈춰서 알린다. `main` 에는 커밋·푸시하지 않는다.

## 2단계 — 요약 파일 `<id>/inherit/<me>-<YYYY-MM-DD>.md` (100~200줄)

- 같은 날짜 파일이 있으면 덮어쓴다. 다른 날짜 파일은 그대로 둔다.
- 모든 항목 끝에 근거를 단다: `[handoff.md §3]`, `[memory-export/<디렉터리>/<파일>.md]`, `[appendix/03-local-repos.md 전체 레포 표 #N]` 처럼 `<id>/` 아래 상대경로로.
- 사적 DM·개인 프로젝트·가족·커리어에 해당하는 내용(개인 관심사 메모, 비회사 레포의 메모리 등)은 §4·§5 에 옮기지 않고 §0 에 "사적 내용 제외 N건" 으로 건수만 적는다(제외한 사적 항목의 파일명·디렉터리명은 §0 건수 줄·§4·§5 어디에도 쓰지 않는다 — 이름 자체가 내용을 드러낸다. 짝이 맞은 회사 레포의 파일명·디렉터리명은 §4 상위 10개와 근거 표기에 그대로 쓴다. §6·§7 은 레포에 이미 있는 디렉터리명을 그대로 나열하고 `<U>` 에도 포함한다). 전임자 패키지가 현행 `upload.md` 이전 판으로 만들어졌으면 이런 항목이 섞여 있을 수 있다.
- 절 제목은 아래 8개로 고정한다(번호·문구 그대로):
  - `## 0. 출처·생성일` — `<id>`, 생성일, 읽은 파일 목록과 각 줄 수, persona.md 유무, 세션 판별 결과와 `(확인 필요)` 항목, 사적 내용 제외 N건(건수만), 기존 패키지 QA 히트 N건(`경로:행` 만 적고 일치 문자열은 옮기지 않는다; 인계자 수정 불가; 없으면 0).
  - `## 1. 지금 당장 깨질 수 있는 것 (handoff §3)` — §3 표에서 긴급도 높은 순으로 항목·위치·이관 방법.
  - `## 2. 미완 작업 (handoff §4)` — 티켓/PR 별 현재 상태·다음 단계·차단 요인.
  - `## 3. 반복 운영 (handoff §5)` — 주기·업무·실패 시 대응.
  - `## 4. 함정·교훈 (handoff §8 + feedback 메모리 상위)` — §8 사고 기록 + 3단계에서 짝이 맞은 디렉터리의 `type: feedback` 파일 중 MEMORY.md 색인 순 상위 10개(파일명·description 한 줄).
  - `## 5. 페르소나 핵심 10줄` — persona.md 에서 판단 기준·금지 표현·승인 습관 위주 10줄.
  - `## 6. 원문 색인` — 디렉터리마다 한 줄: `memory-export/<디렉터리>/MEMORY.md` 경로 · 파일 수(`ls | wc -l`) · feedback 수(`grep -lE '^\s*type: feedback\s*$' *.md | wc -l`). 색인 없는 디렉터리도 "색인 없음" 으로 적는다.
  - `## 7. 매핑 결과` — 3단계 결과. §7 은 3단계가 끝나야 채워지므로 **커밋은 3단계 뒤**에 한다.
- 커밋·푸시·PR(3단계 뒤, 순서대로):
  1. `git branch --show-current` 가 1단계 5 에서 옮긴 `inherit/<me>-<id>` 인지 확인한다. 아니면(`main` 등) 멈춘다. `main` 이나 다른 브랜치에는 커밋·푸시하지 않는다.
  2. `bash scripts/qa.sh <id>` 를 돌린다. qa.sh 는 `<id>/` 전체(전임자 원문 포함)를 검사하므로 히트를 경로로 나눈다: `bash scripts/qa.sh <id> | grep -F -- "/<id>/inherit/"` 가 비어 있지 않으면(내 요약 파일의 히트) 커밋하지 말고 그 줄을 고쳐 다시 돌린다. 그 밖의 히트(전임자 원문 — 인계자 수정 금지)는 요약 §0 에 "기존 패키지 QA 히트 N건" 과 **`경로:행` 만** 적고 커밋은 진행한다 — qa.sh 출력 각 줄의 `: <일치 문자열>` 부분(24자까지 — AKIA 키 20자·휴대폰 번호 13자가 통째로 들어간다)은 §0 에도 PR 본문에도 옮기지 않는다. 이 경우 PR 의 `qa` 워크플로도 같은 히트로 실패하므로 PR 본문에 그 사실과 `경로:행` 목록을 적는다. 요약 파일을 **한 글자라도 고친 뒤에는**(§0 에 히트를 적는 편집 포함) 반드시 `bash scripts/qa.sh <id> | grep -F -- "/<id>/inherit/"` 를 다시 돌려 비어 있을 때만 커밋한다.
  3. 요약 파일만 스테이징: `git add <id>/inherit/<me>-<YYYY-MM-DD>.md` → `git commit -m "feat: add inherit summary <id> → <me> (<YYYY-MM-DD>)"`.
  4. **push 는 사용자에게 묻는다**(허락 전 푸시 금지). 허락하면 `AGENTS.md` 안전 규칙의 공개 레포 확인을 먼저 하고(`PUBLIC` 이면 푸시하지 않고 멈춘다) `git push -u origin inherit/<me>-<id>`.
  5. `gh` 가 있으면 `gh pr create --base main --head inherit/<me>-<id> --title "inherit: <id> → <me>" --body "<요약 §0·§7 요약>"`. 없으면 push 출력에 나온 PR 생성 URL 을 사용자에게 안내한다.

## 3단계 — 매핑: 전임자 메모리 디렉터리 ↔ 인계자 로컬 레포

디렉터리명은 전임자 머신의 절대경로 slug 다(예: `-Users-janedoe-Documents-main-02-code-acme-data-pipeline`). 사람 이름·상위 폴더가 다르므로 **꼬리**로만 맞춘다. 먼저 두 목록을 만든다(`git fetch` 금지, config 읽기만).

```bash
. "$(git rev-parse --show-toplevel)/.dementor-work/env.sh"
ls -d "$ROOT/$ID"/memory-export/*/MEMORY.md | xargs -n1 dirname | xargs -n1 basename > "$W/dirs.txt"   # 색인 있는 디렉터리만
find ~ -maxdepth 5 -name .git -not -path '*/node_modules/*' -not -path '*/.Trash/*' 2>/dev/null \
  | while read -r g; do r=$(dirname "$g"); printf '%s\t%s\n' "$r" "$(git -C "$r" config --get remote.origin.url)"; done > "$W/local-repos.all.tsv"
# 회사 레포만 후보로 남긴다(개인 프로젝트 제외). ORG = dementor 자체 origin 의 org. 03 의 origin 열에 다른 회사 org 가 더 있으면 그 org 행도 같은 식으로 추가한다.
ORG=$(git -C "$ROOT" config --get remote.origin.url | sed -E 's#\.git$##; s#.*[:/]([^/]+)/[^/]+$#\1#')
awk -F'\t' -v o="$ORG" 'index($2, ":" o "/") || index($2, "/" o "/")' "$W/local-repos.all.tsv" > "$W/local-repos.tsv"
awk -F'\t' '$2 == ""' "$W/local-repos.all.tsv"   # origin 없는 레포 — 목록을 보여 주고 회사 레포인지 묻는다. 사용자가 지목한 행만 "$W/local-repos.tsv" 에 덧붙인다. 그 밖(다른 org·개인 계정)은 후보에서 뺀다.
```

폴백 순서(앞에서 맞으면 뒤로 가지 않는다):

- **(a) origin 으로** — 03 에 경로별 origin 열이 있을 때. 03 행의 경로 → slug 꼬리로 전임자 디렉터리를 찾고, 같은 행의 origin 과 인계자 레포 origin(`org/repo` 로 정규화)이 같으면 짝.
  ```bash
  . "$(git rev-parse --show-toplevel)/.dementor-work/env.sh"
  grep -E '^\| [0-9]+ \|' "$ROOT/$ID/appendix/03-local-repos.md" | awk -F'|' '{gsub(/[`🔴 ]/,"",$3); gsub(/ /,"",$5); print $3"\t"$5}' > "$W/pred-origins.tsv"   # 경로<TAB>org/repo
  awk -F'\t' '{u=$2; sub(/\.git$/,"",u); n=split(u,a,/[:\/]/); print $1"\t"a[n-1]"/"a[n]}' "$W/local-repos.tsv" > "$W/local-origins.tsv"   # 경로<TAB>org/repo
  # 03 경로 P 의 slug: S=$(slug "$P"); grep -- "-${S}\$" "$W/dirs.txt"      # slug 는 0 의 함수
  ```
  org/repo 가 같은 인계자 레포가 여럿(클론 2개·워크트리)이면 묻는다. 원격 URL 이 로컬 경로인 행(예: `../acme-sales-platform`)은 (b) 로 넘긴다.
- **(b) 디렉터리명 꼬리 ↔ 로컬 레포 basename** — 03 에 origin 이 없거나 (a) 에서 못 맞춘 디렉터리.
  ```bash
  . "$(git rev-parse --show-toplevel)/.dementor-work/env.sh"
  grep -E '^\| [0-9]+ \|' "$ROOT/$ID/appendix/03-local-repos.md" | awk -F'|' '{gsub(/[`🔴 ]/,"",$3); n=split($3,a,"/"); print a[n]}' | while read -r p; do slug "$p"; done | sort -u > "$W/pred-basenames.txt"   # 전임자 레포 basename 의 slug 집합(경로 열은 origin 열이 없어도 있다; 03 표가 없으면 빈 파일)
  while IFS=$'\t' read -r r o; do b=$(slug "$(basename "$r")"); grep -- "-${b}\$" "$W/dirs.txt" | sed "s|^|$r	|"; done < "$W/local-repos.tsv"
  ```
  꼬리 일치는 **후보**일 뿐이다 — slug 가 `/` 도 하이픈으로 바꿔 레포 이름 경계가 사라지므로, `~/agents` 는 `...-acme-agents` 에, `~/redash` 는 `...-data-redash` 에, `~/api` 는 `...-shop-admin-api` 에 맞는다. 후보 `r`(basename slug `b`) ↔ `D` 를 **자동 짝으로 치는 조건**은 둘 중 하나다: (i) `grep -qxF "$b" "$W/pred-basenames.txt"` — 전임자도 같은 basename 의 레포를 가졌다. (ii) 남는 앞부분 `${D%-$b}` 가 이미 확정된 다른 짝의 앞부분과 같다(공통 상위 폴더, 예: `-Users-janedoe-Documents-main-02-code`). 이를 위해 짝이 확정될 때마다 앞부분을 모아 둔다: (a) 는 `echo "${D%-$(slug "$P")}"`, (b) 는 `echo "${D%-$b}"` 를 `"$W/pred-prefixes.txt"` 에 추가하고, (ii) 는 `grep -qxF "${D%-$b}" "$W/pred-prefixes.txt"` 로 본다. 둘 다 아니면 자동으로 짝짓지 않고 후보를 보여 주고 묻는다. 한 디렉터리에 후보 레포가 여럿이어도 묻는다. basename 이 `default` `workdir` `workspace` `main` `wt` `src` 처럼 범용 단어 하나뿐인 레포는 짝으로 치지 않는다.
  **두 번째 패스(레포 하위 폴더 세션)**: (a)·(b) 로 짝이 맞은 디렉터리 `D` ↔ 레포 `R` 마다 `grep -- "^${D}-" "$W/dirs.txt"` 로 `D-<꼬리>` 꼴 디렉터리를 찾는다(예: `...-acme-agents` 에 대한 `...-acme-agents-billing-agent` — 레포 하위 폴더에서 띄운 세션의 메모리). 꼬리 `T` 에 대응하는 하위 폴더 후보는 글자 그대로 `R/<T>` 를 보지 않고(하이픈이 `/`·`_`·`.` 어느 것이었는지 모른다 — 실데이터: `billing-agent` 의 실제 폴더는 `billing_agent`) 상대경로의 slug 로 구한다:
  ```bash
  . "$(git rev-parse --show-toplevel)/.dementor-work/env.sh"; R='<레포 절대경로>'; T='<꼬리>'; find "$R" -mindepth 1 -maxdepth 2 -type d -not -path '*/.git/*' -not -path '*/node_modules/*' | while read -r d; do [ "$(slug "${d#$R/}")" = "$T" ] && echo "$d"; done
  ```
  후보가 정확히 1개면 같은 레포 `R` 의 **추가 디렉터리**로 짝(4단계에서 원문 색인 줄이 하나 더 붙는다)으로 치되 `(확인 필요)` 를 달고, 0개면 (c) 로 보내고, 2개 이상이면 후보를 보여 주고 묻는다 — 0 의 메모리 디렉터리 찾기 (3) 과 같은 규칙이다.
- **(c) 못 맞춘 디렉터리** — UUID 기반 `paperclip-instances-*`, `multica-workspaces-*`, `obsd-*`, 홈 루트(`-Users-<이름>`), 비ASCII 경로 류가 대부분이다. 짝을 지어내지 말고 §7 에 디렉터리명·파일 수·feedback 수와 함께 목록으로 남긴다.

§7 에는 "짝 맞은 레포(전임자 디렉터리 → 인계자 절대경로, 근거 (a)/(b)/두 번째 패스)" 와 "못 맞춘 디렉터리" 두 표를 쓴다. 한 레포에 디렉터리가 여럿이면 모두 적는다. 못 맞춘 표에는 색인 없는(빈) 디렉터리도 "색인 없음" 행으로 넣는다(5단계 `<U>` 는 이 표의 행 수다). 회사 org 가 아닌 로컬 레포 경로는 어느 표에도 쓰지 않는다.

## 4단계 — 포인터 심기 (Claude 자동 메모리 경로)

짝이 맞은 로컬 레포마다 내 메모리 디렉터리의 `MEMORY.md` 에 절을 붙인다. 원문 복사가 아니라 **링크 두 줄**이다.

1. `<root>` 는 0 의 역산 규칙으로(모양 검증 포함 — 평평한 커스텀 메모리 디렉터리면 `<root>` 를 사용자에게 묻고 `(확인 필요)` 를 단다). 레포 `R` 의 메모리 디렉터리는 0 의 **메모리 디렉터리 찾기** 규칙(정확 slug → ASCII 면 `mkdir -p` → 비ASCII 는 꼬리 검색, 만들지 않음)으로 정한다. `MEMORY.md` 가 없으면 새로 만든다.
2. 이미 같은 제목의 절이 있으면 건너뛴다: `grep -qxF "## 상속: <id> (<YYYY-MM-DD>, dementor)" MEMORY.md`.
3. 위치: 기본은 `MEMORY.md` **끝**. 다만 Claude Code 는 `MEMORY.md` 를 처음 **200줄·25,000바이트**까지만 로드한다(2.1.308 바이너리의 `"MEMORY.md",…=200,…=25000`, "truncated to the first N lines"). 붙이기 전에 `wc -l`·`wc -c` 를 보고 **붙인 뒤 200줄 또는 25,000바이트를 넘으면** 끝 대신 첫 색인 줄(`grep -n -m1 '^- \[' MEMORY.md`, 없으면 1행) 앞에 삽입하고, 5단계 보고에 "맨 위 삽입" 으로 적는다.
4. 붙이는 형식(기존 한 줄 색인 형식과 같게, `<dementor절대경로>` 는 `$ROOT` 실측값). 3단계 두 번째 패스로 레포에 디렉터리가 여럿이면 원문 색인 줄을 디렉터리 수만큼 쓴다:
   ```markdown

   ## 상속: <id> (<YYYY-MM-DD>, dementor)
   - [<id> 인계 요약](<dementor절대경로>/<id>/inherit/<me>-<YYYY-MM-DD>.md) — 함정·미완·반복운영 요약
   - [<id> 원문 메모리 색인](<dementor절대경로>/<id>/memory-export/<원본디렉터리>/MEMORY.md) — 필요할 때만 연다
   ```
5. dementor 레포 자체의 프로젝트 메모리(`<root>/<slug($ROOT)>/memory/MEMORY.md`, 같은 찾기·위치 규칙. 평평한 커스텀 메모리 디렉터리면 시스템 프롬프트가 알려준 그 경로의 `MEMORY.md`)에도 같은 제목의 절을 붙이되 **요약 파일 한 줄 + `memory-export/` 루트 한 줄**만 쓴다.
6. Codex 경로(세션 판별 2)일 때는 1~5 대신 `$CODEX_HOME/AGENTS.md`(0 의 Codex 홈; 기본 `~/.codex/AGENTS.md`) 끝에 같은 제목의 절 + 요약 파일 한 줄만 붙인다. 5단계의 표 보고는 하되 복사 제안 고정 문구와 6단계는 생략한다. 이미 같은 제목이 있으면 건너뛴다. `$CODEX_HOME` 디렉터리가 없으면 만들지 않는다(세션 판별 3 으로 간다).

## 5단계 — 결과 보고 (고정 문구)

등록한 포인터 수(레포별 경로, 삽입 위치 끝/맨 위), 건너뛴 수(이미 있음), 짝 못 찾은 디렉터리 수 `<U>`(= §7 "못 맞춘 디렉터리" 표의 행 수. 색인 없는(빈) 디렉터리를 포함하며, 그중 "색인 없음 N개" 를 별도 칸으로 적는다), `(확인 필요)` 항목, 사적 내용 제외 수, 기존 패키지 QA 히트 수(`경로:행` 만), 요약 파일 경로와 커밋 해시를 표로 보고한 뒤 아래 문단을 그대로 붙인다. `N` 은 **짝이 맞은 프로젝트**의 memory-export 에서 `grep -lE '^\s*type: feedback\s*$' *.md | wc -l` 합계다(파일명 접두 `feedback_` 가 아니라 프론트매터 `type` 기준 — `gotcha_*` 파일도 `type: feedback` 인 경우가 있다).

> 등록한 포인터 <P>개, 짝 못 찾은 디렉터리 <U>개. 더 깊이 들이려면 <id> 의 feedback 유형 메모리 N개를 reference 유형으로 복사할 수 있습니다. 원문은 바뀌지 않고 inherited_<id>_ 접두어로 구분되며 한 번에 지울 수 있습니다. 원하면 복사해 라고 하세요.

사용자가 답하기 전에는 **아무것도 복사하지 않는다**.

## 6단계 — "복사해" 를 받았을 때만

- 대상: 4단계에서 짝이 맞은 프로젝트에 한해, 그 `memory-export/<디렉터리>/` 의 프론트매터 `type: feedback` 파일만. `type: project` / `type: user` 는 **어떤 경우에도 복사하지 않는다**(사용자가 요청해도 거절하고 이유를 말한다). `reference`·`MEMORY.md` 도 복사 대상이 아니다. 2단계의 사적 내용 기준(사적 DM·개인 프로젝트·가족·커리어·이직)에 해당하는 feedback 파일은 복사하지 않고 건수만 보고한다(파일명은 쓰지 않는다). 판정이 애매하면 복사 전에 description 한 줄을 보여 주고 묻는다.
- 사본 이름: `<내 메모리 디렉터리>/inherited_<id>_<원본파일명>`. 원본은 손대지 않는다. 같은 이름이 이미 있으면 건너뛰고 보고한다.
- 프론트매터 재작성(나머지 키는 그대로 둔다). 들여쓰기와 무관하게: `^\s*type: feedback` 에 매치된 **바로 그 줄**을 들여쓰기 그대로 `type: reference` 로 바꾸고, 그 아래에 `inherited_from: <id>`·`original_type: feedback`·`inherited_at: <YYYY-MM-DD>` 세 줄을 **같은 들여쓰기**로 넣는다. `metadata:` 가 없으면 만들지 않는다. 현행 포맷(`metadata:` 아래 두 칸) 예:
  ```yaml
  ---
  name: feedback-slack-draft-before-send
  description: "Never send a Slack message to colleagues ... draft it, don't send it"
  metadata:
    node_type: memory
    type: reference            # feedback → reference 로 바꾼다
    inherited_from: <id>       # 아래 세 줄을 추가한다
    original_type: feedback
    inherited_at: <YYYY-MM-DD>
    originSessionId: ...       # 원본 값 유지
    modified: ...              # 원본 값 유지
  ---
  ```
  구포맷(`metadata:` 없이 최상위 `type: feedback`)도 같은 방식 — 최상위 줄을 `type: reference` 로 바꾸고 세 줄을 들여쓰기 없이 그 아래에 넣는다.
- 파일마다 `MEMORY.md` 의 상속 절 끝에 한 줄 색인을 추가한다(기존 형식): `- [상속: <원본 name>](inherited_<id>_<원본파일명>) — <description 요약> (원출처 <id>)`.
- 끝에 보고: 복사한 파일 수(디렉터리별), 건너뛴 수, 되돌리는 방법 두 줄.
  ```bash
  rm <memdir>/inherited_<id>_*                      # 사본 삭제 (원문은 dementor 에 그대로 있다)
  sed -i '' '/inherited_<id>_/d' <memdir>/MEMORY.md  # 색인 줄 제거 (macOS; Linux 는 sed -i)
  ```
