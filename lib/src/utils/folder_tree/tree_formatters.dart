import 'dart:io';

import '../ansi.dart';

String createProgressBar(int current, int total, {int width = 20}) {
  if (total == 0) {
    return '░' * width;
  }

  final filled = (current * width / total).round();
  final empty = width - filled;
  return '█' * filled + '░' * empty;
}

String buildProgressLine(String projectName, int current, int total, bool success) {
  final percentage = (current * 100 / total).round();
  final progressBar = createProgressBar(current, total);
  final status = success ? '✅' : '❌';
  return '\r${Ansi.sequence(Ansi.clearLine)}$status [$current/$total] '
      '$progressBar $percentage% - $projectName';
}

List<String> buildSectionHeaderLines(String title, {String emoji = '📋'}) {
  return [
    '',
    Ansi.wrap('$emoji $title', Ansi.cyan),
    Ansi.wrap('─' * (title.length + 3), Ansi.cyan),
  ];
}

List<String> buildSummaryLines(Map<String, dynamic> results) {
  final total = results.length;
  final successful = results.values.where((value) => value == true).length;
  final failed = total - successful;
  final lines = <String>[];

  if (failed > 0) {
    lines.add(Ansi.wrap('❌ Failed: $failed', Ansi.red));
  }

  lines.add('');
  final percentage = total > 0 ? (successful * 100 / total).round() : 0;
  lines.add('Success rate: $percentage%');

  if (failed == 0) {
    lines.add(Ansi.wrap('🎉 All projects processed successfully!', Ansi.green));
  }

  return lines;
}

List<String> buildFoundProjectsLines(List<String> projects, String basePath) {
  final lines = <String>[
    Ansi.wrap('📁 Found ${projects.length} projects:', Ansi.green),
  ];

  for (var index = 0; index < projects.length; index++) {
    final project = projects[index];
    final relativePath = getRelativePath(project, basePath);
    final isLast = index == projects.length - 1;
    final connector = isLast ? '└── ' : '├── ';
    lines.add('   $connector📁 ${relativePath.isEmpty ? '.' : relativePath}');
  }

  return lines;
}

String getRelativePath(String fullPath, String basePath) {
  if (fullPath == basePath) {
    return '';
  }

  if (fullPath.startsWith(basePath)) {
    return fullPath.substring(basePath.length).replaceFirst(
          RegExp('^[${RegExp.escape(Platform.pathSeparator)}]+'),
          '',
        );
  }

  return fullPath;
}

String getLastSegment(String path) {
  final segments =
      path.split(Platform.pathSeparator).where((segment) => segment.isNotEmpty).toList();
  return segments.isNotEmpty ? segments.last : 'root';
}
