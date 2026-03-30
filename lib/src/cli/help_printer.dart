class HelpPrinter {
  void printHelp() {
    print('''
dh - Unified build tool for Dart/Flutter/Serverpod projects


Usage:
  dh build [--fvm] [--force]                   Build Flutter module
  dh build-server [--fvm] [--force]            Build Serverpod server
  dh build-full [--fvm] [--force]              Build both frontend and backend
  dh check [options]                           Analyze project for unused files
  dh get-all [options]                         Run "dart pub get" in all subprojects


Global Options:
  --fvm    Run commands through "fvm exec"
  --force  Force operations (migrations, etc.)


Check Command Options:
  -p, --path <directory>           Path to project directory (default: current)
  -e, --exclude-pattern <pattern>  File patterns to exclude (e.g., "*.g.dart")
  -f, --exclude-folder <folder>    Folders to exclude (e.g., "generated")
  -d, --[no-]details              Show detailed list of unused files (default: on)
  -i, --interactive                Enable interactive cleanup mode


Get-All Command Options:
  -p, --path <directory>           Path to start searching (default: current)
  --fvm                            Run pub get through "fvm exec"
  -i, --interactive                Ask for confirmation before processing
  -t, --[no-]tree                 Display enhanced tree view (default: on)


Examples:
  # Build commands
  dh build --fvm
  dh build-server --force
  dh build-full --fvm --force
  
  # Check command
  dh check
  dh check --path ./my_project
  dh check --exclude-pattern "*.g.dart" --exclude-pattern "*.freezed.dart"
  dh check --exclude-folder "generated" --exclude-folder "build"
  dh check --interactive --no-details
  dh check -p ./project -e "*.test.dart" -f "temp" -i
  
  # Get-all command
  dh get-all
  dh get-all --path ./packages
  dh get-all -p ./my_monorepo --fvm
  dh get-all --interactive --no-tree    # Simple list view with confirmation
  dh get-all -i -t                      # Tree view with confirmation


Check Command Features:
  • Unused Dart files detection and removal
  • AST-based dependency analysis via import/export/part parsing
  • Package-aware resolution for local package: URIs
  • Automatic exclusion of generated files (*.g.dart, *.freezed.dart, etc.)
  • Interactive cleanup with confirmation prompts
  • Explicit warnings for unresolved or unreadable files
  • Cross-platform support (Windows, macOS, Linux)
  • Detailed size reporting of unused files


Get-All Command Features:
  • Recursively finds all subprojects with pubspec.yaml
  • 🎆 Beautiful tree-structured output with folder status indicators:
    📁 Unprocessed folders    ✅ Successfully processed
  • Interactive mode with confirmation prompts
  • Smart exclusion of Flutter build folders (build, ios, android, web, etc.)
  • Real-time progress tracking with visual progress bars
  • Automatic symlink loop detection
  • Cross-platform support (Windows, macOS, Linux)
  • Perfect for monorepo structures
  • Colored output for better readability


Automatically Excluded Folders:
  build, ios, android, web, linux, macos, windows, .dart_tool, .git, .github,
  .vscode, .idea, node_modules, .pub-cache, .gradle, .m2, DerivedData, Pods,
  doc, docs, documentation


Automatically Excluded Files:
  *.g.dart, *.gr.dart, *.freezed.dart, *.mocks.dart, firebase_options.dart
''');
  }
}
