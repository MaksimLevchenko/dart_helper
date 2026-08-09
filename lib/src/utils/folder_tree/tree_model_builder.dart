import 'dart:io';

import 'tree_formatters.dart';

Map<String, dynamic> buildTreeModel(
  String basePath,
  Map<String, dynamic> results,
) {
  final tree = <String, dynamic>{};
  final baseDirName = getLastSegment(basePath);

  for (final entry in results.entries) {
    final relativePath = entry.key.toString();
    final rawValue = entry.value;

    var isSuccess = false;
    if (rawValue is bool) {
      isSuccess = rawValue;
    } else if (rawValue is Map) {
      final candidate = rawValue['__result'];
      if (candidate is bool) {
        isSuccess = candidate;
      }
    }

    var current = tree;

    if (relativePath.isEmpty) {
      final existing = current[baseDirName];
      if (existing is Map) {
        final normalized = ensureMapStringDynamic(existing);
        current[baseDirName] = normalized;
        normalized['__result'] = isSuccess;
        normalized['__isProject'] = true;
      } else {
        current[baseDirName] = {
          '__result': isSuccess,
          '__isProject': true,
        };
      }
      continue;
    }

    final parts = relativePath.split(Platform.pathSeparator);

    for (var index = 0; index < parts.length; index++) {
      final part = parts[index];
      final isLast = index == parts.length - 1;

      if (isLast) {
        final existing = current[part];
        if (existing == null) {
          current[part] = {
            '__result': isSuccess,
            '__isProject': true,
          };
        } else if (existing is Map) {
          final normalized = ensureMapStringDynamic(existing);
          current[part] = normalized;
          normalized['__result'] = isSuccess;
          normalized['__isProject'] = true;
        } else {
          current[part] = {
            '__result': isSuccess,
            '__isProject': true,
          };
        }
        continue;
      }

      final existing = current[part];
      if (existing == null) {
        final newNode = <String, dynamic>{'__isProject': false};
        current[part] = newNode;
        current = newNode;
      } else if (existing is Map) {
        final normalized = ensureMapStringDynamic(existing);
        if (!identical(existing, normalized)) {
          current[part] = normalized;
        }
        current = normalized;
      } else {
        final replacement = <String, dynamic>{'__isProject': false};
        current[part] = replacement;
        current = replacement;
      }
    }
  }

  return tree;
}

Map<String, dynamic> ensureMapStringDynamic(Map existing) {
  try {
    return Map<String, dynamic>.from(existing);
  } catch (_) {
    final result = <String, dynamic>{};
    existing.forEach((key, value) {
      try {
        result[key.toString()] = value;
      } catch (_) {
        // Ignore keys that cannot be converted.
      }
    });
    return result;
  }
}
