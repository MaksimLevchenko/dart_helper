import 'dart:io';

class ProjectDiscovery {
  static const List<String> defaultExcludedFolders = [
    'build',
    'ios',
    'android',
    'web',
    'linux',
    'macos',
    'windows',
    '.dart_tool',
    '.git',
    '.github',
    '.vscode',
    '.idea',
    '.fvm',
    'node_modules',
    '.pub-cache',
    '.gradle',
    '.m2',
    'DerivedData',
    'Pods',
    'doc',
    'docs',
    'documentation',
  ];

  final List<String> _excludedFolders;

  const ProjectDiscovery({
    List<String> excludedFolders = defaultExcludedFolders,
  }) : _excludedFolders = excludedFolders;

  Future<List<String>> findDartProjects(Directory directory) async {
    final projects = <String>[];
    final visited = <String>{};

    Future<void> searchRecursively(Directory dir) async {
      try {
        final canonicalPath = dir.absolute.path;
        if (!visited.add(canonicalPath)) {
          return;
        }

        final List<FileSystemEntity> entities;
        try {
          entities = await dir.list().toList();
        } catch (_) {
          return;
        }

        final pubspecFile =
            File('${dir.path}${Platform.pathSeparator}pubspec.yaml');
        if (await pubspecFile.exists()) {
          projects.add(dir.absolute.path);
        }

        for (final entity in entities) {
          if (entity is! Directory) {
            continue;
          }

          final dirName = entity.path.split(Platform.pathSeparator).last;
          if (_excludedFolders.contains(dirName)) {
            continue;
          }

          await searchRecursively(entity);
        }
      } catch (_) {
        // Ignore inaccessible directories.
      }
    }

    await searchRecursively(directory);
    return projects;
  }
}
