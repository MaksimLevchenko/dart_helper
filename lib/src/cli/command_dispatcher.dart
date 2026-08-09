import '../commands/build_command.dart';
import '../commands/check_command.dart';
import '../commands/config_command.dart';
import '../commands/get_all_command.dart';
import '../commands/reverse_command.dart';
import 'parsed_command.dart';

class CommandDispatcher {
  final BuildCommand _buildCommand;
  final CheckCommand _checkCommand;
  final GetAllCommand _getAllCommand;
  final ReverseCommand _reverseCommand;
  final ConfigCommand _configCommand;

  CommandDispatcher({
    required BuildCommand buildCommand,
    required CheckCommand checkCommand,
    required GetAllCommand getAllCommand,
    required ReverseCommand reverseCommand,
    required ConfigCommand configCommand,
  })  : _buildCommand = buildCommand,
        _checkCommand = checkCommand,
        _getAllCommand = getAllCommand,
        _reverseCommand = reverseCommand,
        _configCommand = configCommand;

  Future<int> execute(ParsedCommand command) async {
    switch (command.name) {
      case 'build':
        await _buildCommand.executeBuild(
          force: command.force,
          useFvm: command.useFvm ?? false,
        );
        break;
      case 'build-server':
        await _buildCommand.executeBuildServer(
          forceMigration: command.force,
          useFvm: command.useFvm ?? false,
        );
        break;
      case 'build-full':
        await _buildCommand.executeBuild(
          force: command.force,
          useFvm: command.useFvm ?? false,
        );
        await _buildCommand.executeBuildServer(
          forceMigration: command.force,
          useFvm: command.useFvm ?? false,
        );
        break;
      case 'check':
        final result = await _checkCommand.executeWithResult(
          projectPath: command.checkPath,
          excludePatterns: command.excludePatterns,
          excludeFolders: command.excludeFolders,
          showDetails: command.showDetails ?? true,
        );

        if (command.checkInteractive ?? false) {
          await _checkCommand.interactiveCleanup(result);
        }
        break;
      case 'get-all':
        return _getAllCommand.execute(
          path: command.getAllPath,
          useFvm: command.getAllUseFvm ?? false,
          interactive: command.getAllInteractive ?? false,
          treeView: command.getAllTreeView ?? true,
        );
      case 'reverse':
        return _reverseCommand.execute(
          ports: command.reversePorts ?? const [],
        );
      case 'config':
        return _configCommand.execute(
          args: command.configArgs,
        );
      default:
        throw ArgumentError('Unknown command: ${command.name}');
    }

    return 0;
  }
}
