import 'dart:async';
import 'dart:io';

import 'ansi.dart';

class TaskStatus {
  static const List<String> _frames = ['|', '/', '-', r'\'];

  final String _label;
  final IOSink _output;
  final bool _interactive;
  Timer? _timer;
  int _frameIndex = 0;
  String _message = '';
  bool _started = false;

  TaskStatus(
    this._label, {
    IOSink? output,
    bool? interactive,
  })  : _output = output ?? stdout,
        _interactive = interactive ?? stdout.hasTerminal;

  void start([String? message]) {
    if (_started) {
      return;
    }

    _started = true;
    _message = message ?? _label;

    if (_interactive) {
      _renderFrame();
      _timer = Timer.periodic(const Duration(milliseconds: 120), (_) {
        _frameIndex = (_frameIndex + 1) % _frames.length;
        _renderFrame();
      });
      return;
    }

    _output.writeln('... $_message');
  }

  void update(String message) {
    _message = message;
    if (_interactive && _started) {
      _renderFrame();
    }
  }

  void complete(String message) {
    _finish('OK', message, Ansi.green);
  }

  void fail(String message) {
    _finish('ERROR', message, Ansi.red);
  }

  void info(String message) {
    _finish('INFO', message, Ansi.cyan);
  }

  void _renderFrame() {
    final frame = _frames[_frameIndex];
    final text = '\r${Ansi.sequence(Ansi.clearLine)}'
        '${Ansi.wrap('[$frame]', Ansi.cyan)} $_message';
    _output.write(text);
  }

  void _finish(String prefix, String message, String color) {
    _timer?.cancel();
    _timer = null;

    final formattedPrefix = Ansi.wrap('[$prefix]', color);
    if (_interactive) {
      _output.write('\r${Ansi.sequence(Ansi.clearLine)}');
      _output.writeln('$formattedPrefix $message');
      return;
    }

    _output.writeln('$formattedPrefix $message');
  }
}
