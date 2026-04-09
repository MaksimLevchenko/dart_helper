import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../utils/ansi.dart';

class ProcessService {
  Future<int> runCommand(
    List<String> cmd, {
    required bool useFvm,
    bool showDetails = true, // <- new param
  }) async {
    if (useFvm) {
      cmd = ['fvm', 'exec', ...cmd];
    }

    final directory = Directory.current.path.split(Platform.pathSeparator).last;

    final commandDisplay = () {
      var displayCmd = cmd;
      // Remove 'dart pub global run' prefix if present (old behaviour preserved)
      if (displayCmd.length >= 5 &&
          displayCmd[0] == 'dart' &&
          displayCmd[1] == 'pub' &&
          displayCmd[2] == 'global' &&
          displayCmd[3] == 'run') {
        displayCmd = displayCmd.sublist(4);
      }
      return displayCmd.join(' ');
    }();

    // Фиолетовая строка перед командой (оставляем — полезно)
    print(Ansi.wrap('Running $commandDisplay in $directory', Ansi.magenta));

    try {
      if (showDetails) {
        // Прямой вывод в терминал — для подробного режима
        final process = await Process.start(
          cmd.first,
          cmd.length > 1 ? cmd.sublist(1) : <String>[],
          runInShell: true,
          mode: ProcessStartMode.inheritStdio,
          includeParentEnvironment: true,
        );

        final exitCode = await process.exitCode;
        return exitCode;
      } else {
        // Подавленный (по умолчанию для pub get при showDetails=false)
        // Собираем stdout/stderr в память и печатаем только при ошибке.
        final process = await Process.start(
          cmd.first,
          cmd.length > 1 ? cmd.sublist(1) : <String>[],
          runInShell: true,
          mode: ProcessStartMode.normal,
          includeParentEnvironment: true,
        );

        final outBuffer = StringBuffer();
        final errBuffer = StringBuffer();

        // слушаем stdout
        final stdoutSub = process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((line) {
          outBuffer.writeln(line);
        });

        // слушаем stderr
        final stderrSub = process.stderr
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((line) {
          errBuffer.writeln(line);
        });

        final exitCode = await process.exitCode;

        // дождёмся закрытия стримов
        await stdoutSub.cancel();
        await stderrSub.cancel();

        if (exitCode != 0) {
          // при ошибке печатаем и stdout и stderr — чтобы дать контекст
          final outText = outBuffer.toString().trim();
          final errText = errBuffer.toString().trim();

          if (outText.isNotEmpty) {
            print(Ansi.wrap('--- OUTPUT ---', Ansi.gray));
            print(outText);
          }
          if (errText.isNotEmpty) {
            print(Ansi.wrap('--- ERROR ---', Ansi.red));
            print(errText);
          }
        }

        return exitCode;
      }
    } on ProcessException catch (e) {
      // Обрабатываем ошибку "файл не найден"
      final msg = e.toString();
      if (msg.contains('Не удается найти указанный файл') ||
          msg.contains('No such file or directory')) {
        await _handleMissingCommand(cmd, useFvm);
        return 127; // "command not found"
      }
      return e.errorCode;
    }
  }

  Future<void> _handleMissingCommand(List<String> cmd, bool useFvm) async {
    final commandName = cmd.first;
    print('');
    print(Ansi.wrap('Error: Command "$commandName" not found', Ansi.red));

    final solutions = <String, String>{
      'fluttergen': 'dart pub global activate flutter_gen',
      'serverpod': 'dart pub global activate serverpod_cli',
      'fvm':
          'Add FVM to your system by following instructions at https://fvm.app/documentation/getting-started/installation',
      'dart': 'Install Dart SDK from https://dart.dev/get-dart',
      'flutter':
          'Install Flutter SDK from https://flutter.dev/docs/get-started/install',
      'build_runner': 'Add build_runner to dev_dependencies in pubspec.yaml',
      'dart-unused-files': 'dart pub global activate dart_unused_files',
      'dart-format': 'Install Dart SDK from https://dart.dev/get-dart',
    };

    if (solutions.containsKey(commandName)) {
      print(Ansi.wrap('Solution: ${solutions[commandName]}', Ansi.yellow));
    } else {
      print(Ansi.wrap(
        'Solution: Please install $commandName and ensure it\'s in your PATH',
        Ansi.yellow,
      ));
    }

    if (useFvm && commandName == 'fvm') {
      print('');
      print(
        Ansi.wrap('Note: FVM is required when using --fvm flag', Ansi.cyan),
      );
      print(
        Ansi.wrap('Install with: dart pub global activate fvm', Ansi.cyan),
      );
    }
  }
}
