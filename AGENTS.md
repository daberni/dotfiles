# Frameworks and Setup

## Java SDK

Before running Java or Gradle commands, check for `.sdkmanrc`; if present, run `sdk env` first. Do not run `sdk env` for unrelated work.

## Gradle projects

In Gradle projects, always use any existing gradle wrapper (gradlew).
Under no conditions ever, download any gradle versions yourself. If something fails this is likely due to sandboxing, request elevated privileges in these scenarios.

## Node / npm projects

Before running Node or npm commands, check for `.nvmrc`; if present, run `nvm use` first.

When evaluation is blocked because a project's `node_modules` is missing, install dependencies with `npm ci` (clean, lockfile-exact install) — never `npm install` — then continue with the intended task. `npm ci` keeps the install reproducible and leaves `package-lock.json` untouched. Only use `npm install` when the task is to *add or change* a dependency (which legitimately updates the lockfile); `npm ci` cannot add new packages.

# Development Workflow

## Feature Development

For feature work with meaningful behavior, define expected behavior before or alongside implementation using focused tests or comparable automated checks. Prefer a failing/absent-behavior check first when the desired behavior is clear, then implement and rerun it to green.

Avoid retrofitting tests merely to match the finished implementation; tests should describe intended behavior.

## Bug Analysis

When investigating a bug, establish a red-green feedback loop before changing the implementation. Reproduce the reported behavior with a focused failing test, regression test, or comparable automated check first. Confirm that the check fails for the expected reason, then make the smallest suitable fix and rerun the same check to prove it turns green.

## Time tracking for Jira work items

When a task is tied to a Jira work item (a key like `TIMR-1234`, `IN-42`, `TJI-146`) and real development happens on it — implementing, fixing, picking up, switching to, or finishing it — treat "should this effort be tracked in timr?" as an explicit check, even if the user never mentions time. A coding prompt won't make an agent reach for a time-tracking skill on its own, so the check has to be deliberate: when dev work on a keyed item starts, switches, or wraps up, invoke the `jira-timr-tracking` skill to start, switch, or stop the matching timr project time. Skip it for non-dev Jira touches (pure JQL/reporting, issue creation with no work starting) and for attendance/working-time or drive logs — those are out of scope.

## Code Comments

Keep code comments short and brief. Add them only when they explain important, non-obvious intent, constraints, or tradeoffs that are not clear from the code itself. Avoid comments that narrate edit history, migration paths, or earlier implementations.

## Long-running tasks

Some tasks are legitimately long-running (full browser/native builds and compiles, large downloads, big test suites, packaging). Do not kill, cancel, or abandon such a task while it is still making progress — let it run to completion. Never auto-terminate a long-running background task just because the turn appears idle or you are waiting on it; waiting is expected.

Run long tasks detached and logged, then perform occasional checking and give the user progress feedback (milestone reached, elapsed time, current step) rather than blocking silently. Only stop a long-running task on explicit user request, a genuine error, or a real hang (no progress for an extended period).

# Version Control / Git

My GitHub username is `daberni`.

## Never rewrite the default branch

Creating new commits on a repository's default branch (`main`/`master`) locally is allowed. What must never happen is rewriting its history or discarding commits — no force-push, rebase, reset, amend, or any operation that drops or rewrites existing commits on the default branch.

Remote modifications of the default branch are a hard rule with no exceptions: never `push`, fast-forward, or otherwise mutate the remote default branch, even when remote changes have otherwise been approved.

## Remote changes require explicit approval

Never mutate remotes without first describing the exact change and getting explicit approval. This includes pushes, force-pushes, remote branch/tag/ref changes, PR changes, repository settings, access changes, and non-GET API calls. Read-only inspection is fine without asking.

Never rewrite commits that have already been pushed unless the user explicitly asks. To revise pushed work, add a new commit on top. Local-only commits may be amended, rebased, or squashed when it produces cleaner history.

When working in git repositories, treat existing staged changes as read-only. They are semantically already reviewed and approved: do not modify, unstage, discard, overwrite, commit, or reset them. If staged changes are present, keep your work unstaged unless the user explicitly asks otherwise.

Local edits and commits are allowed when there are no existing staged changes, but do not publish them without approval. Do not perform destructive operations such as reset, clean, checkout/restore that discards work, or forceful history edits without acknowledgement.

When rebasing branches, always use `git rebase --update-refs` so dependent local branches are moved along with the rewritten commits. For fixup/reword workflows, prefer `git rebase --autosquash --update-refs` to apply autosquash directives automatically.

Only work in the local workspace unless the user approves remote publication.

## Ongoing fixes branches

