import 'package:dart_helper_cli/src/commands/reverse_command.dart';
import 'package:dart_helper_cli/src/services/process_service.dart';
import 'package:test/test.dart';

void main() {
  group('ReverseCommand', () {
    test('runs adb reverse for each port in order', () async {
      final processService = _FakeProcessService([0, 0, 0]);
      final command = ReverseCommand(processService);

      final exitCode = await command.execute(
        ports: [8080, 8081, 8092],
      );

      expect(exitCode, 0);
      expect(processService.commands, [
        ['adb', 'reverse', 'tcp:8080', 'tcp:8080'],
        ['adb', 'reverse', 'tcp:8081', 'tcp:8081'],
        ['adb', 'reverse', 'tcp:8092', 'tcp:8092'],
      ]);
      expect(processService.showDetailsValues, [false, false, false]);
      expect(processService.announceCommandValues, [false, false, false]);
    });

    test('returns non-zero when at least one port fails', () async {
      final processService = _FakeProcessService([0, 42, 0]);
      final command = ReverseCommand(processService);

      final exitCode = await command.execute(
        ports: [8080, 8081, 8092],
      );

      expect(exitCode, 42);
      expect(processService.commands, hasLength(3));
      expect(processService.showDetailsValues, [false, false, false]);
      expect(processService.announceCommandValues, [false, false, false]);
    });

    test('returns success without invoking adb when no ports configured',
        () async {
      final processService = _FakeProcessService(const []);
      final command = ReverseCommand(processService);

      final exitCode = await command.execute(
        ports: const [],
      );

      expect(exitCode, 0);
      expect(processService.commands, isEmpty);
    });
  });
}

class _FakeProcessService extends ProcessService {
  final List<int> _exitCodes;
  final List<List<String>> commands = [];
  final List<bool> showDetailsValues = [];
  final List<bool> announceCommandValues = [];

  _FakeProcessService(this._exitCodes);

  @override
  Future<int> runCommand(
    List<String> cmd, {
    required bool useFvm,
    bool showDetails = true,
    bool announceCommand = true,
  }) async {
    commands.add(List<String>.from(cmd));
    showDetailsValues.add(showDetails);
    announceCommandValues.add(announceCommand);
    return _exitCodes[commands.length - 1];
  }
}
