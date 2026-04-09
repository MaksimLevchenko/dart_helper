import '../models/cli_config.dart';

class HelpPrinter {
  void printHelp() {
    print('''
dh - Unified build tool for Dart/Flutter/Serverpod projects


Usage:
  dh build|b [--fvm|--no-fvm] [--force]        Build Flutter module
  dh build-server|bs [--fvm|--no-fvm] [--force] Build Serverpod server
  dh build-full|bf [--fvm|--no-fvm] [--force]  Build both frontend and backend
  dh check|c [options]                         Analyze project for unused files
  dh get-all|ga [options]                      Run "dart pub get" in all subprojects
  dh config [key] [action]                     Manage global CLI settings


Executable Aliases:
  dh, dart-helper, dart_helper, nit-helper


Global Options:
  --fvm    Run commands through "fvm exec"
  --no-fvm Override the global fvm default for this command
  --force  Force operations (migrations, etc.)


Check Command Options:
  -p, --path <directory>           Path to project directory (default: current)
  -e, --exclude-pattern <pattern>  File patterns to exclude (e.g., "*.g.dart")
  -f, --exclude-folder <folder>    Folders to exclude (e.g., "generated")
  -d, --[no-]details              Show detailed list of unused files (default: on)
  -i, --[no-]interactive           Enable interactive cleanup mode


Get-All Command Options:
  -p, --path <directory>           Path to start searching (default: current)
  --[no-]fvm                       Run pub get through "fvm exec"
  -i, --[no-]interactive           Ask for confirmation before processing
  -t, --[no-]tree                  Display enhanced tree view (default: on)


Examples:
  # Build commands
  dh build --fvm
  dh b --fvm
  dh build-server --force
  dh bs --force
  dh build-full --fvm --force
  dh bf --fvm --force
  
  # Check command
  dh check
  dh c
  dh check --path ./my_project
  dh check --exclude-pattern "*.g.dart" --exclude-pattern "*.freezed.dart"
  dh check --exclude-folder "generated" --exclude-folder "build"
  dh check --interactive --no-details
  dh check -p ./project -e "*.test.dart" -f "temp" -i
  
  # Get-all command
  dh get-all
  dh ga
  dh get-all --path ./packages
  dh get-all -p ./my_monorepo --fvm
  dh get-all --interactive --no-tree    # Simple list view with confirmation
  dh get-all -i -t                      # Tree view with confirmation

  # Config command
  dh config
  dh config fvm on
  dh config update-checks off
  dh config check.details off
  dh config check.exclude-pattern add "*.gen.dart"
  dh config color off
  dh config fluttergen off
  dh config fluttergen on


Check Command Features:
  • Unused Dart files detection and removal
  • AST-based dependency analysis via import/export/part parsing
  • Package-aware resolution for local package: URIs
  • Automatic exclusion of generated files (*.g.dart, *.freezed.dart, etc.)
  • Automatic exclusion of client/server/build folders (*_client, *_server, build, etc.)
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
  build, ios, android, web, linux, macos, windows, *_server, *_client, .dart_tool, .git,
  .github, .vscode, .idea, node_modules, .pub-cache, .gradle, .m2, DerivedData,
  Pods, doc, docs, documentation


Automatically Excluded Files:
  *.g.dart, *.gr.dart, *.freezed.dart, *.mocks.dart, firebase_options.dart
''');
  }

  void printConfigHelp(CliConfig config) {
    final fluttergenState = config.fluttergenEnabled ? 'on' : 'off';
    final fvmState = config.useFvmByDefault ? 'on' : 'off';
    final updateChecksState = config.updateChecksEnabled ? 'on' : 'off';
    final checkDetailsState = config.checkDetailsByDefault ? 'on' : 'off';
    final checkInteractiveState =
        config.checkInteractiveByDefault ? 'on' : 'off';
    final getAllTreeState = config.getAllTreeByDefault ? 'on' : 'off';
    final colorState = config.colorEnabled ? 'on' : 'off';
    final excludePatterns = config.checkExcludePatterns.isEmpty
        ? '(empty)'
        : config.checkExcludePatterns.join(', ');
    final excludeFolders = config.checkExcludeFolders.isEmpty
        ? '(empty)'
        : config.checkExcludeFolders.join(', ');

    print('''
Config command

Current settings:
  fluttergen: $fluttergenState
  fvm: $fvmState
  update-checks: $updateChecksState
  check.details: $checkDetailsState
  check.interactive: $checkInteractiveState
  get-all.tree: $getAllTreeState
  check.exclude-pattern: $excludePatterns
  check.exclude-folder: $excludeFolders
  color: $colorState

Usage:
  dh config
  dh config <key>
  dh config <boolean-key> on|off
  dh config <list-key> set <value>...
  dh config <list-key> add <value>...
  dh config <list-key> remove <value>...
  dh config <list-key> clear

Description:
  Controls global CLI settings stored per user.
  Explicit CLI flags override config values for a single command run.
''');
  }

  void printConfigSettingHelp({
    required String key,
    required String currentValue,
    required String description,
    required List<String> usage,
  }) {
    print('''
Config setting: $key

Current value:
  $currentValue

Description:
  $description

Usage:
  ${usage.join('\n  ')}
''');
  }
}
