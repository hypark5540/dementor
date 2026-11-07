---
description: 인계자용 — 전임자 <id>/ 폴더를 읽어 요약 파일을 만들고 내 로컬 AI 메모리에 포인터를 붙인다
argument-hint: "<전임자 ID — 회사 이메일 @ 앞부분, 예: jane.doe>"
---
`$ARGUMENTS` 가 전임자 ID 다. 이메일이 들어오면 `@` 앞부분만 쓴다.
비어 있으면 레포 루트를 `ls` 해 ID 폴더 목록(`AGENTS.md` `CLAUDE.md` `README.md` `README.ko.md` `SECURITY.md` `LICENSE` `prompts` `scripts` `.claude` `.github` `.dementorrc` 제외)을 보여주고 어느 전임자인지 물은 뒤 진행한다.
그다음 레포 루트(`git rev-parse --show-toplevel`)의 `prompts/inherit.md` 를 읽고 끝까지 수행한다.
