import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

String _comparisonKey(String value) {
  return Platform.isWindows ? value.toLowerCase() : value;
}

class UnusedFileResult {
  final String projectPath;
  final List<String> unusedFiles;
  final int totalFiles;
  final int usedFiles;
  final double totalSizeKb;
  final List<String> warnings;
  final List<String> unreadableFiles;

  UnusedFileResult({
    required this.projectPath,
    required this.unusedFiles,
    required this.totalFiles,
    required this.usedFiles,
    required this.totalSizeKb,
    required this.warnings,
    required this.unreadableFiles,
  });

  int get unusedCount => unusedFiles.length;
  int get warningCount => warnings.length;
  String get formattedSize => '${totalSizeKb.toStringAsFixed(2)} KB';
}

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

    final analysisRoot = await _resolveAnalysisRoot(requestedDir);
    final warnings = <String>{};
    final dartFiles = <String>[];
    final pubspecFiles = <String>[];

    await _walkWorkspace(
      analysisRoot,
      onDartFile: (filePath) => dartFiles.add(filePath),
      onPubspecFile: (filePath) => pubspecFiles.add(filePath),
      excludePatterns: [..._defaultExcludePatterns, ...excludePatterns],
      excludeFolders: [..._defaultExcludeFolders, ...excludeFolders],
      warnings: warnings,
    );

    final packageRoots = _buildPackageRoots(pubspecFiles, warnings);
    final packageRootsByName = _groupPackageRootsByName(packageRoots);

    final fileOwners = <String, _PackageRoot?>{};
    for (final filePath in dartFiles) {
      fileOwners[filePath] = _findOwningPackageRoot(filePath, packageRoots);
    }

    final dependencyMap = <String, Set<String>>{};
    final entryPoints = <String>{};
    final unreadableFiles = <String>{};

    for (final filePath in dartFiles) {
      final content = await _readFileContent(filePath, warnings);
      if (content == null) {
        unreadableFiles.add(filePath);
        continue;
      }

      final unit = parseString(
        content: content,
        path: filePath,
        throwIfDiagnostics: false,
      ).unit;

      dependencyMap[filePath] = _extractDependencies(
        filePath: filePath,
        unit: unit,
        fileOwners: fileOwners,
        packageRootsByName: packageRootsByName,
        warnings: warnings,
      );

      if (_isEntryPoint(filePath, unit)) {
        entryPoints.add(filePath);
      }

      if (_isProtectedPublicExportBarrel(
        filePath: filePath,
        unit: unit,
        fileOwners: fileOwners,
      )) {
        entryPoints.add(filePath);
      }
    }

    final usedFiles = _findUsedFiles(dependencyMap, entryPoints);
    final unusedFiles = dartFiles
        .where((filePath) =>
            !usedFiles.contains(filePath) &&
            !unreadableFiles.contains(filePath))
        .toList();

    final totalSize = await _calculateTotalSize(unusedFiles);

    return UnusedFileResult(
      projectPath: analysisRoot.path,
      unusedFiles: unusedFiles,
      totalFiles: dartFiles.length,
      usedFiles: usedFiles.length,
      totalSizeKb: totalSize / 1024,
      warnings: warnings.toList(),
      unreadableFiles: unreadableFiles.toList(),
    );
  }

  Future<Directory> _resolveAnalysisRoot(Directory requestedDir) async {
    final ancestorPackageRoot =
        _findNearestPackageRootAncestor(requestedDir.path);
    if (ancestorPackageRoot != null) {
      return ancestorPackageRoot;
    }

    return Directory(_normalizeExistingPath(requestedDir.path));
  }

  Directory? _findNearestPackageRootAncestor(String path) {
    var current = Directory(_normalizeExistingPath(path));

    while (true) {
      final pubspec =
          File('${current.path}${Platform.pathSeparator}pubspec.yaml');
      if (pubspec.existsSync()) {
        return Directory(_normalizeExistingPath(current.path));
      }

      final parent = current.parent;
      if (parent.path == current.path) {
        return null;
      }

      current = Directory(_normalizeExistingPath(parent.path));
    }
  }

  Future<void> _walkWorkspace(
    Directory directory, {
    required void Function(String filePath) onDartFile,
    required void Function(String filePath) onPubspecFile,
    required List<String> excludePatterns,
    required List<String> excludeFolders,
    required Set<String> warnings,
  }) async {
    if (_shouldExcludeByFolder(directory.path, excludeFolders)) {
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

      if (_shouldExcludeByFolder(entity.path, excludeFolders)) {
        continue;
      }

      final fileName = _fileName(entity.path);
      if (fileName == 'pubspec.yaml') {
        onPubspecFile(_normalizeExistingPath(entity.path));
        continue;
      }

      if (!entity.path.endsWith('.dart')) {
        continue;
      }

      if (_shouldExcludeByPattern(entity.path, excludePatterns)) {
        continue;
      }

      onDartFile(_normalizeExistingPath(entity.path));
    }
  }

  List<_PackageRoot> _buildPackageRoots(
    List<String> pubspecFiles,
    Set<String> warnings,
  ) {
    final roots = <_PackageRoot>[];
    final seenPaths = <String>{};

    for (final pubspecPath in pubspecFiles) {
      final rootPath =
          _normalizeExistingPath(Directory(pubspecPath).parent.path);
      if (!seenPaths.add(rootPath)) {
        continue;
      }

      final packageName = _readPackageName(pubspecPath, warnings);
      roots.add(
        _PackageRoot(
          path: rootPath,
          packageName: packageName,
        ),
      );
    }

    roots.sort((a, b) => b.path.length.compareTo(a.path.length));
    return roots;
  }

  Map<String, List<_PackageRoot>> _groupPackageRootsByName(
    List<_PackageRoot> packageRoots,
  ) {
    final grouped = <String, List<_PackageRoot>>{};

    for (final root in packageRoots) {
      final packageName = root.normalizedPackageName;
      if (packageName == null) {
        continue;
      }

      grouped.putIfAbsent(packageName, () => []).add(root);
    }

    return grouped;
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

  _PackageRoot? _findOwningPackageRoot(
    String filePath,
    List<_PackageRoot> packageRoots,
  ) {
    _PackageRoot? owner;

    for (final packageRoot in packageRoots) {
      if (_isWithin(filePath, packageRoot.path)) {
        if (owner == null || packageRoot.path.length > owner.path.length) {
          owner = packageRoot;
        }
      }
    }

    return owner;
  }

  Set<String> _extractDependencies({
    required String filePath,
    required CompilationUnit unit,
    required Map<String, _PackageRoot?> fileOwners,
    required Map<String, List<_PackageRoot>> packageRootsByName,
    required Set<String> warnings,
  }) {
    final dependencies = <String>{};

    for (final directive in unit.directives) {
      if (directive is ImportDirective || directive is ExportDirective) {
        final namespaceDirective = directive as NamespaceDirective;
        _collectDirectiveUris(namespaceDirective).forEach((uri) {
          final resolved = _resolveReference(
            filePath: filePath,
            uri: uri,
            fileOwners: fileOwners,
            packageRootsByName: packageRootsByName,
            warnings: warnings,
          );
          if (resolved != null) {
            dependencies.add(resolved);
          }
        });
        continue;
      }

      if (directive is PartDirective) {
        final uri = directive.uri.stringValue;
        if (uri == null) {
          continue;
        }

        final resolved = _resolveReference(
          filePath: filePath,
          uri: uri,
          fileOwners: fileOwners,
          packageRootsByName: packageRootsByName,
          warnings: warnings,
        );
        if (resolved != null) {
          dependencies.add(resolved);
        }
      }
    }

    return dependencies;
  }

  Iterable<String> _collectDirectiveUris(NamespaceDirective directive) sync* {
    final mainUri = directive.uri.stringValue;
    if (mainUri != null) {
      yield mainUri;
    }

    for (final configuration in directive.configurations) {
      final configuredUri = configuration.uri.stringValue;
      if (configuredUri != null) {
        yield configuredUri;
      }
    }
  }

  String? _resolveReference({
    required String filePath,
    required String uri,
    required Map<String, _PackageRoot?> fileOwners,
    required Map<String, List<_PackageRoot>> packageRootsByName,
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
        packageRootsByName: packageRootsByName,
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
    required Map<String, _PackageRoot?> fileOwners,
    required Map<String, List<_PackageRoot>> packageRootsByName,
    required Set<String> warnings,
  }) {
    final packageUri = uri.substring('package:'.length);
    final parts = packageUri.split('/');
    if (parts.isEmpty || parts.first.isEmpty) {
      warnings.add('Invalid package URI "$uri" in ${_prettyPath(filePath)}');
      return null;
    }

    final packageName = parts.first;
    final packageNameKey = _comparisonKey(packageName);
    final owningRoot = fileOwners[_normalizeExistingPath(filePath)];
    final matchingRoots = packageRootsByName[packageNameKey];

    if (matchingRoots == null || matchingRoots.isEmpty) {
      return null;
    }

    _PackageRoot? targetRoot;
    if (owningRoot?.normalizedPackageNameKey == packageNameKey) {
      targetRoot = owningRoot;
    } else if (matchingRoots.length == 1) {
      targetRoot = matchingRoots.single;
    } else {
      warnings.add(
        'Ambiguous package URI "$uri" in ${_prettyPath(filePath)}; '
        'multiple package roots named "$packageName" were found.',
      );
      return null;
    }

    final resolvedTargetRoot = targetRoot!;
    final relativePath = parts.skip(1).join(Platform.pathSeparator);
    final candidatePath = relativePath.isEmpty
        ? resolvedTargetRoot.libDirectoryPath
        : '${resolvedTargetRoot.libDirectoryPath}${Platform.pathSeparator}$relativePath';

    final normalizedCandidate = _normalizeExistingPath(candidatePath);
    if (File(normalizedCandidate).existsSync()) {
      return normalizedCandidate;
    }

    if (!normalizedCandidate.endsWith('.dart')) {
      final dartCandidate = '$normalizedCandidate.dart';
      if (File(dartCandidate).existsSync()) {
        return _normalizeExistingPath(dartCandidate);
      }
    }

    warnings.add(
      'Could not resolve "$uri" in ${_prettyPath(filePath)}',
    );
    return null;
  }

  String? _resolveRelativeUri({
    required String filePath,
    required String uri,
    required Set<String> warnings,
  }) {
    final baseDirectory = Directory(filePath).parent;
    final resolvedPath = File.fromUri(baseDirectory.uri.resolve(uri)).path;
    final normalizedPath = _normalizeExistingPath(resolvedPath);

    if (File(normalizedPath).existsSync()) {
      return normalizedPath;
    }

    if (!normalizedPath.endsWith('.dart')) {
      final dartCandidate = '$normalizedPath.dart';
      if (File(dartCandidate).existsSync()) {
        return _normalizeExistingPath(dartCandidate);
      }
    }

    warnings.add(
      'Could not resolve "$uri" in ${_prettyPath(filePath)}',
    );
    return null;
  }

  bool _isEntryPoint(String filePath, CompilationUnit unit) {
    if (_hasTopLevelMain(unit)) {
      return true;
    }

    final fileName = _fileName(filePath);
    if (_isUnderTestFolder(filePath) || fileName.endsWith('_test.dart')) {
      return true;
    }

    return _containsTestHarnessCalls(unit);
  }

  bool _hasTopLevelMain(CompilationUnit unit) {
    for (final declaration in unit.declarations) {
      if (declaration is FunctionDeclaration &&
          declaration.name.lexeme == 'main') {
        return true;
      }
    }

    return false;
  }

  bool _containsTestHarnessCalls(CompilationUnit unit) {
    final visitor = _TestHarnessVisitor();
    unit.accept(visitor);
    return visitor.found;
  }

  bool _isProtectedPublicExportBarrel({
    required String filePath,
    required CompilationUnit unit,
    required Map<String, _PackageRoot?> fileOwners,
  }) {
    if (unit.declarations.isNotEmpty) {
      return false;
    }

    final hasExportDirective =
        unit.directives.any((directive) => directive is ExportDirective);
    if (!hasExportDirective) {
      return false;
    }

    final owningRoot = fileOwners[_normalizeExistingPath(filePath)];
    if (owningRoot == null) {
      return false;
    }

    final normalizedPath = _normalizeExistingPath(filePath);
    if (!_isWithin(normalizedPath, owningRoot.libDirectoryPath)) {
      return false;
    }

    final srcDirectory =
        '${owningRoot.libDirectoryPath}${Platform.pathSeparator}src';
    if (_isWithin(normalizedPath, srcDirectory)) {
      return false;
    }

    return true;
  }

  bool _isUnderTestFolder(String filePath) {
    final segments = _pathSegments(filePath);
    return segments.contains('test') || segments.contains('integration_test');
  }

  Future<String?> _readFileContent(
    String filePath,
    Set<String> warnings,
  ) async {
    try {
      return await File(filePath).readAsString();
    } catch (e) {
      warnings.add('Could not read ${_prettyPath(filePath)}: $e');
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

  bool _shouldExcludeByFolder(String path, List<String> excludeFolders) {
    final segments = _pathSegments(path);
    for (final folder in excludeFolders) {
      final folderKey = _comparisonKey(folder);
      if (segments.any((segment) => _matchesExcludedFolderSegment(
            segment,
            folderKey,
          ))) {
        return true;
      }
    }
    return false;
  }

  bool _matchesExcludedFolderSegment(String segment, String folderKey) {
    if (segment == folderKey) {
      return true;
    }

    if (folderKey == '_server' || folderKey == '_client') {
      return segment.endsWith(folderKey);
    }

    return false;
  }

  bool _shouldExcludeByPattern(String path, List<String> excludePatterns) {
    final fileName = _fileName(path);

    for (final pattern in excludePatterns) {
      if (pattern.startsWith('*') && fileName.endsWith(pattern.substring(1))) {
        return true;
      }

      if (pattern.endsWith('*') &&
          fileName.startsWith(pattern.substring(0, pattern.length - 1))) {
        return true;
      }

      if (fileName == pattern) {
        return true;
      }
    }

    return false;
  }

  bool _isWithin(String childPath, String parentPath) {
    final child = _comparisonKey(_normalizeExistingPath(childPath));
    final parent = _comparisonKey(_normalizeExistingPath(parentPath));

    if (child == parent) {
      return true;
    }

    final parentWithSeparator = parent.endsWith(Platform.pathSeparator)
        ? parent
        : '$parent${Platform.pathSeparator}';
    return child.startsWith(parentWithSeparator);
  }

  List<String> _pathSegments(String path) {
    final normalized = _comparisonKey(_normalizeExistingPath(path));
    return normalized
        .split(RegExp(r'[\\/]+'))
        .where((segment) => segment.isNotEmpty)
        .toList();
  }

  String _fileName(String path) {
    final normalized = _normalizeExistingPath(path);
    return normalized.split(Platform.pathSeparator).last;
  }

  String _prettyPath(String path) {
    final normalized = _normalizeExistingPath(path);
    final base = _comparisonKey(_normalizeExistingPath(Directory.current.path));
    final normalizedKey = _comparisonKey(normalized);

    if (normalizedKey == base) {
      return '.';
    }

    final baseWithSeparator = base.endsWith(Platform.pathSeparator)
        ? base
        : '$base${Platform.pathSeparator}';
    if (normalizedKey.startsWith(baseWithSeparator)) {
      return normalized.substring(
          base.length + (base.endsWith(Platform.pathSeparator) ? 0 : 1));
    }

    return normalized;
  }

  String _normalizeExistingPath(String path) {
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

  Set<String> _findUsedFiles(
    Map<String, Set<String>> dependencyMap,
    Set<String> entryPoints,
  ) {
    final usedFiles = <String>{};
    final queue = <String>[];

    queue.addAll(entryPoints);
    usedFiles.addAll(entryPoints);

    while (queue.isNotEmpty) {
      final currentFile = queue.removeAt(0);
      final dependencies = dependencyMap[currentFile] ?? <String>{};

      for (final dependency in dependencies) {
        if (usedFiles.add(dependency)) {
          queue.add(dependency);
        }
      }
    }

    return usedFiles;
  }
}

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
            '   ❌ Failed to delete: ${_relativePath(filePath, projectPath)} - $e');
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

class _PackageRoot {
  final String path;
  final String? packageName;

  _PackageRoot({
    required this.path,
    required this.packageName,
  });

  String? get normalizedPackageName => packageName;

  String? get normalizedPackageNameKey =>
      packageName == null ? null : _comparisonKey(packageName!);

  String get libDirectoryPath => '$path${Platform.pathSeparator}lib';
}

class _TestHarnessVisitor extends RecursiveAstVisitor<void> {
  static const Set<String> _testFunctionNames = {
    'group',
    'test',
    'testWidgets',
  };

  bool found = false;

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (!found &&
        node.function is SimpleIdentifier &&
        _testFunctionNames.contains((node.function as SimpleIdentifier).name)) {
      found = true;
    }

    if (!found) {
      super.visitFunctionExpressionInvocation(node);
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!found &&
        node.target == null &&
        _testFunctionNames.contains(node.methodName.name)) {
      found = true;
    }

    if (!found) {
      super.visitMethodInvocation(node);
    }
  }
}
