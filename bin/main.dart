import 'dart:io';

import 'package:dart_helper_cli/dart_helper_cli.dart';

Future<void> main(List<String> args) async {
  exitCode = await runCli(args);
}
