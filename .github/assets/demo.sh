#!/usr/bin/env bash
# README 데모(demo.gif)의 각본. `vhs .github/assets/demo.tape` 가 이 스크립트를 재생해 GIF 를 만든다.
# 에이전트 출력은 업로드·인계 절차의 대표 장면을 압축한 각본이다(가짜 회사 acme.com, 가짜 사람 jane.doe·j.kim).
# `bash scripts/qa.sh jane.doe` 만은 임시 폴더에 만든 가짜 패키지에 실제로 돈다(임시 경로만 ~/acme/dementor 로 바꿔 보여 준다).
set -u

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

# ================= 장면 1: 퇴사자 =================
printf '\033[2J\033[H' # vhs 가 입력한 "bash demo.sh" 줄을 지운다
say "${D}# acme 의 비공개 dementor 레포에서, 떠나는 사람 jane.doe 가 Claude Code 를 연다${R}" 1.2
type_cmd "/dementor-upload"
say "${B}0단계${R}  ID = jane.doe (출처: userEmail) · COMPANY_DOMAIN = acme.com · 레포 visibility = PRIVATE ${G}✓${R}" 0.9
say "${B}1단계${R}  수집기 A–F 병렬 실행 ${D}(read-only)${R}" 0.6
say "  A  GitHub·GitLab    PR 184 · 열린 PR 3 · 유일 admin 레포 2            → 01 02 19"
say "  B  로컬·머신        레포 27 · 미푸시 커밋 2 · launchd 1               → 03 07 14"
say "  C  Jira·Linear      In Progress 6 · 담당 에픽 2 · 런북 4             → 04 05 20"
say "  D  Notion·Slack     운영 봇 3 · DM 추출 41건 (사적 대화 제외 128건)  → 06 18 21 22"
say "  E  클라우드·SaaS    IAM 역할 5 · 단독 admin 2 · 나만 받는 알림 3      → 12 13 16 23"
say "  F  AI 메모리        디렉터리 9 · 파일 38 · feedback 12                → 08–11 15 memory-export/" 0.9
say "${B}2단계${R}  \"내 계정이 꺼지면 깨지는 것\" 후보 9건 → 17-tracked-01..09 (지금 시각에 재조회)" 0.9
say "${B}3단계${R}  handoff.md 412줄 · persona.md 96줄 — 모든 문장에 근거(appendix·URL), (추정) 4" 0.9
say "${B}4단계${R}  QA" 0.5
type_cmd "bash scripts/qa.sh jane.doe"
(cd "$T" && bash scripts/qa.sh jane.doe) | sed "s#$T#~/acme/dementor#"
sleep 3.5
say ""
say "${B}5단계${R}  git commit → push soul/jane.doe → gh pr create ${D}(body: heredoc)${R}" 0.6
say "        ${C}https://github.com/acme/dementor/pull/12${R}" 1.0
say ""
say "${B}${Y}퇴사 전에 직접 넘겨야 할 것${R}" 0.5
say "- [ ] ops-alert Slack 봇 토큰 — 16-saas-other.md §2, 만료 2026-12-01 — 후임 계정으로 재발급" 0.5
say "- [ ] billing-api 레포 유일 admin — 02-github-ownership.md §2 — 퇴사 전 admin 1명 추가" 0.5
say "- [ ] 개인 계정으로 도는 Datadog 모니터 3개 — 23-oncall-monitoring.md §1 — 후임에게 소유권 이전" 0.5
say "- [ ] 공용 계정 ops@acme.com 비밀번호 — 12-aws-assets.md §1 — 직접 전달(패키지에 없음)" 0.8
say ""
say "${D}> 위 항목은 시크릿 값·비밀번호가 패키지에 들어 있지 않아 사람끼리 넘겨야 하는 것입니다. 퇴사일 전에 인계자와 함께"
say "${D}> 하나씩 처리하세요. 인계자에게는 /dementor-inherit jane.doe 를 내가 재직 중일 때 돌려 달라고 하세요 — 그 절차 끝에"
say "${D}> 나오는 질문 목록은 퇴사 후에는 답할 사람이 없습니다.${R}" 6

# ================= 장면 2: 인계자 =================
printf '\033[2J\033[H'
say "${D}# 같은 레포를 클론한 후임 j.kim 이, jane.doe 가 아직 재직 중일 때 연다${R}" 1.2
type_cmd "/dementor-inherit jane.doe"
say "${B}0단계${R}  세션 = Claude Code · 내 ID = j.kim · 메모리 루트 확인 ${G}✓${R}" 0.9
say "${B}1단계${R}  jane.doe/ 읽기 — handoff.md §0–12 · persona.md · appendix 23 · memory-export 9 디렉터리" 0.9
say "${B}2단계${R}  요약 → jane.doe/inherit/j.kim-2026-11-07.md ${D}(지금 깨질 것 → 미완 → 반복 운영 → 함정 → 페르소나)${R}" 0.9
say "${B}3단계${R}  origin 으로 내 로컬 레포와 짝 맞추기 — 9개 중 6개 일치" 0.9
say "${B}4단계${R}  포인터 등록 — MEMORY.md 상속 절 + 일치한 레포 6곳에 링크 2줄씩 ${D}(복사 없음)${R}" 0.9
say "${B}5단계${R}  push inherit/j.kim-jane.doe → ${C}https://github.com/acme/dementor/pull/13${R}" 1.0
say ""
say "등록한 포인터 6개, 짝 못 찾은 디렉터리 3개. 더 깊이 들이려면 jane.doe 의 feedback 유형 메모리 12개를"
say "reference 유형으로 복사할 수 있습니다. 원문은 바뀌지 않고 inherited_jane.doe_ 접두어로 구분되며 한 번에 지울 수"
say "있습니다. 원하면 복사해 라고 하세요." 1.0
say ""
say "${B}${Y}전임자에게 지금 확인할 것${R}" 0.5
say "- [ ] ops-alert 봇 토큰 재발급은 누가 승인하나요? — [jane.doe/appendix/16-saas-other.md §2]" 0.5
say "- [ ] billing-api 야간 배치가 실패하면 어디를 먼저 보나요? — [jane.doe/handoff.md §8]" 0.5
say "- [ ] 공용 계정 ops@acme.com 비밀번호 — [jane.doe/handoff.md §12]" 0.8
say ""
say "${D}> 시크릿 값·비밀번호는 패키지에 없습니다. 전임자가 아직 재직 중이면 위 질문을 지금 물어보세요 — 퇴사 후에는 답할 사람이"
say "${D}> 없습니다. 답은 이 요약 파일 §1·§2 의 해당 항목에 적고, bash scripts/qa.sh jane.doe | grep -F -- \"/jane.doe/inherit/\" 가"
say "${D}> 비어 있는지 확인한 뒤 같은 브랜치에 다시 커밋하세요.${R}" 8
