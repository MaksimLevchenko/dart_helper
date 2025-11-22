import 'dart:io';
import '../models/config_model.dart';

class ConfigCommand {
  
  Future<int> execute({
    bool? show,
    bool? reset,
    bool? setFvm,
    bool? setForce,
    bool? setFluttergen,
    bool? setAutoUpdate,
    String? setDefaultPath,
    List<String>? addExcludePattern,
    List<String>? removeExcludePattern,
    List<String>? addExcludeFolder,
    List<String>? removeExcludeFolder,
  }) async {
    try {
      final config = await NitConfig.load();

      // Показать текущую конфигурацию
      if (show == true) {
        config.printConfig();
        return 0;
      }

      // Сбросить конфигурацию к значениям по умолчанию
      if (reset == true) {
        final confirmed = _confirmReset();
        if (confirmed) {
          final defaultConfig = NitConfig();
          await defaultConfig.save();
          print('✅ Configuration reset to defaults');
          defaultConfig.printConfig();
        } else {
          print('❌ Reset cancelled');
        }
        return 0;
      }

      // Обновление настроек
      bool hasChanges = false;

      if (setFvm != null) {
        config.useFvm = setFvm;
        hasChanges = true;
        print('🔧 FVM ${setFvm ? "enabled" : "disabled"}');
      }

      if (setForce != null) {
        config.forceRebuilds = setForce;
        hasChanges = true;
        print('⚡ Force rebuilds ${setForce ? "enabled" : "disabled"}');
      }

      if (setFluttergen != null) {
        config.enableFluttergen = setFluttergen;
        hasChanges = true;
        print('🎨 FlutterGen ${setFluttergen ? "enabled" : "disabled"}');
      }

      if (setAutoUpdate != null) {
        config.autoUpdateCheck = setAutoUpdate;
        hasChanges = true;
        print('🔄 Auto update check ${setAutoUpdate ? "enabled" : "disabled"}');
      }

      if (setDefaultPath != null) {
        config.defaultProjectPath = setDefaultPath;
        hasChanges = true;
        print('📁 Default project path set to: $setDefaultPath');
      }

      if (addExcludePattern != null && addExcludePattern.isNotEmpty) {
        for (var pattern in addExcludePattern) {
          if (!config.excludePatterns.contains(pattern)) {
            config.excludePatterns.add(pattern);
            print('➕ Added exclude pattern: $pattern');
          }
        }
        hasChanges = true;
      }

      if (removeExcludePattern != null && removeExcludePattern.isNotEmpty) {
        for (var pattern in removeExcludePattern) {
          if (config.excludePatterns.remove(pattern)) {
            print('➖ Removed exclude pattern: $pattern');
          }
        }
        hasChanges = true;
      }

      if (addExcludeFolder != null && addExcludeFolder.isNotEmpty) {
        for (var folder in addExcludeFolder) {
          if (!config.excludeFolders.contains(folder)) {
            config.excludeFolders.add(folder);
            print('➕ Added exclude folder: $folder');
          }
        }
        hasChanges = true;
      }

      if (removeExcludeFolder != null && removeExcludeFolder.isNotEmpty) {
        for (var folder in removeExcludeFolder) {
          if (config.excludeFolders.remove(folder)) {
            print('➖ Removed exclude folder: $folder');
          }
        }
        hasChanges = true;
      }

      if (hasChanges) {
        await config.save();
        print('');
        config.printConfig();
      } else {
        // Если никакие параметры не переданы, показываем текущую конфигурацию
        config.printConfig();
      }

      return 0;
    } catch (e) {
      print('❌ Error: $e');
      return 1;
    }
  }

  bool _confirmReset() {
    print('⚠️  Are you sure you want to reset configuration to defaults? (y/N)');
    final input = stdin.readLineSync()?.toLowerCase();
    return input == 'y' || input == 'yes';
  }
}
