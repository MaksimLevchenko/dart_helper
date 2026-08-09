import 'dart:io';

import '../services/process_service.dart';
import '../utils/ansi.dart';
import '../utils/folder_tree_printer.dart';
import 'get_all/interactive_prompt.dart';
import 'get_all/project_discovery.dart';
import 'get_all/project_executor.dart';
import 'get_all/project_path_formatter.dart';

class GetAllCommand {
  final ProjectDiscovery _projectDiscovery;
  final ProjectExecutor _projectExecutor;
  final InteractivePrompt _interactivePrompt;
  final ProjectPathFormatter _pathFormatter;

  GetAllCommand(
    ProcessService processService, {
    ProjectDiscovery? projectDiscovery,
    ProjectExecutor? projectExecutor,
    InteractivePrompt? interactivePrompt,
    ProjectPathFormatter? pathFormatter,
  })  : _projectDiscovery = projectDiscovery ?? const ProjectDiscovery(),
        _pathFormatter = pathFormatter ?? const ProjectPathFormatter(),
        _interactivePrompt = interactivePrompt ?? const InteractivePrompt(),
        _projectExecutor = projectExecutor ?? ProjectExecutor(processService);

  Future<int> execute({
    String? path,
    bool useFvm = false,
    bool interactive = false,
    bool treeView = true,
  }) async {
    final startDir = Directory.current.path;
    final searchDir = _pathFormatter.resolveSearchDirectory(
      startDir: startDir,
      path: path,
    );

    try {
      print(Ansi.wrap(
        '🔍 Searching for Dart/Flutter projects in: $searchDir',
        Ansi.cyan,
      ));

      final projects = await _projectDiscovery.findDartProjects(
        Directory(searchDir),
      );

      if (projects.isEmpty) {
        print(Ansi.wrap('⚠ No Dart/Flutter projects found', Ansi.yellow));
        return 0;
      }

      _printFoundProjects(
        projects: projects,
        searchDir: searchDir,
        treeView: treeView,
      );

      if (interactive) {
        final confirmed =
            await _interactivePrompt.confirmProcessingAllProjects();
        if (!confirmed) {
          print(Ansi.wrap('⚠ Operation cancelled by user', Ansi.yellow));
          return 0;
        }
      }

      FolderTreePrinter.printSectionHeader('PROCESSING PROJECTS', emoji: '🚀');

      final projectResults = <String, bool>{};
      var currentProject = 0;

      for (final projectPath in projects) {
        currentProject++;
        final relativePath = _pathFormatter.relativeProjectPath(
          projectPath,
          searchDir,
        );
        final projectName = _pathFormatter.projectName(projectPath);

        if (!treeView) {
          FolderTreePrinter.printProgress(
            projectName,
            currentProject - 1,
            projects.length,
            false,
          );
        }

        final result = await _projectExecutor.runPubGetInProject(
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

      print('\n');

      if (treeView) {
        FolderTreePrinter.printSectionHeader('FINAL RESULTS', emoji: '📊');
        FolderTreePrinter.printProjectTree(searchDir, projectResults);
      }

      FolderTreePrinter.printSummary(projectResults);

      final failCount = projectResults.values.where((value) => !value).length;
      return failCount > 0 ? 1 : 0;
    } catch (e) {
      print(Ansi.wrap('❌ Error during get-all execution: $e', Ansi.red));
      return 1;
    } finally {
      Directory.current = startDir;
    }
  }

  void _printFoundProjects({
    required List<String> projects,
    required String searchDir,
    required bool treeView,
  }) {
    if (treeView) {
      final previewResults = <String, bool>{};
      for (final project in projects) {
        final relativePath =
            _pathFormatter.relativeProjectPath(project, searchDir);
        previewResults[relativePath] = false;
      }

      FolderTreePrinter.printSectionHeader('FOUND PROJECTS', emoji: '📁');
      FolderTreePrinter.printProjectTree(
        searchDir,
        previewResults,
        showStatus: true,
        colorOutput: true,
      );
      return;
    }

    FolderTreePrinter.printFoundProjects(projects, searchDir);
  }
}
