import '../commands/build_command.dart';
import '../commands/check_command.dart';
import '../commands/config_command.dart';
import '../commands/get_all_command.dart';
import '../commands/reverse_command.dart';
import '../services/config_service.dart';
import '../services/file_service.dart';
import '../services/http_client.dart';
import '../services/process_service.dart';
import '../services/update_service.dart';
import 'error_handler.dart';
import 'help_printer.dart';

class CommandRunnerComponents {
  final BuildCommand buildCommand;
  final CheckCommand checkCommand;
  final UpdateService updateService;
  final GetAllCommand getAllCommand;
  final ReverseCommand reverseCommand;
  final ConfigCommand configCommand;
  final ConfigService configService;
  final HelpPrinter helpPrinter;
  final ErrorHandler errorHandler;

  CommandRunnerComponents({
    required this.buildCommand,
    required this.checkCommand,
    required this.updateService,
    required this.getAllCommand,
    required this.reverseCommand,
    required this.configCommand,
    required this.configService,
    required this.helpPrinter,
    required this.errorHandler,
  });
}

CommandRunnerComponents createCommandRunnerComponents() {
  final processService = ProcessService();
  final fileService = FileService();
  final configService = ConfigService();
  final buildCommand = BuildCommand(processService, fileService, configService);
  final checkCommand = CheckCommand();
  final getAllCommand = GetAllCommand(processService);
  final reverseCommand = ReverseCommand(processService);
  final helpPrinter = HelpPrinter();
  final configCommand = ConfigCommand(configService, helpPrinter);
  final httpClient = HttpClient();
  final updateService = UpdateService(httpClient);
  final errorHandler = ErrorHandler();

  return CommandRunnerComponents(
    buildCommand: buildCommand,
    checkCommand: checkCommand,
    updateService: updateService,
    getAllCommand: getAllCommand,
    reverseCommand: reverseCommand,
    configCommand: configCommand,
    configService: configService,
    helpPrinter: helpPrinter,
    errorHandler: errorHandler,
  );
}
