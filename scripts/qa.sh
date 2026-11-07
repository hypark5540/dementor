#!/usr/bin/env bash
# dementor QA — <id>/ 패키지의 구조 점검(정보성)과 시크릿·전화번호 검사(차단). 읽기 전용, 파일을 만들지 않는다.
#
# 사용법: bash scripts/qa.sh <id>
#   <id> 가 디렉터리 경로면 그대로 쓰고, 아니면 <레포루트>/<id> 로 본다. 레포 루트는 이 스크립트 위치의 상위.
# 종료 코드: 0 = QA: PASS / 1 = 차단 검사 히트(QA: FAIL) / 2 = 사용법 오류·폴더 없음
# macOS 기본 bash 3.2 호환(mapfile·declare -A·${var,,} 미사용). GNU 전용 grep 옵션 미사용.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [ $# -ne 1 ] || [ -z "$1" ]; then
  echo "사용법: bash scripts/qa.sh <id>   (예: bash scripts/qa.sh jane.doe)" >&2
  exit 2
fi

if [ -d "$1" ]; then
  DIR="$(cd "$1" && pwd)"
else
  DIR="$ROOT/${1%/}"
fi
if [ ! -d "$DIR" ]; then
  echo "폴더 없음: $DIR" >&2
  exit 2
fi
ID="$(basename "$DIR")"

H="$DIR/handoff.md"
APPX="$DIR/appendix"
ME="$DIR/memory-export"
# appendix 파일 참조: 01-github-prs.md, 17-tracked-04.md, 02-github-prs-all.tsv 등. 앞 경계로 날짜(2026-09-22.md) 오탐을 막는다.
REF_RE='(^|[^0-9a-z-])[0-9]{2}-[a-z0-9_-]+\.(md|tsv)'

count_lines() { # 빈 문자열이면 0
  if [ -n "$1" ]; then printf '%s\n' "$1" | wc -l | tr -d ' '; else echo 0; fi
}

echo "== dementor QA: $ID"
echo "   폴더: $DIR"
echo
echo "-- 정보성 검사 (실패 아님)"

if [ -f "$H" ]; then
  echo "handoff.md: $(wc -l < "$H" | tr -d ' ')줄, $(wc -c < "$H" | tr -d ' ')바이트"
  echo "## 절 목록:"
  grep -n -E '^## ' "$H" | sed 's/^/   /'
  nonempty=$(grep -c -v '^[[:space:]]*$' "$H")
  cited=$(grep -c -E "$REF_RE|https?://" "$H")
  echo "인용 밀도: 근거(appendix 파일명 또는 URL)가 있는 줄 $cited / 비어있지 않은 줄 $nonempty"
  echo "실존하지 않는 appendix 참조:"
  missing=$(grep -o -E "$REF_RE" "$H" | sed 's/^[^0-9]*//' | sort -u | while read -r r; do
    [ -f "$APPX/$r" ] || echo "   MISSING: $r"
  done)
  echo "${missing:-   (없음)}"
  echo "미인용 appendix 파일:"
  uncited=$(for f in "$APPX"/[0-9][0-9]-*; do
    [ -e "$f" ] || continue
    b=$(basename "$f")
    grep -q -F "$b" "$H" || echo "   $b"
  done)
  echo "${uncited:-   (없음)}"
  echo "'(추정)' 수: $(grep -o '(추정)' "$H" | wc -l | tr -d ' ')"
else
  echo "handoff.md: 없음 (필수 산출물)"
fi

if [ -f "$DIR/persona.md" ]; then
  echo "persona.md: 있음 ($(wc -l < "$DIR/persona.md" | tr -d ' ')줄)"
else
  echo "persona.md: 없음 (필수 산출물)"
fi

