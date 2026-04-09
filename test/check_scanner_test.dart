import 'dart:io';

import 'package:dart_helper_cli/src/commands/check_scanner.dart';
import 'package:test/test.dart';

void main() {
  group('UnusedFileScanner', () {
    late Directory tempDir;
    late UnusedFileScanner scanner;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('dart_helper_check_');
      scanner = UnusedFileScanner();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('tracks relative imports, exports, and parts', () async {
      _writeFile(
        _path(tempDir, ['app', 'pubspec.yaml']),
        'name: app\n',
      );
      _writeFile(
        _path(tempDir, ['app', 'lib', 'main.dart']),
        '''
import 'src/feature.dart';

void main() {}
''',
      );
      _writeFile(
        _path(tempDir, ['app', 'lib', 'src', 'feature.dart']),
        '''
import '../utils.dart';
export 'feature_public.dart';
part 'feature_part.dart';

class Feature {}
''',
      );
      _writeFile(
        _path(tempDir, ['app', 'lib', 'src', 'feature_part.dart']),
        '''
part of 'feature.dart';

class FeaturePart {}
''',
      );
      _writeFile(
        _path(tempDir, ['app', 'lib', 'src', 'feature_public.dart']),
        'class FeaturePublic {}\n',
      );
      _writeFile(
        _path(tempDir, ['app', 'lib', 'utils.dart']),
        'class Utils {}\n',
      );
      _writeFile(
        _path(tempDir, ['app', 'lib', 'unused.dart']),
        'class Unused {}\n',
      );

      final result = await scanner.scanProject(projectPath: tempDir.path);

      expect(
        result.unusedFiles.map((path) => _relative(path, result.projectPath)),
        contains(
            'app${Platform.pathSeparator}lib${Platform.pathSeparator}unused.dart'),
      );
      expect(result.unusedCount, 1);
      expect(result.warnings, isEmpty);
    });

    test('resolves package imports between workspace packages', () async {
      _writeFile(
        _path(tempDir, ['workspace', 'app', 'pubspec.yaml']),
        'name: app\n',
      );
      _writeFile(
        _path(tempDir, ['workspace', 'app', 'lib', 'main.dart']),
        '''
import 'package:shared_pkg/shared.dart';

void main() {}
''',
      );
      _writeFile(
        _path(tempDir, ['workspace', 'shared_pkg', 'pubspec.yaml']),
        'name: shared_pkg\n',
      );
      _writeFile(
        _path(tempDir, ['workspace', 'shared_pkg', 'lib', 'shared.dart']),
        '''
import 'src/helper.dart';

class Shared {}
''',
      );
      _writeFile(
        _path(
            tempDir, ['workspace', 'shared_pkg', 'lib', 'src', 'helper.dart']),
        'class Helper {}\n',
      );
      _writeFile(
        _path(tempDir, ['workspace', 'shared_pkg', 'lib', 'unused.dart']),
        'class SharedUnused {}\n',
      );

      final result = await scanner.scanProject(
        projectPath: _path(tempDir, ['workspace']),
      );

      expect(
        result.unusedFiles.map((path) => _relative(path, result.projectPath)),
        contains(
            'shared_pkg${Platform.pathSeparator}lib${Platform.pathSeparator}unused.dart'),
      );
      expect(result.unusedCount, 1);
      expect(result.warnings, isEmpty);
    });

    test(
        'treats test files as entry points and reports unresolved local imports',
        () async {
      _writeFile(
        _path(tempDir, ['app', 'pubspec.yaml']),
        'name: app\n',
      );
      _writeFile(
        _path(tempDir, ['app', 'lib', 'main.dart']),
        '''
import 'missing.dart';

void main() {}
''',
      );
      _writeFile(
        _path(tempDir, ['app', 'test', 'app_test.dart']),
        '''
import '../lib/main.dart';

test('smoke', () {
  main();
});
''',
      );

      final result = await scanner.scanProject(projectPath: tempDir.path);

      expect(result.unusedCount, 0);
      expect(result.warnings, isNotEmpty);
      expect(
        result.warnings.any((warning) => warning.contains('Could not resolve')),
        isTrue,
      );
    });

    test('applies custom exclude patterns during file discovery', () async {
      _writeFile(
        _path(tempDir, ['app', 'pubspec.yaml']),
        'name: app\n',
      );
      _writeFile(
        _path(tempDir, ['app', 'lib', 'main.dart']),
        'void main() {}\n',
      );
      _writeFile(
        _path(tempDir, ['app', 'lib', 'unused.gen.dart']),
        'class GeneratedUnused {}\n',
      );
      _writeFile(
        _path(tempDir, ['app', 'lib', 'unused.dart']),
        'class Unused {}\n',
      );

      final result = await scanner.scanProject(
        projectPath: tempDir.path,
        excludePatterns: const ['*.gen.dart'],
      );

      final relativeUnused =
          result.unusedFiles.map((path) => _relative(path, result.projectPath));

      expect(
        relativeUnused,
        isNot(
          contains(
            'app${Platform.pathSeparator}lib${Platform.pathSeparator}unused.gen.dart',
          ),
        ),
      );
      expect(
        relativeUnused,
        contains(
          'app${Platform.pathSeparator}lib${Platform.pathSeparator}unused.dart',
        ),
      );
    });
  });
}

void _writeFile(String path, String content) {
  final file = File(path);
  file.createSync(recursive: true);
  file.writeAsStringSync(content);
}

String _path(Directory root, List<String> segments) {
  return [root.path, ...segments].join(Platform.pathSeparator);
}

String _relative(String absolutePath, String basePath) {
  final normalizedFile = File(absolutePath).absolute.path;
  final normalizedBase = Directory(basePath).absolute.path;

  if (normalizedFile == normalizedBase) {
    return '.';
  }

  final baseWithSeparator = normalizedBase.endsWith(Platform.pathSeparator)
      ? normalizedBase
      : '$normalizedBase${Platform.pathSeparator}';

  if (normalizedFile.startsWith(baseWithSeparator)) {
    return normalizedFile.substring(baseWithSeparator.length);
  }

  return normalizedFile;
}
