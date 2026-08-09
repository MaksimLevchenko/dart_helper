import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'package_root_index.dart';
import 'path_utils.dart';

class FileDependencyAnalysis {
  final Set<String> dependencies;
  final bool isEntryPoint;
  final bool isProtectedPublicExportBarrel;

  FileDependencyAnalysis({
    required this.dependencies,
    required this.isEntryPoint,
    required this.isProtectedPublicExportBarrel,
  });
}

class DependencyExtractor {
  FileDependencyAnalysis analyze({
    required String filePath,
    required CompilationUnit unit,
    required Map<String, PackageRoot?> fileOwners,
    required PackageRootIndex packageRootIndex,
    required Set<String> warnings,
  }) {
    return FileDependencyAnalysis(
      dependencies: _extractDependencies(
        filePath: filePath,
        unit: unit,
        fileOwners: fileOwners,
        packageRootIndex: packageRootIndex,
        warnings: warnings,
      ),
      isEntryPoint: _isEntryPoint(filePath, unit),
      isProtectedPublicExportBarrel: _isProtectedPublicExportBarrel(
        filePath: filePath,
        unit: unit,
        fileOwners: fileOwners,
      ),
    );
  }

  Set<String> findUsedFiles(
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

  Set<String> _extractDependencies({
    required String filePath,
    required CompilationUnit unit,
    required Map<String, PackageRoot?> fileOwners,
    required PackageRootIndex packageRootIndex,
    required Set<String> warnings,
  }) {
    final dependencies = <String>{};

    for (final directive in unit.directives) {
      if (directive is ImportDirective || directive is ExportDirective) {
        final namespaceDirective = directive as NamespaceDirective;
        for (final uri in _collectDirectiveUris(namespaceDirective)) {
          final resolved = packageRootIndex.resolveReference(
            filePath: filePath,
            uri: uri,
            fileOwners: fileOwners,
            warnings: warnings,
          );
          if (resolved != null) {
            dependencies.add(resolved);
          }
        }
        continue;
      }

      if (directive is PartDirective) {
        final uri = directive.uri.stringValue;
        if (uri == null) {
          continue;
        }

        final resolved = packageRootIndex.resolveReference(
          filePath: filePath,
          uri: uri,
          fileOwners: fileOwners,
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

  bool _isEntryPoint(String filePath, CompilationUnit unit) {
    if (_hasTopLevelMain(unit)) {
      return true;
    }

    final currentFileName = fileName(filePath);
    if (_isUnderTestFolder(filePath) ||
        currentFileName.endsWith('_test.dart')) {
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
    required Map<String, PackageRoot?> fileOwners,
  }) {
    if (unit.declarations.isNotEmpty) {
      return false;
    }

    final hasExportDirective =
        unit.directives.any((directive) => directive is ExportDirective);
    if (!hasExportDirective) {
      return false;
    }

    final owningRoot = fileOwners[normalizeExistingPath(filePath)];
    if (owningRoot == null) {
      return false;
    }

    final normalizedPath = normalizeExistingPath(filePath);
    if (!isWithin(normalizedPath, owningRoot.libDirectoryPath)) {
      return false;
    }

    final srcDirectory =
        '${owningRoot.libDirectoryPath}${Platform.pathSeparator}src';
    if (isWithin(normalizedPath, srcDirectory)) {
      return false;
    }

    return true;
  }

  bool _isUnderTestFolder(String filePath) {
    final segments = pathSegments(filePath);
    return segments.contains('test') || segments.contains('integration_test');
  }
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
