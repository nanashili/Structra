# Structra (The Intelligent Documentation Editor for macOS)

<p>
  <img src="https://img.shields.io/badge/build-passing-brightgreen" />
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey" />
  <img src="https://img.shields.io/badge/swift-5.0-orange" />
  <img src="https://img.shields.io/badge/license-MIT-blue" />
</p>

**Structra** is a native macOS application that automates the creation and maintenance of software documentation. Using modern AI models, it analyzes your codebase and generates consistent, high-quality documentation—so you can focus on building.

## 🧩 The Problem

Documentation is crucial but often ignored. It’s tedious to write and even harder to keep in sync. Outdated docs can mislead developers and introduce bugs.

## 🧠 The Solution

Structra is your intelligent documentation partner. It understands your code, detects outdated comments, and provides a beautiful, focused workspace for managing your documentation pipeline.

## ✨ Features

* **🤖 AI-Powered Generation**
  Connect with OpenAI, Claude, Gemini, or self-hosted models to generate documentation for functions, classes, APIs, and modules.

* **🔍 Doc Drift Detection**
  Structra’s standout feature. It continuously scans your codebase and flags outdated or inconsistent documentation.

* **🎛️ Custom Prompt Templates**
  Tailor the AI’s tone, format, and style with reusable prompt templates.

* **🧭 Native macOS UX**
  Built with Swift + AppKit/SwiftUI for a lightweight, native, offline-capable experience.

* **🗂️ Project Workspace**
  Work in a familiar Xcode-like interface with a navigator, editor, and inspector.

* **🔐 Secure & Flexible Connectivity**
  Use Structra Cloud, third-party APIs, or your own models—with full control over data handling.

## 🛠️ Tech Stack

### macOS Client

* **Language**: Swift 5
* **UI**: AppKit + SwiftUI hybrid
* **Dependencies**: Swift Package Manager
* **Architecture**: Modular & protocol-oriented

## 🚧 Project Status

Structra is in **active development** (Pre-Alpha). Core components are under construction and evolving rapidly. Current focus: editor stabilization & AI integration.

## 🗺️ Roadmap

### Phase 1 (In Progress)

* [x] Core UI and project manager
* [x] First-time setup walkthrough
* [ ] Stable AI provider integrations
* [ ] Core Doc Drift engine

### Phase 2

* [ ] Team collaboration features
* [ ] Git-aware documentation
* [ ] Export to HTML, PDF, Markdown

### Phase 3

* [ ] Structra Cloud sync
* [ ] Public API for integrations

## 🚀 Getting Started

### Prerequisites

* macOS 14.0+
* Xcode 16.0+
* Swift 5.0

### Build & Run

```bash
git clone https://github.com/[YourUsername]/structra.git
cd structra
xed .
```

1. Open in Xcode
2. Select the `structra` scheme
3. Press `Cmd+R` to build & run
4. Follow the setup walkthrough on first launch

## 🤝 Contributing

Contributions are welcome! Bug reports, ideas, pull requests—bring them on.

1. Fork the repo
2. Create a branch: `git checkout -b feature/AmazingFeature`
3. Commit: `git commit -m 'Add AmazingFeature'`
4. Push: `git push origin feature/AmazingFeature`
5. Submit a Pull Request

## 📄 License

Structra is licensed under the **GNU General Public License v3.0**.  
See the [`LICENSE`](./LICENSE) file for full details.
