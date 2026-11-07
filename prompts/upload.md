# dementor 업로드 — 인수인계 패키지 + 페르소나 수집 절차 (퇴사자용)

이 파일은 `AGENTS.md` 의 업로드 트리거 또는 `/dementor-upload` 로 실행된다. 사람이 Claude Code 나 Codex 세션에 통째로 붙여넣어도 그대로 동작한다.
결과물은 이 레포의 `<id>/` 폴더 하나로 나오고, 끝나면 `soul/<id>` 브랜치로 PR 이 열린다. 1~2시간 걸린다.
도중에 뜨는 조회(읽기) 권한 요청은 허용해도 된다. 파일 쓰기는 `<레포루트>/<id>/` 아래뿐이고 `git push`·`gh pr create` 는 6단계에서만 나오니, 그 요청은 내용을 보고 허용하라. 시크릿 값·토큰·비밀번호는 어디에도 기록되지 않고(이름·경로·만료일만), 사적 DM·개인 프로젝트는 제외된다.

----------------------------------------------------------------------

너는 내 인수인계 패키지를 만드는 세션이다. 수집은 전부 **read-only** 다. 조회가 막히면 "미수집/부분" 과 사유를 적고 넘어간다. 지어내지 않는다. 모든 사실 뒤에 근거 `[파일명 §절]` 또는 URL 을 붙이고, 추정은 `(추정)` 으로 표기한다. DB/Iceberg/Glue/dbt 등 데이터 테이블은 '테이블'로 쓴다.

안전 규칙(전 단계 공통):
- 쓰는 곳은 `<레포루트>/<id>/` 뿐이고, git 쓰기(커밋·푸시)는 6단계에서 `soul/<id>` 브랜치에만 한다. 그 밖의 쓰기·푸시·코멘트·설정 변경·재인증 시도는 하지 않는다.
- 시크릿 값·토큰·비밀번호·개인 연락처는 appendix 와 본문 어디에도 쓰지 않는다(이름·경로·만료일만).
- 사적 DM·개인 프로젝트·가족·커리어 관련 메모리는 제외한다.
- 원본 메모리 파일과 타인의 `<id>/` 폴더는 수정하지 않는다. `main` 에 직접 푸시하지 않는다.

