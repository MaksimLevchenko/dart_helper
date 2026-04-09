import 'dart:io';
import '../services/process_service.dart';
import '../utils/folder_tree_printer.dart';
import '../utils/ansi.dart';

class GetAllCommand {
  final ProcessService _processService;

  GetAllCommand(this._processService);

  /// Рекурсивно выполняет dart pub get во всех подпапках с pubspec.yaml
  Future<int> execute({
    String? path,
    bool useFvm = false,
    bool interactive = false,
    bool treeView = true,
  }) async {
    final startDir = Directory.current.path;
    final searchDir =
        path != null && path != '.' ? Directory(path).absolute.path : startDir;

    try {
      print(Ansi.wrap(
        '🔍 Searching for Dart/Flutter projects in: $searchDir',
        Ansi.cyan,
      ));

      final projects = await _findDartProjects(Directory(searchDir));

      if (projects.isEmpty) {
        print(Ansi.wrap('⚠ No Dart/Flutter projects found', Ansi.yellow));
        return 0;
      }

      // Показываем найденные проекты
      if (treeView) {
        // Предварительный просмотр структуры с индикаторами "не обработано"
        final previewResults = <String, bool>{};
        for (final project in projects) {
          var relativePath = _getRelativePath(project, searchDir);
          previewResults[relativePath] = false; // Еще не обработано
        }

        FolderTreePrinter.printSectionHeader('FOUND PROJECTS', emoji: '📁');
        FolderTreePrinter.printProjectTree(
          searchDir,
          previewResults,
          showStatus: true,
          colorOutput: true,
        );
      } else {
        FolderTreePrinter.printFoundProjects(projects, searchDir);
      }

      if (interactive) {
        print(
          "\n${Ansi.wrap('❓ Continue with processing all projects? (y/N): ', Ansi.yellow)}",
        );
        final response = stdin.readLineSync()?.toLowerCase() ?? 'n';
        if (response != 'y' && response != 'yes') {
          print(Ansi.wrap('⚠ Operation cancelled by user', Ansi.yellow));
          return 0;
        }
      }

      FolderTreePrinter.printSectionHeader('PROCESSING PROJECTS', emoji: '🚀');

      // Выполняем dart pub get в каждом проекте
      final projectResults = <String, bool>{};
      int currentProject = 0;

      for (final projectPath in projects) {
        currentProject++;
        final relativePath = _getRelativePath(projectPath, searchDir);
        final projectName = projectPath.split(Platform.pathSeparator).last;

        // Показываем прогресс
        if (!treeView) {
          FolderTreePrinter.printProgress(
            projectName,
            currentProject - 1,
            projects.length,
            false,
          );
        }

        final result = await _runPubGetInProject(
          projectPath,
          searchDir,
          useFvm,
          showDetails: !treeView,
        );

        final success = result == 0;
        projectResults[relativePath] = success;

        if (treeView) {
          final status = success ? '✅' : '❌';
          final color = success ? Ansi.green : Ansi.red;
          print(Ansi.wrap(
            '$status [$currentProject/${projects.length}] $projectName',
            color,
          ));
        } else {
          FolderTreePrinter.printProgress(
            projectName,
            currentProject,
            projects.length,
            success,
          );
        }
      }

      // Финальный вывод результатов
      print('\n');

      if (treeView) {
        FolderTreePrinter.printSectionHeader('FINAL RESULTS', emoji: '📊');
        FolderTreePrinter.printProjectTree(searchDir, projectResults);
      }

      FolderTreePrinter.printSummary(projectResults);

      final failCount = projectResults.values.where((v) => !v).length;
      return failCount > 0 ? 1 : 0;
    } catch (e) {
      print(Ansi.wrap('❌ Error during get-all execution: $e', Ansi.red));

      return 1;
    } finally {
      Directory.current = startDir;
    }
  }

