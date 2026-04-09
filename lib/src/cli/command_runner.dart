import 'package:args/args.dart';
import 'package:dart_helper_cli/src/commands/get_all_command.dart';
import '../models/cli_config.dart';
import '../commands/config_command.dart';
import '../commands/build_command.dart';
import '../commands/check_command.dart';
import '../services/update_service.dart';
import '../services/http_client.dart';
import '../services/process_service.dart';
import '../services/file_service.dart';
import '../services/config_service.dart';
import '../utils/ansi.dart';
import 'help_printer.dart';
import 'error_handler.dart';

class CommandRunner {
  static const Map<String, String> _commandAliases = {
    'build': 'build',
    'b': 'build',
    'build-server': 'build-server',
    'bs': 'build-server',
    'build-full': 'build-full',
    'bf': 'build-full',
    'check': 'check',
    'c': 'check',
    'get-all': 'get-all',
    'ga': 'get-all',
    'config': 'config',
  };

  final BuildCommand _buildCommand;
  final CheckCommand _checkCommand;
  final GetAllCommand _getAllCommand;
  final ConfigCommand _configCommand;
  final ConfigService _configService;
  final UpdateService _updateService;
  final HelpPrinter _helpPrinter;
  final ErrorHandler _errorHandler;

  CommandRunner({
    required BuildCommand buildCommand,
    required CheckCommand checkCommand,
    required UpdateService updateService,
    required GetAllCommand getAllCommand,
    required ConfigCommand configCommand,
    required ConfigService configService,
    required HelpPrinter helpPrinter,
    required ErrorHandler errorHandler,
  })  : _buildCommand = buildCommand,
        _checkCommand = checkCommand,
        _updateService = updateService,
        _getAllCommand = getAllCommand,
        _configCommand = configCommand,
        _configService = configService,
        _helpPrinter = helpPrinter,
        _errorHandler = errorHandler;

  Future<int> run(List<String> args) async {
    return _errorHandler.handleErrors(() async {
      final parser = _buildParser();
      final command = _parseCommand(parser, args);
      final config = await _configService.readConfig();

      Ansi.enabled = config.colorEnabled;

      if (config.updateChecksEnabled) {
        await _updateService.checkForUpdates();
      }

      final resolvedCommand = _applyConfigDefaults(command, config);

      return await _executeCommand(resolvedCommand);
    });
  }