if [ -d "$ME" ]; then
  me_dirs=$(find "$ME" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
  me_files=$(find "$ME" -type f | wc -l | tr -d ' ')
  me_cfg="없음 (필수 산출물)"
  [ -d "$ME/_config" ] && me_cfg="있음"
  echo "memory-export: 디렉터리 ${me_dirs}개, 파일 ${me_files}개, _config: $me_cfg"
else
  echo "memory-export: 없음 (필수 산출물)"
fi
[ -d "$DIR/inherit" ] && echo "inherit/: 파일 $(find "$DIR/inherit" -type f | wc -l | tr -d ' ')개"

echo
echo "-- 차단 검사 (1건이라도 있으면 FAIL)"

# 검사 대상: <id>/ 안의 handoff.md persona.md appendix/ memory-export/ inherit/ 중 존재하는 것,
# 그리고 _raw/ 의 수집 스크립트(.sh .py — .gitignore 가 추적을 남기는 유일한 _raw 파일). _raw/ 의 데이터 덤프와
# _work/ _gen/ 은 커밋되지 않으므로 보지 않는다(로컬 QA 와 CI 가 같은 결과를 낸다).
targets=()
for t in handoff.md persona.md appendix memory-export inherit; do
  [ -e "$DIR/$t" ] && targets+=("$DIR/$t")
done
if [ -d "$DIR/_raw" ]; then
  while IFS= read -r f; do targets+=("$f"); done < <(find "$DIR/_raw" -type f \( -name '*.sh' -o -name '*.py' \) | sort)
fi

# 회사 도메인 = <레포루트>/.dementorrc 의 COMPANY_DOMAIN 값. 파일을 source 하지 않고 값만 읽는다.
# 비었거나 example.com(템플릿 기본값)이거나 도메인에 못 쓰는 문자가 있으면 미설정으로 본다.
DOMAIN=$(sed -n 's/^COMPANY_DOMAIN=//p' "$ROOT/.dementorrc" 2>/dev/null | head -n 1 | tr -d "[:space:]\"'" | tr '[:upper:]' '[:lower:]')
case "$DOMAIN" in '' | example.com | *[!a-z0-9.-]*) DOMAIN="" ;; esac
OWN_RE='@[a-z0-9-]+\.iam\.gserviceaccount\.com$'
domain_note=" (COMPANY_DOMAIN 미설정 — .dementorrc 확인)"
if [ -n "$DOMAIN" ]; then
  OWN_RE="@($(printf '%s' "$DOMAIN" | sed 's/\./\\./g')|[a-z0-9-]+\\.iam\\.gserviceaccount\\.com)\$"
  domain_note=""
fi

