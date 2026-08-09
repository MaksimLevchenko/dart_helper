import 'dart:async';

import 'package:dart_helper_cli/src/utils/ansi.dart';
import 'package:dart_helper_cli/src/utils/folder_tree/tree_formatters.dart';
import 'package:dart_helper_cli/src/utils/folder_tree/tree_model_builder.dart';
import 'package:dart_helper_cli/src/utils/folder_tree_printer.dart';
import 'package:test/test.dart';

void main() {
  group('FolderTreePrinter helpers', () {
    setUp(() {
      Ansi.enabled = false;
    });

    tearDown(() {
      Ansi.enabled = true;
    });

    test('builds a tree model from flat project paths', () {
      final tree = buildTreeModel('D:\\workspace', {
        'workspace\\app_one': true,
        'workspace\\packages\\feature': false,
      });

      expect(tree.keys, contains('workspace'));
      final workspace = tree['workspace'] as Map<String, dynamic>;
      expect(workspace.keys, contains('app_one'));
      expect(workspace.keys, contains('packages'));
    });

    test('normalizes mixed map values when building a tree', () {
      final tree = buildTreeModel('workspace', {
        'workspace\\app': true,
        'workspace\\packages\\feature': <String, bool>{'__result': false},
      });

      final workspace = tree['workspace'] as Map<String, dynamic>;
      final packages = workspace['packages'] as Map<String, dynamic>;
      final feature = packages['feature'] as Map<String, dynamic>;

      expect(feature['__result'], isFalse);
      expect(feature['__isProject'], isTrue);
    });

    test('summary and progress helpers build expected text', () {
      final summaryLines = buildSummaryLines({
        'app': true,
        'feature': false,
      });
      final progressLine = buildProgressLine('feature', 1, 2, false);

      expect(summaryLines, contains('Success rate: 50%'));
      expect(summaryLines.join('\n'), contains('Failed: 1'));
      expect(progressLine, contains('[1/2]'));
      expect(progressLine, contains('feature'));
    });

    test('public printer prints tree without throwing', () async {
      final printed = <String>[];

      await runZoned(
        () async {
          FolderTreePrinter.printProjectTree('workspace', {
            'workspace\\app': true,
            'workspace\\packages\\feature': false,
          });
        },
        zoneSpecification: ZoneSpecification(
          print: (_, __, ___, line) {
            printed.add(line);
          },
        ),
      );

      expect(printed, isNotEmpty);
      expect(printed.join('\n'), contains('workspace'));
    });
  });
}
