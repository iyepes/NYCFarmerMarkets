# Merged code review: feature/1-internal-map-and-directions-button

Verdict: APPROVED

Both reviewers (agent, semantic) found no blocking issues. All 9 tasks in `.kiro/specs/internal-map-and-directions-button/tasks.md` are checked `- [x]`; no unchecked tasks.

## Agreement (high confidence)
- Open in Maps pushes the in-app single-market map inside the sheet's NavigationStack; exactly one pin (Req 1.x).
- Directions runs the unchanged old external Apple Maps action, renamed `openInExternalMaps` (Req 2.x).
- Conventions respected (AppIcon, nonisolated logic, tests, no .agents committed). The `MarketPin` and toolbar refactors preserve behavior.
- Tests: iOS full run succeeded, macOS build succeeded.

## Non-blocking notes (semantic reviewer only)
1. Directions has no automated or manual check (it leaves the app). The action body is unchanged. Mention it in the PR.
2. macOS UI behavior (Back button, Close placement on the pushed view) is unverified. Only a build was run.
3. Spec wording says the pushed screen has no favorites toggle, but the shared toolbar shows it. This is intentional. Note it in the PR.
