# SnapPath — Claude Code Context

SnapPath is a macOS menu bar screenshot utility (no dock icon). It captures full screen,
windows, or selections via `/usr/sbin/screencapture`, saves PNGs to a configurable directory,
and copies the saved file path to the clipboard for direct use in Claude Code.

## Build & Run

```bash
make build      # swift build (debug)
make release    # swift build -c release
make app        # release build → .build/SnapPath.app bundle
make run        # debug build + launch binary
make open       # build app bundle + open with macOS
make install    # copy app → /Applications
make uninstall  # remove from /Applications
make test       # swift test
make clean      # remove all build artifacts
```

## Project Structure

```
Sources/SnapPath/main.swift                    Entry point
Sources/SnapPathCore/AppDelegate.swift         NSApplicationDelegate
Sources/SnapPathCore/StatusBarController.swift Menu bar icon + menu
Sources/SnapPathCore/ScreenCaptureService.swift Wraps /usr/sbin/screencapture
Sources/SnapPathCore/ClipboardService.swift    NSPasteboard wrapper
Sources/SnapPathCore/PreferencesManager.swift  NSUserDefaults + NSOpenPanel
Tests/SnapPathTests/SnapPathTests.swift        XCTest suite
```

## Key Facts

- macOS 13+ target, Swift 5.9, Swift Package Manager
- `LSUIElement = true` — accessory app, no Dock icon
- No sandbox, no ScreenCaptureKit — uses `screencapture` CLI
- `StatusBarController` must inherit `NSObject` (required for `@objc` selectors)
- All AppKit work must run on the main thread — use `DispatchQueue.main.async`
- `ScreenCaptureService.capture()` is synchronous/blocking — always call from background thread
- `NSOpenPanel` in accessory apps needs `NSApp.activate(ignoringOtherApps: true)` first

---

## Git Workflow (Mandatory)

Before pushing ANY code to GitHub, you MUST pass all local checks. There is NO automated
CI/CD pipeline — all checks run locally. Code that fails checks should NEVER leave this machine.

1. Every task starts with a GitHub issue. Create one using `gh issue create` if one doesn't exist.
2. Always start from latest main: `git checkout main && git pull origin main`
3. Create a branch with the format: `prefix/issue-number-short-description`
   - `feature/` for new features
   - `fix/` for bug fixes
   - `hotfix/` for emergency production fixes
   - `refactor/` for code restructuring
   - `chore/` for dependency updates and maintenance
4. Implement the change.
5. Run `make lint` — fix ALL errors before committing.
6. Run `make check` (lint + build + fast tests) — fix all failures. Do NOT push until this passes.
7. Commit with a message referencing the issue: `"feat: short description (closes #XX)"`
8. Run `make check-full` (adds integration tests) — fix all failures.
9. **Run code review agents** on all changed code (see "Code Review" section below). Fix ALL RED findings. Do not proceed until review is clean.
10. Push the branch.
11. Open a PR with `gh pr create`, linking the issue in the body.
12. Stop. Do not merge PRs. Do not start new work until told to.
13. Never have more than 2 open PRs at once.
14. Never push directly to main.

## Code Review (Mandatory Before Every PR)

Run the appropriate agents on ALL changed files before pushing. Use
`git diff main...HEAD --name-only` to get the exact list of changed files.

| Changed code | Required agents |
|---|---|
| Any Swift file | `code-review-specialist` **+** `ios-swiftui-expert` |
| Performance-sensitive (capture, hot paths) | `code-review-specialist` **+** `ios-swiftui-expert` **+** `performance-optimizer` |
| Security-sensitive (auth, file access) | `code-review-specialist` **+** `security-vulnerability-scanner` |
| New services, shared packages, structural changes | `code-review-specialist` **+** `architecture-review-specialist` |
| Test changes | `code-review-specialist` **+** `qa-test-analyst` |
| UI/UX decisions (layouts, color, design) | `ui-ux-design-specialist` **+** `brand-style-expert` |
| CI/CD, Makefile, shell scripts | `code-review-specialist` |

