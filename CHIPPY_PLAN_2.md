# 🏝️ Chippy — Implementation Plan 2 (Hardening, Fidelity & Companion Features)

> **Follows:** [CHIPPY_PLAN.md](CHIPPY_PLAN.md) (Revision 3) — architecture, event model, and Director decision still apply.
> **Input:** Phase 2 code review of the built app (15 commits, ~6k lines).
> **Goal:** turn the working prototype into a stable, safe, open-source-ready companion app, then add the features that make people use it daily and share it.

---

## 📌 0. Summary

| Area | State today | Target after Plan 2 |
| :--- | :--- | :--- |
| Live mode | Locks to one transcript, can drop lines, renders while hidden | Follows new sessions, lossless tailing, pauses when idle/hidden |
| Scene | Animations overlap, wrong districts, mirrored bubbles | Queued, truthful choreography using the classifier |
| Safety | AppleScript sends keystrokes to *any* Electron app | Targets Antigravity only, restores clipboard, then replaced by `agy` |
| Portability | Hardcoded `/Users/johnrey/...` paths | Settings → Skill Sources, portable recordings |
| Compliance | Green dots, glow halos, pulsing beacons | Fully `AGENTS.md` compliant |
| Value | Visualizer | Companion: notifications, menu bar, session picker, chronicle, teaching mode |

### Defaults assumed (change if you disagree)
1. Order: **Sprint A (stability) → B (safety/open-source) → C (fidelity) → D (companion) → E (teach & share) → F (Director)**.
2. AppleScript bridge: **harden now (Sprint B)**, **replace with `agy` backend (Sprint F)**.
3. First features: **"Needs you" notifications, menu-bar mini mode, Session Chronicle**.

---

## 🔴 1. Issue Register

### 1.1 Bugs

| ID | Issue | Location | Sprint |
| :--- | :--- | :--- | :--- |
| B1 | `SKView: no drawables available` log spam; renders at 60 fps while hidden/occluded | `App/ContentView.swift` L33-37 | A |
| B2 | Speech bubbles mirrored when facing left (bubble is child of flipped `bodyContainer`) | `Scene/CreatureNode.swift` L68, L185 | A |
| B3 | Partial JSONL lines dropped during live tailing | `ChippyCore/Telemetry/TelemetryWatcher.swift` L137-152 | A |
| B4 | Live mode never follows new conversations | `App/ContentView.swift` L112-131 | A |
| B5 | AppleScript bridge targets any `Electron` process; clobbers clipboard | `App/AntigravityBridge.swift` L17-29 | B |
| B6 | Backend file edits route to `ironBastion` instead of `engineCore` | `Scene/SceneDirector.swift` L52 | C |
| B7 | Skill loads always go to Scriptorium, ignoring `DistrictClassifier` | `Scene/SceneDirector.swift` L35 | C |
| B8 | Overlapping walks; delayed global `setAllWorkshopsWorking(false)` cancels newer work | `Scene/SceneDirector.swift` L95-105 | A |
| B9 | Replay can lose first event; each Play leaks a listener task | `ContentView.swift` L211-213, `ReplayEngine.swift` L54-58 | C |
| B10 | Step backward re-animates forwards instead of undoing | `ReplayEngine.swift` L128-134 | C |
| B11 | CI uses Xcode 15.4 (Swift 5.10) but package requires tools 6.0 | `.github/workflows/build.yml` L18 | A |
| B12 | Response modal auto-pops on every agent message in live mode | `HUD/ChippyHUDView.swift` L132-138 | A |
| B13 | Unbounded `eventLog` memory and full re-render | `App/ContentView.swift` L18 | A |
| B14 | Test resource bundle shipped inside `Chippy.app` | `scripts/package_app.sh` | B |

### 1.2 `AGENTS.md` violations

| ID | Issue | Location | Sprint |
| :--- | :--- | :--- | :--- |
| R1 | `Color.green` status dots (neon) | `ChippyHUDView.swift` L172, L263; `PromptChatboxView.swift` L32; `ModelSelectorView.swift` L45 | B |
| R2 | Glow halos and `repeatForever` pulsing dots on workshops | `Scene/WorkshopNode.swift` L141-176, L240 | B |
| R3 | Bright gold "working" bubble text | `Scene/CreatureNode.swift` L165 | B |

### 1.3 Gaps vs. CHIPPY_PLAN

