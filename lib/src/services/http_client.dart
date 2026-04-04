import 'dart:convert';
import 'dart:io' as io;
import 'package:dart_helper_cli/src/utils/logger.dart';
import '../models/version.dart';

class HttpClient {
  Future<Version?> getLatestVersion() async {
    const packageName = 'dart_helper_cli';
    final url = Uri.parse('https://pub.dev/api/packages/$packageName');

    try {
      final client = io.HttpClient();
      try {
        final request = await client.getUrl(url);
        final response = await request.close();
        if (response.statusCode != io.HttpStatus.ok) {
          return null;
        }

        final responseBody = await utf8.decoder.bind(response).join();
        final json = jsonDecode(responseBody);
        final latest = json['latest']['version'] as String?;
        return latest != null ? Version.parse(latest) : null;
      } finally {
        client.close(force: true);
      }
    } catch (e) {
      Logger.error('Failed to fetch latest version from pub.dev: $e');
      return null;
    }
  }
}