**What to do with findings:**

- **RED** (bugs, security issues, correctness errors) — fix before pushing, no exceptions
- **YELLOW** (warnings, style, minor issues) — fix or explicitly acknowledge in the PR description
- **GREEN** (suggestions) — optional, use judgment

## Commit Message Prefixes

- `feat:` new feature
- `fix:` bug fix
- `test:` adding or fixing tests
- `refactor:` code restructuring
- `chore:` dependency updates, config changes
- `docs:` documentation only

## CI/CD

**No automated CI/CD pipeline is configured.** All checks (lint, build, test) run locally
via `make check` / `make check-full` before pushing. GitHub Actions are not integrated yet.
**SOC2**: PR description must reference a GitHub Issue.

---

# Multi-Agent Decision Workflow

This workflow governs **every** decision across all Intenteon projects —
architectural, business, UI/UX, content, functional, infrastructure, copy,
pricing, or any other choice. No exceptions. No need to paste this — it
activates automatically whenever a decision needs to be made.

## Configuration

```
MIN_AGENTS = 3   # Minimum agents per decision — change this single value to scale
MAX_AGENTS = 6   # Cap to keep output readable
```

## Decision Format

Present decisions **ONE AT A TIME** in this exact format. No variations allowed.
Copy this template literally — the layout, spacing, and ★ placement must match exactly.

```
#[github-issue-number]: [Decision Title]

[Context: 2-3 short sentences. State the problem only. No solution hints.]

**Specialist agents:** [agent1] + [agent2] + [agent3]

**Option A — [Short title]**
- [1-line description bullet]
- [1-line description bullet]
- [agent1]: "[Direct 2-3 sentence opinion on this option]"
- [agent2]: "[Direct 2-3 sentence opinion on this option]"
- ★ [agent3]: "[Direct 2-3 sentence opinion on this option]"

**Option B — [Short title]**
- [1-line description bullet]
- [1-line description bullet]
- ★ [agent1]: "[Direct 2-3 sentence opinion on this option]"
- ★ [agent2]: "[Direct 2-3 sentence opinion on this option]"
- [agent3]: "[Direct 2-3 sentence opinion on this option]"

**Option C — [Short title]**
- [1-line description bullet]
- [1-line description bullet]
- [agent1]: "[Direct 2-3 sentence opinion on this option]"
- [agent2]: "[Direct 2-3 sentence opinion on this option]"
- [agent3]: "[Direct 2-3 sentence opinion on this option]"

**Claude's view:** [Letter]. [2-3 sentence recommendation and why.]

Which do you choose — A, B, or C?
```

## Format Rules (violations are bugs — fix before showing the user)

1. **Applies to ALL decisions** — architecture, business, UI/UX, content,
   functional, infrastructure, copy, pricing. Every time.
2. **Every agent appears under every option** — never skip an agent under any option.
3. **Each agent gets exactly one ★ total** — on their single preferred option.
4. **★ placement**: `- ★ agent-name:` — the star comes before the agent name,
   never after, never on a separate line, never on the option header.
5. **Description bullets are short** — one line each, 2–4 bullets per option.
   Never combine into one long paragraph bullet.
6. **Agent opinions are 2–3 sentences** — direct, opinionated, no hedging.
7. **No blank lines within an option block** — bullets and agent lines are
   contiguous with no gaps between them.
8. **One blank line between option blocks.**
9. **One question at a time** — wait for the answer before showing the next.
10. **After the user answers**: confirm the choice in one sentence, then
    immediately show the next question (if any).

## Rules

- Assign at least `MIN_AGENTS` agents per decision. Assign MORE when the topic
  spans multiple categories (e.g., a feature with both macOS API and UI implications
  gets agents from both pools). Never exceed `MAX_AGENTS`.