| ID | Gap | Sprint |
| :--- | :--- | :--- |
| G1 | Hardcoded skill/workspace paths; no Settings | B |
| G2 | Recordings contain `/Users/johnrey/...`; only 3 synthetic 5-line sessions | B |
| G3 | Missing `LICENSE`; stray "What are we building today?" lines in README (L95, L101) | B |
| G4 | Single `agentID`; random `childID`; all subagents reuse one Sentinel | C |
| G5 | `commandFinished` never emitted (tool results not parsed) | C |
| G6 | No quota / rate-limit detection | C |
| G7 | No event pacing / coalescing | A |
| G8 | No idle pause | A |
| G9 | No accessibility (Reduce Motion, VoiceOver) | E |
| G10 | Model selector implies it changes Antigravity's model (it doesn't) | C |
| G11 | Window always floating on all Spaces | A |
| G12 | Marketing text says "authentic Stardew Valley textures" (art is procedural) | B |

---

## 🧱 2. Sprint A — Stability (live mode you can leave running)

**Exit criteria:** Chippy runs for 2+ hours against live Antigravity sessions with no log spam, no dropped events, < 2% CPU when idle, and automatically follows new conversations.

### A1. Pause rendering when hidden or idle (B1, G8)
- New `Scene/RenderGovernor.swift` (`@MainActor`):
  - Observes `NSWindow.didChangeOcclusionStateNotification`, `didMiniaturize`, `didDeminiaturize`.
  - Pauses `scene.isPaused` when `!window.occlusionState.contains(.visible)`.
  - Idle policy: no `AgentEvent` for 20 s → `preferredFramesPerSecond = 15`; 120 s → pause; any event → resume at 60.
- Access the `SKView` via an `NSViewRepresentable` wrapper (replace `SpriteView`) so frame rate and pause are controllable.

### A2. Fix mirrored bubbles (B2)
```swift
// CreatureNode.walk(...)
spriteNode.xScale = movingLeft ? -1.0 : 1.0   // flip sprite only
// bubble stays on bodyContainer (unflipped) or move it to `self`
```

### A3. Lossless tailing (B3)
- `TelemetryWatcher` keeps `pendingBuffer: Data`.
- On read: append new bytes → split at the **last** `\n` → decode complete lines → keep remainder in buffer.
- Reset buffer on truncation/rotation.
- Extract to a testable `LineAssembler` struct in `ChippyCore/Telemetry/`.
- **Tests:** line written in 2 chunks; 3 lines in one chunk; truncation reset; 1 MB single line.

### A4. Follow new sessions (B4)
- New `ChippyCore/Telemetry/SessionMonitor.swift` (actor):
  - FSEvents stream on `~/.gemini/antigravity-ide/brain/` (configurable).
  - Publishes `AsyncStream<[SessionInfo]>` (id, title if available, lastModified, isActive = modified < 60 s).
  - **Auto-follow** mode switches the watcher to the newest active transcript.
- `ContentView` swaps the `TelemetryWatcher` file on change; posts `.sessionStarted`.

### A5. Event pacing & per-familiar queues (B8, G7)
- New `Scene/ChoreographyQueue.swift`:
  - One FIFO per `FamiliarKind`; next action starts only when the previous completes.
  - **Coalescing:** consecutive `fileRead`s within 1.5 s → one "Inspecting 4 files" action.
  - **Adaptive speed:** queue length > 5 → animation durations × 0.5; > 15 → skip walks, show bubble only.
- Workshops track `lastActivityAt`; a single 1 s timer sets each workshop idle after 4 s of no activity (replaces global `asyncAfter` resets).

### A6. HUD calm-down (B12, B13, G11)
- Response modal auto-opens **only** for prompts sent from Chippy; otherwise "Dispatch" button shows an unread dot.
- `eventLog` → ring buffer (max 500) in a new `@Observable AppState`; `ActivityLogView` uses `LazyVStack`.
- Window "Pin on top" toggle (default **off**) in the top bar and View menu; remove `.canJoinAllSpaces` by default.

### A7. CI (B11)
```yaml
runs-on: macos-15
- run: sudo xcode-select -s /Applications/Xcode_16.4.app || sudo xcode-select -s /Applications/Xcode.app
```

### A8. State refactor (enables everything after)
- Move the many `@State` vars in `ContentView` into `App/AppState.swift` (`@Observable @MainActor`): mode, session, model, events, skills, replay state, settings.
- `ContentView` becomes layout only.

---

## 🛡️ 3. Sprint B — Safety, Compliance & Open-Source Readiness