  ArgParser _buildParser() {
    return ArgParser()
      ..addCommand('build', _buildBuildParser())
      ..addCommand('b', _buildBuildParser())
      ..addCommand('build-server', _buildBuildParser())
      ..addCommand('bs', _buildBuildParser())
      ..addCommand('build-full', _buildBuildParser())
      ..addCommand('bf', _buildBuildParser())
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

  ParsedCommand _parseCommand(ArgParser parser, List<String> args) {
    try {
      final result = parser.parse(args);
      final rawCommandName = result.command?.name;
      final commandName = _normalizeCommandName(rawCommandName);
      final commandArgs = result.command;

      bool? useFvm;
      bool force = false;

      // Параметры для команд build
      if (commandArgs != null &&
          ['build', 'build-server', 'build-full'].contains(commandName)) {
        useFvm = _maybeParsedFlag(commandArgs, 'fvm');
        if (['build-server', 'build-full', 'build'].contains(commandName)) {
          force = commandArgs['force'] as bool? ?? false;
        }
      }

      // Параметры для команды check
      String? checkPath;
      List<String> excludePatterns = [];
      List<String> excludeFolders = [];
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

      // Параметры для команды get-all
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

      List<String> configArgs = const [];
      if (commandName == 'config') {
        configArgs = commandArgs?.rest ?? result.rest;
      }

      return ParsedCommand(
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
        configArgs: configArgs,
      );
    } catch (e) {
      throw ArgumentError('Failed to parse arguments: $e');
    }
  }

  String? _normalizeCommandName(String? commandName) {
    if (commandName == null) {
      return null;
    }

    return _commandAliases[commandName] ?? commandName;
  }

  ParsedCommand _applyConfigDefaults(ParsedCommand command, CliConfig config) {
    return ParsedCommand(
      name: command.name,
      useFvm: command.useFvm ?? config.useFvmByDefault,
      force: command.force,
      checkPath: command.checkPath,
      excludePatterns: _mergeUnique(
        config.checkExcludePatterns,
        command.excludePatterns,
      ),
      excludeFolders: _mergeUnique(
        config.checkExcludeFolders,
        command.excludeFolders,
      ),
      showDetails: command.showDetails ?? config.checkDetailsByDefault,
      checkInteractive:
          command.checkInteractive ?? config.checkInteractiveByDefault,
      getAllPath: command.getAllPath,
      getAllUseFvm: command.getAllUseFvm ?? config.useFvmByDefault,
      getAllInteractive: command.getAllInteractive ?? false,
      getAllTreeView: command.getAllTreeView ?? config.getAllTreeByDefault,
      configArgs: command.configArgs,
    );
  }

  List<String> _mergeUnique(
    List<String> baseValues,
    List<String> overrideValues,
  ) {
    final merged = <String>[];
    for (final value in [...baseValues, ...overrideValues]) {
      if (!merged.contains(value)) {
        merged.add(value);
      }
    }
    return merged;
  }

  bool? _maybeParsedFlag(ArgResults commandArgs, String name) {
    if (!commandArgs.wasParsed(name)) {
      return null;
    }

    return commandArgs[name] as bool?;
  }

  Future<int> _executeCommand(ParsedCommand command) async {
    switch (command.name) {
      case 'build':
        await _buildCommand.executeBuild(
            force: command.force, useFvm: command.useFvm ?? false);
        break;
      case 'build-server':
        await _buildCommand.executeBuildServer(
            forceMigration: command.force, useFvm: command.useFvm ?? false);
        break;
      case 'build-full':
        await _buildCommand.executeBuild(
            force: command.force, useFvm: command.useFvm ?? false);
        await _buildCommand.executeBuildServer(
            forceMigration: command.force, useFvm: command.useFvm ?? false);
        break;
      case 'check':
        final result = await _checkCommand.executeWithResult(
          projectPath: command.checkPath,
          excludePatterns: command.excludePatterns,
          excludeFolders: command.excludeFolders,
          showDetails: command.showDetails ?? true,
        );

        // Интерактивная очистка если включена
        if (command.checkInteractive ?? false) {
          await _checkCommand.interactiveCleanup(result);
        }
        break;
      case 'get-all':
        return await _getAllCommand.execute(
          path: command.getAllPath,
          useFvm: command.getAllUseFvm ?? false,
          interactive: command.getAllInteractive ?? false,
          treeView: command.getAllTreeView ?? true,
        );
      case 'config':
        return await _configCommand.execute(
          args: command.configArgs,
        );
      case null:
      case '--help':
      case '-h':
        _helpPrinter.printHelp();
        break;
      default:
        throw ArgumentError('Unknown command: ${command.name}');
    }

    return 0;
  }
}

class ParsedCommand {
  final String? name;
  final bool? useFvm;
  final bool force;

  // Параметры для команды check
  final String? checkPath;
  final List<String> excludePatterns;
  final List<String> excludeFolders;
  final bool? showDetails;
  final bool? checkInteractive;

  // Параметры для команды get-all
  final String? getAllPath;
  final bool? getAllUseFvm;
  final bool? getAllInteractive;
  final bool? getAllTreeView;

  final List<String> configArgs;

  ParsedCommand({
    required this.name,
    required this.useFvm,
    required this.force,
    this.checkPath,
    this.excludePatterns = const [],
    this.excludeFolders = const [],
    this.showDetails,
    this.checkInteractive,
    this.getAllPath,
    this.getAllUseFvm,
    this.getAllInteractive,
    this.getAllTreeView,
    this.configArgs = const [],
  });
}

CommandRunner createCommandRunner() {
  final processService = ProcessService();
  final fileService = FileService();
  final configService = ConfigService();
  final buildCommand = BuildCommand(processService, fileService, configService);
  final checkCommand = CheckCommand();
  final getAllCommand = GetAllCommand(processService);
  final helpPrinter = HelpPrinter();
  final configCommand = ConfigCommand(configService, helpPrinter);
  final httpClient = HttpClient();
  final updateService = UpdateService(httpClient);
  final errorHandler = ErrorHandler();

  return CommandRunner(
    buildCommand: buildCommand,
    checkCommand: checkCommand,
    updateService: updateService,
    getAllCommand: getAllCommand,
    configCommand: configCommand,
    configService: configService,
    helpPrinter: helpPrinter,
    errorHandler: errorHandler,
  );
}

/// Запускает CLI с переданными аргументами
///
/// Возвращает код завершения процесса
Future<int> runCli(List<String> args) {
  return createCommandRunner().run(args);
}
