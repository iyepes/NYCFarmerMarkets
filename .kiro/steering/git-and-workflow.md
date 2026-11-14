---
inclusion: always
---

# Git, safety and workflow rules

## Owner preferences

- Always answer in English.
- Commit only when the owner asks or approves. Push only with approval. The owner reviews and merges PRs on GitHub.
- Every `rm` command must show its full literal destination path. No variables, no wildcards, no `rm -rf "$DIR"`. State the exact path before running it.
- Ask before anything hard to reverse (reset, branch deletion, force push, bulk deletes). Prefer `git reset --keep` over `--hard`. Never force-push.

## Branches and commits

- Never work on `main`. Before editing, branch from the latest `origin/main`: `git fetch origin && git switch -c <type>/<topic> origin/main`. Feature branches from the workflow are `feature/<issue-number>-<slug>`; others use `fix/`, `chore/`, `docs/`.
- Run `git branch --show-current` right before every commit; the owner may have switched branches.
- Before pushing, run `git pull --rebase` if `main` may have moved (PRs are merged on GitHub, so local `main` is often behind).
- Stage files by name; never `git add .` or `-A`. Commit messages follow Conventional Commits (`feat:`, `fix:`, `docs(specs):`, `chore(workflow):`).
- PR titles under 70 characters; the body has Summary, Tested, and what was not verified or deviates.

## Commit hook

`.kiro/hooks/security-review-before-commit.json` intercepts every shell command. For anything that is not a `git commit`, say so and re-run the same command unchanged. For a commit: list staged Swift files (`git diff --cached --name-only -- '*.swift'`), review their diff for security issues, report findings, and commit only if nothing is high severity.

## Specs, workflow and agent files

- Specs live in `.kiro/specs/<feature-name>/` as `requirements.md`, `design.md` and `tasks.md`. When the code changes outside a spec (manual commits), amend the spec with a dated "Amendment" section instead of rewriting history.
- Features usually run through the workflow recipe `.kiro/workflows/feature-to-pr.workflow.json` (issue → branch → requirements → design loop → plan → spec → code loop → test loop → archive → push → PR → PR loop). It pauses for the owner's approval of the issue draft and the push.
- `.agents/tasks/feature-to-pr/` holds the working files of the current workflow run; never stage or commit them. The archive step copies each run into `.agents/runs/<issue>-<slug>/` and commits only that folder. The owner commits other `.agents/` changes themselves.
- Manual design changes are recorded in `Design/design-changes.md`.

## Tooling pitfalls

- Do not run dependent tool calls in parallel (a read or build can run before the edit it depends on).
- zsh aborts a command when a glob matches nothing (`no matches found`); quote globs or check first.
- Remove temporary files you create (state their literal paths).