**Exit criteria:** `security_audit.py` passes, no personal paths in repo, all `AGENTS.md` UI rules satisfied, app runs on a fresh Mac with no `production-agents` folder.

### B1. Harden the AppleScript bridge (B5)
- Resolve Antigravity via `NSWorkspace.shared.runningApplications` by **bundle identifier** (verify actual ID with `osascript -e 'id of app "Antigravity"'`); abort with a HUD message if not running.
- Save and **restore** the previous clipboard contents after paste.
- Confirmation on first use + "Don't ask again" setting.
- Explain the Accessibility permission requirement in onboarding; detect missing permission (`AXIsProcessTrusted()`).
- Rate-limit prompt sends (max 1 per 2 s) to prevent accidental floods.
- Mark as **experimental** in UI; scheduled for replacement in Sprint F.

### B2. Settings window (G1)
- `App/SettingsView.swift` (SwiftUI `Settings` scene):
  - **Skill Sources:** add/remove folders (security-scoped bookmarks), rescan.
  - **Transcript Sources:** brain directory path (default `~/.gemini/antigravity-ide/brain`).
  - **Behavior:** auto-follow sessions, pin on top, notifications, animation speed, Reduce Motion override.
- `SkillDiscovery` uses settings + common locations + bundled samples (no hardcoded paths).

### B3. UI compliance (R1–R3)
- Replace `Color.green` → `ChippyTheme.statusDot` everywhere; live state shown by solid dot + label text.
- Remove workshop glow circles and pulsing dots; replace "working" with **chimney smoke puffs, open door sprite, and the signboard task text** (motion, not glow).
- Working bubble text → muted parchment `#D9CBA8`.
- Add a `ThemeComplianceTests` grep-style test in CI that fails on `Color.green`, `.glow`, `repeatForever` on status dots.

### B4. Repo hygiene (B14, G2, G3, G12)
- `package_app.sh`: skip `*Tests.bundle`.
- Recordings/fixtures: replace `/Users/johnrey/...` with `~/projects/...`; add 3–5 **real** redacted sessions (≥ 50 steps each, including subagents, errors, commands).
- Add `LICENSE` (MIT), `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`; fix README stray lines.
- Wording: "cozy pixel art inspired by farming sims" (no "authentic Stardew Valley").

### B5. Security validation
- Run `python3 /Users/johnrey/Desktop/Programming/production-agents/.agents/skills/security-hardening/scripts/security_audit.py /Users/johnrey/Desktop/Programming/Chippy` and resolve findings.
- Extend `Redactor` tests: JWTs, AWS keys (`AKIA…`), Anthropic keys (`sk-ant-…`), Supabase service keys, `.env` multi-line blocks.

---

## 🎯 4. Sprint C — Fidelity (the scene tells the truth)

**Exit criteria:** For a recorded real session, every familiar movement corresponds to a real step, in the correct district, and replay scrubbing is accurate.

### C1. Correct routing (B6, B7)
- `SceneDirector` receives `[SkillWorkshop]`; `skillLoaded` → walk to the skill's **own district + workshop**, signboard shows the skill name.
- File edits routed by `PathRouter` in `ChippyCore`:
  - Frontend extensions (`.tsx .jsx .css .scss .html .vue .svelte`, `*View.swift`) → Weaver / Grand Atelier
  - Tests (`*Tests*`, `*.test.*`, `*.spec.*`) → Sentinel / Iron Bastion
  - Docs (`.md`) → Scribe / Scriptorium
  - Everything else → Mason / Engine Core
- Unit-test `PathRouter`.

### C2. Richer adapter (G4, G5, G6)
- Agent identity: lead = conversation ID; subagents = IDs parsed from `invoke_subagent` / `browser_subagent` results (fallback: deterministic hash of task name, so `subagentFinished` can match).
- Parse tool-result steps → `commandFinished(exitCode:)`, `subagentFinished`, `error`.
- Use `toolAction` / `toolSummary` args as human-readable bubble text for every tool.
- Detect quota / rate-limit errors (`429`, "quota", "rate limit", "resource exhausted") → `AgentEvent.error(..., reason: .quotaExceeded)`.
- Add `ErrorReason` enum to `AgentEvent.error`.
- Fixture tests for each new mapping.

### C3. Multiple subagent familiars (G4)
- `ParadiseScene` supports N familiars keyed by `agentID` (not `FamiliarKind`); subagents spawn at the Citadel with a small variant tint/hat, walk to their district, and leave on `subagentFinished`.
- Cap visible subagents at 6; overflow shown as "+N" at the Citadel.

