import '../commands/build_command.dart';
import '../commands/check_command.dart';
import '../commands/config_command.dart';
import '../commands/get_all_command.dart';
import '../commands/reverse_command.dart';
import '../services/config_service.dart';
import '../services/update_service.dart';
import '../utils/ansi.dart';
import 'command_defaults_resolver.dart';
import 'command_dispatcher.dart';
import 'command_parser.dart';
import 'command_runner_factory.dart';
import 'error_handler.dart';
import 'help_printer.dart';

export 'parsed_command.dart';

class CommandRunner {
  final BuildCommand _buildCommand;
  final CheckCommand _checkCommand;
  final GetAllCommand _getAllCommand;
  final ReverseCommand _reverseCommand;
  final ConfigCommand _configCommand;
  final ConfigService _configService;
  final UpdateService _updateService;
  final HelpPrinter _helpPrinter;
  final ErrorHandler _errorHandler;
  final CommandParser _commandParser = const CommandParser();
  final CommandDefaultsResolver _defaultsResolver =
      const CommandDefaultsResolver();

  late final CommandDispatcher _commandDispatcher = CommandDispatcher(
    buildCommand: _buildCommand,
    checkCommand: _checkCommand,
    getAllCommand: _getAllCommand,
    reverseCommand: _reverseCommand,
    configCommand: _configCommand,
  );

  CommandRunner({
    required BuildCommand buildCommand,
    required CheckCommand checkCommand,
    required UpdateService updateService,
    required GetAllCommand getAllCommand,
    required ReverseCommand reverseCommand,
    required ConfigCommand configCommand,
    required ConfigService configService,
    required HelpPrinter helpPrinter,
    required ErrorHandler errorHandler,
  })  : _buildCommand = buildCommand,
        _checkCommand = checkCommand,
        _updateService = updateService,
        _getAllCommand = getAllCommand,
        _reverseCommand = reverseCommand,
        _configCommand = configCommand,
        _configService = configService,
        _helpPrinter = helpPrinter,
        _errorHandler = errorHandler;

  Future<int> run(List<String> args) async {
    return _errorHandler.handleErrors(() async {
      final command = _commandParser.parse(args);
      if (command.showHelp) {
        _helpPrinter.printHelp();
        return 0;
      }

      final config = await _configService.readConfig();

      Ansi.enabled = config.colorEnabled;

      if (config.updateChecksEnabled) {
        await _updateService.checkForUpdates();
      }

      final resolvedCommand = _defaultsResolver.apply(command, config);
      return _commandDispatcher.execute(resolvedCommand);
    });
  }
}

CommandRunner createCommandRunner() {
  final components = createCommandRunnerComponents();

  return CommandRunner(
    buildCommand: components.buildCommand,
    checkCommand: components.checkCommand,
    updateService: components.updateService,
    getAllCommand: components.getAllCommand,
    reverseCommand: components.reverseCommand,
    configCommand: components.configCommand,
    configService: components.configService,
    helpPrinter: components.helpPrinter,
    errorHandler: components.errorHandler,
  );
}

Future<int> runCli(List<String> args) {
  return createCommandRunner().run(args);
}
