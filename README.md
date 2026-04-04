# dart_helper

**dart_helper** is a cross-platform Dart CLI tool designed to automate building Flutter and Serverpod projects, with support for monorepo structures.

The tool automatically detects the necessary directories (`*_flutter`, `*_server`) and executes the appropriate commands, with optional `fvm` support. Additionally, it can manage dependencies across multiple subprojects in large project hierarchies.

---

## ✨ Features

- 📦 Automatic Flutter module building  
- 🛠 Code generation and migrations for Serverpod  
- 🔁 Support for `fvm` (Flutter Version Management)  
- 🧠 Smart project structure navigation  
- 🔧 Commands unified in a single CLI: `dh`  
- 🗑️ Unused files detection and cleanup
- 📚 Get-All command for monorepo dependency management with tree-structured output

---

## 🚀 Installation

```bash
dart pub global activate dart_helper_cli
```

Available executable aliases:

* `dh`
* `dart-helper`
* `dart_helper`
* `nit-helper` (legacy compatibility alias)

Ensure that the Dart global utilities path is added to `PATH`:

* **Linux/macOS**:
  ```bash
  export PATH="$PATH:$HOME/.pub-cache/bin"
  ```
* **Windows**:
  Open **System Properties → Advanced → Environment Variables** and add
  ```
  %APPDATA%\Pub\Cache\bin
  ```
  to the `Path` variable.

---

## 🧪 Usage

You can invoke the CLI with any executable alias above. Examples below use `dh`.

### 🔨 `build` / `b`

Builds the Flutter project (searches for a directory ending with `_flutter`, or works in the current directory if it matches).

```bash
dh build
dh b
```

With `fvm`:
```bash
dh build --fvm
dh b --fvm
```

Executes commands:
* `dart run build_runner build`
* `fluttergen`

---

### 🖥 `build-server` / `bs`

Generates Serverpod code and applies migrations. Searches for a directory ending with `_server`.

```bash
dh build-server
dh bs
```

Force migration creation:
```bash
dh build-server --force
dh bs --force
```

With `fvm`:
```bash
dh build-server --fvm
dh bs --fvm
```

Executes commands:
* `serverpod generate`
* `serverpod create-migration` (or `--force`)
* `dart run bin/main.dart --role maintenance --apply-migrations`

---

### 🔁 `build-full` / `bf`

Combines `build` and `build-server`:

```bash
dh build-full
dh bf
```

With options:
```bash
dh build-full --fvm --force
dh bf --fvm --force
```

---

### 🔍 `check` / `c`

Analyzes the project for unused Dart files and provides cleanup options.

```bash
dh check
dh c
```

With options:
```bash
# Scan specific project
dh check --path ./my_project
dh c --path ./my_project

# Exclude patterns and folders
dh check --exclude-pattern "*.g.dart" --exclude-folder "generated"
dh c --exclude-pattern "*.g.dart" --exclude-folder "generated"

# Interactive cleanup mode
dh check --interactive
dh c --interactive

# Combine options
dh check -p ./project -e "*.test.dart" -f "temp" -i
dh c -p ./project -e "*.test.dart" -f "temp" -i
```

Features:
* AST-based dependency analysis via import/export/part parsing
* Package-aware resolution for local `package:` imports
* Automatic exclusion of generated files (*.g.dart, *.freezed.dart, etc.)
* Interactive cleanup with confirmation prompts
* Explicit warnings for unresolved or unreadable files
* Cross-platform support
* Detailed size reporting

---

### 📚 `get-all` / `ga`

Recursively finds all subprojects with `pubspec.yaml` and runs `dart pub get` in each. Automatically excludes standard Flutter folders to avoid unnecessary scanning.

```bash
dh get-all
dh ga
```

With custom path:
```bash
dh get-all --path ./my_monorepo
dh ga --path ./my_monorepo
```

With `fvm`:
```bash
dh get-all --path ./packages --fvm
dh ga --path ./packages --fvm
```

Features:
* **Recursive Project Discovery**: Automatically finds all Dart/Flutter projects at any depth
* **Beautiful Tree Output**: Results displayed in a structured tree format with status indicators
* **Smart Folder Exclusion**: Ignores build directories (build, ios, android, web, windows, macos, linux) and system folders (.git, .vscode, etc.)
* **Symlink Loop Detection**: Prevents infinite loops from circular symlinks
* **Cross-Platform Support**: Works on Windows, macOS, and Linux
* **Interactive Output**: Preserves colored terminal output during dependency installation
* **Perfect for Monorepos**: Handles complex project structures with nested dependencies

Example output:
```
📁 Found 4 projects:

📊 GET ALL SUMMARY
═════════════════════════════════════════════════
📦 packages/
├── ✅ shared_models
├── ✅ ui_components
└── 📦 utils/
    └── ✅ string_utils
✅ my_app

Total projects: 4
Successful: 4
All projects processed successfully! 🎉
```

---

## 🧰 Arguments

| Argument | Command | Description |
| -------- | ------- | ----------- |
| `--fvm` | build / b, build-server / bs, build-full / bf, get-all / ga | Execute through `fvm exec` |
| `--force` | build-server / bs, build-full / bf | Force create migrations |
| `--path`, `-p` | check / c, get-all / ga | Path to project directory |
| `--exclude-pattern`, `-e` | check / c | File patterns to exclude |
| `--exclude-folder`, `-f` | check / c | Folders to exclude |
| `--interactive`, `-i` | check / c | Enable interactive cleanup |
| `--details`, `-d` | check / c | Show detailed file list |

---

## 💡 Examples

```bash
# Build Flutter with fvm
dh build --fvm
dh b --fvm

# Build Serverpod with forced migration
dh build-server --force
dh bs --force

# Full project build
dh build-full --fvm --force
dh bf --fvm --force

# Check for unused files
dh check
dh c

# Interactive cleanup with exclusions  
dh check --exclude-pattern "*.g.dart" --interactive
dh c --exclude-pattern "*.g.dart" --interactive

# Get dependencies for all subprojects in current directory
dh get-all
dh ga

# Get dependencies for specific monorepo path
dh get-all --path ./packages
dh ga --path ./packages

# Get dependencies with FVM
dh get-all -p ./my_monorepo --fvm
dh ga -p ./my_monorepo --fvm
```

---

## 📂 Project Structure

```text
project_root/
├── my_app_flutter/
│   ├── pubspec.yaml
│   └── main.dart
├── my_app_server/
│   ├── pubspec.yaml
│   └── bin/main.dart
├── packages/
│   ├── shared_models/
│   │   └── pubspec.yaml
│   └── ui_components/
│       └── pubspec.yaml
```

`dh` will automatically detect where `*_flutter` and `*_server` are located and execute the appropriate commands. The same behavior is available through `dart-helper`, `dart_helper`, and `nit-helper`. The `get-all` command is particularly useful in monorepo structures like the one above, scanning through all nested `pubspec.yaml` files and installing dependencies for each.

---

## 🙏 Acknowledgments

Special thanks to **[Emad Beltaje](https://github.com/EmadBeltaje)** for the original [dart_unused_files](https://github.com/EmadBeltaje/dart_unused_files) package, which inspired and provided the foundation for the unused files detection functionality in the `check` command.

---

## 📜 License

MIT License.
© 2025 Maksim Levchenko

---

## 📫 Feedback

Report bugs or suggestions:
[GitHub Issues](https://github.com/MaksimLevchenko/nit-helper/issues)
