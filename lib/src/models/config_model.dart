import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

class NitConfig {
  // Настройки по умолчанию
  bool useFvm;
  bool forceRebuilds;
  bool enableFluttergen;
  bool autoUpdateCheck;
  String defaultProjectPath;
  List<String> excludePatterns;
  List<String> excludeFolders;

  NitConfig({
    this.useFvm = false,
    this.forceRebuilds = false,
    this.enableFluttergen = true,
    this.autoUpdateCheck = true,
    this.defaultProjectPath = '.',
    this.excludePatterns = const [],
    this.excludeFolders = const [],
  });

  // Путь к конфигу в домашней директории
  static String get configPath {
    final home = Platform.environment['HOME'] ?? 
                 Platform.environment['USERPROFILE'] ?? 
                 '.';
    return path.join(home, '.nit_helper_config.json');
  }

  // Загрузка конфига из файла
  static Future<NitConfig> load() async {
    final file = File(configPath);
    
    if (!await file.exists()) {
      return NitConfig();
    }

    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return NitConfig.fromJson(json);
    } catch (e) {
      print('⚠️  Error loading config, using defaults: $e');
      return NitConfig();
    }
  }

  // Сохранение конфига в файл
  Future<void> save() async {
    final file = File(configPath);
    await file.writeAsString(jsonEncode(toJson()));
    print('✅ Configuration saved to $configPath');
  }

  // Конвертация из JSON
  factory NitConfig.fromJson(Map<String, dynamic> json) {
    return NitConfig(
      useFvm: json['useFvm'] as bool? ?? false,
      forceRebuilds: json['forceRebuilds'] as bool? ?? false,
      enableFluttergen: json['enableFluttergen'] as bool? ?? true,
      autoUpdateCheck: json['autoUpdateCheck'] as bool? ?? true,
      defaultProjectPath: json['defaultProjectPath'] as String? ?? '.',
      excludePatterns: (json['excludePatterns'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      excludeFolders: (json['excludeFolders'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  // Конвертация в JSON
  Map<String, dynamic> toJson() {
    return {
      'useFvm': useFvm,
      'forceRebuilds': forceRebuilds,
      'enableFluttergen': enableFluttergen,
      'autoUpdateCheck': autoUpdateCheck,
      'defaultProjectPath': defaultProjectPath,
      'excludePatterns': excludePatterns,
      'excludeFolders': excludeFolders,
    };
  }

  // Красивый вывод текущей конфигурации
  void printConfig() {
    print('\n📋 Current nit-helper configuration:');
    print('════════════════════════════════════════');
    print('🔧 FVM enabled:           $useFvm');
    print('⚡ Force rebuilds:        $forceRebuilds');
    print('🎨 FlutterGen enabled:    $enableFluttergen');
    print('🔄 Auto update check:     $autoUpdateCheck');
    print('📁 Default project path:  $defaultProjectPath');
    
    if (excludePatterns.isNotEmpty) {
      print('🚫 Exclude patterns:      ${excludePatterns.join(", ")}');
    }
    
    if (excludeFolders.isNotEmpty) {
      print('📂 Exclude folders:       ${excludeFolders.join(", ")}');
    }
    
    print('════════════════════════════════════════');
    print('📍 Config file: $configPath\n');
  }
}
