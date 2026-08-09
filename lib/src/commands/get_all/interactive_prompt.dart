import 'dart:io';

import '../../utils/ansi.dart';

class InteractivePrompt {
  const InteractivePrompt();

  Future<bool> confirmProcessingAllProjects() async {
    print(
      "\n${Ansi.wrap('❓ Continue with processing all projects? (y/N): ', Ansi.yellow)}",
    );
    final response = stdin.readLineSync()?.toLowerCase() ?? 'n';
    return response == 'y' || response == 'yes';
  }
}