## 0단계 — ID · 출력 폴더 · 브랜치
- 레포 루트 = `git rev-parse --show-toplevel`. 루트에 `AGENTS.md` 가 없으면 dementor 클론이 아니므로 멈추고 알린다.
- `<회사도메인>` = 레포 루트 `.dementorrc` 의 `COMPANY_DOMAIN` 값. `sed -n 's/^COMPANY_DOMAIN=//p' "$(git rev-parse --show-toplevel)/.dementorrc" | head -n 1 | tr -d "[:space:]\"'"` 로 읽는다. 비었거나 `example.com` 이면 설정 전이므로 멈추고 "`.dementorrc` 의 `COMPANY_DOMAIN` 을 회사 이메일 도메인으로 바꿔 `main` 에 커밋하세요" 라고 알린다.
- 공개 레포 차단: 수집을 시작하기 **전에** `gh repo view "$(git config --get remote.origin.url | sed -E 's#\.git$##; s#.*[:/]([^/]+/[^/]+)$#\1#')" --json visibility -q .visibility` 를 본다. `PUBLIC` 이면 멈추고 "이 레포는 공개입니다. 패키지에는 사내 식별자와 판단 기록이 들어가므로 비공개 레포에서만 실행하세요(공개 템플릿의 포크는 공개입니다)" 라고 알린다. origin 호스트가 github.com 이 아니면(GitHub Enterprise) 명령 앞에 `GH_HOST=<호스트>` 를 붙인다. `gh` 가 없거나 조회가 실패하면 비공개 레포인지 사용자에게 묻고, 답을 받은 뒤에만 진행한다.
- `<id>` = 회사 이메일(도메인 `<회사도메인>`)의 `@` 앞부분 그대로(예: `jane.doe`). Claude 세션이면 시스템 프롬프트의 userEmail, 없으면 `git config user.email`, 둘 다 없으면 사용자에게 묻는다. **어느 출처든** 도메인이 `<회사도메인>` 이 아니면(`users.noreply.github.com`·개인 메일 등) 그 값을 쓰지 않고 다음 출처로 폴백하지도 않는다 — 멈추고 회사 이메일을 묻는다. 정규식 `^[a-z0-9]+(\.[a-z0-9]+)*$` 에 안 맞으면 멈추고 묻는다.
- id 출처가 `git config` 이거나 `<레포루트>/<id>/` 가 이미 존재하면, 쓰기 전에 "ID = `<id>` (출처: …) 로 진행할까요?" 를 한 번 묻고 승인 뒤에만 진행한다.
- 출력 폴더: `<레포루트>/<id>/` 아래 `handoff.md` · `persona.md` · `appendix/01~18` · `memory-export/`. `~/handoff-<이름>/` 은 더 이상 쓰지 않는다.
- 수집기의 원본 덤프·중간 파일(API 응답 JSON·TSV·로그)은 `<id>/_raw/`(수집 스크립트 `.sh`·`.py` 만 추적되고 데이터는 `.gitignore` 가 제외) 또는 `<id>/appendix/_work/`(전부 제외)에만 쓴다. `appendix/` 직하에는 `01~18` 산출물과 `02-github-prs-all.tsv` 만 둔다. `scripts/qa.sh` 는 `_work/`·`_gen/` 과 `_raw/` 의 데이터는 검사하지 않지만(커밋되지 않는 곳이라 로컬 QA 와 CI 가 같은 결과를 낸다) `_raw/` 의 `.sh`·`.py` 는 커밋되므로 검사한다 — 수집 스크립트에 토큰·비밀번호를 하드코딩하지 않는다.
- `persona.md` 와 `memory-export/_config/` 는 필수 산출물이다. 재실행이면 같은 폴더에 덮어쓴다(이전 판은 git 이력이 보존한다). 덮어쓰기 범위는 `handoff.md`·`persona.md`·`appendix/`·`memory-export/` 로 한정하고, `<id>/inherit/` 는 인계자가 쓴 파일이므로 읽지도 지우지도 않는다. `memory-export/` 아래 각 디렉터리(`memory-export/<디렉터리명>/`·`memory-export/_config/`)는 복사 전에 `rm -rf` 로 지우고 새로 만든다(1단계 F) — 이전 실행의 잔여 파일이 남거나 `memory/` 가 한 단계 더 중첩되면 "덮어쓴다" 가 성립하지 않기 때문이다.
- 브랜치: 파일을 쓰기 **전에** `soul/<id>` 로 옮긴다. `git fetch origin soul/<id>` 가 성공하면 `git checkout -B soul/<id> origin/soul/<id>`, 실패하면 로컬에 있을 때 `git checkout soul/<id>`, 없을 때 `git checkout -b soul/<id>`. 그 다음에 `<id>/` 를 쓴다. `main` 에는 직접 커밋·푸시하지 않는다.

## 환경 적응
- 서브에이전트(Task/Agent 도구)가 있으면 1단계 수집기를 병렬로 띄우되 **F 는 B 가 끝난 뒤에 띄운다**(A·C·D·E 와 B 를 병렬, B 완료 후 F). F 가 B 의 `03-local-repos.md` 표(개인 프로젝트 제외 판정)에 의존하기 때문이다. 서브에이전트가 없으면(Codex 등) A→F 순서로 순차 실행한다. 어느 쪽이든 수집기를 띄우기 **전에** 메인 세션이 F 의 `_config/` "내가 직접 쓴 것" 질문(1단계 F 참고)을 먼저 하고 답을 받아 둔다.
- MCP(Jira·Confluence·Notion·Slack 등)가 없으면 해당 소스의 appendix 파일에 "미수집: MCP 없음" 과 수동 확인 방법을 적고 넘어간다. 파일은 비어 있어도 만든다.

## 1단계 — 수집기 6개로 appendix 를 만든다 (각각 read-only)

