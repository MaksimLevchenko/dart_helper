import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';

import 'check/dependency_extractor.dart';
import 'check/package_root_index.dart';
import 'check/path_utils.dart';
import 'check/unused_file_result.dart';
import 'check/workspace_walker.dart';

export 'check/unused_file_result.dart';

class UnusedFileScanner {
  static const List<String> _defaultExcludePatterns = [
    '*.g.dart',
    '*.gr.dart',
    '*.freezed.dart',
    '*.mocks.dart',
    'generated_plugin_registrant.dart',
    'firebase_options.dart',
  ];

  static const List<String> _defaultExcludeFolders = [
    'generated',
    '.dart_tool',
    'build',
    '.fvm',
    '.git',
    '_client',
    '_server',
    'windows',
  ];

  final WorkspaceWalker _workspaceWalker;
  final DependencyExtractor _dependencyExtractor;

  UnusedFileScanner({
    WorkspaceWalker? workspaceWalker,
    DependencyExtractor? dependencyExtractor,
  })  : _workspaceWalker = workspaceWalker ?? WorkspaceWalker(),
        _dependencyExtractor = dependencyExtractor ?? DependencyExtractor();

  Future<UnusedFileResult> scanProject({
    String? projectPath,
    List<String> excludePatterns = const [],
    List<String> excludeFolders = const [],
  }) async {
    final requestedPath = projectPath ?? Directory.current.path;
    final requestedDir = Directory(requestedPath);

    if (!requestedDir.existsSync()) {
      throw ArgumentError('Project directory does not exist: $requestedPath');
    }

    final analysisRoot = resolveAnalysisRootDirectory(requestedDir);
    final warnings = <String>{};

    final walkResult = await _workspaceWalker.walk(
      analysisRoot,
      excludePatterns: [..._defaultExcludePatterns, ...excludePatterns],
      excludeFolders: [..._defaultExcludeFolders, ...excludeFolders],
      warnings: warnings,
    );

    final packageRootIndex = PackageRootIndex.fromPubspecFiles(
      walkResult.pubspecFiles,
      warnings,
    );
    final fileOwners = packageRootIndex.ownersFor(walkResult.dartFiles);
    final dependencyMap = <String, Set<String>>{};
    final entryPoints = <String>{};
    final lineCounts = <String, int>{};
    final unreadableFiles = <String>{};

    for (final filePath in walkResult.dartFiles) {
      final content = await _readFileContent(filePath, warnings);
      if (content == null) {
        unreadableFiles.add(filePath);
        continue;
      }

      lineCounts[filePath] = _countLines(content);

      final unit = parseString(
        content: content,
        path: filePath,
        throwIfDiagnostics: false,
      ).unit;

      final analysis = _dependencyExtractor.analyze(
        filePath: filePath,
        unit: unit,
        fileOwners: fileOwners,
        packageRootIndex: packageRootIndex,
        warnings: warnings,
      );

      dependencyMap[filePath] = analysis.dependencies;

      if (analysis.isEntryPoint || analysis.isProtectedPublicExportBarrel) {
        entryPoints.add(filePath);
      }
    }

    final usedFiles = _dependencyExtractor.findUsedFiles(
      dependencyMap,
      entryPoints,
    );
    final unusedFiles = walkResult.dartFiles
        .where((filePath) =>
            !usedFiles.contains(filePath) &&
            !unreadableFiles.contains(filePath))
        .toList();

    final usedLineCount = _sumLineCounts(usedFiles, lineCounts);
    final totalSize = await _calculateTotalSize(unusedFiles);

    return UnusedFileResult(
      projectPath: analysisRoot.path,
      unusedFiles: unusedFiles,
      totalFiles: walkResult.dartFiles.length,
      usedFiles: usedFiles.length,
      usedLineCount: usedLineCount,
      totalSizeKb: totalSize / 1024,
      warnings: warnings.toList(),
      unreadableFiles: unreadableFiles.toList(),
    );
  }

  Future<String?> _readFileContent(
    String filePath,
    Set<String> warnings,
  ) async {
    try {
      return await File(filePath).readAsString();
    } catch (e) {
      warnings.add('Could not read ${prettyPath(filePath)}: $e');
      return null;
    }
  }

  Future<int> _calculateTotalSize(List<String> files) async {
    var totalSize = 0;

    for (final filePath in files) {
      try {
        final stat = await File(filePath).stat();
        totalSize += stat.size;
      } catch (_) {
        // Ignore file size errors. They are already surfaced as warnings.
      }
    }

    return totalSize;
  }

  int _countLines(String content) {
    if (content.isEmpty) {
      return 0;
    }

    return const LineSplitter().convert(content).length;
  }

  int _sumLineCounts(
    Set<String> files,
    Map<String, int> lineCounts,
  ) {
    var total = 0;
    for (final filePath in files) {
      total += lineCounts[filePath] ?? 0;
    }
    return total;
  }
}
