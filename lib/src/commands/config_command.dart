import 'dart:collection';

import '../models/cli_config.dart';
import '../services/config_service.dart';
import '../cli/help_printer.dart';

class ConfigCommand {
  final ConfigService _configService;
  final HelpPrinter _helpPrinter;

  ConfigCommand(this._configService, this._helpPrinter);

  Future<int> execute({
    List<String> args = const [],
  }) async {
    final config = await _configService.readConfig();
    if (args.isEmpty) {
      _helpPrinter.printConfigHelp(config);
      return 0;
    }

    final setting = args.first;
    final values = args.skip(1).toList();

    switch (setting) {
      case 'fluttergen':
      case 'fvm':
      case 'update-checks':
      case 'check.details':
      case 'check.interactive':
      case 'get-all.tree':
      case 'color':
        return _handleBooleanSetting(config, setting, values);
      case 'check.exclude-pattern':
      case 'check.exclude-folder':
        return _handleListSetting(config, setting, values);
      case 'reverse.ports':
        return _handlePortListSetting(config, setting, values);
      default:
        throw ArgumentError(
          'Unknown config setting: $setting. '
          'Use "dh config" to see supported settings.',
        );
    }
  }

  Future<int> _handleBooleanSetting(
    CliConfig config,
    String setting,
    List<String> values,
  ) async {
    if (values.isEmpty) {
      _helpPrinter.printConfigSettingHelp(
        key: setting,
        currentValue: _boolSettingValue(config, setting) ? 'on' : 'off',
        description: _settingDescription(setting),
        usage: [
          'dh config $setting on',
          'dh config $setting off',
        ],
      );
      return 0;
    }

    if (values.length != 1) {
      throw ArgumentError(
        'Usage: dh config $setting on|off',
      );
    }

    switch (values.first) {
      case 'on':
        await _configService.updateConfig(
          (current) => _setBooleanSetting(current, setting, true),
        );
        print('$setting is enabled.');
        return 0;
      case 'off':
        await _configService.updateConfig(
          (current) => _setBooleanSetting(current, setting, false),
        );
        print('$setting is disabled.');
        return 0;
      default:
        throw ArgumentError(
          'Invalid value for $setting: ${values.first}. '
          'Use "dh config $setting on" or "dh config $setting off".',
        );
    }
  }

  Future<int> _handleListSetting(
    CliConfig config,
    String setting,
    List<String> values,
  ) async {
    if (values.isEmpty) {
      _helpPrinter.printConfigSettingHelp(
        key: setting,
        currentValue: _formatListValue(_listSettingValue(config, setting)),
        description: _settingDescription(setting),
        usage: [
          'dh config $setting set <value>...',
          'dh config $setting add <value>...',
          'dh config $setting remove <value>...',
          'dh config $setting clear',
        ],
      );
      return 0;
    }

    final action = values.first;
    final items = values.skip(1).toList();

    switch (action) {
      case 'set':
        if (items.isEmpty) {
          throw ArgumentError(
            'Usage: dh config $setting set <value>...',
          );
        }
        await _configService.updateConfig(
          (current) => _setListSetting(current, setting, _unique(items)),
        );
        print('$setting list updated.');
        return 0;
      case 'add':
        if (items.isEmpty) {
          throw ArgumentError(
            'Usage: dh config $setting add <value>...',
          );
        }
        await _configService.updateConfig((current) {
          final merged = [
            ..._listSettingValue(current, setting),
            ...items,
          ];
          return _setListSetting(current, setting, _unique(merged));
        });
        print('Added values to $setting.');
        return 0;
      case 'remove':
        if (items.isEmpty) {
          throw ArgumentError(
            'Usage: dh config $setting remove <value>...',
          );
        }
        await _configService.updateConfig((current) {
          final itemsToRemove = items.toSet();
          final remaining = _listSettingValue(current, setting)
              .where((item) => !itemsToRemove.contains(item))
              .toList();
          return _setListSetting(current, setting, remaining);
        });
        print('Removed values from $setting.');
        return 0;
      case 'clear':
        if (items.isNotEmpty) {
          throw ArgumentError(
            'Usage: dh config $setting clear',
          );
        }
        await _configService.updateConfig(
          (current) => _setListSetting(current, setting, const []),
        );
        print('$setting list cleared.');
        return 0;
      default:
        throw ArgumentError(
          'Invalid action for $setting: $action. '
          'Use set, add, remove, or clear.',
        );
    }
  }

  Future<int> _handlePortListSetting(
    CliConfig config,
    String setting,
    List<String> values,
  ) async {
    if (values.isEmpty) {
      _helpPrinter.printConfigSettingHelp(
        key: setting,
        currentValue: _formatIntListValue(_portSettingValue(config, setting)),
        description: _settingDescription(setting),
        usage: [
          'dh config $setting set <port>...',
          'dh config $setting add <port>...',
          'dh config $setting remove <port>...',
          'dh config $setting clear',
        ],
      );
      return 0;
    }

    final action = values.first;
    final items = values.skip(1).toList();

    switch (action) {
      case 'set':
        if (items.isEmpty) {
          throw ArgumentError(
            'Usage: dh config $setting set <port>...',
          );
        }
        await _configService.updateConfig(
          (current) => _setPortSetting(current, setting, _parsePorts(items)),
        );
        print('$setting list updated.');
        return 0;
      case 'add':
        if (items.isEmpty) {
          throw ArgumentError(
            'Usage: dh config $setting add <port>...',
          );
        }
        await _configService.updateConfig((current) {
          final merged = [
            ..._portSettingValue(current, setting),
            ..._parsePorts(items),
          ];
          return _setPortSetting(current, setting, _uniqueInts(merged));
        });
        print('Added values to $setting.');
        return 0;
      case 'remove':
        if (items.isEmpty) {
          throw ArgumentError(
            'Usage: dh config $setting remove <port>...',
          );
        }
        await _configService.updateConfig((current) {
          final itemsToRemove = _parsePorts(items).toSet();
          final remaining = _portSettingValue(current, setting)
              .where((item) => !itemsToRemove.contains(item))
              .toList();
          return _setPortSetting(current, setting, remaining);
        });
        print('Removed values from $setting.');
        return 0;
      case 'clear':
        if (items.isNotEmpty) {
          throw ArgumentError(
            'Usage: dh config $setting clear',
          );
        }
        await _configService.updateConfig(
          (current) => _setPortSetting(current, setting, const []),
        );
        print('$setting list cleared.');
        return 0;
      default:
        throw ArgumentError(
          'Invalid action for $setting: $action. '
          'Use set, add, remove, or clear.',
        );
    }
  }

