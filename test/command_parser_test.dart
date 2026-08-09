import 'package:dart_helper_cli/src/cli/command_parser.dart';
import 'package:test/test.dart';

void main() {
  group('CommandParser', () {
    const parser = CommandParser();

    test('returns help mode for empty args', () {
      final command = parser.parse(const []);

      expect(command.showHelp, isTrue);
      expect(command.name, isNull);
    });

    test('returns help mode for --help', () {
      final command = parser.parse(const ['--help']);

      expect(command.showHelp, isTrue);
      expect(command.name, isNull);
    });

    test('returns help mode for -h', () {
      final command = parser.parse(const ['-h']);

      expect(command.showHelp, isTrue);
      expect(command.name, isNull);
    });

    test('normalizes aliases and parses check options', () {
      final command = parser.parse([
        'c',
        '--path',
        'example',
        '--exclude-pattern',
        '*.g.dart',
        '--exclude-folder',
        'build',
        '--no-details',
        '--interactive',
      ]);

      expect(command.name, 'check');
      expect(command.showHelp, isFalse);
      expect(command.checkPath, 'example');
      expect(command.excludePatterns, ['*.g.dart']);
      expect(command.excludeFolders, ['build']);
      expect(command.showDetails, isFalse);
      expect(command.checkInteractive, isTrue);
    });

    test('parses get-all alias and flags', () {
      final command = parser.parse([
        'ga',
        '--no-tree',
        '--fvm',
      ]);

      expect(command.name, 'get-all');
      expect(command.getAllTreeView, isFalse);
      expect(command.getAllUseFvm, isTrue);
    });
  });
}