### C4. Replay correctness (B9, B10)
- `ReplayEngine` exposes one long-lived `events: AsyncStream` created at init.
- New `ChippyCore/Scene/WorldState.swift` reducer: `(WorldState, AgentEvent) -> WorldState` (familiar locations, active workshops, harbor crates).
- Seeking/stepping back = rebuild `WorldState` from 0…N and snap the scene (no animation); forward play animates.
- Timeline scrubber slider in the HUD.
- **Tests:** reducer determinism; seek(N) equals play-to-N state.

### C5. Honest model indicator (G10)
- Rename to **"Observed model"**; read-only in Spectator mode, with a tooltip: "Change the model in Antigravity."
- Selector re-enabled only for Director mode (Sprint F).

### C6. Visual truth upgrades
- **Persistent Harbor:** each touched file becomes a crate for the session (created = new crate, modified = crate with hammer mark); hover shows path.
- **Error state:** familiar stops, dark "!" marker, Sovereign bubble with plain-language message.
- **Quota state:** "The Sovereign rests" — sits down, HUD explains limits are from the user's Antigravity account.

---

## 🔔 5. Sprint D — Companion Features (daily-use value)

**Exit criteria:** A user can keep Chippy in the menu bar all day and is notified when the agent needs them.

### D1. "Needs you" notifications
- `UserNotifications` on: `ask_question`, session finished (agent message after last tool + 30 s quiet), errors, quota.
- Sovereign rings the Citadel bell; Dock badge count.
- Per-type toggles in Settings; respect Focus modes.

### D2. Menu-bar mini mode
- `MenuBarExtra` with a compact live strip: Sovereign icon + current action text + session timer.
- Click → open/focus the island window; option to run menu-bar only (hide Dock icon).

### D3. Session picker
- Top-bar dropdown fed by `SessionMonitor`: recent sessions (title, project folder, last active, live dot).
- "Auto-follow newest" toggle; selecting a past session opens it in **Replay** mode.

### D4. Click-to-inspect
- Click a familiar → inspector card: role, current task, last 10 actions.
- Click a Harbor crate → path, edit count, "Reveal in Finder" / "Open in Editor" (`NSWorkspace.open`).
- Click a workshop → skill description from `SKILL.md` frontmatter.

---

## 📚 6. Sprint E — Teach & Share (mission + growth)

**Exit criteria:** A non-programmer can watch a session with captions on and explain what happened; users can export and share a session.

### E1. Teaching mode
- **Narrator captions** (toggle): plain-English subtitle per event, e.g. *"The Scout is reading `App.tsx` to understand the project."* Templates live in `ChippyCore/Narration/`.
- **Glossary tooltips:** skill, tool call, subagent, transcript, model.
- **First-run tour** using a bundled replay with step-by-step callouts.

### E2. Session Chronicle
- End-of-session card: duration, prompts, files created/modified, commands run (+ failures), skills used, subagents spawned, errors.
- Export as PNG; copy as Markdown.

### E3. Export replay as GIF / MP4
- Render the scene offscreen at fixed timestep (`SKView.texture(from:)` frames → `AVAssetWriter` for MP4; ImageIO for GIF).
- Options: speed, length cap, captions on/off, watermark "Made with Chippy".

### E4. Accessibility (G9)
- Respect `accessibilityReduceMotion`: no bobbing, walks become fades.
- VoiceOver labels on all HUD controls; the Activity Log doubles as an accessible text timeline.
- Keyboard shortcuts: Space play/pause, ←/→ step, R recenter, ⌘K session picker, ⌘, Settings.

### E5. Atmosphere (muted, rule-compliant)
- Day/night tint from local time; light rain when recent error rate is high; optional soft ambient audio (off by default).

---

## 🎬 7. Sprint F — Director Mode via `agy` (Plan 1, Phase 7)

- Complete the pre-commit verification in CHIPPY_PLAN §6 (non-interactive mode, transcript location, ToS).
- `AgentBackend` protocol, `AgyLocator`, `AgyRunner` (no shell strings, cancel, exit codes).
- Onboarding "Install `agy` & sign in".
- Quest Launcher (goal templates, folder picker, confirmation).
- `RunHandle.transcriptDirectory` → `TelemetryWatcher` (reuses Spectator pipeline).
- **Remove `AntigravityBridge` (AppleScript)** once `agy` works.

