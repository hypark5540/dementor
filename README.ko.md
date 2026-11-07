<p align="center">
  <img src=".github/assets/dementor.png" alt="달아나는 사람에게서 업무 맥락과 페르소나를 뽑아내는 dementor" width="100%">
</p>

# dementor

[![CI](https://github.com/hypark5540/dementor/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/hypark5540/dementor/actions/workflows/ci.yml)
[![CodeQL](https://github.com/hypark5540/dementor/actions/workflows/codeql.yml/badge.svg?branch=main)](https://github.com/hypark5540/dementor/actions/workflows/codeql.yml)
[![Release](https://img.shields.io/github/v/release/hypark5540/dementor?sort=semver)](https://github.com/hypark5540/dementor/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-supported-8A63D2)](.claude/commands)
[![Codex](https://img.shields.io/badge/Codex-supported-8A63D2)](AGENTS.md)
[![bash 3.2+](https://img.shields.io/badge/bash-3.2%2B-4EAA25?logo=gnubash&logoColor=white)](scripts/qa.sh)

[English](README.md) · **한국어**

퇴사자의 업무 맥락·판단 기준·AI 메모리를 "영혼" 패키지 하나로 뽑아 보관하고, 후임이 한 줄로 이어받게 하는 인수인계 템플릿이다.
떠나는 사람은 자기 AI 에이전트에게 `/dementor-upload` 한 줄을 입력하고, 이어받는 사람은 `/dementor-inherit <id>` 한 줄을 입력한다.

## 왜 만들었나

인수인계 문서는 쓰는 사람이 기억나는 것만 담긴다. 실제로 받은 인수인계 패키지에서 가장 많이 열어 본 것은 요약 문서가 아니라 전임자의 AI 메모리 원본이었다 — 왜 그렇게 결정했는지, 어디서 사고가 났는지, 무엇을 하지 말라고 했는지가 거기 있었다.

그래서 dementor 는 두 가지를 한다.

- **뽑아낸다**: 퇴사자의 에이전트가 GitHub·로컬 레포·Jira·Confluence·Notion·Slack·클라우드·AI 메모리를 읽기 전용으로 훑어, 근거가 달린 인수인계 문서와 페르소나, 메모리 원본 사본을 만든다.
- **잇는다**: 후임의 에이전트가 그 패키지를 읽고 요약을 만든 뒤, 후임의 로컬 AI 메모리에 원문을 가리키는 링크를 심는다. 복사가 아니라 포인터가 기본이라 후임의 메모리가 남의 기억으로 덮이지 않는다.

## 시작하기 (관리자, 한 번만)

패키지에는 계정 ID·협업 관계·판단 기록이 들어간다. **반드시 비공개 레포에서 쓴다. 이 공개 레포나 그 포크에 패키지를 올리지 않는다**(포크는 공개다).

1. 이 레포로 회사 org 에 **비공개** 레포를 만든다. GitHub 의 **Use this template → Create a new repository → Private**, 또는:

   ```bash
   git clone https://github.com/hypark5540/dementor.git && cd dementor
   rm -rf .git && git init -b main && git add -A && git commit -m "chore: init dementor"
   gh repo create <org>/dementor --private --source=. --push
   ```

2. `.dementorrc` 의 `COMPANY_DOMAIN` 을 회사 이메일 도메인으로 바꿔 `main` 에 커밋한다. 폴더 이름(ID)은 회사 이메일의 `@` 앞부분이 된다.

   ```ini
   COMPANY_DOMAIN=acme.com
   ```

3. `main` 브랜치를 보호한다: PR 필수, 상태 검사 `qa` 필수. 접근 권한은 인수인계 당사자와 관리자로 좁힌다.

## 퇴사자

1. 회사의 dementor 레포를 클론한다.
2. 레포 루트에서 Claude Code 나 Codex 를 연다.
3. 한 줄 입력: `/dementor-upload` 또는 "영혼 업로드".
4. 1~2시간 뒤 `soul/<id>` 브랜치로 PR 이 열린다. Jira·Confluence·Notion·Slack MCP 가 연결된 회사 계정이면 더 많이 채워지고, 없는 소스는 "미수집" 과 수동 확인 방법이 적힌다.

에이전트가 수집하는 것:

| 수집기 | 소스 | 산출물 (`<id>/appendix/`) |
|---|---|---|
| A | GitHub·GitLab — 내 PR/MR 전수, 열린 것, 레포·그룹 권한, 유일 admin/Owner 레포, 워크플로·CI 변수·시크릿 이름 | `01` `02` `19` |
| B | 로컬 레포·머신·문서 — 미push 커밋, stash, 클라우드 프로파일, 스케줄러, CLI 설정 | `03` `07` `14` |
| C | Jira·Confluence·Linear — 진행 중·To Do 전량, 소유·lead 인 Epic·프로젝트, 런북 페이지 | `04` `05` `20` |
| D | Notion·Slack·Google Docs/Drive·Teams — 정본 문서, 내 드라이브에만 있는 문서, 운영하는 봇·알림 채널, 반복 보고 포맷, DM — 업무 결정·약속·암묵지만 근거 달린 항목으로 추출(원문 전재 없음, 사적 대화 제외) | `06` `18` `21` `22` |
| E | 클라우드·SaaS·온콜 — IAM, 내가 owner 인 리소스, 관리자 권한 도구, 기타 작업 추적 도구(Asana·Monday·ClickUp·Azure DevOps·ServiceNow…), 내게 배정된 Sentry 이슈, PagerDuty/Opsgenie 로테이션, 나에게만 알람이 가는 Datadog/Grafana 모니터 | `12` `13` `16` `23` |
| F | AI 메모리 — Claude Code 자동 메모리·직접 쓴 rules/skills·Codex 설정 사본, 세션 메타 | `08`~`11` `15`, `memory-export/` |

수집 뒤에는 "내 계정이 꺼지면 깨지는 것" 후보 10개 안팎을 지금 시각에 다시 조회해 확인하고(`17-tracked-*`), 이를 합쳐 `handoff.md` 와 `persona.md` 를 쓴다. 모든 문장에 근거(appendix 파일이나 URL)가 붙고, 추정은 `(추정)` 으로 표시된다.

시크릿 값·비밀번호·개인 연락처는 패키지에 들어가지 않는다(이름·위치·만료일만). 그래서 절차 끝에 **"퇴사 전에 직접 넘겨야 할 것"** 체크리스트가 터미널과 PR 본문에 나온다 — 키 회전, 유일 admin 레포 양도, 개인 계정으로 도는 자동화 이관 같은 것이다. 퇴사일 전에 인계자와 함께 하나씩 처리한다.

## 인계자

1. 회사의 dementor 레포를 클론한다(이미 있으면 `git pull`).
2. 레포 루트에서 Claude Code 나 Codex 를 연다.
3. 한 줄 입력: `/dementor-inherit <전임자id>` 또는 "<전임자id> 인계받을게".
4. 10~20분 뒤 `<전임자id>/inherit/<내id>-<날짜>.md` 요약이 생기고, 내 로컬 AI 메모리에 전임자 포인터가 붙는다. 원문은 필요할 때만 열면 된다.

**전임자의 퇴사일 전에 돌린다.** 절차 끝에 **"전임자에게 지금 확인할 것"** 질문 목록이 나오는데, 시크릿 값과 권한처럼 사람이 넘겨야 하는 것이라 퇴사 후에는 답할 사람이 없다. 답은 요약 파일에 적어 다시 커밋한다.

요약은 "지금 당장 깨질 수 있는 것 → 미완 작업 → 반복 운영 → 함정·교훈 → 페르소나 핵심" 순서다. 전임자의 메모리 디렉터리와 내 로컬 레포는 origin 으로 짝을 맞추고, 짝이 맞은 레포의 메모리에만 링크 두 줄을 붙인다. 더 깊이 들이고 싶으면 전임자의 feedback 유형 메모리만 `inherited_<id>_` 접두어 사본으로 복사할 수 있고, 명령 두 줄로 되돌릴 수 있다.

## PR 받는 사람

PR 의 CI(`qa`)가 통과했는지 확인하고, 내용을 한 번 훑어본 뒤 머지한다.
FAIL 이면 히트 파일을 보고 올린 사람에게 수정을 요청한다. `main` 직접 푸시는 하지 않는다.
훑어볼 때 `persona.md` 와 `memory-export/` 에 에이전트에게 무언가를 실행하라고 지시하는 문장이 섞여 있지 않은지 본다 — 인계자의 에이전트가 그 파일을 읽는다. `appendix/18-slack.md`·`22-teams.md` 의 DM 추출본도 한 번 본다 — 업무 결정만 있어야 하고, 사적 대화 인용이나 시크릿 값이 있으면 안 된다.

## 구조

```text
AGENTS.md                         Codex·Claude 공용 진입점(트리거·규칙). CLAUDE.md 는 이 파일을 가리킨다
.dementorrc                       회사 이메일 도메인 설정
prompts/upload.md                 퇴사자용 수집 절차
prompts/inherit.md                인계자용 절차
.claude/commands/                 /dementor-upload, /dementor-inherit (Claude Code 전용)
scripts/qa.sh <id>                시크릿·전화번호·구조 검사
scripts/qa.test.sh                qa.sh 테스트
.github/workflows/qa.yml          PR 에서 변경된 ID 폴더마다 qa.sh 실행
.github/workflows/ci.yml          도구 자체 검사(ShellCheck + qa.sh 테스트)
<id>/                             id = 회사 이메일 @ 앞부분 (예: jane.doe)
  handoff.md                      인수인계 본문 0~12절
  persona.md                      설계 철학·판단 기준·작업 원칙
  appendix/01~23                  소스별 수집 원자료
  memory-export/<원본 디렉터리명>/  AI 메모리 원본 사본
  memory-export/_config/          CLAUDE.md·rules·skills·Codex 설정 사본
  inherit/<인계자id>-YYYY-MM-DD.md 인계자가 만든 요약
```

## 안전장치

- **읽기 전용 수집**: 절차는 조회만 지시한다. 쓰는 곳은 레포의 자기 `<id>/` 폴더와 인계자 자신의 메모리뿐이다.
- **공개 레포 차단**: 업로드를 시작하기 전과 푸시 직전에 레포 공개 여부를 확인하고, 공개면 멈춘다.
- **시크릿 값은 기록하지 않는다**: 이름·경로·만료일만 적는다. 설정·토큰 파일은 복사 직후 지우고 `.gitignore` 가 한 번 더 막는다.
- **DM 은 추출만, 전재 없음**: 업무는 DM 에서도 일어나므로 읽되, 결정·약속·암묵지만 날짜·상대·링크 근거를 달아 항목으로 꺼낸다(인용 한 줄 이내). 사적 대화(가족·건강·급여·HR·이직)와 상대방의 개인정보는 들어가지 않고 전체 제외 건수만 남는다(상대별로 세지 않는다). DM 원문은 로컬 디스크에도 남기지 않는다.
- **사적 정보 제외**: 개인 프로젝트·가족·커리어 메모리는 수집하지 않고 제외 건수만 남긴다.
- **QA 게이트 두 번**: `scripts/qa.sh` 가 시크릿·전화번호 패턴을 커밋 전(로컬)과 PR(CI)에서 검사한다. 한 건이라도 걸리면 FAIL 이다.
- **PR 게이트**: 패키지는 `soul/<id>`, 인계 요약은 `inherit/<me>-<id>` 브랜치로만 올라간다.
- **지어내지 않는다**: 근거 없는 문장은 쓰지 않고, 확신이 없으면 `(확인 필요)` 로 남긴다.

정규식 검사가 모든 시크릿을 잡지는 못한다. 자세한 위협 표면과 신고 방법은 [SECURITY.md](SECURITY.md) 에 있다.

## 요구 사항

- [Claude Code](https://claude.com/claude-code) 또는 Codex CLI
- `git`, `bash` 3.2 이상, `python3`(없으면 `node`)
- [`gh`](https://cli.github.com/) — GitHub 수집, PR 생성, 공개 여부 확인에 쓴다. 없으면 해당 단계가 "미수집" 이 되거나 사용자에게 묻는다
- 선택: Jira·Confluence·Linear·Notion·Slack·Google Drive·Teams·Sentry·PagerDuty·Datadog/Grafana 의 MCP 나 CLI, GitLab 은 `glab`, AWS·GCP·Azure CLI 로그인. 없는 것은 "미수집" 과 수동 확인 방법으로 남는다

## 한계

- 프롬프트와 산출물이 한국어다.
- 보관소 레포 자체는 GitHub 여야 한다(PR, Actions, `gh`). GitLab 은 수집 소스로 지원하고 보관소 호스트로는 지원하지 않는다.
- ID 는 `^[a-z0-9]+(\.[a-z0-9]+)*$` 만 받는다. 이메일 앞부분에 밑줄·하이픈·대문자가 있으면 에이전트가 멈추고 ID 를 묻는다.
- 회사 도메인은 하나만 설정할 수 있다.
- `qa.sh` 의 전화번호 패턴은 한국 휴대폰 형식뿐이다.
- AI 메모리는 Claude Code 자동 메모리와 Codex 설정을 대상으로 한다.

## License

[MIT](LICENSE)
