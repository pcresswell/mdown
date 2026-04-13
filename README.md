# MDown

A fast, native macOS Markdown reader built with SwiftUI and cmark-gfm.

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **Native rendering** — Uses cmark-gfm via NSTextView for accurate GitHub Flavored Markdown
- **Themes** — Multiple built-in themes with a theme picker
- **Search** — Standard macOS find (Cmd+F, Cmd+G, Cmd+Shift+G)
- **Drag and drop** — Drop `.md` files directly into the window
- **Font control** — Adjust font size with Cmd+/Cmd-/Cmd+0
- **Full width toggle** — Switch between half and full width layout (Cmd+\\)
- **Fast** — Optimized chunked layout for large documents

## Install

### Homebrew

```bash
brew tap pcresswell/tap
brew install mdown
```

### Build from source

Requires Swift 5.9+ and macOS 13+.

```bash
git clone https://github.com/pcresswell/mdown.git
cd mdown
make install
```

This builds a release binary, assembles an `.app` bundle, and copies it to `/Applications`.

## Usage

Open MDown and drag a Markdown file into the window, or use **File > Open** (Cmd+O).

You can also open files from the command line:

```bash
open -a MDown file.md
```

## License

[MIT](LICENSE)
