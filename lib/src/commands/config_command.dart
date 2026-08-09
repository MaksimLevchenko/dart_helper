import '../cli/help_printer.dart';
import '../services/config_service.dart';
import 'config/config_action_handlers.dart';
import 'config/config_setting_registry.dart';
import 'config/config_setting_spec.dart';

class ConfigCommand {
  final ConfigService _configService;
  final HelpPrinter _helpPrinter;
  final ConfigActionHandlers _actionHandlers;

  ConfigCommand(this._configService, this._helpPrinter)
      : _actionHandlers = ConfigActionHandlers(_configService, _helpPrinter);

  Future<int> execute({
    List<String> args = const [],
  }) async {
    final config = await _configService.readConfig();
    if (args.isEmpty) {
      _helpPrinter.printConfigHelp(config);
      return 0;
    }

    final settingKey = args.first;
    final values = args.skip(1).toList();
    final setting = configSettingRegistry[settingKey];

    if (setting == null) {
      throw ArgumentError(
        'Unknown config setting: $settingKey. '
        'Use "dh config" to see supported settings.',
      );
    }

    if (setting is BooleanConfigSettingSpec) {
      return _actionHandlers.handleBooleanSetting(config, setting, values);
    }

    if (setting is StringListConfigSettingSpec) {
      return _actionHandlers.handleStringListSetting(config, setting, values);
    }

    if (setting is IntListConfigSettingSpec) {
      return _actionHandlers.handleIntListSetting(config, setting, values);
    }

    throw ArgumentError('Unsupported config setting: $settingKey');
  }
}
