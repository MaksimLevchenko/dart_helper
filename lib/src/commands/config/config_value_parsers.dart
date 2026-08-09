import 'dart:collection';

List<String> formatStringList(List<String> values) {
  if (values.isEmpty) {
    return const ['(empty)'];
  }

  return values;
}

String formatCurrentStringList(List<String> values) {
  return formatStringList(values).join(', ');
}

String formatCurrentIntList(List<int> values) {
  if (values.isEmpty) {
    return '(empty)';
  }

  return values.join(', ');
}

List<String> uniqueStrings(Iterable<String> values) {
  return LinkedHashSet<String>.from(values).toList();
}

List<int> uniqueInts(Iterable<int> values) {
  return LinkedHashSet<int>.from(values).toList();
}

List<int> parsePorts(List<String> values) {
  final ports = <int>[];
  for (final value in values) {
    final port = int.tryParse(value);
    if (port == null || port < 1 || port > 65535) {
      throw ArgumentError(
        'Invalid port for reverse.ports: $value. Use integers from 1 to 65535.',
      );
    }
    ports.add(port);
  }
  return uniqueInts(ports);
}
