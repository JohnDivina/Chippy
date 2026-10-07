# 🏝️ Chippy (AI Paradise)

> **A living, animated 2.5D isometric diorama for AI agent orchestration.**  
> Translating the invisible mechanics of models, subagents, and production skills into an interactive visual world.

[![Build & Test](https://github.com/JohnDivina/Chippy/actions/workflows/build.yml/badge.svg)](https://github.com/JohnDivina/Chippy/actions/workflows/build.yml)
[![Swift 6](https://img.shields.io/badge/Swift-6.0%2B-F05138?logo=swift&logoColor=white)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2014%2B-black?logo=apple&logoColor=white)](https://apple.com)
[![Privacy](https://img.shields.io/badge/Privacy-100%25%20Local-success)](README.md)

---

## 📖 What is Chippy?

Agentic AI tools are extraordinarily powerful, but to non-programmers or newcomers they often feel like an intimidating black box of rapid terminal text, tool calls, and complex JSON logs.

**Chippy** translates multi-agent development into an **interactive isometric diorama**:
- **👑 The Sovereign (Lead AI Model):** Oversees strategy and reasoning from the High Citadel. The model identity is auto-detected dynamically from session telemetry.
- **🐾 The Familiars (Agents & Subagents):** Animated worker creatures (Scouts, Masons, Weavers, Sentinels, Arbiters, Scribes) that move across stone paths, inspect files, and hammer at workshops.
- **🏛️ The Workshops (Skills):** Automatically ingests the **48 production skills** from your local agent environment and organizes them into themed island districts.
- **⚓ Project Harbor:** Visualizes created and modified project files as crates and scrolls arriving in real-time.

---

## 🎮 Modes

| Mode | Status | Description |
| :--- | :--- | :--- |
| **Replay Mode** | **Available (v0.1)** | Deterministic session playback with play/pause, 0.5×–8× speed multipliers, and scrubbing. |
| **Spectator Mode** | **v0.2** | Real-time live mirror of active local agent sessions via FSEvents transcript tailing. |
| **Director Mode** | **v1.0** | Visual quest builder launching the local `agy` CLI non-interactively in your target folder. |

---

## 🏛️ The 6 Island Districts

| District | Workshop Name | Skills Mapped | Resident Familiar |
| :--- | :--- | :--- | :--- |
| **🏛️ The High Council** (10) | War Table & Spire | `coordinator-mode`, `parallel-agents`, `plan-writing`, `brainstorming`, `architecture`… | **The Sovereign & The Scribe** |
| **🛡️ The Iron Bastion** (11) | Fortress Forge & Gate | `security-hardening`, `vulnerability-scanner`, `red-team-tactics`, `tdd-workflow`… | **The Sentinel & The Arbiter** |
| **🎨 The Grand Atelier** (11) | The Weaver's Loom | `frontend-design`, `nextjs-react-expert`, `tailwind-patterns`, `web-design-guidelines`… | **The Weaver** |
| **⚙️ The Engine Core** (12) | The Clockwork Foundry | `database-design`, `api-patterns`, `server-management`, `bash-linux`, `python-patterns`… | **The Mason** |
| **📜 The Scriptorium** (4) | The Archive | `documentation-templates`, `app-builder`, `mcp-builder`, `skillify` | **The Scribe** |
| **🧭 The Wanderer's Market** | Open Stalls | Any newly discovered, third-party, or unclassified skills | **The Scout** |

---

## 🔒 Privacy & Anti-Slop Guarantee

- **100% Local:** Zero network requests, zero telemetry uploads, and zero analytics.
- **In-Memory Redaction:** Built-in `Redactor` automatically masks API keys (`sk-…`, `AIza…`, `ghp_…`), authorization tokens, and `.env` passwords before events reach the screen.
- **Anti-Slop Visual Design:** Conforms to strict design directives: solid grey bubbles (`surfaceBubble`), crisp 1pt borders, high-contrast monochrome accents, and discrete state indicators without distracting fluorescent glows.

---

## 🚀 Getting Started

### Prerequisites
- macOS 14.0 (Sonoma) or macOS 15.0+ (Sequoia)
- Swift 6.0+ toolchain (Xcode 15.4+ or Xcode 16+)

### Build & Run from Terminal
```bash
git clone https://github.com/JohnDivina/Chippy.git
cd Chippy

# Build and run immediately
swift run
```

### Open in Xcode
```bash
open Package.swift
```

### Run Unit Tests
```bash
swift test
```

### Package `.dmg` for Distribution
```bash
./scripts/package_dmg.sh
# Output located at dist/Chippy.dmg
```

---

## 🏗️ Architecture

Chippy is split into two clean modules:
- **`ChippyCore`:** Pure Swift library (no UI frameworks). Contains domain models, `FrontmatterParser`, `SkillScanner`, `DistrictClassifier`, `AntigravityAdapter`, `Redactor`, `ReplayEngine`, and coordinate math. Fully unit-tested.
- **`Chippy`:** The native macOS application combining SpriteKit 2.5D graphics (`ParadiseScene`, `CreatureNode`, `IslandMapNode`, `SceneDirector`) with a reactive SwiftUI overlay HUD (`ChippyHUDView`, `ActivityLogView`).

---

## 📄 License

MIT License. Contributions and issues welcome!
