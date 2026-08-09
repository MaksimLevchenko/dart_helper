import 'dart:async';
import 'dart:io';

import 'package:dart_helper_cli/src/commands/get_all/interactive_prompt.dart';
import 'package:dart_helper_cli/src/commands/get_all_command.dart';
import 'package:dart_helper_cli/src/services/process_service.dart';
import 'package:dart_helper_cli/src/utils/ansi.dart';
import 'package:test/test.dart';

void main() {
  group('GetAllCommand', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('dart_helper_get_all_');
      Ansi.enabled = false;
    });

    tearDown(() {
      Ansi.enabled = true;
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('searches projects while skipping excluded folders', () async {
      _writePubspec(_join(tempDir.path, ['workspace', 'app']));
      _writePubspec(_join(tempDir.path, ['workspace', 'packages', 'feature']));
      _writePubspec(_join(tempDir.path, ['workspace', 'build', 'ignored']));
      _writePubspec(_join(tempDir.path, ['workspace', '.git', 'hidden']));

      final processService = _FakeProcessService([0, 0]);
      final prompt = _FakeInteractivePrompt();
      final command = GetAllCommand(
        processService,
        interactivePrompt: prompt,
      );

      final exitCode = await _capturePrints(() {
        return command.execute(
          path: _join(tempDir.path, ['workspace']),
          treeView: false,
          interactive: false,
        );
      });

      expect(exitCode, 0);
      expect(prompt.callCount, 0);
      expect(processService.workingDirectories, hasLength(2));
      expect(
        processService.workingDirectories,
        everyElement(
          isNot(contains(
              '${Platform.pathSeparator}build${Platform.pathSeparator}')),
        ),
      );
      expect(
        processService.workingDirectories,
        everyElement(
          isNot(contains(
              '${Platform.pathSeparator}.git${Platform.pathSeparator}')),
        ),
      );
    });

    test('returns non-zero when some projects fail in both tree and list modes',
        () async {
      _writePubspec(_join(tempDir.path, ['monorepo', 'app_one']));
      _writePubspec(_join(tempDir.path, ['monorepo', 'app_two']));

      final treeProcessService = _FakeProcessService([0, 42]);
      final listProcessService = _FakeProcessService([0, 42]);

      final treeCommand = GetAllCommand(treeProcessService);
      final listCommand = GetAllCommand(listProcessService);

      final treeExitCode = await _capturePrints(() {
        return treeCommand.execute(
          path: _join(tempDir.path, ['monorepo']),
          treeView: true,
        );
      });
      final listExitCode = await _capturePrints(() {
        return listCommand.execute(
          path: _join(tempDir.path, ['monorepo']),
          treeView: false,
        );
      });

      expect(treeExitCode, 1);
      expect(listExitCode, 1);
      expect(treeProcessService.commands, hasLength(2));
      expect(listProcessService.commands, hasLength(2));
    });

    test('interactive false does not read confirmation prompt', () async {
      _writePubspec(_join(tempDir.path, ['workspace', 'app']));

      final processService = _FakeProcessService([0]);
      final prompt = _FakeInteractivePrompt();
      final command = GetAllCommand(
        processService,
        interactivePrompt: prompt,
      );

      final exitCode = await _capturePrints(() {
        return command.execute(
          path: _join(tempDir.path, ['workspace']),
          interactive: false,
        );
      });

      expect(exitCode, 0);
      expect(prompt.callCount, 0);
      expect(processService.commands, hasLength(1));
    });
  });
}

class _FakeProcessService extends ProcessService {
  final List<int> _exitCodes;
  final List<List<String>> commands = [];
  final List<String> workingDirectories = [];

  _FakeProcessService(this._exitCodes);

  @override
  Future<int> runCommand(
    List<String> cmd, {
    required bool useFvm,
    bool showDetails = true,
    bool announceCommand = true,
  }) async {
    commands.add(List<String>.from(cmd));
    workingDirectories.add(Directory.current.path);
    return _exitCodes[commands.length - 1];
  }
}

class _FakeInteractivePrompt extends InteractivePrompt {
  int callCount = 0;

  @override
  Future<bool> confirmProcessingAllProjects() async {
    callCount++;
    return true;
  }
}

void _writePubspec(String directoryPath) {
  final file = File('$directoryPath${Platform.pathSeparator}pubspec.yaml');
  file.createSync(recursive: true);
  file.writeAsStringSync('name: sample_project\n');
}

String _join(String root, List<String> segments) {
  return [root, ...segments].join(Platform.pathSeparator);
}

Future<T> _capturePrints<T>(Future<T> Function() action) {
  return runZoned(
    action,
    zoneSpecification: ZoneSpecification(
      print: (_, __, ___, ____) {},
    ),
  );
}