A. **GitHub** → `appendix/01-github-prs.md`, `02-github-ownership.md`, `02-github-prs-all.tsv`
   입사일~오늘 내가 쓴 PR 전수(레포별·월별·상태별 집계 + TSV: repo, number, title, state, created, merged, url, labels), 열린 PR 전량(리뷰 상태), 리뷰어로 참여한 PR 수, 커밋 author 집계, 레포 권한(admin/maintain/write), **내가 유일 admin 인 레포**, 개인 계정 레포 중 회사 관련 가능성, org 멤버십·팀, 내가 만든 Actions 워크플로·시크릿 **이름**·Ruleset 변경 흔적, fork. `gh api --paginate` 만.
B. **로컬 레포·머신·문서** → `03-local-repos.md`, `07-local-machine.md`, `14-local-docs.md`
   `~` 아래 모든 git 레포: 경로, origin, 브랜치, 미push 커밋 수(`git fetch` 금지, 로컬 refs 기준이라 명시), 미커밋 변경, stash, 마지막 커밋일, origin 없는 레포, 로컬 전용 브랜치 → 유실 위험 요약. 경로별 origin 은 표의 열로 반드시 넣는다(인계 단계가 이 열로 레포를 짝 맞춘다). 이 표는 `## 전체 레포 표` 절에 두고 앞 네 열을 `| # | 경로 | 종류 | origin |` 순서로 고정한다(인계 단계가 3번째·5번째 필드를 경로·origin 으로 읽는다. 나머지 열은 그 뒤에 자유롭게 둔다). 머신: aws 프로파일·SSO, kube context, gcloud/ADC 유무, ssh host alias, 업무용 alias·PATH, launchd/crontab, SA 키 파일(이름·경로·만료만), 비밀 디렉터리는 존재만, CLI 버전, Claude Code·Codex 설정(훅·MCP 서버 이름, 토큰 제외). 로컬 문서 디렉터리 인덱스(파일 수·최근 30일 수정·주요 문서 표). 개인 프로젝트·사적 문서로 판정되는 행(origin 이 회사 org 가 아니고 업무 연관 근거가 없는 것)은 표에서 빼고, 제외 건수와 판정 기준만 적는다.
C. **Jira·Confluence** → `04-jira.md`, `05-confluence.md`
   reporter/assignee/was assignee/watcher = 나, 내가 소유한 Epic 과 하위, 프로젝트별·상태별 집계, **In Progress / To Do 전량 표**, 최근 90일 Done 요약, 타 팀에 낸 요청 중 미완료, 코멘트 많은 이슈 상위. Confluence: 내가 만든/수정한 페이지, 개인 스페이스, 최근 90일 수정 표, 런북·인계 성격 페이지.
D. **Notion·Slack** → `06-notion.md`, `18-slack.md`
   내가 만든/편집한 페이지, 정본으로 지정한 문서 목록, 최근 90일 편집 표(제목·ID·URL·요지), 공유 범위. Slack(D 전체에서 im·mpim 즉 DM·그룹 DM 은 조회하지 않는다 — 채널 목록·핀·북마크·표본·Connect 모두 public/private 채널만): 가입 채널 전량(공개/비공개·멤버 수), 내가 운영 주체인 봇·알림 채널, 월별 `from:me` 표본 20건(채널 메시지만), 핀·북마크, 반복 보고 포맷 샘플, Slack Connect 채널, 내가 owner/collaborator 인 Slack 앱(API 불가면 "콘솔 필요").
E. **클라우드·SaaS 자산** → `12-aws-assets.md`, `13-gcp-assets.md`, `16-saas-other.md`
   내 IAM user(그룹·직접 정책·액세스 키 개수·MFA·마지막 사용), 소속 그룹과 정책 이름, **내가 owner/주 운영자인 리소스**(대시보드 owner, 에이전트 런타임·스케줄, 시크릿 **이름**, EKS access entry, 파이프라인 소유, 알람·토픽, 태그로 식별되는 버킷), Cost Explorer 접근 여부. GCP: 프로젝트·역할·로컬 SA 키(이름·만료)·잔존 리소스. SaaS: BI·워크플로·CI·모니터링·검색·마케팅 도구별 관리자 여부, 공용 계정 보유 현황, 내가 운영하는 서버/MCP. `get/list/describe` 만.
