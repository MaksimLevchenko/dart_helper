import '../../cli/help_printer.dart';
import '../../models/cli_config.dart';
import '../../services/config_service.dart';
import 'config_setting_spec.dart';
import 'config_value_parsers.dart';

class ConfigActionHandlers {
  final ConfigService _configService;
  final HelpPrinter _helpPrinter;

  ConfigActionHandlers(this._configService, this._helpPrinter);

  Future<int> handleBooleanSetting(
    CliConfig config,
    BooleanConfigSettingSpec setting,
    List<String> values,
  ) async {
    if (values.isEmpty) {
      _helpPrinter.printConfigSettingHelp(
        key: setting.key,
        currentValue: setting.readValue(config) ? 'on' : 'off',
        description: setting.description,
        usage: [
          'dh config ${setting.key} on',
          'dh config ${setting.key} off',
        ],
      );
      return 0;
    }

    if (values.length != 1) {
      throw ArgumentError('Usage: dh config ${setting.key} on|off');
    }

    switch (values.first) {
      case 'on':
        await _configService.updateConfig(
          (current) => setting.writeValue(current, true),
        );
        print('${setting.key} is enabled.');
        return 0;
      case 'off':
        await _configService.updateConfig(
          (current) => setting.writeValue(current, false),
        );
        print('${setting.key} is disabled.');
        return 0;
      default:
        throw ArgumentError(
          'Invalid value for ${setting.key}: ${values.first}. '
          'Use "dh config ${setting.key} on" or "dh config ${setting.key} off".',
        );
    }
  }

  Future<int> handleStringListSetting(
    CliConfig config,
    StringListConfigSettingSpec setting,
    List<String> values,
  ) async {
    if (values.isEmpty) {
      _helpPrinter.printConfigSettingHelp(
        key: setting.key,
        currentValue: formatCurrentStringList(setting.readValue(config)),
        description: setting.description,
        usage: [
          'dh config ${setting.key} set <value>...',
          'dh config ${setting.key} add <value>...',
          'dh config ${setting.key} remove <value>...',
          'dh config ${setting.key} clear',
        ],
      );
      return 0;
    }

    final action = values.first;
    final items = values.skip(1).toList();

    switch (action) {
      case 'set':
        if (items.isEmpty) {
          throw ArgumentError('Usage: dh config ${setting.key} set <value>...');
        }
        await _configService.updateConfig(
          (current) => setting.writeValue(current, uniqueStrings(items)),
        );
        print('${setting.key} list updated.');
        return 0;
      case 'add':
        if (items.isEmpty) {
          throw ArgumentError('Usage: dh config ${setting.key} add <value>...');
        }
        await _configService.updateConfig((current) {
          final merged = [...setting.readValue(current), ...items];
          return setting.writeValue(current, uniqueStrings(merged));
        });
        print('Added values to ${setting.key}.');
        return 0;
      case 'remove':
        if (items.isEmpty) {
          throw ArgumentError(
            'Usage: dh config ${setting.key} remove <value>...',
          );
        }
        await _configService.updateConfig((current) {
          final itemsToRemove = items.toSet();
          final remaining = setting
              .readValue(current)
              .where((item) => !itemsToRemove.contains(item))
              .toList();
          return setting.writeValue(current, remaining);
        });
        print('Removed values from ${setting.key}.');
        return 0;
      case 'clear':
        if (items.isNotEmpty) {
          throw ArgumentError('Usage: dh config ${setting.key} clear');
        }
        await _configService.updateConfig(
          (current) => setting.writeValue(current, const []),
        );
        print('${setting.key} list cleared.');
        return 0;
      default:
        throw ArgumentError(
          'Invalid action for ${setting.key}: $action. '
          'Use set, add, remove, or clear.',
        );
    }
  }

  Future<int> handleIntListSetting(
    CliConfig config,
    IntListConfigSettingSpec setting,
    List<String> values,
  ) async {
    if (values.isEmpty) {
      _helpPrinter.printConfigSettingHelp(
        key: setting.key,
        currentValue: formatCurrentIntList(setting.readValue(config)),
        description: setting.description,
        usage: [
          'dh config ${setting.key} set <port>...',
          'dh config ${setting.key} add <port>...',
          'dh config ${setting.key} remove <port>...',
          'dh config ${setting.key} clear',
        ],
      );
      return 0;
    }

    final action = values.first;
    final items = values.skip(1).toList();

    switch (action) {
      case 'set':
        if (items.isEmpty) {
          throw ArgumentError('Usage: dh config ${setting.key} set <port>...');
        }
        await _configService.updateConfig(
          (current) => setting.writeValue(current, parsePorts(items)),
        );
        print('${setting.key} list updated.');
        return 0;
      case 'add':
        if (items.isEmpty) {
          throw ArgumentError('Usage: dh config ${setting.key} add <port>...');
        }
        await _configService.updateConfig((current) {
          final merged = [...setting.readValue(current), ...parsePorts(items)];
          return setting.writeValue(current, uniqueInts(merged));
        });
        print('Added values to ${setting.key}.');
        return 0;
      case 'remove':
        if (items.isEmpty) {
          throw ArgumentError(
            'Usage: dh config ${setting.key} remove <port>...',
          );
        }
        await _configService.updateConfig((current) {
          final itemsToRemove = parsePorts(items).toSet();
          final remaining = setting
              .readValue(current)
              .where((item) => !itemsToRemove.contains(item))
              .toList();
          return setting.writeValue(current, remaining);
        });
        print('Removed values from ${setting.key}.');
        return 0;
      case 'clear':
        if (items.isNotEmpty) {
          throw ArgumentError('Usage: dh config ${setting.key} clear');
        }
        await _configService.updateConfig(
          (current) => setting.writeValue(current, const []),
        );
        print('${setting.key} list cleared.');
        return 0;
      default:
        throw ArgumentError(
          'Invalid action for ${setting.key}: $action. '
          'Use set, add, remove, or clear.',
        );
    }
  }
}
