# Project Instructions for AI Agents

This file provides instructions and context for AI coding agents working on this project.

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:6cd5cc61 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.

## Agent Context Profiles

The managed Beads block is task-tracking guidance, not permission to override repository, user, or orchestrator instructions.

- **Conservative (default)**: Use `bd` for task tracking. Do not run git commits, git pushes, or Dolt remote sync unless explicitly asked. At handoff, report changed files, validation, and suggested next commands.
- **Minimal**: Keep tool instruction files as pointers to `bd prime`; use the same conservative git policy unless active instructions say otherwise.
- **Team-maintainer**: Only when the repository explicitly opts in, agents may close beads, run quality gates, commit, and push as part of session close. A current "do not commit" or "do not push" instruction still wins.

## Session Completion

This protocol applies when ending a Beads implementation workflow. It is subordinate to explicit user, repository, and orchestrator instructions.

1. **File issues for remaining work** - Create beads for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **Handle git/sync by active profile**:
   ```bash
   # Conservative/minimal/default: report status and proposed commands; wait for approval.
   git status

   # Team-maintainer opt-in only, unless current instructions forbid it:
   git pull --rebase
   git push
   git status
   ```
5. **Hand off** - Summarize changes, validation, issue status, and any blocked sync/commit/push step

**Critical rules:**
- Explicit user or orchestrator instructions override this Beads block.
- Do not commit or push without clear authority from the active profile or the current user request.
- If a required sync or push is blocked, stop and report the exact command and error.
<!-- END BEADS INTEGRATION -->


## Build & Test

```bash
swift build      # debug build
make install     # release build -> /Applications/MDown.app (kills + relaunches the app)
```

There is no automated test suite; verify UI changes in the real app (build, install, drive the menus).

## Releasing — the full checklist

`make install` is NOT a release. Users install via Homebrew (`brew tap pcresswell/tap && brew install mdown`), so a release is not done until the tap serves it. Every release:

1. In `Resources/Info.plist`, bump `CFBundleShortVersionString` and set `CFBundleVersion` to the commit count of the release commit itself (`git rev-list --count HEAD` + 1, since the release commit adds one). The number must live in the plist because the brew tarball has no `.git` to count; `bundle.sh` stamps it automatically for local dev builds.
2. Commit ("<summary>; bump to X.Y") and push to `origin main`.
3. Tag: `git tag -a vX.Y <sha> && git push origin vX.Y`.
4. GitHub release: `gh release create vX.Y --title "MDown vX.Y" --notes "<what changed>"`.
5. Update the tap: in `~/repos/homebrew-tap/Formula/mdown.rb`, set `url` to the vX.Y tarball and recompute `sha256` (`curl -sL <tarball-url> | shasum -a 256`). **Pull the tap first** — the local clone is often behind. Commit ("mdown X.Y") and push.
6. Install locally the brew way: `brew update && brew upgrade mdown`, then `pkill -x MDown; rm -rf /Applications/MDown.app; ln -sf "$(brew --prefix mdown)/MDown.app" /Applications/MDown.app`.
7. Verify by reading stamps, not exit codes: `brew list --versions mdown` and `CFBundleShortVersionString` from the resolved `/Applications/MDown.app/Contents/Info.plist` must both show X.Y, and `CFBundleVersion` there must equal `git rev-list --count vX.Y`.

Skipping steps 3-5 leaves brew users on the old version while /Applications looks current — this happened for v1.11; don't repeat it.

## Architecture Overview

SwiftUI + Swift Package Manager macOS Markdown reader (no Xcode project; bundled by `bundle.sh`). Entry point `Sources/MDown/MDownApp.swift` (menus live in its `.commands` block); per-window state in `AppState.swift`; file open/recents flow through `AppState.loadFile` + `NSDocumentController`; rendering in `Sources/MDown/Rendering/` (cmark-gfm + Mermaid).