F. **AI 메모리 export + 타임라인** → `memory-export/`, `08~11-memory-*.md`, `15-session-timeline.md`
   먼저 Claude 설정 디렉터리 `CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"` 를 정한다(Claude Code 는 `CLAUDE_CONFIG_DIR` 가 있으면 그 아래 `projects/`·`rules/` 등을 쓴다). Claude 메모리 루트 `<root>`: 이 세션의 시스템 프롬프트가 알려주는 자기 메모리 경로(`<root>/<slug>/memory/` 꼴)에서 `<root>` 를 취한다. `~/.claude/projects` 가 아닐 수 있다(예: Orca 프로필 디렉터리). 시스템 프롬프트에 없으면(Codex 등) `$CFG/projects` 를 기본으로 하되, `ls "$CFG"/projects/*/memory/MEMORY.md 2>/dev/null | wc -l` 값을 보여주고 "다른 Claude 프로필·메모리 루트(Orca 등)가 있으면 경로를 알려달라" 를 아래 `_config/` 질문과 함께 한 번 묻고 답을 받은 뒤 복사한다. 경로를 하드코딩하지 말고 실제로 쓴 `<root>` 와 `$CFG` 값을 `11-memory-rest.md` 첫머리에 적는다. 이 문단의 셸 스니펫은 각각 새 셸에서 실행되므로 매 명령 앞에 `CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"; CODEX_HOME="${CODEX_HOME:-$HOME/.codex}";` 를 다시 쓴다(변수는 도구 호출 사이에 유지되지 않는다).
   `<root>/*/memory/` 전 디렉터리를 복사한다(원본 수정 금지). 목표 레이아웃은 `memory-export/<디렉터리명>/MEMORY.md` 다 — `memory/` 의 **내용물**이 `memory-export/<디렉터리명>/` 바로 아래에 오고 `memory/` 단계는 없다. 디렉터리마다 `D="<레포루트>/<id>/memory-export/<디렉터리명>"; rm -rf "$D" && mkdir -p "$D" && cp -R "<root>/<디렉터리명>/memory/." "$D/"` (대상이 이미 있을 때 `cp -R src/memory dest` 가 `dest/memory/` 로 중첩되는 것과 이전 실행의 잔여 파일을 막는다). 개인 프로젝트로 판정되는 **디렉터리**(B 가 `03-local-repos.md` 표에서 뺀 레포에 대응하는 것 포함)와 이직·커리어·가족 관련 **파일**은 제외한다. `11-memory-rest.md` 에는 B 와 같게 제외 건수와 사유 범주(커리어/가족/개인)만 적고 파일명·디렉터리명은 쓰지 않는다(이름 자체가 내용을 드러낸다). 시크릿 검사는 아래 `_config/` 복사까지 끝낸 뒤 `scripts/qa.sh` 로 한 번에 한다. 요약: 프로젝트별 메모리 수, 유형 집계, 트랙 인벤토리(진행/완료/보류), 🔴 함정·규칙 목록, 사고 기록(날짜·내용·교훈), 결정 기록, 남이 이어받을 반복 업무. 가장 큰 3개 프로젝트를 08/09/10, 나머지를 11. 세션 타임라인은 claude-mem 이 있으면 그것, 없으면 `<root>/*/*.jsonl` 을 쓰되 어느 쪽이든 세션 수·기간·프로젝트 분포 같은 **메타만** 옮기고 관찰 본문·대화 본문은 읽지도 옮기지도 않는다. 프로젝트 분포는 `03-local-repos.md` 표에 남은(회사) 레포에 대응하는 디렉터리로 한정하고 나머지는 "기타 N개" 로 합산한다.
   `memory-export/_config/` (필수, allow-list — 아래 것만 복사한다): `$CFG/CLAUDE.md`, 그리고 `$CFG/rules/`·`$CFG/commands/`·`$CFG/skills/`·`$CFG/hooks/` 의 항목 중 **내가 직접 쓴 것**. 판정은 저작자 판단이며 사용자에게 묻는다: 수집기를 띄우기 **전에** 메인 세션이 목록을 만들어 보여주고 "이 중 내가 직접 쓴 것만 골라 달라" 고 **한 번만** 묻는다(답을 받기 전에는 `_config/` 를 복사하지 않는다). 목록은 글롭 하나로 묶지 않는다(zsh 는 안 맞는 글롭이 하나라도 있으면 명령 전체가 실행되지 않는다): `CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"; CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"; for d in "$CFG"/rules "$CFG"/commands "$CFG"/skills "$CFG"/hooks "$CODEX_HOME"/rules "$CODEX_HOME"/skills "$CODEX_HOME"/prompts; do if [ -d "$d" ]; then find "$d" -mindepth 1 -maxdepth 1 | sort; else echo "없음: $d"; fi; done`. Codex 항목도 이 한 번의 질문에 포함한다. 고르지 않은 항목 — README·`install.sh` 흔적이 있는 서드파티 팩, `$CFG/plugins/` 아래(`settings.json` 의 `enabledPlugins` 가 가리키는 것 포함) — 는 이름만 `11-memory-rest.md` 에 적고 복사하지 않는다. `.git` 이 있는 디렉터리는 복사하지 않고 origin URL 만 `11-memory-rest.md` 에 적는다.
   복사 방법: `$CFG` 하위 디렉터리 자체가 `~/.claude/*` 로 가는 심링크일 수 있다(Orca 프로필 등). 그 경우 `cp -R "$CFG/rules" dest` 는 심링크 하나만 복사하고 `find "$CFG/commands" -type f` 는 0건이 되므로, 디렉터리마다 실경로를 먼저 푼다: `R=$(cd "$CFG/rules" && pwd -P); D="<레포루트>/<id>/memory-export/_config/rules"; mkdir -p "$D"; cp -R "$R/<고른 항목>" "$D/"` 를 고른 항목마다(`commands/`·`skills/`·`hooks/` 도 같은 식), `$CFG/CLAUDE.md` 는 `cp -L` 로. 마지막에 `find "<레포루트>/<id>/memory-export/_config" -type l -delete` — "심링크 제외" 는 이렇게 푼 디렉터리 **안의** 항목(플러그인이 심어 둔 링크 등)에만 적용된다. 바로 이어서 설정·토큰 파일을 사본에서 지운다(산문 규칙만으로는 `cp -R` 이 통째로 가져온다): `find "<레포루트>/<id>/memory-export/_config" -type f \( -name 'settings*.json' -o -name '*credentials*.json' -o -name '*.env' -o -name '.env*' -o -name '*mcp*.json' -o -name 'config.toml' -o -name 'auth.json' -o -name '*.pem' -o -name '*.key' \) -print -delete` 를 돌리고 지운 파일 수를 `11-memory-rest.md` 에 적는다. 그 뒤 같은 경로에서 `find … -type l | wc -l` 이 0, `find … -type f | wc -l` 이 1 이상인지 확인하고 두 값을 `11-memory-rest.md` 에 적는다(qa.sh 는 `_config/` 존재만 보므로 이 확인이 없으면 심링크만 남아도 PASS 한다). 각 레포의 `CLAUDE.md` 는 **B 가 `03-local-repos.md` 표에 남긴 레포(개인 프로젝트로 뺀 것 제외)에 한해** `git log --format=%ae -- CLAUDE.md` 에 내 이메일이 있는 것만 `_config/repos/<레포 basename>/CLAUDE.md` 로 복사하고, basename 이 겹치면 origin 의 `org/repo` 를 `org__repo` 로 써서 구분한다. Codex 자산은 `$CODEX_HOME`(`CODEX_HOME` 환경변수, 없으면 `~/.codex`) 기준이다: `$CODEX_HOME/rules/`·`skills/`·`prompts/` 는 위 질문에서 고른 것만, `$CODEX_HOME/AGENTS.md` 와 `$CODEX_HOME/memories/` 는 질문 없이(사적 파일 제외 규칙만 적용) 같은 심링크·`.git` 규칙으로 `memory-export/_config/codex/` 에 복사한다. `settings*.json`·`*credentials*.json`·`*.env`·`*mcp*.json`·`config.toml`·`auth.json` 등 설정·토큰 파일은 어디서도 복사하지 않는다(훅 이름·MCP 서버 이름은 `07-local-machine.md` 에만 적는다). 위 문단의 사적 파일 제외는 `_config/` 전체와 `$CODEX_HOME/memories/` 에도 똑같이 적용한다. 스크럽 세 단계(심링크 삭제 → 설정·토큰 `find -delete` → 심링크 0건·파일 1건 이상 확인)는 `_config/` 아래 **모든** 복사(rules·commands·skills·hooks·CLAUDE.md·repos·codex)가 끝난 뒤 한 번만 돌린다. 위의 "마지막에" 는 그 시점을 뜻한다. 없는 소스는 `11-memory-rest.md` 에 "없음" 으로 적는다.
   복사가 모두 끝나면 레포 루트에서 `bash scripts/qa.sh <id>` 를 한 번 돌린다. 시크릿·전화번호 패턴의 단일 출처는 이 스크립트다(이 파일에 별도 grep 목록을 두지 않는다). `memory-export/` 아래 히트는 여기서 처리한다: memory 원본 파일이면 히트 값을 마스킹한 사본으로 바꾸고(원본은 손대지 않는다), `_config/` 아래 서드파티 문서면 복사본에서 지운다. 다시 돌려 `memory-export/` 히트가 0건이어야 F 가 끝난다. 다른 수집기가 쓴 appendix 의 히트는 건드리지 않고 5·6단계에서 본다.

