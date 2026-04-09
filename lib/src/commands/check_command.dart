import 'dart:io';

export 'check_scanner.dart';

import 'check_scanner.dart';

class CheckCommand {
  final UnusedFileScanner _scanner = UnusedFileScanner();

  CheckCommand();

  Future<int> execute() async {
    try {
      await executeWithResult();
      return 0;
    } catch (_) {
      return 1;
    }
  }

  Future<UnusedFileResult> executeWithResult({
    String? projectPath,
    List<String> excludePatterns = const [],
    List<String> excludeFolders = const [],
    bool showDetails = true,
  }) async {
    try {
      final path = projectPath ?? Directory.current.path;

      print('🚀 Starting unused files analysis...');
      print('📂 Project path: $path');
      print('');

      final result = await _scanner.scanProject(
        projectPath: path,
        excludePatterns: excludePatterns,
        excludeFolders: excludeFolders,
      );

      _printResults(result, showDetails);

      return result;
    } catch (e) {
      print('❌ Error during analysis: $e');
      rethrow;
    }
  }

  void _printResults(UnusedFileResult result, bool showDetails) {
    print('============================================================');
    print('📊 UNUSED FILES ANALYSIS');
    print('============================================================');
    print('Scanned root: ${result.projectPath}');
    print('Total files scanned: ${result.totalFiles}');
    print('Files definitely used: ${result.usedFiles}');
    print('Total lines in used files: ${result.usedLineCount}');
    print('Files definitely unused: ${result.unusedCount}');
    print('============================================================');

    if (result.warnings.isNotEmpty) {
      print('⚠️ WARNINGS (${result.warningCount})');
      for (final warning in result.warnings) {
        print('   - $warning');
      }
      print('--------------------------------------------------');
    }

    if (result.unreadableFiles.isNotEmpty) {
      print('⚠️ Skipped unreadable files: ${result.unreadableFiles.length}');
      for (final file in result.unreadableFiles) {
        print('   - ${_relativePath(file, result.projectPath)}');
      }
      print('--------------------------------------------------');
    }

    if (result.unusedCount > 0) {
      print('🗑️ UNUSED FILES (safe to remove) 🔻');

      if (showDetails) {
        for (final file in result.unusedFiles) {
          print('   - 📄 ${_relativePath(file, result.projectPath)}');
        }
      } else {
        print('   ${result.unusedCount} files found');
      }

      print('--------------------------------------------------');
      print('💡 These files are NOT imported/exported/referenced anywhere.');
      print('💡 They are safe to delete after a final manual review.');
      print('💾 Total size of unused files: ${result.formattedSize}');
      print('--------------------------------------------------');
    } else {
      print('🎉 No unused files found! Your project is clean.');
    }

    print('');
  }

  Future<void> interactiveCleanup(UnusedFileResult result) async {
    if (result.unusedCount == 0) {
      print('🎉 No files to clean up!');
      return;
    }

    print('');
    print('🤔 Would you like to delete these unused files? (y/N): ');

    final input = stdin.readLineSync();
    if (input?.toLowerCase() == 'y' || input?.toLowerCase() == 'yes') {
      await _deleteUnusedFiles(result.unusedFiles, result.projectPath);
    } else {
      print('👍 Files kept. You can review and delete them manually.');
    }
  }

  Future<void> _deleteUnusedFiles(
    List<String> unusedFiles,
    String projectPath,
  ) async {
    print('🗑️ Deleting unused files...');

    var deletedCount = 0;
    for (final filePath in unusedFiles) {
      try {
        final file = File(filePath);
        await file.delete();
        print('   ✅ Deleted: ${_relativePath(filePath, projectPath)}');
        deletedCount++;
      } catch (e) {
        print(
          '   ❌ Failed to delete: ${_relativePath(filePath, projectPath)} - $e',
        );
      }
    }

    print('');
    print(
      '🎉 Cleanup completed! Deleted $deletedCount out of ${unusedFiles.length} files.',
    );
  }

  String _relativePath(String filePath, String basePath) {
    final normalizedFile = File(filePath).absolute.path;
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
}
