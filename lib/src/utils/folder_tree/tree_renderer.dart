import '../ansi.dart';
import 'tree_model_builder.dart';

const String folderProcessedIcon = '✅';
const String folderUnprocessedIcon = '⏳';
const String folderIcon = '📦';
const String verticalLine = '│';
const String horizontalLine = '├── ';
const String lastItem = '└── ';
const String spacing = '    ';

List<String> renderTreeLines(
  Map<String, dynamic> node, {
  String prefix = '',
  bool isRoot = true,
  bool showStatus = true,
  bool colorOutput = true,
}) {
  final lines = <String>[];
  final entries = node.entries.where((entry) => !entry.key.startsWith('__')).toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  for (var index = 0; index < entries.length; index++) {
    final entry = entries[index];
    final key = entry.key;
    final value = entry.value;

    if (value is! Map<String, dynamic>) {
      continue;
    }

    final isLast = index == entries.length - 1;
    final isProject = value['__isProject'] == true;

    var connector = '';
    var nextPrefix = prefix;

    if (!isRoot) {
      connector = isLast ? lastItem : horizontalLine;
      nextPrefix = prefix + (isLast ? spacing : '$verticalLine   ');
    }

    var icon = folderIcon;
    var displayName = key;
    var color = '';
    var resetColor = '';
    final useColor = colorOutput && Ansi.enabled;

    if (useColor) {
      resetColor = Ansi.reset;
    }

    if (isProject) {
      final success = (value['__result'] as bool?) ?? false;
      icon = showStatus
          ? (success ? folderProcessedIcon : folderUnprocessedIcon)
          : folderIcon;
      if (useColor) {
        color = success ? Ansi.green : Ansi.red;
      }
    } else {
      displayName = '$key/';
      if (useColor) {
        color = Ansi.blue;
      }
    }

    lines.add('$prefix$connector$color$icon $displayName$resetColor');

    final childNodes = <String, dynamic>{};
    for (final childEntry in value.entries) {
      if (childEntry.key.startsWith('__')) {
        continue;
      }

      if (childEntry.value is Map) {
        childNodes[childEntry.key] =
            ensureMapStringDynamic(childEntry.value as Map);
      }
    }

    if (childNodes.isNotEmpty) {
      lines.addAll(
        renderTreeLines(
          childNodes,
          prefix: nextPrefix,
          isRoot: false,
          showStatus: showStatus,
          colorOutput: colorOutput,
        ),
      );
    }
  }

  return lines;
}
