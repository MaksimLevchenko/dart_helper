import 'package:dart_helper_cli/src/cli/command_defaults_resolver.dart';
import 'package:dart_helper_cli/src/cli/parsed_command.dart';
import 'package:dart_helper_cli/src/models/cli_config.dart';
import 'package:test/test.dart';

void main() {
  group('CommandDefaultsResolver', () {
    const resolver = CommandDefaultsResolver();

    test('merges check defaults with CLI overrides', () {
      final resolved = resolver.apply(
        const ParsedCommand(
          name: 'check',
          useFvm: null,
          force: false,
          excludePatterns: ['*.freezed.dart'],
          excludeFolders: ['build'],
          showDetails: null,
          checkInteractive: null,
        ),
        const CliConfig(
          useFvmByDefault: true,
          checkDetailsByDefault: false,
          checkInteractiveByDefault: true,
          checkExcludePatterns: ['*.g.dart'],
          checkExcludeFolders: ['generated'],
        ),
      );

      expect(resolved.useFvm, isTrue);
      expect(resolved.showDetails, isFalse);
      expect(resolved.checkInteractive, isTrue);
      expect(resolved.excludePatterns, ['*.g.dart', '*.freezed.dart']);
      expect(resolved.excludeFolders, ['generated', 'build']);
    });

    test('preserves explicit command values over config defaults', () {
      final resolved = resolver.apply(
        const ParsedCommand(
          name: 'get-all',
          useFvm: null,
          force: false,
          getAllUseFvm: false,
          getAllInteractive: true,
          getAllTreeView: false,
          reversePorts: [9000],
        ),
        const CliConfig(
          useFvmByDefault: true,
          getAllTreeByDefault: true,
          reversePorts: [8080],
        ),
      );

      expect(resolved.getAllUseFvm, isFalse);
      expect(resolved.getAllInteractive, isTrue);
      expect(resolved.getAllTreeView, isFalse);
      expect(resolved.reversePorts, [9000]);
    });
  });
}