For "ongoing fixes" versions and `release/ongoing-fixes` branches, base new work on the latest common ancestor of the main branch and the target branch, not on the target branch tip. Only base on the target branch tip when it already contains related changes that are needed to avoid conflicts; when doing so, state that reason explicitly.

## Cloning

Before cloning a git repository, check `~/Developer` for an existing local clone and reuse it — many repos are already cloned there (e.g. `~/Developer/<group>/<repo>`). Match by repo name or remote URL. Only clone fresh when none exists.

## Worktrees

When creating a git worktree, create it outside the project directory to avoid dirtying git status. Use `~/.agents/worktrees/<projectname>/<branchname>` as the target path, where `<projectname>` is derived from the repository root directory name.

## Conflict Resolution

Never resolve rebase/cherry-pick conflicts by wholesale taking one side (`git checkout --ours`, `git checkout --theirs`, or equivalent) across entire files without explicit user approval.

Always perform hunk-level semantic conflict resolution:
- inspect each conflict and keep intended behavior from both sides where applicable,
- explicitly account for upstream fixes/refactors/API changes,
- summarize resolved conflicts and rationale after completion.

If a quick one-sided resolution is proposed as a fallback, ask for explicit confirmation first.

## Editor

When continuing a rebase, cherry-pick, revert, or commit from a non-interactive shell, always prevent Git from opening an editor. Use a command-local editor override such as `GIT_EDITOR=true git rebase --continue` or `GIT_EDITOR=true git cherry-pick --continue` so the existing commit message is accepted without launching Vim.

# Tooling and Integrations

## Structured files

When reading structured files, use the locally available CLI parser: `jq` for `*.json` files and `yq` for `*.yaml`/`*.yml` files.

## Jira (Atlassian MCP)

Two Atlassian MCP servers are configured — always pick the correct one based on context:

| MCP server | Site | Workspace | Cloud ID | My accountId |
| --- | --- | --- | --- | --- |
| `atlassian-troiisoftware` | `troiisoftware.atlassian.net` | troii Software (Jira, Confluence) | `f7dc18ff-5265-4cf8-9227-22d31ce5213c` | `557058:83d0ea58-c77e-44b4-b4fb-cb17d512929c` |
| `atlassian-bawag` | `bawaggroup.atlassian.net` | BAWAG (Jira, Confluence) | `e05cc597-edfc-498c-b673-022b5b754ad2` | `557058:83d0ea58-c77e-44b4-b4fb-cb17d512929c` |

If the workspace is not clear from context, ask the user before proceeding.

Atlassian account IDs are workspace-scoped (same person, different ID per cloud) and stable. Use the cached `My accountId` directly whenever a Jira tool call needs an `accountId` (assignee, mentions, reporter, etc.) instead of re-running `lookupJiraAccountId`. If the cell is empty, look up once via `lookupJiraAccountId` against that cloudId with `searchString: "bernhard.danecker@troii.com"`, then update this file. If a cached ID ever returns "user not found", overwrite it.

Temporary restriction (as of 2026-04-27):
- In `atlassian-troiisoftware`, do not use `search` (Rovo). It is currently broken (403 "The app is not installed on this instance").
- For troii Jira lookups, use direct Jira read endpoints such as `getJiraIssue` and `searchJiraIssuesUsingJql` instead.

Do not add arbitrary comments when creating new issues, when not explicitly prompted.

## timr Environments

Login credentials for timr environments (development/staging `*.troii.dev`, production `troii.timr.com`, and related accounts) are documented in `~/Developer/timr-environment-credentials.md`. Source of truth remains 1Password (troii.1password.com).

## Chrome Devtools MCP

Only use Chrome Devtools MCP for testing and debugging our own projects.
Never use it for production sites, arbitrary website data access, or any production access use case.

Exception: `troii.timr.com` is allowed — it is our own test account in the timr production environment, used for our own testing and debugging.

## Skills

Agent skills under `~/.claude/skills` and `~/.agents/skills` are potentially installed via `npx skills` and actually are sourced from `~/Developer/agent-skills/skills`. When fixing or editing a skill, edit it there — never the symlinked/installed copy.

Always read a skill's full instructions (and any referenced files) before acting on it. Do not follow a skill from a truncated read — a partial read is how rules get missed.

`~/Developer/agent-skills` is a git repo (with a remote) holding our team's shared Claude Code / Codex skills — e.g. `jira`, `bitbucket`, `sonar-lookup`. Edits there propagate to the team. When you codify a reusable convention or improve a skill, make the change under `~/Developer/agent-skills/skills/<name>/` and commit it, rather than as a one-off.
