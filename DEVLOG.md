# Development Log

## 2026-11-02 (part 10) — shared Claude Code rules for both accounts

### What was done

- Created `~/.claude-shared/` with `CLAUDE.md`, `skills/` and `agents/`. The general rules moved there,
  including the DEVLOG rules from part 9; `~/.claude/CLAUDE.md` now imports them and keeps only the Jira rules,
  and `~/.claude-personal/CLAUDE.md` is just the import.
- Moved `uloz-session` to the shared folder and linked it into both config folders, with `agents/` linked the
  same way. `skills/synced` was left alone.
- Removed the `claude-work` aliases from `~/.zshrc` and moved `~/.claude-work` and the identical personal copy
  of `uloz-session` to the Trash. `code-work` stays because it uses `~/.claude`.

### Current state

- One `claude -p --model haiku` run per config: both reported the 150-line DEVLOG rule and the `uloz-session`
  skill; only `~/.claude` reported the Jira rules. `zsh -n ~/.zshrc` passed.
- The shared agent link was not exercised because `~/.claude-shared/agents/` is empty.
- These changes live outside this repository. The repository changes from parts 7-9 are still not committed.

## 2026-11-02 (part 9) — DEVLOG size rules added to the global instructions

### What was done

- Added the rules from part 8 to the DEVLOG section of `~/.claude/CLAUDE.md`: read the first 150 lines, keep
  older entries in `docs/devlog/YYYY-MM.md`, and rotate above 400 lines. The append-only rule now allows
  moving whole entries unchanged to the archive.

### Current state

- The edit to `~/.claude/CLAUDE.md` applied; it lives outside this repository. Other projects were not
  changed or checked, so a project with its own "read `DEVLOG.md`" rule still needs that rule updated.

## 2026-11-02 (part 8) — docs: rotate DEVLOG by size, not by calendar

### What was done

- Replaced the month-start rule from part 7 in `AGENTS.md`: when adding an entry would push `DEVLOG.md` over
  400 lines, its oldest whole entries move to `docs/devlog/YYYY-MM.md` by the date in their heading, and at
  least the newest 150 lines stay.

### What was fixed

- The part 7 rule would have emptied `DEVLOG.md` at the start of each month, so the first task of a month
  would have read no recent context.

### Current state

- Rule text checked in `AGENTS.md`. No rotation has run under it yet, and nothing enforces it: Claude
  follows it when it writes a DEVLOG entry.
- Not committed.

## 2026-11-02 (part 7) — docs: split DEVLOG by month

### What was done

- Moved every entry older than 2026-11 unchanged from `DEVLOG.md` to `docs/devlog/YYYY-MM.md`
  (`2025-01`, `2026-02`, `2026-03`, `2026-06`, `2026-08`, `2026-09`, `2026-10`). Only a title line was added
  to each archive file.
- Updated the Development Context Log rules in `AGENTS.md`: read the first 150 lines of `DEVLOG.md`, search
  `docs/devlog/` only for older history, and move the previous month's entries when a new month starts.

### What was fixed

- `AGENTS.md` told every task to read the whole log, which had grown to 4,658 lines, 333 KB and 136 entries.

### Design decisions

- Split by month, not by topic: one entry often covers several topics, while a date gives each entry one
  obvious place.
- Five entries headed `2025-02-23` sit between `2026-02-23` entries, so the year is probably a typo. They
  stay in `docs/devlog/2026-02.md` in their original position with their headings unchanged, because the log
  is append-only. The three `2025-01-XX` entries keep their own file for the same reason.

### Current state

- Rejoining `DEVLOG.md` and the archive files in order (without the added title lines), before this entry was
  added, matched `git show HEAD:DEVLOG.md` byte for byte (`cmp`); 136 headings before and after.
- `.github/workflows/claude-review.yml` was not changed; it already reads only the first 150 lines.
- Not committed.

### Pending / next steps

- `fix/unknown-song-title` still has the old log and its own 2026-11-02 entries. Reconcile them with this
  file when that branch goes to main; the merge was not tried.

## 2026-11-02 (part 6) — Claude review verified on PR #1

### What was done

- Replaced `CLAUDE_CODE_OAUTH_TOKEN` from the clipboard with a command that rejects text not starting
  with `sk-ant-`, then reran `Claude Review` (run `41432492583`, commit `e6db580`).

### What was fixed

- Likely source of the bad secret: it had the same length and spaces as the `gh secret set` command
  itself (63 characters, 5 spaces). Copying that command had overwritten the token in the clipboard.

### Current state

- First successful run: 57 s job, 6 turns, reported cost $0.11, 0 permission denials. The agent posted
  a summary and 2 inline comments as `github-actions[bot]`.
- Findings checked by hand:
  - Line 21 "token blocker": false positive. It repeated DEVLOG part 5, which this run had just disproved.
  - Oldest DEVLOG entry out of date: true, left as is because DEVLOG is append-only and parts 2-3 correct it.
  - No `concurrency` group: true but minor for one developer; not added.
  - Floating `@v1` tag: true; not pinned for now.

### Pending / next steps

- Merge PR #1 once CI is green. The review then runs on new PRs.

## 2026-11-02 (part 5) — Claude review: the stored secret is not a token

### What was done

- Added a temporary `Check token shape` step (run `41432347720`, commit `97f9285`), then removed it.
  It printed only the length, whitespace count and prefix match, never the value.

### What was fixed

