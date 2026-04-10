import 'dart:io';

import 'package:dart_helper_cli/src/cli/command_runner.dart';
import 'package:dart_helper_cli/src/cli/error_handler.dart';
import 'package:dart_helper_cli/src/cli/help_printer.dart';
import 'package:dart_helper_cli/src/commands/build_command.dart';
import 'package:dart_helper_cli/src/commands/check_command.dart';
import 'package:dart_helper_cli/src/commands/config_command.dart';
import 'package:dart_helper_cli/src/commands/get_all_command.dart';
import 'package:dart_helper_cli/src/commands/reverse_command.dart';
import 'package:dart_helper_cli/src/models/cli_config.dart';
import 'package:dart_helper_cli/src/services/config_service.dart';
import 'package:dart_helper_cli/src/services/file_service.dart';
import 'package:dart_helper_cli/src/services/http_client.dart';
import 'package:dart_helper_cli/src/services/process_service.dart';
import 'package:dart_helper_cli/src/services/update_service.dart';
import 'package:dart_helper_cli/src/utils/ansi.dart';
import 'package:test/test.dart';

void main() {
  group('CommandRunner config defaults', () {
    late _RecordingBuildCommand buildCommand;
    late _RecordingCheckCommand checkCommand;
    late _RecordingGetAllCommand getAllCommand;
    late _RecordingReverseCommand reverseCommand;
    late _RecordingUpdateService updateService;
    late _StaticConfigService configService;
    late CommandRunner runner;

    setUp(() {
      buildCommand = _RecordingBuildCommand();
      checkCommand = _RecordingCheckCommand();
      getAllCommand = _RecordingGetAllCommand();
      reverseCommand = _RecordingReverseCommand();
      updateService = _RecordingUpdateService();
      configService = _StaticConfigService(const CliConfig());
      runner = CommandRunner(
        buildCommand: buildCommand,
        checkCommand: checkCommand,
        updateService: updateService,
        getAllCommand: getAllCommand,
        reverseCommand: reverseCommand,
        configCommand: ConfigCommand(configService, HelpPrinter()),
        configService: configService,
        helpPrinter: HelpPrinter(),
        errorHandler: ErrorHandler(),
      );
    });

    tearDown(() {
      Ansi.enabled = true;
    });

    test('uses fvm from config when flag is omitted', () async {
      configService.config = const CliConfig(useFvmByDefault: true);

      final exitCode = await runner.run(['build']);

      expect(exitCode, 0);
      expect(buildCommand.lastBuildUseFvm, isTrue);
      expect(updateService.checkForUpdatesCalled, isTrue);
    });

    test('explicit no-fvm overrides config default', () async {
      configService.config = const CliConfig(useFvmByDefault: true);

      final exitCode = await runner.run(['build', '--no-fvm']);

      expect(exitCode, 0);
      expect(buildCommand.lastBuildUseFvm, isFalse);
    });

    test('check command merges configured excludes and uses config defaults',
        () async {
      configService.config = const CliConfig(
        checkDetailsByDefault: false,
        checkInteractiveByDefault: true,
        checkExcludePatterns: ['*.g.dart'],
        checkExcludeFolders: ['generated'],
      );

      final exitCode = await runner.run([
        'check',
        '--exclude-pattern',
        '*.freezed.dart',
        '--exclude-folder',
        'build',
      ]);

      expect(exitCode, 0);
      expect(checkCommand.lastShowDetails, isFalse);
      expect(
        checkCommand.lastExcludePatterns,
        ['*.g.dart', '*.freezed.dart'],
      );
      expect(checkCommand.lastExcludeFolders, ['generated', 'build']);
      expect(checkCommand.interactiveCleanupCalled, isTrue);
    });

    test('get-all uses configured tree default', () async {
      configService.config = const CliConfig(
        getAllTreeByDefault: false,
        useFvmByDefault: true,
      );

      final exitCode = await runner.run(['get-all']);

      expect(exitCode, 0);
      expect(getAllCommand.lastTreeView, isFalse);
      expect(getAllCommand.lastUseFvm, isTrue);
    });

    test('reverse uses ports from config', () async {
      configService.config = const CliConfig(
        reversePorts: [8080, 8092],
      );

      final exitCode = await runner.run(['reverse']);

      expect(exitCode, 0);
      expect(reverseCommand.lastPorts, [8080, 8092]);
    });

    test('reverse alias routes to the same command', () async {
      configService.config = const CliConfig(
        reversePorts: [9000],
      );

      final exitCode = await runner.run(['r']);

      expect(exitCode, 0);
      expect(reverseCommand.lastPorts, [9000]);
    });

    test('update-checks off skips update service and color off disables ansi',
        () async {
      configService.config = const CliConfig(
        updateChecksEnabled: false,
        colorEnabled: false,
      );

      final exitCode = await runner.run(['build']);

      expect(exitCode, 0);
      expect(updateService.checkForUpdatesCalled, isFalse);
      expect(Ansi.enabled, isFalse);
    });
  });
}

