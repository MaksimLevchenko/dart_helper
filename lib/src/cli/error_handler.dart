import '../utils/ansi.dart';

class ErrorHandler {
  Future<int> handleErrors(Future<int> Function() action) async {
    try {
      final result = await action();
      // Если команда вернула ненулевой код, это уже обработано в ProcessService
      return result;
    } on ArgumentError catch (e) {
      print(Ansi.wrap('Error: ${e.message}', Ansi.red));
      return 1;
    } on Exception catch (e) {
      // Для других исключений выводим чистое сообщение
      print(Ansi.wrap(
        'Error: ${e.toString().replaceFirst('Exception: ', '')}',
        Ansi.red,
      ));
      return 1;
    } catch (e) {
      print(Ansi.wrap('Unexpected error occurred', Ansi.red));
      return 1;
    }
  }
}