  /// Рекурсивно находит все папки с pubspec.yaml, начиная с указанной директории
  Future<List<String>> _findDartProjects(Directory directory) async {
    final projects = <String>[];
    final excludedFolders = _getExcludedFolders();
    final visited = <String>{};

    Future<void> searchRecursively(Directory dir) async {
      try {
        final canonicalPath = dir.absolute.path;

        // Избегаем бесконечных циклов (симлинки)
        if (visited.contains(canonicalPath)) {
          return;
        }
        visited.add(canonicalPath);

        // Получаем список сущностей в текущей директории
        final List<FileSystemEntity> entities;
        try {
          entities = await dir.list().toList();
        } catch (e) {
          // Пропускаем директории, в которые нет доступа
          return;
        }

        // Проверяем есть ли pubspec.yaml в текущей папке
        final pubspecFile =
            File('${dir.path}${Platform.pathSeparator}pubspec.yaml');
        if (await pubspecFile.exists()) {
          projects.add(dir.absolute.path);
          // Продолжаем искать в подпапках этого проекта
        }

        // Рекурсивно ищем в подпапках
        for (final entity in entities) {
          if (entity is Directory) {
            final dirName = entity.path.split(Platform.pathSeparator).last;

            // Пропускаем исключенные папки (но не если это подпапка проекта с pubspec.yaml)
            if (excludedFolders.contains(dirName)) continue;

            // Рекурсивно ищем в подпапках
            await searchRecursively(entity);
          }
        }
      } catch (e) {
        // Игнорируем ошибки доступа к некоторым папкам
      }
    }

    await searchRecursively(directory);
    return projects;
  }

  /// Возвращает список папок для исключения из поиска
  List<String> _getExcludedFolders() {
    return [
      // Стандартные Flutter папки
      'build',
      'ios',
      'android',
      'web',
      'linux',
      'macos',
      'windows',
      // Системные папки
      '.dart_tool',
      '.git',
      '.github',
      '.vscode',
      '.idea',
      '.fvm',
      'node_modules',
      // Кэш и временные файлы
      '.pub-cache',
      '.gradle',
      '.m2',
      'DerivedData',
      'Pods',
      // Документация
      'doc',
      'docs',
      'documentation',
    ];
  }

  /// Выполняет dart pub get в указанной папке проекта
  Future<int> _runPubGetInProject(
    String projectPath,
    String basePath,
    bool useFvm, {
    bool showDetails = true,
  }) async {
    final projectName = projectPath.split(Platform.pathSeparator).last;
    final relativePath = _getRelativePath(projectPath, basePath);

    if (showDetails) {
      print('');
      print(Ansi.wrap('🔄 Processing: $projectName', Ansi.blue));
      print(Ansi.wrap(
        '  Path: ${relativePath.isEmpty ? '.' : relativePath}',
        Ansi.gray,
      ));
    }

    try {
      final currentDir = Directory.current.path;
      Directory.current = projectPath;

      final result = await _processService.runCommand(
        ['dart', 'pub', 'get'],
        useFvm: useFvm,
        showDetails: false,
      );

      Directory.current = currentDir;

      if (showDetails) {
        if (result == 0) {
          print(Ansi.wrap('  ✅ Success: $projectName', Ansi.green));
        } else {
          print(Ansi.wrap('  ❌ Failed: $projectName', Ansi.red));
        }
      }

      return result;
    } catch (e) {
      if (showDetails) {
        print(Ansi.wrap('  ❌ Error in $projectName: $e', Ansi.red));
      }
      return 1;
    }
  }

  /// Получает относительный путь от базовой директории
  String _getRelativePath(String fullPath, String basePath) {
    final mainDirName = basePath.split(Platform.pathSeparator).last;

    if (fullPath == basePath) {
      return mainDirName; // Показываем имя корневой директории
    }

    if (fullPath.startsWith(basePath)) {
      final remainder = fullPath.substring(basePath.length).replaceFirst(
          RegExp('^[${RegExp.escape(Platform.pathSeparator)}]+'), '');
      return remainder.isEmpty
          ? mainDirName
          : '$mainDirName${Platform.pathSeparator}$remainder';
    }
    return fullPath;
  }
}