class _StaticConfigService extends ConfigService {
  CliConfig config;

  _StaticConfigService(this.config)
      : super(configFile: File('test-config.json'));

  @override
  Future<CliConfig> readConfig() async => config;
}

class _RecordingUpdateService extends UpdateService {
  bool checkForUpdatesCalled = false;

  _RecordingUpdateService() : super(HttpClient());

  @override
  Future<void> checkForUpdates() async {
    checkForUpdatesCalled = true;
  }
}

class _RecordingBuildCommand extends BuildCommand {
  bool? lastBuildUseFvm;
  bool? lastServerUseFvm;

  _RecordingBuildCommand()
      : super(
          ProcessService(),
          FileService(),
          ConfigService(configFile: File('unused-config.json')),
        );

  @override
  Future<int> executeBuild({required bool force, required bool useFvm}) async {
    lastBuildUseFvm = useFvm;
    return 0;
  }

  @override
  Future<int> executeBuildServer({
    required bool forceMigration,
    required bool useFvm,
  }) async {
    lastServerUseFvm = useFvm;
    return 0;
  }
}

class _RecordingCheckCommand extends CheckCommand {
  List<String>? lastExcludePatterns;
  List<String>? lastExcludeFolders;
  bool? lastShowDetails;
  bool interactiveCleanupCalled = false;

  @override
  Future<UnusedFileResult> executeWithResult({
    String? projectPath,
    List<String> excludePatterns = const [],
    List<String> excludeFolders = const [],
    bool showDetails = true,
  }) async {
    lastExcludePatterns = excludePatterns;
    lastExcludeFolders = excludeFolders;
    lastShowDetails = showDetails;

    return UnusedFileResult(
      projectPath: projectPath ?? '.',
      unusedFiles: const [],
      totalFiles: 0,
      usedFiles: 0,
      usedLineCount: 0,
      totalSizeKb: 0,
      warnings: const [],
      unreadableFiles: const [],
    );
  }

  @override
  Future<void> interactiveCleanup(UnusedFileResult result) async {
    interactiveCleanupCalled = true;
  }
}

class _RecordingGetAllCommand extends GetAllCommand {
  bool? lastUseFvm;
  bool? lastInteractive;
  bool? lastTreeView;

  _RecordingGetAllCommand() : super(ProcessService());

  @override
  Future<int> execute({
    String? path,
    bool useFvm = false,
    bool interactive = false,
    bool treeView = true,
  }) async {
    lastUseFvm = useFvm;
    lastInteractive = interactive;
    lastTreeView = treeView;
    return 0;
  }
}

class _RecordingReverseCommand extends ReverseCommand {
  List<int>? lastPorts;

  _RecordingReverseCommand() : super(ProcessService());

  @override
  Future<int> execute({
    required List<int> ports,
  }) async {
    lastPorts = ports;
    return 0;
  }
}