# 회사 도메인 밖 이메일(정보성, 실패 아님). 주소 자체는 출력하지 않고 개수와 도메인만.
if [ ${#targets[@]} -gt 0 ]; then
  ext_emails=$(grep -r -h -I -o -E --exclude-dir=_work --exclude-dir=_gen --exclude-dir=_raw '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[a-z]{2,}' "${targets[@]}" 2>/dev/null \
    | grep -v -i -E "$OWN_RE" \
    | grep -v -i -E '\.(png|jpe?g|gif|svg|webp|md|ts|js|py|json|ya?ml)$' | sort -u)
  n_ext=$(count_lines "$ext_emails")
  ext_domains=$(printf '%s\n' "$ext_emails" | sed 's/.*@//' | sort -u | tr '\n' ' ')
  echo "회사 도메인 밖 이메일(정보성): ${n_ext}건  도메인: ${ext_domains:-(없음)}${domain_note}"
  echo
fi

# 시크릿 패턴. 마스킹된 값(AKIA**** 처럼 길이가 모자란 것)은 걸리지 않는다.
# sk- 는 앞 경계를 둬 task-/disk- 같은 일반 단어를 피하고,
# password/token 류는 값 뒤에 '(' 가 오는 함수 호출(token = fn(...))을 제외한다.
Q="'"
SECRET_RE='(AKIA|ASIA)[0-9A-Z]{16}'
SECRET_RE="$SECRET_RE|xox[abpesr]-[A-Za-z0-9-]{10,}"
SECRET_RE="$SECRET_RE|xapp-[0-9]-[A-Z0-9]+-[0-9]+-[a-z0-9]+"
SECRET_RE="$SECRET_RE|(^|[^A-Za-z0-9])sk-[A-Za-z0-9_-]{20,}"
SECRET_RE="$SECRET_RE|gh[pousr]_[A-Za-z0-9]{36}"
SECRET_RE="$SECRET_RE|github_pat_[A-Za-z0-9_]{20,}"
SECRET_RE="$SECRET_RE|gl(pat|dt|rt|ptt|soat|cbt|agent|ft)-[A-Za-z0-9_-]{20,}"
SECRET_RE="$SECRET_RE|lin_(api|oauth)_[A-Za-z0-9]{32,}"
SECRET_RE="$SECRET_RE|sntrys_[A-Za-z0-9_=-]{20,}"
SECRET_RE="$SECRET_RE|ntn_[A-Za-z0-9]{30,}"
SECRET_RE="$SECRET_RE|ATATT3[A-Za-z0-9_=-]{20,}"
SECRET_RE="$SECRET_RE|AIza[0-9A-Za-z_-]{35}"
SECRET_RE="$SECRET_RE|-----BEGIN [A-Z ]*PRIVATE KEY-----"
SECRET_RE="$SECRET_RE|hooks\\.slack\\.com/services/T[A-Z0-9]+/B[A-Z0-9]+/[A-Za-z0-9]+"
SECRET_RE="$SECRET_RE|eyJ[A-Za-z0-9_-]{20,}\\.eyJ[A-Za-z0-9_-]{20,}"
SECRET_RE="$SECRET_RE|(password|passwd|secret|token|api_?key)[[:space:]]*[:=][[:space:]]*[\"$Q]?[A-Za-z0-9/+=_-]{12,}([^A-Za-z0-9/+=_(-]|\$)"
# ponytail: 한국 휴대폰 형식만 잡는다. 다른 나라 번호가 필요하면 PHONE_RE 에 | 로 패턴을 더한다.
# 전화번호(한국 휴대폰). 앞뒤 숫자 경계를 둬 긴 숫자열(계정 번호·프로젝트 번호) 안의 부분 일치를 피하고,
# 앞 경계에서 영숫자·밑줄·하이픈 직후를 제외해 슬러그/ID 꼬리(gen-lang-client-NNNN)도 제외한다.
PHONE_RE='(^|[^0-9A-Za-z_-])01[016789]-?[0-9]{3,4}-?[0-9]{4}([^0-9]|$)'

scan() { # $1 = ERE. 출력: "   경로:줄: 일치문자열(24자까지)" — 전체 값은 로그에 남기지 않는다.
  [ ${#targets[@]} -eq 0 ] && return 0
  grep -r -H -I -n -o -E --exclude-dir=_work --exclude-dir=_gen --exclude-dir=_raw "$1" "${targets[@]}" 2>/dev/null \
    | awk -F: '{ m=$3; for (i=4; i<=NF; i++) m=m ":" $i; if (length(m) > 24) m=substr(m, 1, 24) "..."; print "   " $1 ":" $2 ": " m }'
}

show() { # $1 = 라벨, $2 = 히트 수, $3 = 히트 목록
  echo "$1: $2건"
  [ "$2" -gt 0 ] && printf '%s\n' "$3" | head -50
  [ "$2" -gt 50 ] && echo "   ... (이하 $(($2 - 50))건 생략)"
  return 0
}

secret_hits=$(scan "$SECRET_RE")
phone_hits=$(scan "$PHONE_RE")
n_secret=$(count_lines "$secret_hits")
n_phone=$(count_lines "$phone_hits")
show "시크릿 패턴" "$n_secret" "$secret_hits"
show "전화번호 패턴" "$n_phone" "$phone_hits"

total=$((n_secret + n_phone))
echo
if [ "$total" -gt 0 ]; then
  echo "QA: FAIL ($total hits)"
  exit 1
fi
echo "QA: PASS"
exit 0
