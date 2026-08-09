import '../models/cli_config.dart';
import 'parsed_command.dart';

class CommandDefaultsResolver {
  const CommandDefaultsResolver();

  ParsedCommand apply(ParsedCommand command, CliConfig config) {
    return ParsedCommand(
      showHelp: command.showHelp,
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
      reversePorts: command.reversePorts ?? config.reversePorts,
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
}