  bool _boolSettingValue(CliConfig config, String setting) {
    switch (setting) {
      case 'fluttergen':
        return config.fluttergenEnabled;
      case 'fvm':
        return config.useFvmByDefault;
      case 'update-checks':
        return config.updateChecksEnabled;
      case 'check.details':
        return config.checkDetailsByDefault;
      case 'check.interactive':
        return config.checkInteractiveByDefault;
      case 'get-all.tree':
        return config.getAllTreeByDefault;
      case 'color':
        return config.colorEnabled;
      default:
        throw ArgumentError('Unsupported boolean setting: $setting');
    }
  }

  CliConfig _setBooleanSetting(CliConfig config, String setting, bool value) {
    switch (setting) {
      case 'fluttergen':
        return config.copyWith(fluttergenEnabled: value);
      case 'fvm':
        return config.copyWith(useFvmByDefault: value);
      case 'update-checks':
        return config.copyWith(updateChecksEnabled: value);
      case 'check.details':
        return config.copyWith(checkDetailsByDefault: value);
      case 'check.interactive':
        return config.copyWith(checkInteractiveByDefault: value);
      case 'get-all.tree':
        return config.copyWith(getAllTreeByDefault: value);
      case 'color':
        return config.copyWith(colorEnabled: value);
      default:
        throw ArgumentError('Unsupported boolean setting: $setting');
    }
  }

  List<String> _listSettingValue(CliConfig config, String setting) {
    switch (setting) {
      case 'check.exclude-pattern':
        return List<String>.from(config.checkExcludePatterns);
      case 'check.exclude-folder':
        return List<String>.from(config.checkExcludeFolders);
      default:
        throw ArgumentError('Unsupported list setting: $setting');
    }
  }

  List<int> _portSettingValue(CliConfig config, String setting) {
    switch (setting) {
      case 'reverse.ports':
        return List<int>.from(config.reversePorts);
      default:
        throw ArgumentError('Unsupported port list setting: $setting');
    }
  }

  CliConfig _setListSetting(
    CliConfig config,
    String setting,
    List<String> values,
  ) {
    switch (setting) {
      case 'check.exclude-pattern':
        return config.copyWith(checkExcludePatterns: values);
      case 'check.exclude-folder':
        return config.copyWith(checkExcludeFolders: values);
      default:
        throw ArgumentError('Unsupported list setting: $setting');
    }
  }

  CliConfig _setPortSetting(
    CliConfig config,
    String setting,
    List<int> values,
  ) {
    switch (setting) {
      case 'reverse.ports':
        return config.copyWith(reversePorts: values);
      default:
        throw ArgumentError('Unsupported port list setting: $setting');
    }
  }

  String _settingDescription(String setting) {
    switch (setting) {
      case 'fluttergen':
        return 'Controls whether "dh build" runs fluttergen after build_runner.';
      case 'fvm':
        return 'Controls the default use of "fvm exec" for supported commands.';
      case 'update-checks':
        return 'Controls automatic package update checks at CLI startup.';
      case 'check.details':
        return 'Controls whether "dh check" shows the full list of unused files.';
      case 'check.interactive':
        return 'Controls whether "dh check" prompts for interactive cleanup by default.';
      case 'get-all.tree':
        return 'Controls whether "dh get-all" uses tree view output by default.';
      case 'check.exclude-pattern':
        return 'Global file patterns appended to the "dh check" exclude-pattern list.';
      case 'check.exclude-folder':
        return 'Global folders appended to the "dh check" exclude-folder list.';
      case 'reverse.ports':
        return 'Ports used by "dh reverse" for sequential adb reverse commands.';
      case 'color':
        return 'Controls ANSI-colored CLI output.';
      default:
        return 'Global CLI setting.';
    }
  }

  String _formatListValue(List<String> values) {
    if (values.isEmpty) {
      return '(empty)';
    }
    return values.join(', ');
  }

  String _formatIntListValue(List<int> values) {
    if (values.isEmpty) {
      return '(empty)';
    }
    return values.join(', ');
  }

  List<int> _parsePorts(List<String> values) {
    final ports = <int>[];
    for (final value in values) {
      final port = int.tryParse(value);
      if (port == null) {
        throw ArgumentError(
          'Invalid port for reverse.ports: $value. Use integers from 1 to 65535.',
        );
      }
      if (port < 1 || port > 65535) {
        throw ArgumentError(
          'Invalid port for reverse.ports: $value. Use integers from 1 to 65535.',
        );
      }
      ports.add(port);
    }
    return _uniqueInts(ports);
  }

  List<String> _unique(Iterable<String> values) {
    return LinkedHashSet<String>.from(values).toList();
  }

  List<int> _uniqueInts(Iterable<int> values) {
    return LinkedHashSet<int>.from(values).toList();
  }
}
