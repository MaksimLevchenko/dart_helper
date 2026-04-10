import '../services/process_service.dart';
import '../utils/logger.dart';
import '../utils/task_status.dart';

class ReverseCommand {
  final ProcessService _processService;

  ReverseCommand(this._processService);

  Future<int> execute({
    required List<int> ports,
  }) async {
    if (ports.isEmpty) {
      Logger.warning(
        'No reverse ports configured. '
        'Use "dh config reverse.ports add <port>" to add ports.',
      );
      return 0;
    }

    final status = TaskStatus('Reversing adb ports');
    status.start('Preparing adb reverse for ${ports.length} port(s)...');

    final successfulPorts = <int>[];
    final failedPorts = <int>[];
    int failureExitCode = 1;

    for (var index = 0; index < ports.length; index++) {
      final port = ports[index];
      status.update(
        'Reversing port $port (${index + 1}/${ports.length})...',
      );

      final exitCode = await _processService.runCommand(
        ['adb', 'reverse', 'tcp:$port', 'tcp:$port'],
        useFvm: false,
        showDetails: false,
        announceCommand: false,
      );

      if (exitCode == 0) {
        successfulPorts.add(port);
      } else {
        failedPorts.add(port);
        failureExitCode = exitCode;
      }
    }

    if (failedPorts.isNotEmpty) {
      status.fail(
        'adb reverse failed for ${failedPorts.length} of ${ports.length} port(s).',
      );
      Logger.error('Failed ports: ${failedPorts.join(', ')}');
      if (successfulPorts.isNotEmpty) {
        Logger.info('Successful ports: ${successfulPorts.join(', ')}');
      }
      return failureExitCode;
    }

    status.complete(
      'adb reverse completed for ${successfulPorts.length} port(s).',
    );
    Logger.success('Ports: ${successfulPorts.join(', ')}');
    return 0;
  }
}
