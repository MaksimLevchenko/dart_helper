import 'dart:io';

import 'path_utils.dart';

Directory resolveAnalysisRootDirectory(Directory requestedDir) {
  final ancestorPackageRoot =
      _findNearestPackageRootAncestor(requestedDir.path);
  if (ancestorPackageRoot != null) {
    return ancestorPackageRoot;
  }

  return Directory(normalizeExistingPath(requestedDir.path));
}

Directory? _findNearestPackageRootAncestor(String path) {
  var current = Directory(normalizeExistingPath(path));

  while (true) {
    final pubspec =
        File('${current.path}${Platform.pathSeparator}pubspec.yaml');
    if (pubspec.existsSync()) {
      return Directory(normalizeExistingPath(current.path));
    }

    final parent = current.parent;
    if (parent.path == current.path) {
      return null;
    }

    current = Directory(normalizeExistingPath(parent.path));
  }
}

class PackageRoot {
  final String path;
  final String? packageName;

  PackageRoot({
    required this.path,
    required this.packageName,
  });

  String? get normalizedPackageName => packageName;

  String? get normalizedPackageNameKey =>
      packageName == null ? null : comparisonKey(packageName!);

  String get libDirectoryPath => '$path${Platform.pathSeparator}lib';
}

class PackageRootIndex {
  final List<PackageRoot> _roots;
  final Map<String, List<PackageRoot>> _rootsByName;

  PackageRootIndex._(this._roots, this._rootsByName);

  factory PackageRootIndex.fromPubspecFiles(
    List<String> pubspecFiles,
    Set<String> warnings,
  ) {
    final roots = <PackageRoot>[];
    final seenPaths = <String>{};

    for (final pubspecPath in pubspecFiles) {
      final rootPath =
          normalizeExistingPath(Directory(pubspecPath).parent.path);
      if (!seenPaths.add(rootPath)) {
        continue;
      }

      final packageName = _readPackageName(pubspecPath, warnings);
      roots.add(
        PackageRoot(
          path: rootPath,
          packageName: packageName,
        ),
      );
    }

    roots.sort((a, b) => b.path.length.compareTo(a.path.length));

    final rootsByName = <String, List<PackageRoot>>{};
    for (final root in roots) {
      final packageName = root.normalizedPackageName;
      if (packageName == null) {
        continue;
      }

      rootsByName.putIfAbsent(packageName, () => []).add(root);
    }

    return PackageRootIndex._(roots, rootsByName);
  }

  Map<String, PackageRoot?> ownersFor(Iterable<String> filePaths) {
    final owners = <String, PackageRoot?>{};
    for (final filePath in filePaths) {
      owners[filePath] = ownerOf(filePath);
    }
    return owners;
  }

  PackageRoot? ownerOf(String filePath) {
    PackageRoot? owner;

    for (final packageRoot in _roots) {
      if (isWithin(filePath, packageRoot.path)) {
        if (owner == null || packageRoot.path.length > owner.path.length) {
          owner = packageRoot;
        }
      }
    }

    return owner;
  }

  String? resolveReference({
    required String filePath,
    required String uri,
    required Map<String, PackageRoot?> fileOwners,
    required Set<String> warnings,
  }) {
    if (uri.startsWith('dart:')) {
      return null;
    }

    if (uri.startsWith('package:')) {
      return _resolvePackageUri(
        filePath: filePath,
        uri: uri,
        fileOwners: fileOwners,
        warnings: warnings,
      );
    }

    return _resolveRelativeUri(
      filePath: filePath,
      uri: uri,
      warnings: warnings,
    );
  }

  String? _resolvePackageUri({
    required String filePath,
    required String uri,
    required Map<String, PackageRoot?> fileOwners,
    required Set<String> warnings,
  }) {
    final packageUri = uri.substring('package:'.length);
    final parts = packageUri.split('/');
    if (parts.isEmpty || parts.first.isEmpty) {
      warnings.add('Invalid package URI "$uri" in ${prettyPath(filePath)}');
      return null;
    }

    final packageName = parts.first;
    final packageNameKey = comparisonKey(packageName);
    final owningRoot = fileOwners[normalizeExistingPath(filePath)];
    final matchingRoots = _rootsByName[packageNameKey];

    if (matchingRoots == null || matchingRoots.isEmpty) {
      return null;
    }

    PackageRoot? targetRoot;
    if (owningRoot?.normalizedPackageNameKey == packageNameKey) {
      targetRoot = owningRoot;
    } else if (matchingRoots.length == 1) {
      targetRoot = matchingRoots.single;
    } else {
      warnings.add(
        'Ambiguous package URI "$uri" in ${prettyPath(filePath)}; '
        'multiple package roots named "$packageName" were found.',
      );
      return null;
    }

    final resolvedTargetRoot = targetRoot!;
    final relativePath = parts.skip(1).join(Platform.pathSeparator);
    final candidatePath = relativePath.isEmpty
        ? resolvedTargetRoot.libDirectoryPath
        : '${resolvedTargetRoot.libDirectoryPath}${Platform.pathSeparator}$relativePath';

    final normalizedCandidate = normalizeExistingPath(candidatePath);
    if (File(normalizedCandidate).existsSync()) {
      return normalizedCandidate;
    }

    if (!normalizedCandidate.endsWith('.dart')) {
      final dartCandidate = '$normalizedCandidate.dart';
      if (File(dartCandidate).existsSync()) {
        return normalizeExistingPath(dartCandidate);
      }
    }

    warnings.add('Could not resolve "$uri" in ${prettyPath(filePath)}');
    return null;
  }

  String? _resolveRelativeUri({
    required String filePath,
    required String uri,
    required Set<String> warnings,
  }) {
    final baseDirectory = Directory(filePath).parent;
    final resolvedPath = File.fromUri(baseDirectory.uri.resolve(uri)).path;
    final normalizedPath = normalizeExistingPath(resolvedPath);

    if (File(normalizedPath).existsSync()) {
      return normalizedPath;
    }

    if (!normalizedPath.endsWith('.dart')) {
      final dartCandidate = '$normalizedPath.dart';
      if (File(dartCandidate).existsSync()) {
        return normalizeExistingPath(dartCandidate);
      }
    }

    warnings.add('Could not resolve "$uri" in ${prettyPath(filePath)}');
    return null;
  }
}

String? _readPackageName(String pubspecPath, Set<String> warnings) {
  try {
    final content = File(pubspecPath).readAsStringSync();
    final match = RegExp(
      r"""^\s*name\s*:\s*["']?([A-Za-z0-9_]+)["']?\s*$""",
      multiLine: true,
    ).firstMatch(content);
    if (match == null) {
      warnings.add('Could not determine package name from $pubspecPath');
      return null;
    }

    return match.group(1);
  } catch (e) {
    warnings.add('Could not read $pubspecPath: $e');
    return null;
  }
}
