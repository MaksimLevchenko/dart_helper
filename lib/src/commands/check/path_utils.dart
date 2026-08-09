import 'dart:io';

String comparisonKey(String value) {
  return Platform.isWindows ? value.toLowerCase() : value;
}

String normalizeExistingPath(String path) {
  try {
    final file = File(path);
    if (file.existsSync()) {
      return file.resolveSymbolicLinksSync();
    }

    final directory = Directory(path);
    if (directory.existsSync()) {
      return directory.resolveSymbolicLinksSync();
    }
  } catch (_) {
    // Fall back to absolute path normalization below.
  }

  return File(path).absolute.path;
}

bool isWithin(String childPath, String parentPath) {
  final child = comparisonKey(normalizeExistingPath(childPath));
  final parent = comparisonKey(normalizeExistingPath(parentPath));

  if (child == parent) {
    return true;
  }

  final parentWithSeparator = parent.endsWith(Platform.pathSeparator)
      ? parent
      : '$parent${Platform.pathSeparator}';
  return child.startsWith(parentWithSeparator);
}

List<String> pathSegments(String path) {
  final normalized = comparisonKey(normalizeExistingPath(path));
  return normalized
      .split(RegExp(r'[\\/]+'))
      .where((segment) => segment.isNotEmpty)
      .toList();
}

String fileName(String path) {
  final normalized = normalizeExistingPath(path);
  return normalized.split(Platform.pathSeparator).last;
}

String prettyPath(String path, {String? basePath}) {
  final normalized = normalizeExistingPath(path);
  final base = comparisonKey(
    normalizeExistingPath(basePath ?? Directory.current.path),
  );
  final normalizedKey = comparisonKey(normalized);

  if (normalizedKey == base) {
    return '.';
  }

  final baseWithSeparator = base.endsWith(Platform.pathSeparator)
      ? base
      : '$base${Platform.pathSeparator}';
  if (normalizedKey.startsWith(baseWithSeparator)) {
    return normalized.substring(
      base.length + (base.endsWith(Platform.pathSeparator) ? 0 : 1),
    );
  }

  return normalized;
}

String relativePath(String filePath, String basePath) {
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

bool shouldExcludeByFolder(String path, List<String> excludeFolders) {
  final segments = pathSegments(path);
  for (final folder in excludeFolders) {
    final folderKey = comparisonKey(folder);
    if (segments.any((segment) => matchesExcludedFolderSegment(
          segment,
          folderKey,
        ))) {
      return true;
    }
  }
  return false;
}

bool matchesExcludedFolderSegment(String segment, String folderKey) {
  if (segment == folderKey) {
    return true;
  }

  if (folderKey == '_server' || folderKey == '_client') {
    return segment.endsWith(folderKey);
  }

  return false;
}

bool shouldExcludeByPattern(String path, List<String> excludePatterns) {
  final normalizedFileName = fileName(path);

  for (final pattern in excludePatterns) {
    if (pattern.startsWith('*') &&
        normalizedFileName.endsWith(pattern.substring(1))) {
      return true;
    }

    if (pattern.endsWith('*') &&
        normalizedFileName
            .startsWith(pattern.substring(0, pattern.length - 1))) {
      return true;
    }

    if (normalizedFileName == pattern) {
      return true;
    }
  }

  return false;
}