- Each issue must follow our git workflow (branch → PR → check → auto-merge).
- Launch specialist agents in parallel to get real opinions.
- As the user answers questions, implement decided issues in the background
  using worktree-isolated agents and auto-merge PRs.

---

## Default Agent Pools by Category

When no playbook matches, draw `MIN_AGENTS` or more from these pools:

| Category              | Agents                                                          |
| --------------------- | --------------------------------------------------------------- |
| Business/marketing    | `business-strategist-ceo`, `strategic-marketing-architect`      |
| Infrastructure        | `scalable-systems-architect`, `architecture-review-specialist`  |
| Go code               | `elite-code-craftsman`, `go-systems-expert`                     |
| Frontend coding       | `frontend-expert`, `elite-code-craftsman`                       |
| iOS/macOS development | `elite-code-craftsman`, `ios-swiftui-expert`                    |
| Android development   | `elite-code-craftsman`, `android-jetpack-expert`                |
| UI/UX                 | `ui-ux-design-specialist`, `brand-style-expert`                 |
| Security/compliance   | `security-vulnerability-scanner`, `dependency-security-auditor` |
| Cross-cutting / other | `product-requirements-guardian`                                 |

## Agent Selection Rules

1. Start with the primary pool for the topic's category.
2. If that pool has fewer than `MIN_AGENTS` agents, pull from adjacent
   or cross-cutting pools based on relevance.
3. If a topic spans multiple categories, MERGE those pools and pick the
   top `MIN_AGENTS` (or more) most relevant agents.
4. `product-requirements-guardian` may be added to ANY topic as an
   additional agent when requirements clarity is at stake.
5. Never exceed `MAX_AGENTS` — if more are relevant, pick the most
   critical and note which agents were excluded.

---

## Playbooks

Playbooks are predefined agent pool configurations for common work patterns.
When a task matches a playbook, use it as the starting agent pool instead of
the generic category pools. `MIN_AGENTS` still applies.

---

### Playbook: `mobile-ios`

**Trigger:** Any native iOS / macOS / SwiftUI development work.

**Primary pool:**

- `ios-swiftui-expert` — SwiftUI, UIKit/AppKit interop, platform APIs
- `elite-code-craftsman` — architecture, patterns, code quality
- `ui-ux-design-specialist` — mobile/desktop UX, HIG compliance, interaction design

**Escalation agents:**

- `brand-style-expert` — brand consistency across platforms
- `performance-optimizer` — app launch time, memory, battery
- `security-vulnerability-scanner` — keychain, file access, data at rest
- `api-contract-validator` — client-server contract alignment

**Minimum for this playbook:** 3

---

### Playbook: `infra-deploy`

**Trigger:** Any CI/CD, deployment pipeline, infrastructure, or DevOps work.

**Primary pool:**

- `scalable-systems-architect` — infrastructure design, redundancy, failover
- `devops-cicd-automation` — pipelines, GitHub Actions, automation
- `architecture-review-specialist` — infrastructure review, blast radius

**Escalation agents:**

- `security-vulnerability-scanner` — secrets management, network policies
- `deployment-readiness-checker` — pre-deploy validation
- `performance-optimizer` — resource sizing, scaling policies
- `infrastructure-docs-updater` — runbook and documentation updates

**Minimum for this playbook:** 3

---

### Playbook: `branding-design`

**Trigger:** Brand identity, logo work, style guide updates, visual design
systems, or design-only tasks not tied to a specific page build.

**Primary pool:**

- `brand-style-expert` — brand identity, voice, visual standards
- `graphic-designer` — logo, typography, color, visual assets
- `ui-ux-design-specialist` — design systems, component libraries
- `strategic-marketing-architect` — brand positioning, audience alignment

**Escalation agents:**

- `business-strategist-ceo` — strategic brand direction
- `frontend-expert` — design-to-code feasibility

**Minimum for this playbook:** 3
