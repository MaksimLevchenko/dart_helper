import 'package:dart_helper_cli/src/utils/ansi.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() {
    Ansi.enabled = true;
  });

  test('wrap adds ANSI codes when enabled', () {
    Ansi.enabled = true;

    expect(
      Ansi.wrap('hello', Ansi.red),
      equals('${Ansi.red}hello${Ansi.reset}'),
    );
  });

  test('wrap returns plain text when disabled', () {
    Ansi.enabled = false;

    expect(Ansi.wrap('hello', Ansi.red), equals('hello'));
    expect(Ansi.sequence(Ansi.clearLine), isEmpty);
  });

  test('strip removes ANSI escape sequences', () {
    expect(
      Ansi.strip('${Ansi.green}done${Ansi.reset}'),
      equals('done'),
    );
  });
}