## 2단계 — 라이브 재검증 → `appendix/17-tracked-01~NN.md`
appendix 를 읽고 "내 계정이 꺼지면 깨지는 것" 후보(개인 계정으로 돌아가는 자동화·로컬 launchd·만료 예정 자격·개인 ID 하드코딩·유일 admin·권한 경계·알람 수신자)를 10개 안팎 고른 뒤, 각각 지금 시각에 실제로 조회해 한 파일씩 쓴다. 절 구성: 조회 일시 · 방법 · 결과 표 · 판정 · 후임이 할 일 · 근거/명령.

## 3단계 — 합성 → `handoff.md` (550~800줄)
헤더(생성일시 · 수집 범위 · 표기 규칙) 뒤 절 12개:
0. 소스별 수집 상태(표: 소스·appendix 파일·상태·사유) · 1. 식별자·계정 · 2. 역할·담당 범위 · 3. 🔴 계정 비활성화 시 깨지는 자산(즉시 조치 순) · 4. 🔴 진행 중·미완 작업(트랙별 / 열린 PR / 미push·미커밋 / To Do) · 5. 반복 운영 업무(시각·주기·방법·후임) · 6. 작업 이력 타임라인(월별) · 7. 의사결정 기록 · 8. 함정·교훈(사고 / 임시 우회 / 재발 방지) · 9. 협업 관계(역할+이름) · 10. 커뮤니케이션 스타일·작업 원칙(보고 형식 / 승인 습관 / 도구 사용) · 11. 문서·링크 인덱스 · 12. 미확인·확인 필요(해소됨 / 여전히 미확인).
모든 문장은 appendix 에서만 가져오고 근거를 단다.