---

## 🗂️ 8. File Change Map

| File | Change | Sprint |
| :--- | :--- | :--- |
| `App/AppState.swift` | **New** — observable app state, ring-buffered events | A |
| `App/ContentView.swift` | Slim to layout; remove hardcoded paths; use `AppState` | A, B |
| `Scene/RenderGovernor.swift` | **New** — occlusion & idle pausing | A |
| `Scene/ParadiseSKView.swift` | **New** — `NSViewRepresentable` replacing `SpriteView` | A |
| `Scene/ChoreographyQueue.swift` | **New** — per-familiar queues, coalescing | A |
| `Scene/CreatureNode.swift` | Flip sprite only; muted working color; variants for subagents | A, B, C |
| `Scene/SceneDirector.swift` | Use queue, classifier, `PathRouter`; error/quota states | A, C |
| `Scene/WorkshopNode.swift` | Remove glow/pulse; smoke + door + signboard | B |
| `Scene/ParadiseScene.swift` | Familiars keyed by `agentID`; harbor crates; snap-to-state | C |
| `HUD/ChippyHUDView.swift` | Unread dot, pin toggle, session picker, scrubber, statusDot | A, C, D |
| `HUD/SettingsView.swift` | **New** | B |
| `HUD/InspectorView.swift` | **New** — familiar / crate / workshop cards | D |
| `HUD/ChronicleView.swift` | **New** | E |
| `App/AntigravityBridge.swift` | Harden (B), then delete (F) | B, F |
| `App/MenuBarView.swift` | **New** | D |
| `App/NotificationService.swift` | **New** | D |
| `ChippyCore/Telemetry/LineAssembler.swift` | **New** | A |
| `ChippyCore/Telemetry/TelemetryWatcher.swift` | Use `LineAssembler`; swap files | A |
| `ChippyCore/Telemetry/SessionMonitor.swift` | **New** | A |
| `ChippyCore/Telemetry/AntigravityAdapter.swift` | Agent IDs, tool results, quota, toolAction text | C |
| `ChippyCore/Models/AgentEvent.swift` | `ErrorReason`; agent identity | C |
| `ChippyCore/Routing/PathRouter.swift` | **New** | C |
| `ChippyCore/Scene/WorldState.swift` | **New** — reducer for replay/seek | C |
| `ChippyCore/Narration/Narrator.swift` | **New** — caption templates | E |
| `ChippyCore/Replay/ReplayEngine.swift` | Single stream; seek via reducer | C |
| `ChippyCore/Privacy/Redactor.swift` | More secret patterns | B |
| `scripts/package_app.sh` | Skip test bundles | B |
| `.github/workflows/build.yml` | macOS 15 / Xcode 16 | A |
| `Resources/Recordings/*` | Real, redacted, portable sessions | B |
| `LICENSE`, `CONTRIBUTING.md`, `README.md` | Add / fix | B |

---

## 🧪 9. Testing Plan

| Area | Tests |
| :--- | :--- |
| `LineAssembler` | chunked lines, multi-line chunks, truncation, very long lines |
| `SessionMonitor` | new session detection, active/inactive threshold (temp dirs) |
| `AntigravityAdapter` | subagent IDs, tool results → `commandFinished`, quota detection, toolAction text |
| `PathRouter` | extension/name routing table |
| `WorldState` | reducer determinism; seek(N) == play-to-N |
| `Redactor` | new secret patterns, no false positives on normal paths |
| `Narrator` | caption per event type |
| Theme compliance | CI grep fails on `Color.green`, glow nodes, pulsing status dots |
| Manual soak | 2 h live run: CPU, memory, no log spam, auto-follow works |

---

## ✅ 10. Definition of Done (each sprint)
- `swift build` + `swift test` pass locally and in CI (macOS 15).
- No Swift 6 concurrency warnings.
- `AGENTS.md` UI rules verified (no neon, glow, pulsing, pastel washes).
- `security_audit.py` run on the project with no new findings.
- README / CHIPPY_PLAN updated if behavior or architecture changed.

## ⚠️ 11. Open Questions
1. Confirm the default sprint order and bridge decision in §0.
2. Antigravity's actual **bundle identifier** (needed for B1).
3. Do Antigravity transcripts include a **conversation title** we can show in the session picker, or should we derive one from the first prompt?
4. GIF/MP4 export: include in v0.3, or defer?
5. Menu-bar-only mode: default on or off?
