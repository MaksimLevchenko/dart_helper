import 'dart:io';

import 'path_utils.dart';

class WorkspaceWalkResult {
  final List<String> dartFiles;
  final List<String> pubspecFiles;

  WorkspaceWalkResult({
    required this.dartFiles,
    required this.pubspecFiles,
  });
}

class WorkspaceWalker {
  Future<WorkspaceWalkResult> walk(
    Directory directory, {
    required List<String> excludePatterns,
    required List<String> excludeFolders,
    required Set<String> warnings,
  }) async {
    final dartFiles = <String>[];
    final pubspecFiles = <String>[];

    await _walkWorkspace(
      directory,
      onDartFile: (filePath) => dartFiles.add(filePath),
      onPubspecFile: (filePath) => pubspecFiles.add(filePath),
      excludePatterns: excludePatterns,
      excludeFolders: excludeFolders,
      warnings: warnings,
    );

    return WorkspaceWalkResult(
      dartFiles: dartFiles,
      pubspecFiles: pubspecFiles,
    );
  }

  Future<void> _walkWorkspace(
    Directory directory, {
    required void Function(String filePath) onDartFile,
    required void Function(String filePath) onPubspecFile,
    required List<String> excludePatterns,
    required List<String> excludeFolders,
    required Set<String> warnings,
  }) async {
    if (shouldExcludeByFolder(directory.path, excludeFolders)) {
      return;
    }

    List<FileSystemEntity> entities;
    try {
      entities = await directory.list(followLinks: false).toList();
    } catch (e) {
      warnings.add(
        'Skipped directory "${directory.path}" because it could not be read: $e',
      );
      return;
    }

    for (final entity in entities) {
      if (entity is Directory) {
        await _walkWorkspace(
          entity,
          onDartFile: onDartFile,
          onPubspecFile: onPubspecFile,
          excludePatterns: excludePatterns,
          excludeFolders: excludeFolders,
          warnings: warnings,
        );
        continue;
      }

      if (entity is! File) {
        continue;
      }

      if (shouldExcludeByFolder(entity.path, excludeFolders)) {
        continue;
      }

      final entityFileName = fileName(entity.path);
      if (entityFileName == 'pubspec.yaml') {
        onPubspecFile(normalizeExistingPath(entity.path));
        continue;
      }

      if (!entity.path.endsWith('.dart')) {
        continue;
      }

      if (shouldExcludeByPattern(entity.path, excludePatterns)) {
        continue;
      }

      onDartFile(normalizeExistingPath(entity.path));
    }
  }
}