## 4단계 — 페르소나 → `persona.md` (100~200줄, 필수)
memory-export 와 handoff §7·§8·§10 만 근거로: 설계 철학과 판단 기준(무엇을 fail-closed 로 두는가, 무엇을 자동화하고 무엇을 사람에게 남기는가), 도구·에이전트 운용 방식(세션 구조, 위임 규칙, 검증 습관), 내가 내 에이전트에 준 원칙(CLAUDE.md·AGENTS.md·rules·feedback 메모리에서 추출), Slack·문서 톤, 자주 쓰는 표현과 금지 표현, 다른 사람이 내 산출물을 읽을 때 의도를 해석하는 법, 내가 반복해서 틀렸던 패턴. 전부 근거 표기.

## 5단계 — 자체 QA
`handoff.md` 의 appendix 참조가 전부 실존하는지, 인용 안 된 appendix 가 없는지, `(추정)` 개수를 확인해 출력한다. 시크릿 0건·전화번호 0건 확인은 레포 루트에서 `bash scripts/qa.sh <id>` 를 돌려 그 출력의 "시크릿 패턴 N건"·"전화번호 패턴 N건" 을 그대로 인용한다(별도 grep 으로 대신하지 않는다). `persona.md` 와 `memory-export/_config/` 가 있는지 확인한다. 회사 도메인 밖 이메일 주소를 훑는다(qa.sh 는 개수와 도메인만 알려준다): `D=$(sed -n 's/^COMPANY_DOMAIN=//p' "$(git rev-parse --show-toplevel)/.dementorrc" | head -n 1 | tr -d "[:space:]\"'" | sed 's/\./\\./g'); grep -rhoE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[a-z]{2,}' <id>/ | grep -viE "@($D|[a-z0-9-]+\.iam\.gserviceaccount\.com)\$" | sort -u` 결과를 보여주고, 사적 주소는 F 의 사본 마스킹 규칙대로 마스킹하고 업무용 외부 계정은 `11-memory-rest.md` 에 그 사실을 적는다. 마지막으로 `<id>/` 폴더 트리와 파일별 줄 수를 보여 준다.

