import 'dart:convert';
import 'dart:io';

import '../models/cli_config.dart';

class ConfigService {
  static const _configDirectoryName = 'dart_helper';
  static const _configFileName = 'config.json';
  final File? _overrideConfigFile;
  final Map<String, String>? _environment;

  ConfigService({
    File? configFile,
    Map<String, String>? environment,
  })  : _overrideConfigFile = configFile,
        _environment = environment;

  Future<CliConfig> readConfig() async {
    final configFile = _configFile;
    if (!configFile.existsSync()) {
      return const CliConfig();
    }

    final content = await configFile.readAsString();
    if (content.trim().isEmpty) {
      return const CliConfig();
    }

    final json = jsonDecode(content);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid config file format');
    }

    return CliConfig.fromJson(json);
  }

  Future<CliConfig> writeConfig(CliConfig config) async {
    final configFile = _configFile;
    configFile.parent.createSync(recursive: true);
    await configFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(config.toJson()),
    );

    return config;
  }

  Future<CliConfig> updateConfig(CliConfig Function(CliConfig config) update) async {
    final updatedConfig = update(await readConfig());
    return writeConfig(updatedConfig);
  }

  File get _configFile {
    if (_overrideConfigFile != null) {
      return _overrideConfigFile!;
    }

    final configRoot = _resolveConfigRoot();
    return File(
      '${configRoot.path}${Platform.pathSeparator}'
      '$_configDirectoryName${Platform.pathSeparator}'
      '$_configFileName',
    );
  }

  Directory _resolveConfigRoot() {
    final environment = _environment ?? Platform.environment;

    if (Platform.isWindows) {
      final appData = environment['APPDATA'];
      if (appData != null && appData.isNotEmpty) {
        return Directory(appData);
      }

      final userProfile = environment['USERPROFILE'];
      if (userProfile != null && userProfile.isNotEmpty) {
        return Directory(
          '$userProfile${Platform.pathSeparator}AppData'
          '${Platform.pathSeparator}Roaming',
        );
      }
    }

    final xdgConfigHome = environment['XDG_CONFIG_HOME'];
    if (xdgConfigHome != null && xdgConfigHome.isNotEmpty) {
      return Directory(xdgConfigHome);
    }

    final home = environment['HOME'] ?? environment['USERPROFILE'];
    if (home != null && home.isNotEmpty) {
      return Directory('$home${Platform.pathSeparator}.config');
    }

    throw Exception(
      'Unable to determine the user config directory for dart_helper.',
    );
  }
}
