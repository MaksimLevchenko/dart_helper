import 'dart:io';

class ProjectPathFormatter {
  const ProjectPathFormatter();

  String resolveSearchDirectory({
    required String startDir,
    String? path,
  }) {
    return path != null && path != '.'
        ? Directory(path).absolute.path
        : startDir;
  }

  String relativeProjectPath(String fullPath, String basePath) {
    final mainDirName = basePath.split(Platform.pathSeparator).last;

    if (fullPath == basePath) {
      return mainDirName;
    }

    if (fullPath.startsWith(basePath)) {
      final remainder = fullPath.substring(basePath.length).replaceFirst(
            RegExp('^[${RegExp.escape(Platform.pathSeparator)}]+'),
            '',
          );
      return remainder.isEmpty
          ? mainDirName
          : '$mainDirName${Platform.pathSeparator}$remainder';
    }

    return fullPath;
  }

  String projectName(String projectPath) {
    return projectPath.split(Platform.pathSeparator).last;
  }
}