## 6단계 — QA 스크립트 · 커밋 · PR
1. `git branch --show-current` 가 0단계에서 옮긴 `soul/<id>` 인지 확인한다. `main` 이면 멈춘다. `main` 에는 직접 커밋·푸시하지 않는다.
2. 레포 루트에서 `bash scripts/qa.sh <id>` 를 돌린다. PASS 가 아니면 커밋하지 말고 히트된 파일·줄을 그대로 보여주고 멈춘다. 사용자가 고친 뒤 다시 돌린다.
3. PASS 면 `git add <id>/handoff.md <id>/persona.md <id>/appendix <id>/memory-export <id>/_raw` (`_raw` 는 `.gitignore` 가 스크립트만 남긴다, 없으면 생략) → `git commit -m "feat: add <id> handoff package (<YYYY-MM-DD>)"`. `<id>/inherit/` 와 `<id>/` 밖의 파일은 스테이징하지 않는다.
4. `git push -u origin soul/<id>`. 거절되면(non-fast-forward 등) `--force` 하지 말고 멈춰서 사용자에게 알린다.
5. **"퇴사 전에 직접 넘겨야 할 것"** 목록을 만든다(고정 제목). 출처 세 곳만 쓴다 — `handoff.md` §3 의 행(즉시 조치 순 그대로), `appendix/17-tracked-*` 각 파일의 "후임이 할 일" 절, `handoff.md` §12 의 "여전히 미확인" 항목. 한 줄 형식은 `- [ ] <항목> — <위치/근거> — <퇴사 전에 내가 할 일 또는 후임이 할 일>` 이고, 시크릿은 값 없이 이름·위치·만료일만 쓴다(키 회전·유일 admin 레포 양도·개인 계정으로 도는 자동화 이관·공용 계정 비밀번호 전달 같은 것이 여기 온다). 목록 끝에 아래 문단을 그대로 붙인다:

   > 위 항목은 시크릿 값·비밀번호가 패키지에 들어 있지 않아 사람끼리 넘겨야 하는 것입니다. 퇴사일 전에 인계자와 함께 하나씩 처리하세요. 인계자에게는 `/dementor-inherit <id>` 를 내가 재직 중일 때 돌려 달라고 하세요 — 그 절차 끝에 나오는 질문 목록은 퇴사 후에는 답할 사람이 없습니다.

6. `gh` 가 있으면 `gh pr create --base main --head soul/<id> --title "soul: <id>" --body "<handoff.md §0 수집 상태 표 요약 + 5 의 목록과 문단>"`. 없으면 push 출력에 나온 PR 생성 URL 을 사용자에게 안내한다. 어느 쪽이든 마지막 메시지에 5 의 목록과 문단을 그대로 다시 출력하고 끝낸다.
