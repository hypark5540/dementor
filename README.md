<p align="center">
  <img src=".github/assets/dementor.png" alt="dementor pulling work context and persona out of a person running away" width="100%">
</p>

# dementor

[![CI](https://github.com/hypark5540/dementor/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/hypark5540/dementor/actions/workflows/ci.yml)
[![CodeQL](https://github.com/hypark5540/dementor/actions/workflows/codeql.yml/badge.svg?branch=main)](https://github.com/hypark5540/dementor/actions/workflows/codeql.yml)
[![Release](https://img.shields.io/github/v/release/hypark5540/dementor?sort=semver)](https://github.com/hypark5540/dementor/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-supported-8A63D2)](.claude/commands)
[![Codex](https://img.shields.io/badge/Codex-supported-8A63D2)](AGENTS.md)
[![bash 3.2+](https://img.shields.io/badge/bash-3.2%2B-4EAA25?logo=gnubash&logoColor=white)](scripts/qa.sh)

**English** · [한국어](README.ko.md)

A handover template for employee offboarding. It pulls a leaver's work context, decision rationale, and AI memory into one "soul" package, and lets the successor take it over with a single line.
The person leaving types `/dementor-upload` to their own AI agent; the person taking over types `/dementor-inherit <id>`.

> Prompts and the generated documents are in Korean. The procedures run fine in any Claude Code or Codex session, but the handoff package comes out in Korean.

## Why

Handover documents only contain what the writer happens to remember. In practice, the most-opened part of a handover package was not the summary document but the predecessor's raw AI memory — that is where the "why we decided this", "where it broke", and "never do this again" lived.

So dementor does two things.

- **Extract**: the leaver's agent reads GitHub, local repos, Jira, Confluence, Notion, Slack, cloud accounts, and AI memory — read-only — and produces a cited handoff document, a persona document, and a copy of the memory originals.
- **Connect**: the successor's agent reads that package, writes a summary, and plants links to the originals in the successor's own local AI memory. Pointers, not copies, are the default, so the successor's memory is never overwritten with someone else's.

## Getting started (admin, once)

A package contains account IDs, collaboration history, and decision records. **Use it only in a private repo. Never push a package to this public repo or to a fork of it** (forks are public).

1. Create a **private** repo in your org from this template — GitHub's **Use this template → Create a new repository → Private**, or:

   ```bash
   git clone https://github.com/hypark5540/dementor.git && cd dementor
   rm -rf .git && git init -b main && git add -A && git commit -m "chore: init dementor"
   gh repo create <org>/dementor --private --source=. --push
   ```

2. Set `COMPANY_DOMAIN` in `.dementorrc` to your company email domain and commit it to `main`. Folder names (IDs) are the part of the company email before `@`.

   ```ini
   COMPANY_DOMAIN=acme.com
   ```

3. Protect `main`: require PRs and the `qa` status check. Limit access to the people involved in handovers and the admins.

## Leaver

1. Clone your company's dementor repo.
2. Open Claude Code or Codex at the repo root.
3. Type one line: `/dementor-upload` (Codex: "영혼 업로드").
4. In 1–2 hours a PR opens on the `soul/<id>` branch. A company account with Jira, Confluence, Notion, or Slack MCP connected fills in more; sources that are unavailable are marked "not collected" with instructions for checking manually.

What the agent collects:

| Collector | Source | Output (`<id>/appendix/`) |
|---|---|---|
| A | GitHub — every PR of mine, open PRs, repo permissions, repos where I am the only admin, workflow and secret *names* | `01` `02` |
| B | Local repos, machine, documents — unpushed commits, stashes, cloud profiles, schedulers, CLI configuration | `03` `07` `14` |
| C | Jira, Confluence — everything In Progress / To Do, epics I own, runbook pages | `04` `05` |
| D | Notion, Slack — canonical documents, bots and alert channels I operate, recurring report formats (DMs are never read) | `06` `18` |
| E | Cloud and SaaS — IAM, resources I own, tools where I am an admin | `12` `13` `16` |
| F | AI memory — Claude Code auto-memory, rules/skills I wrote, a copy of Codex settings, session metadata | `08`–`11` `15`, `memory-export/` |

After collecting, the agent picks about ten candidates for "things that break when my account is disabled", re-queries each one live (`17-tracked-*`), and writes `handoff.md` and `persona.md` from all of it. Every sentence carries a citation (an appendix file or a URL); guesses are marked `(추정)` (estimate).

Secret values, passwords, and personal contact details never go into the package (names, locations, and expiry dates only). That is why the run ends with a **"hand over in person before you leave"** checklist, printed in the terminal and in the PR body — key rotation, transferring sole-admin repos, moving automations that run under your personal account. Work through it with the successor before your last day.

## Successor

1. Clone your company's dementor repo (`git pull` if you already have it).
2. Open Claude Code or Codex at the repo root.
3. Type one line: `/dementor-inherit <predecessor-id>` (Codex: "<predecessor-id> 인계받을게").
4. In 10–20 minutes a summary appears at `<predecessor-id>/inherit/<your-id>-<date>.md`, and pointers to the predecessor are added to your local AI memory. Open the originals only when you need them.

**Run it before the predecessor's last day.** The procedure ends with an **"ask the predecessor now"** question list: secret values, permissions, and other things only a person can hand over — nobody can answer them after they are gone. Write the answers into the summary file and commit it again.

The summary is ordered "what can break right now → unfinished work → recurring operations → pitfalls and lessons → persona essentials". The predecessor's memory directories are matched to your local repos by `origin`, and only the matched repos get two link lines in their memory. If you want to go deeper, the predecessor's `feedback`-type memories can be copied as `inherited_<id>_`-prefixed files, and two commands undo that.

## Reviewer

Check that the PR's CI (`qa`) passed, skim the contents, and merge.
On FAIL, look at the flagged file and ask the author to fix it. Never push to `main` directly.
While skimming, check that `persona.md` and `memory-export/` do not contain sentences that instruct an agent to run something — the successor's agent will read those files.

## Layout

```text
AGENTS.md                         Shared entry point for Codex and Claude (triggers, rules). CLAUDE.md points to it
.dementorrc                       Company email domain
prompts/upload.md                 Collection procedure for the leaver
prompts/inherit.md                Procedure for the successor
.claude/commands/                 /dementor-upload, /dementor-inherit (Claude Code only)
scripts/qa.sh <id>                Secret, phone-number, and structure checks
scripts/qa.test.sh                Tests for qa.sh
.github/workflows/qa.yml          Runs qa.sh on every ID folder changed in a PR
.github/workflows/ci.yml          Self-test of the tooling (ShellCheck + qa.sh tests)
<id>/                             id = company email before @ (e.g. jane.doe)
  handoff.md                      Handoff document, sections 0–12
  persona.md                      Design philosophy, judgment criteria, working principles
  appendix/01–18                  Raw material per source
  memory-export/<original dir>/   Copy of the AI memory originals
  memory-export/_config/          Copy of CLAUDE.md, rules, skills, Codex settings
  inherit/<successor-id>-YYYY-MM-DD.md  Summary written by the successor
```

## Safeguards

- **Read-only collection**: the procedures only instruct queries. The only places written are your own `<id>/` folder in the repo and the successor's own memory.
- **Public-repo guard**: before collection starts and right before pushing, the agent checks whether the repo is public and stops if it is.
- **Secret values are never recorded**: only names, paths, and expiry dates. Settings and token files are deleted right after copying, and `.gitignore` blocks them once more.
- **Private information excluded**: private DMs, personal projects, family, and career memories are not collected; only the count of excluded items is kept.
- **Two QA gates**: `scripts/qa.sh` scans for secret and phone-number patterns before committing (locally) and on the PR (CI). A single hit is a FAIL.
- **PR gate**: packages go up only on `soul/<id>` branches, inherit summaries only on `inherit/<me>-<id>`.
- **No invention**: nothing is written without evidence; anything uncertain is marked `(확인 필요)` (needs confirmation).

Regex scanning does not catch every secret. See [SECURITY.md](SECURITY.md) (Korean) for the threat surface and how to report.

## Requirements

- [Claude Code](https://claude.com/claude-code) or Codex CLI
- `git`, `bash` 3.2+, `python3` (or `node`)
- [`gh`](https://cli.github.com/) — used for GitHub collection, PR creation, and the public-repo check. Without it those steps become "not collected" or the agent asks you
- Optional: Jira, Confluence, Notion, Slack MCP; AWS and GCP CLI logins

## Limitations

- Prompts and generated documents are in Korean.
- Built around GitHub (org repos, PRs, Actions).
- IDs must match `^[a-z0-9]+(\.[a-z0-9]+)*$`. If the email local part has underscores, hyphens, or capitals, the agent stops and asks for an ID.
- Only one company domain can be configured.
- The phone-number pattern in `qa.sh` covers Korean mobile numbers only.
- AI memory means Claude Code auto-memory and Codex settings.

## License

[MIT](LICENSE)
