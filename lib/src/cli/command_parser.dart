import 'package:args/args.dart';

import 'parsed_command.dart';

class CommandParser {
  static const Map<String, String> commandAliases = {
    'build': 'build',
    'b': 'build',
    'build-server': 'build-server',
    'bs': 'build-server',
    'build-full': 'build-full',
    'bf': 'build-full',
    'reverse': 'reverse',
    'r': 'reverse',
    'check': 'check',
    'c': 'check',
    'get-all': 'get-all',
    'ga': 'get-all',
    'config': 'config',
  };

  const CommandParser();

  ParsedCommand parse(List<String> args) {
    if (args.isEmpty || _isGlobalHelpInvocation(args)) {
      return const ParsedCommand(
        showHelp: true,
        name: null,
        useFvm: null,
        force: false,
      );
    }

    final parser = _buildParser();

    try {
      final result = parser.parse(args);
      final rawCommandName = result.command?.name;
      final commandName = normalizeCommandName(rawCommandName);
      final commandArgs = result.command;

      bool? useFvm;
      var force = false;

      if (commandArgs != null &&
          ['build', 'build-server', 'build-full'].contains(commandName)) {
        useFvm = _maybeParsedFlag(commandArgs, 'fvm');
        force = commandArgs['force'] as bool? ?? false;
      }

      String? checkPath;
      var excludePatterns = <String>[];
      var excludeFolders = <String>[];
      bool? showDetails;
      bool? checkInteractive;

      if (commandName == 'check' && commandArgs != null) {
        checkPath = commandArgs['path'] as String?;
        excludePatterns =
            (commandArgs['exclude-pattern'] as List<String>?) ?? [];
        excludeFolders = (commandArgs['exclude-folder'] as List<String>?) ?? [];
        showDetails = _maybeParsedFlag(commandArgs, 'details');
        checkInteractive = _maybeParsedFlag(commandArgs, 'interactive');
      }

      String? getAllPath;
      bool? getAllUseFvm;
      bool? getAllInteractive;
      bool? getAllTreeView;

      if (commandName == 'get-all' && commandArgs != null) {
        getAllPath = commandArgs['path'] as String?;
        getAllUseFvm = _maybeParsedFlag(commandArgs, 'fvm');
        getAllInteractive = _maybeParsedFlag(commandArgs, 'interactive');
        getAllTreeView = _maybeParsedFlag(commandArgs, 'tree');
      }

      var configArgs = const <String>[];
      if (commandName == 'config') {
        configArgs = commandArgs?.rest ?? result.rest;
      }

      return ParsedCommand(
        showHelp: false,
        name: commandName,
        useFvm: useFvm,
        force: force,
        checkPath: checkPath,
        excludePatterns: excludePatterns,
        excludeFolders: excludeFolders,
        showDetails: showDetails,
        checkInteractive: checkInteractive,
        getAllPath: getAllPath,
        getAllUseFvm: getAllUseFvm,
        getAllInteractive: getAllInteractive,
        getAllTreeView: getAllTreeView,
        reversePorts: null,
        configArgs: configArgs,
      );
    } catch (e) {
      throw ArgumentError('Failed to parse arguments: $e');
    }
  }

  bool _isGlobalHelpInvocation(List<String> args) {
    return args.length == 1 && (args.single == '--help' || args.single == '-h');
  }

  String? normalizeCommandName(String? commandName) {
    if (commandName == null) {
      return null;
    }

    return commandAliases[commandName] ?? commandName;
  }

  ArgParser _buildParser() {
    return ArgParser()
      ..addCommand('build', _buildBuildParser())
      ..addCommand('b', _buildBuildParser())
      ..addCommand('build-server', _buildBuildParser())
      ..addCommand('bs', _buildBuildParser())
      ..addCommand('build-full', _buildBuildParser())
      ..addCommand('bf', _buildBuildParser())
      ..addCommand('reverse', _buildReverseParser())
      ..addCommand('r', _buildReverseParser())
      ..addCommand('get-all', _buildGetAllParser())
      ..addCommand('ga', _buildGetAllParser())
      ..addCommand('check', _buildCheckParser())
      ..addCommand('c', _buildCheckParser())
      ..addCommand('config', _buildConfigParser());
  }

  ArgParser _buildBuildParser() {
    return ArgParser()
      ..addFlag('fvm', help: 'Run commands through FVM')
      ..addFlag('force', abbr: 'f', negatable: false, help: 'Force operations');
  }

  ArgParser _buildCheckParser() {
    return ArgParser()
      ..addOption(
        'path',
        abbr: 'p',
        help: 'The path to the project directory to scan',
        defaultsTo: '.',
      )
      ..addMultiOption(
        'exclude-pattern',
        abbr: 'e',
        help: 'File patterns to exclude from the scan (e.g., "*.g.dart")',
      )
      ..addMultiOption(
        'exclude-folder',
        abbr: 'f',
        help: 'Folders to exclude from the scan (e.g., "generated")',
      )
      ..addFlag(
        'details',
        abbr: 'd',
        help: 'Show detailed list of unused files',
        defaultsTo: true,
      )
      ..addFlag(
        'interactive',
        abbr: 'i',
        help: 'Enable interactive cleanup mode',
      );
  }

  ArgParser _buildGetAllParser() {
    return ArgParser()
      ..addOption(
        'path',
        abbr: 'p',
        help: 'The path to start searching for Dart/Flutter projects',
        defaultsTo: '.',
      )
      ..addFlag(
        'fvm',
        help: 'Run commands through FVM',
      )
      ..addFlag(
        'interactive',
        abbr: 'i',
        help: 'Ask for confirmation before processing projects',
      )
      ..addFlag(
        'tree',
        abbr: 't',
        help: 'Display results in enhanced tree view format',
        defaultsTo: true,
      );
  }

  ArgParser _buildConfigParser() {
    return ArgParser();
  }

  ArgParser _buildReverseParser() {
    return ArgParser();
  }

  bool? _maybeParsedFlag(ArgResults commandArgs, String name) {
    if (!commandArgs.wasParsed(name)) {
      return null;
    }

    return commandArgs[name] as bool?;
  }
}
