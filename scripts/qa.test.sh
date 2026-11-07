#!/usr/bin/env bash
# qa.sh 자체 테스트 — 임시 폴더에 가짜 패키지를 만들어 종료 코드와 출력을 확인한다.
# 사용법: bash scripts/qa.test.sh        (macOS 기본 bash 3.2 호환)
# 가짜 시크릿·전화번호는 소스에 통째로 두지 않고 실행 중에 이어 붙인다(시크릿 스캐너 오탐 방지).
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
mkdir -p "$T/scripts"
cp "$HERE/qa.sh" "$T/scripts/"
echo 'COMPANY_DOMAIN=acme.com' > "$T/.dementorrc"

AWS_KEY="AKIA""ABCDEFGHIJKLMNOP"
PHONE="010-""1234-5678"
fail=0

pkg() { # $1 = id → 차단 검사에 걸리지 않는 최소 패키지를 새로 만든다
  rm -rf "${T:?}/$1"
  mkdir -p "$T/$1/appendix" "$T/$1/memory-export/_config"
  printf '# handoff\n\n## 0. 수집 상태\n- PR 12건 [01-github-prs.md §1]\n' > "$T/$1/handoff.md"
  echo '# persona' > "$T/$1/persona.md"
  echo '# prs' > "$T/$1/appendix/01-github-prs.md"
}

check() { # $1 = 이름, $2 = 기대 종료 코드, $3 = 출력에 있어야 할 ERE, 나머지 = qa.sh 인자
  name=$1; want=$2; pat=$3; shift 3
  out=$(bash "$T/scripts/qa.sh" "$@" 2>&1); got=$?
  if [ "$got" -eq "$want" ] && printf '%s\n' "$out" | grep -q -E -- "$pat"; then
    echo "ok   $name"
  else
    echo "FAIL $name (exit $got, 기대 $want, 패턴: $pat)"
    printf '%s\n' "$out" | sed 's/^/     /'
    fail=1
  fi
}

pkg jane.doe
check "깨끗한 패키지는 PASS" 0 '^QA: PASS$' jane.doe

pkg jane.doe; echo "key: $AWS_KEY" >> "$T/jane.doe/handoff.md"
check "AWS 액세스 키는 FAIL" 1 '^QA: FAIL \(1 hits\)$' jane.doe

pkg jane.doe; echo "연락처 $PHONE" >> "$T/jane.doe/appendix/01-github-prs.md"
check "휴대폰 번호는 FAIL" 1 '^전화번호 패턴: 1건$' jane.doe

pkg jane.doe; echo 'password: hunter2hunter2hunter2' >> "$T/jane.doe/persona.md"
check "password 값은 FAIL" 1 '^시크릿 패턴: 1건$' jane.doe

pkg jane.doe; echo "key: $AWS_KEY" > "$T/jane.doe/memory-export/_config/notes.md"
check "memory-export 안의 시크릿도 FAIL" 1 '^QA: FAIL' jane.doe

pkg jane.doe; echo 'key: AKIA****************' >> "$T/jane.doe/handoff.md"
check "마스킹된 키는 PASS" 0 '^QA: PASS$' jane.doe

pkg jane.doe; echo 'token = fetch_session_token(client)' >> "$T/jane.doe/handoff.md"
check "함수 호출(token = fn(...))은 PASS" 0 '^QA: PASS$' jane.doe

pkg jane.doe; mkdir -p "$T/jane.doe/appendix/_work"; echo "key: $AWS_KEY" > "$T/jane.doe/appendix/_work/dump.txt"
check "커밋되지 않는 _work/ 는 검사하지 않는다" 0 '^QA: PASS$' jane.doe

pkg jane.doe; echo 'owner a@acme.com, vendor b@gmail.com' >> "$T/jane.doe/handoff.md"
check "회사 도메인(.dementorrc) 이메일은 외부로 세지 않는다" 0 '밖 이메일\(정보성\): 1건  도메인: gmail\.com' jane.doe

echo 'COMPANY_DOMAIN=example.com' > "$T/.dementorrc"
check "도메인 미설정이면 모든 이메일을 세고 알린다" 0 '밖 이메일\(정보성\): 2건.*COMPANY_DOMAIN 미설정' jane.doe
rm "$T/.dementorrc"
check ".dementorrc 가 없어도 미설정으로 알리고 PASS" 0 '2건.*COMPANY_DOMAIN 미설정' jane.doe
printf 'COMPANY_DOMAIN="Acme.com" \r\n' > "$T/.dementorrc"
check "따옴표·CRLF·대문자가 섞인 값도 도메인으로 읽는다" 0 '밖 이메일\(정보성\): 1건  도메인: gmail\.com *$' jane.doe
echo 'COMPANY_DOMAIN=acme.com' > "$T/.dementorrc"

pkg jane.doe; mkdir -p "$T/jane.doe/inherit"; echo "key: $AWS_KEY" > "$T/jane.doe/inherit/j.kim-2026-01-01.md"
check "inherit/ 요약 파일의 시크릿도 FAIL" 1 '/inherit/j\.kim-2026-01-01\.md:1:' jane.doe

pkg jane.doe
check "디렉터리 경로를 인자로 줘도 된다" 0 '^== dementor QA: jane\.doe$' "$T/jane.doe"
check "인자가 없으면 사용법(2)" 2 '사용법'
check "없는 폴더는 2" 2 '폴더 없음' nobody.here

echo
if [ "$fail" -ne 0 ]; then echo "qa.test: FAIL"; exit 1; fi
echo "qa.test: PASS"