- Explained the repeated 401: `CLAUDE_CODE_OAUTH_TOKEN` holds 63 characters with 5 whitespace
  characters and no `sk-ant-oat` prefix, so it is other text rather than a token. A rerun after the
  secret was replaced (`41431823631`) failed the same way.

### Current state

- The workflow is back to its intended form. The review still has not worked and PR #1 is not merged.

### Pending / next steps

- Store the token from the clipboard with a command that refuses anything not starting with
  `sk-ant-`, then rerun the review and check that the agent posts a comment.

## 2026-11-02 (part 4) — Claude review: stored Claude token rejected as invalid

### What was done

- Enabled `show_full_output` for one run (`41431665957`, commit `089c793`) with the owner's OK, then
  removed it again from `.github/workflows/claude-review.yml`.

### What was fixed

- Found the hidden error: `Failed to authenticate. API Error: 401 OAuth access token is invalid.`
  The problem is the value stored in `CLAUDE_CODE_OAUTH_TOKEN`, not the workflow. Why it is invalid
  is unknown; a bad paste is possible but unconfirmed.

### Current state

- The debug log ended before any tool ran and has no `sk-ant-` value.
- The review still has not worked and PR #1 is not merged.

### Pending / next steps

- Create a new token with `claude setup-token`, store it with `gh secret set`, rerun the review.

## 2026-11-02 (part 3) — Claude review: corrected 401 cause, Claude login error still open

### What was done

- Reworded the `github_token` comment in `.github/workflows/claude-review.yml`; it no longer claims
  the app was installed. Decision: keep `github_token` and do not install the Claude GitHub App,
  because the review does not need the app's write access to the repository.

### What was fixed

- Corrected part 2: linking the 401 to `anthropics/claude-code-action#1683` was not established.
  The owner was stopped on GitHub's "Confirm access" (sudo mode) page during the install, so the
  install most likely never completed, and that alone explains the error.

### Current state

- Run `41431166370` on `7cb64d1`: the GitHub step passed ("Using provided GITHUB_TOKEN", actor
  permission `admin`), but Claude Code ended after 1.8 s with `is_error: true`, $0 cost and no model
  usage. The message is hidden while `show_full_output` is false, so the cause is unknown; no review
  comment was posted.
- CI for `7cb64d1` was not read (`gh pr checks` timed out). PR #1 is not merged.
- This entry and the comment change are local until the next push.

### Pending / next steps

- Read the real error, then merge PR #1 only after the agent posts a comment.
- `show_full_output` logs are public on this repository, so enable it for one run at most and only
  with the owner's OK.

## 2026-11-02 (part 2) — fix: run Claude review with the workflow token

### What was done

- `.github/workflows/claude-review.yml`: passes `github_token: ${{ secrets.GITHUB_TOKEN }}` and drops
  `id-token: write`. `setupGitHubToken()` in the action uses a provided token and skips the OIDC
  exchange, so the review no longer depends on the Claude GitHub App.
- `CLAUDE_CODE_OAUTH_TOKEN` is still the Claude login. The workflow token only covers GitHub access,
  is limited to the job's `permissions` and expires with the job.

### What was fixed

- `Claude Review` failed on PR #1 with `401 Unauthorized - Claude Code is not installed on this
  repository`: 4 attempts, the last one after the owner saved the app's repository access. I could
  not confirm the install from here. The same error is reported for a confirmed install on a
  personal account in `anthropics/claude-code-action#1683` (open).

### Current state

- This supersedes the previous entry: `id-token: write` is no longer used, and the review is expected
  to run on PR #1 itself because the skip applied only to the OIDC exchange.
- `flutter analyze`/tests and the Android build passed on PR #1 before this change.
- The workflow token path has not run yet, so the review is still unverified.

### Pending / next steps

- Check the `Claude Review` run on PR #1 and that the agent posts a comment; merge after that.
- Comments will come from `github-actions[bot]`, not `claude[bot]`. The usage docs reserve
  `github_token` for custom apps while the FAQ documents it as the alternative to the app, so
  revisit it once `#1683` is resolved.

## 2026-11-02 — ci: add Claude pull request review

### What was done

- New `.github/workflows/claude-review.yml`, based on the official `anthropics/claude-code-action@v1`
  review example (`docs/solutions.md`, `examples/pr-review-comprehensive.yml`). It runs on non-draft
  pull requests, reads `AGENTS.md`, `docs/TODO.md` and the newest `DEVLOG.md` entries, and comments
  on whether the change matches its description, can break existing behaviour and fits the project.
- The agent can only read the PR and post comments (`gh pr view`, `gh pr diff`, `gh pr comment`,
  inline comments), capped at `--max-turns 20`. `ci.yml` stays the deterministic check.

### Design decisions

- Pull requests instead of push: the action documents PR review, and comments need a PR to attach
  to. Work therefore has to move from direct commits on `main` to branches with PRs.
- `id-token: write` is required by the default Claude GitHub App authentication.
- The PR title and body are not interpolated into the prompt; the agent reads them with `gh pr view`.

### Current state

- YAML parsed locally. The workflow has not run on GitHub yet, so the review itself is unverified.

### Pending / next steps

- Install the Claude GitHub App on `jelazi/song_viewer` and add the `CLAUDE_CODE_OAUTH_TOKEN` secret.
- Merge this workflow first: the action skips itself on the PR that adds it (`src/github/token.ts`
  reports a workflow validation error until the file is on the default branch).
- Open a small trial PR after that merge and check that the agent posts a comment.

