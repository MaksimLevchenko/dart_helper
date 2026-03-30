import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dart_helper/src/utils/logger.dart';
import '../models/version.dart';

class HttpClient {
  Future<Version?> getLatestVersion() async {
    const packageName = 'dart_helper';
    final url = Uri.parse('https://pub.dev/api/packages/$packageName');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final latest = json['latest']['version'] as String?;
        return latest != null ? Version.parse(latest) : null;
      }
      return null;
    } catch (e) {
      Logger.error('Failed to fetch latest version from pub.dev: $e');
      return null;
    }
  }
}
