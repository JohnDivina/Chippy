# Contributing to Chippy

Thank you for your interest in contributing to Chippy! Chippy is an open-source 2.5D ambient AI colony diorama and companion HUD for macOS built in pure Swift, SpriteKit, and SwiftUI.

## Development Workflow

1. Clone the repository:
   ```bash
   git clone https://github.com/JohnDivina/Chippy.git
   cd Chippy
   ```
2. Build and run unit tests:
   ```bash
   swift test
   ```
3. Run in release mode:
   ```bash
   swift run -c release
   ```

## Design & UI Directives

All contributions must strictly respect the workspace design directives:
- Solid opaque surfaces in neutral grays (`#121212`, `#181818`).
- Crisp borders and monochrome high-contrast typography.
- No fluorescent or neon colors (no `Color.green`, bright electric green, or pulsating neon beacons).
- Discrete state dots and gentle physical animations (such as chimney smoke and character bobs).

## Pull Requests

1. Fork the repository and create a branch.
2. Ensure all 22+ unit tests pass.
3. Open a descriptive Pull Request.
