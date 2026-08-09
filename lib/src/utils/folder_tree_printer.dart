import 'folder_tree/tree_formatters.dart';
import 'folder_tree/tree_model_builder.dart';
import 'folder_tree/tree_renderer.dart';

class FolderTreePrinter {
  static void printProjectTree(
    String basePath,
    Map<String, dynamic> results, {
    bool showStatus = true,
    bool colorOutput = true,
  }) {
    if (results.isEmpty) {
      return;
    }

    final tree = buildTreeModel(basePath, results);
    final lines = renderTreeLines(
      tree,
      showStatus: showStatus,
      colorOutput: colorOutput,
    );

    for (final line in lines) {
      print(line);
    }
  }

  static void printSummary(Map<String, dynamic> results) {
    for (final line in buildSummaryLines(results)) {
      print(line);
    }
  }

  static void printProgress(
    String projectName,
    int current,
    int total,
    bool success,
  ) {
    print(buildProgressLine(projectName, current, total, success));
  }

  static void printSectionHeader(String title, {String emoji = '📋'}) {
    for (final line in buildSectionHeaderLines(title, emoji: emoji)) {
      print(line);
    }
  }

  static void printFoundProjects(List<String> projects, String basePath) {
    for (final line in buildFoundProjectsLines(projects, basePath)) {
      print(line);
    }
  }
}
