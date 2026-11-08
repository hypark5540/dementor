#!/usr/bin/env bash
# README 데모(demo.gif / demo.ko.gif)의 각본. `vhs .github/assets/demo.tape`(영어)·`demo.ko.tape`(한국어)가 이 스크립트를 재생한다.
# 사용법: bash .github/assets/demo.sh [en|ko]   (기본 en)
# 에이전트 출력은 업로드·인계 절차의 대표 장면을 압축한 각본이다(가짜 회사 acme.com, 가짜 사람 jane.doe·j.kim).
# 실제 절차는 한국어로 출력한다 — en 은 데모를 위해 그 줄들을 번역한 것이다.
# `bash scripts/qa.sh jane.doe` 만은 임시 폴더에 만든 가짜 패키지에 실제로 돈다(임시 경로만 ~/acme/dementor 로 바꿔 보여 준다).
# en 은 그 한국어 출력도 줄 단위로 번역해 보여 준다(en_qa) — 검사 자체는 그대로다.
set -u

L="${1:-en}"
case "$L" in en | ko) ;; *) echo "usage: bash .github/assets/demo.sh [en|ko]" >&2; exit 2 ;; esac

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

B=$'\033[1m'; D=$'\033[2m'; G=$'\033[32m'; C=$'\033[36m'; Y=$'\033[33m'; R=$'\033[0m'

