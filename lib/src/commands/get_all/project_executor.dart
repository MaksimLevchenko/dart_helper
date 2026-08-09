import 'dart:io';

import '../../services/process_service.dart';
import '../../utils/ansi.dart';
import 'project_path_formatter.dart';

class ProjectExecutor {
  final ProcessService _processService;
  final ProjectPathFormatter _pathFormatter;

  ProjectExecutor(
    this._processService, {
    ProjectPathFormatter? pathFormatter,
  }) : _pathFormatter = pathFormatter ?? const ProjectPathFormatter();

  Future<int> runPubGetInProject(
    String projectPath,
    String basePath,
    bool useFvm, {
    bool showDetails = true,
  }) async {
    final projectName = _pathFormatter.projectName(projectPath);
    final relativePath = _pathFormatter.relativeProjectPath(projectPath, basePath);

    if (showDetails) {
      print('');
      print(Ansi.wrap('🔄 Processing: $projectName', Ansi.blue));
      print(Ansi.wrap(
        '  Path: ${relativePath.isEmpty ? '.' : relativePath}',
        Ansi.gray,
      ));
    }

    final originalDirectory = Directory.current.path;

    try {
      Directory.current = projectPath;

      final result = await _processService.runCommand(
        ['dart', 'pub', 'get'],
        useFvm: useFvm,
        showDetails: false,
      );

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
    } finally {
      Directory.current = originalDirectory;
    }
  }
}