type_cmd() { # 프롬프트에 한 글자씩 입력하는 것처럼 보여 준다
  printf '%s❯%s ' "$C" "$R"
  for ((i = 0; i < ${#1}; i++)); do printf '%s' "${1:i:1}"; sleep 0.06; done
  printf '\n'; sleep 0.8
}
say() { printf '%b\n' "$1"; sleep "${2:-0.45}"; }
say2() { # $1 = 한국어, $2 = English, $3 = 뒤에 쉴 초
  if [ "$L" = ko ]; then say "$1" "${3:-0.45}"; else say "$2" "${3:-0.45}"; fi
}
en_qa() { # ko 면 그대로 통과. en 이면 qa.sh 의 한국어 출력(이 가짜 패키지가 내는 줄들)을 영어로 바꿔 보여 준다.
  if [ "$L" = ko ]; then cat; return; fi
  sed \
    -e 's/^   폴더: /   folder: /' \
    -e 's/^-- 정보성 검사 (실패 아님)$/-- Informational checks (never a FAIL)/' \
    -e 's/^handoff\.md: \([0-9]*\)줄, \([0-9]*\)바이트$/handoff.md: \1 lines, \2 bytes/' \
    -e 's/^## 절 목록:$/## sections:/' \
    -e 's/## 0\. 소스별 수집 상태$/## 0. Collection status per source/' \
    -e 's/## 1\. 식별자·계정$/## 1. Identifiers · accounts/' \
    -e 's/## 2\. 역할·담당 범위$/## 2. Role · scope of ownership/' \
    -e 's/## 3\. 🔴 계정 비활성화 시 깨지는 자산(즉시 조치 순)$/## 3. 🔴 Assets that break when my account is disabled (act on these first)/' \
    -e 's/## 4\. 🔴 진행 중·미완 작업$/## 4. 🔴 In-progress · unfinished work/' \
    -e 's/## 5\. 반복 운영 업무$/## 5. Recurring operations/' \
    -e 's/## 6\. 작업 이력 타임라인$/## 6. Work history timeline/' \
    -e 's/## 7\. 의사결정 기록$/## 7. Decision log/' \
    -e 's/## 8\. 함정·교훈$/## 8. Pitfalls · lessons/' \
    -e 's/## 9\. 협업 관계$/## 9. Working relationships/' \
    -e 's/## 10\. 커뮤니케이션 스타일·작업 원칙$/## 10. Communication style · working principles/' \
    -e 's/## 11\. 문서·링크 인덱스$/## 11. Document · link index/' \
    -e 's/## 12\. 미확인·확인 필요$/## 12. Unverified · needs confirmation/' \
    -e 's/^인용 밀도: 근거(appendix 파일명 또는 URL)가 있는 줄 \([0-9]*\) \/ 비어있지 않은 줄 \([0-9]*\)$/citation density: \1 of \2 non-empty lines cite evidence (an appendix file or a URL)/' \
    -e 's/^실존하지 않는 appendix 참조:$/references to appendix files that do not exist:/' \
    -e 's/^   (없음)$/   (none)/' \
    -e 's/^미인용 appendix 파일:$/appendix files never cited:/' \
    -e "s/^'(추정)' 수: /'(추정)' (estimate) marks: /" \
    -e 's/^persona\.md: 있음 (\([0-9]*\)줄)$/persona.md: present (\1 line(s))/' \
    -e 's/^memory-export: 디렉터리 \([0-9]*\)개, 파일 \([0-9]*\)개, _config: 있음$/memory-export: \1 directories, \2 files, _config: present/' \
    -e 's/^-- 차단 검사 (1건이라도 있으면 FAIL)$/-- Blocking checks (a single hit is a FAIL)/' \
    -e 's/^회사 도메인 밖 이메일(정보성): \([0-9]*\)건  도메인: /emails outside the company domain (informational): \1  domains: /' \
    -e 's/^시크릿 패턴: \([0-9]*\)건$/secret patterns: \1/' \
    -e 's/^전화번호 패턴: \([0-9]*\)건$/phone-number patterns: \1/'
}

# --- qa.sh 가 실제로 검사할 가짜 패키지 ---
P="$T/jane.doe"
mkdir -p "$T/scripts" "$P/appendix" "$P/memory-export/_config" "$P/memory-export/billing-api"
cp "$ROOT/scripts/qa.sh" "$T/scripts/"
echo 'COMPANY_DOMAIN=acme.com' > "$T/.dementorrc"
cat > "$P/handoff.md" <<'EOF'
# jane.doe handoff

## 0. 소스별 수집 상태
- GitHub PR 184건 수집 [01-github-prs.md §1], 유일 admin 레포 2개 [02-github-ownership.md §2]
## 1. 식별자·계정
- 공용 계정 ops@acme.com 관리 [12-aws-assets.md §1]
## 2. 역할·담당 범위
- billing-api 야간 배치 담당 [03-local-repos.md §3]
## 3. 🔴 계정 비활성화 시 깨지는 자산(즉시 조치 순)
- ops-alert Slack 봇 토큰 만료 2026-12-01 [16-saas-other.md §2], 재조회 [17-tracked-01.md]
- billing-api 유일 admin [02-github-ownership.md §2], 재조회 [17-tracked-02.md]
## 4. 🔴 진행 중·미완 작업
- 열린 PR 3건 [01-github-prs.md §2], Jira In Progress 6건 [04-jira.md §1]
## 5. 반복 운영 업무
- 매주 월 09:00 정산 리포트 [06-notion.md §1]
## 6. 작업 이력 타임라인
- 2026-03 ~ 2026-10 월별 [02-github-prs-all.tsv]
## 7. 의사결정 기록
- 배치 재시도 3회로 고정한 이유 [18-slack.md §2]
## 8. 함정·교훈
- 야간 배치 실패 시 partner.io 콜백부터 확인 [memory-export/billing-api/MEMORY.md]
## 9. 협업 관계
- 정산 파트너 담당 vendor@partner.io [06-notion.md §3]
## 10. 커뮤니케이션 스타일·작업 원칙
- 보고는 표 한 장, 승인은 PR 코멘트로 [18-slack.md §1]
## 11. 문서·링크 인덱스
- https://acme.atlassian.net/wiki/spaces/OPS/overview
## 12. 미확인·확인 필요
- 여전히 미확인: Datadog 모니터 3개의 알림 수신자 이관 방법 [23-oncall-monitoring.md §1] (추정)
EOF
echo '# persona' > "$P/persona.md"
for f in 01-github-prs.md 02-github-ownership.md 02-github-prs-all.tsv 03-local-repos.md 04-jira.md 06-notion.md \
         12-aws-assets.md 16-saas-other.md 17-tracked-01.md 17-tracked-02.md 18-slack.md 23-oncall-monitoring.md; do
  echo "# $f" > "$P/appendix/$f"
done
echo '# MEMORY' > "$P/memory-export/billing-api/MEMORY.md"
echo '# CLAUDE.md copy' > "$P/memory-export/_config/CLAUDE.md"

# ================= 장면 1: 퇴사자 / Scene 1: the leaver =================
printf '\033[2J\033[H' # vhs 가 입력한 "bash demo.sh" 줄을 지운다
say2 "${D}# acme 의 비공개 dementor 레포에서, 떠나는 사람 jane.doe 가 Claude Code 를 연다${R}" \
     "${D}# In acme's private dementor repo, the leaver jane.doe opens Claude Code${R}" 1.2
type_cmd "/dementor-upload"
say2 "${B}0단계${R}  ID = jane.doe (출처: userEmail) · COMPANY_DOMAIN = acme.com · 레포 visibility = PRIVATE ${G}✓${R}" \
     "${B}Step 0${R}  ID = jane.doe (from userEmail) · COMPANY_DOMAIN = acme.com · repo visibility = PRIVATE ${G}✓${R}" 0.9
say2 "${B}1단계${R}  수집기 A–F 병렬 실행 ${D}(read-only)${R}" \
     "${B}Step 1${R}  collectors A–F in parallel ${D}(read-only)${R}" 0.6
say2 "  A  GitHub·GitLab    PR 184 · 열린 PR 3 · 유일 admin 레포 2            → 01 02 19" \
     "  A  GitHub·GitLab    184 PRs · 3 open · 2 repos where I am the only admin       → 01 02 19"
say2 "  B  로컬·머신        레포 27 · 미푸시 커밋 2 · launchd 1               → 03 07 14" \
     "  B  Local·machine    27 repos · 2 unpushed commits · 1 launchd job              → 03 07 14"
say2 "  C  Jira·Linear      In Progress 6 · 담당 에픽 2 · 런북 4             → 04 05 20" \
     "  C  Jira·Linear      6 In Progress · 2 epics I own · 4 runbooks                 → 04 05 20"
say2 "  D  Notion·Slack     운영 봇 3 · DM 추출 41건 (사적 대화 제외 128건)  → 06 18 21 22" \
     "  D  Notion·Slack     3 bots I operate · 41 DM items (128 private msgs excluded) → 06 18 21 22"
say2 "  E  클라우드·SaaS    IAM 역할 5 · 단독 admin 2 · 나만 받는 알림 3      → 12 13 16 23" \
     "  E  Cloud·SaaS       5 IAM roles · sole admin in 2 tools · 3 alerts only I get  → 12 13 16 23"
say2 "  F  AI 메모리        디렉터리 9 · 파일 38 · feedback 12                → 08–11 15 memory-export/" \
     "  F  AI memory        9 directories · 38 files · 12 feedback                     → 08–11 15 memory-export/" 0.9
say2 "${B}2단계${R}  \"내 계정이 꺼지면 깨지는 것\" 후보 9건 → 17-tracked-01..09 (지금 시각에 재조회)" \
     "${B}Step 2${R}  9 candidates for \"what breaks when my account is disabled\" → 17-tracked-01..09 (re-queried live)" 0.9
say2 "${B}3단계${R}  handoff.md 412줄 · persona.md 96줄 — 모든 문장에 근거(appendix·URL), (추정) 4" \
     "${B}Step 3${R}  handoff.md 412 lines · persona.md 96 lines — every sentence cited (appendix or URL), 4 marked as estimates" 0.9
say2 "${B}4단계${R}  QA" "${B}Step 4${R}  QA" 0.5
type_cmd "bash scripts/qa.sh jane.doe"
(cd "$T" && bash scripts/qa.sh jane.doe) | sed "s#$T#~/acme/dementor#" | en_qa
sleep 3.5
say ""
say2 "${B}5단계${R}  git commit → push soul/jane.doe → gh pr create ${D}(body: heredoc)${R}" \
     "${B}Step 5${R}  git commit → push soul/jane.doe → gh pr create ${D}(body: heredoc)${R}" 0.6
say "        ${C}https://github.com/acme/dementor/pull/12${R}" 1.0
say ""
say2 "${B}${Y}퇴사 전에 직접 넘겨야 할 것${R}" "${B}${Y}Hand over in person before you leave${R}" 0.5
say2 "- [ ] ops-alert Slack 봇 토큰 — 16-saas-other.md §2, 만료 2026-12-01 — 후임 계정으로 재발급" \
     "- [ ] ops-alert Slack bot token — 16-saas-other.md §2, expires 2026-12-01 — reissue under the successor's account" 0.5
say2 "- [ ] billing-api 레포 유일 admin — 02-github-ownership.md §2 — 퇴사 전 admin 1명 추가" \
     "- [ ] Only admin of the billing-api repo — 02-github-ownership.md §2 — add one more admin before leaving" 0.5
say2 "- [ ] 개인 계정으로 도는 Datadog 모니터 3개 — 23-oncall-monitoring.md §1 — 후임에게 소유권 이전" \
     "- [ ] 3 Datadog monitors running under my personal account — 23-oncall-monitoring.md §1 — transfer ownership" 0.5
say2 "- [ ] 공용 계정 ops@acme.com 비밀번호 — 12-aws-assets.md §1 — 직접 전달(패키지에 없음)" \
     "- [ ] Shared account ops@acme.com password — 12-aws-assets.md §1 — hand over in person (not in the package)" 0.8
say ""
say2 "${D}> 위 항목은 시크릿 값·비밀번호가 패키지에 들어 있지 않아 사람끼리 넘겨야 하는 것입니다. 퇴사일 전에 인계자와 함께" \
     "${D}> These items need a person-to-person handover: secret values and passwords are not in the package. Work through"
say2 "${D}> 하나씩 처리하세요. 인계자에게는 /dementor-inherit jane.doe 를 내가 재직 중일 때 돌려 달라고 하세요 — 그 절차 끝에" \
     "${D}> them with your successor before your last day, and ask them to run /dementor-inherit jane.doe while you are still"
say2 "${D}> 나오는 질문 목록은 퇴사 후에는 답할 사람이 없습니다.${R}" \
     "${D}> here — the question list at the end of that procedure has nobody to answer it after you leave.${R}" 6

# ================= 장면 2: 인계자 / Scene 2: the successor =================
printf '\033[2J\033[H'
say2 "${D}# 같은 레포를 클론한 후임 j.kim 이, jane.doe 가 아직 재직 중일 때 연다${R}" \
     "${D}# The successor j.kim clones the same repo and runs this while jane.doe is still around${R}" 1.2
type_cmd "/dementor-inherit jane.doe"
say2 "${B}0단계${R}  세션 = Claude Code · 내 ID = j.kim · 메모리 루트 확인 ${G}✓${R}" \
     "${B}Step 0${R}  session = Claude Code · my ID = j.kim · memory root found ${G}✓${R}" 0.9
say2 "${B}1단계${R}  jane.doe/ 읽기 — handoff.md §0–12 · persona.md · appendix 23 · memory-export 9 디렉터리" \
     "${B}Step 1${R}  reading jane.doe/ — handoff.md §0–12 · persona.md · 23 appendix files · 9 memory-export directories" 0.9
say2 "${B}2단계${R}  요약 → jane.doe/inherit/j.kim-2026-11-07.md ${D}(지금 깨질 것 → 미완 → 반복 운영 → 함정 → 페르소나)${R}" \
     "${B}Step 2${R}  summary → jane.doe/inherit/j.kim-2026-11-07.md ${D}(what can break now → unfinished → recurring ops → pitfalls → persona)${R}" 0.9
say2 "${B}3단계${R}  origin 으로 내 로컬 레포와 짝 맞추기 — 9개 중 6개 일치" \
     "${B}Step 3${R}  matching my local repos by origin — 6 of 9 matched" 0.9
say2 "${B}4단계${R}  포인터 등록 — MEMORY.md 상속 절 + 일치한 레포 6곳에 링크 2줄씩 ${D}(복사 없음)${R}" \
     "${B}Step 4${R}  pointers planted — inherited section in MEMORY.md + 2 link lines in each of the 6 matched repos ${D}(no copies)${R}" 0.9
say2 "${B}5단계${R}  push inherit/j.kim-jane.doe → ${C}https://github.com/acme/dementor/pull/13${R}" \
     "${B}Step 5${R}  push inherit/j.kim-jane.doe → ${C}https://github.com/acme/dementor/pull/13${R}" 1.0
say ""
say2 "등록한 포인터 6개, 짝 못 찾은 디렉터리 3개. 더 깊이 들이려면 jane.doe 의 feedback 유형 메모리 12개를" \
     "6 pointers registered, 3 directories unmatched. To go deeper, 12 feedback-type memories of jane.doe can be copied"
say2 "reference 유형으로 복사할 수 있습니다. 원문은 바뀌지 않고 inherited_jane.doe_ 접두어로 구분되며 한 번에 지울 수" \
     "as reference-type files. The originals stay untouched, the copies carry the inherited_jane.doe_ prefix and can be"
say2 "있습니다. 원하면 복사해 라고 하세요." \
     "removed in one go. Say 복사해 (copy) if you want that." 1.0
say ""
say2 "${B}${Y}전임자에게 지금 확인할 것${R}" "${B}${Y}Ask the predecessor now${R}" 0.5
say2 "- [ ] ops-alert 봇 토큰 재발급은 누가 승인하나요? — [jane.doe/appendix/16-saas-other.md §2]" \
     "- [ ] Who approves reissuing the ops-alert bot token? — [jane.doe/appendix/16-saas-other.md §2]" 0.5
say2 "- [ ] billing-api 야간 배치가 실패하면 어디를 먼저 보나요? — [jane.doe/handoff.md §8]" \
     "- [ ] When the billing-api nightly batch fails, where do you look first? — [jane.doe/handoff.md §8]" 0.5
say2 "- [ ] 공용 계정 ops@acme.com 비밀번호 — [jane.doe/handoff.md §12]" \
     "- [ ] Shared account ops@acme.com password — [jane.doe/handoff.md §12]" 0.8
say ""
say2 "${D}> 시크릿 값·비밀번호는 패키지에 없습니다. 전임자가 아직 재직 중이면 위 질문을 지금 물어보세요 — 퇴사 후에는 답할 사람이" \
     "${D}> Secret values and passwords are not in the package. If the predecessor is still here, ask these now — nobody can"
say2 "${D}> 없습니다. 답은 이 요약 파일 §1·§2 의 해당 항목에 적고, bash scripts/qa.sh jane.doe | grep -F -- \"/jane.doe/inherit/\" 가" \
     "${D}> answer them after they leave. Write the answers into §1·§2 of this summary file, check that"
say2 "${D}> 비어 있는지 확인한 뒤 같은 브랜치에 다시 커밋하세요.${R}" \
     "${D}> bash scripts/qa.sh jane.doe | grep -F -- \"/jane.doe/inherit/\" is empty, and commit again on the same branch.${R}" 8
