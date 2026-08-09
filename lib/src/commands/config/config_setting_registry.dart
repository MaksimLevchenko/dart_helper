import 'config_setting_spec.dart';

final ConfigSettingRegistry configSettingRegistry = ConfigSettingRegistry();

class ConfigSettingRegistry {
  final Map<String, ConfigSettingSpec> _settings = {
    'fluttergen': BooleanConfigSettingSpec(
      key: 'fluttergen',
      description:
          'Controls whether "dh build" runs fluttergen after build_runner.',
      readValue: (config) => config.fluttergenEnabled,
      writeValue: (config, value) => config.copyWith(fluttergenEnabled: value),
    ),
    'fvm': BooleanConfigSettingSpec(
      key: 'fvm',
      description:
          'Controls the default use of "fvm exec" for supported commands.',
      readValue: (config) => config.useFvmByDefault,
      writeValue: (config, value) => config.copyWith(useFvmByDefault: value),
    ),
    'update-checks': BooleanConfigSettingSpec(
      key: 'update-checks',
      description: 'Controls automatic package update checks at CLI startup.',
      readValue: (config) => config.updateChecksEnabled,
      writeValue: (config, value) =>
          config.copyWith(updateChecksEnabled: value),
    ),
    'check.details': BooleanConfigSettingSpec(
      key: 'check.details',
      description:
          'Controls whether "dh check" shows the full list of unused files.',
      readValue: (config) => config.checkDetailsByDefault,
      writeValue: (config, value) =>
          config.copyWith(checkDetailsByDefault: value),
    ),
    'check.interactive': BooleanConfigSettingSpec(
      key: 'check.interactive',
      description:
          'Controls whether "dh check" prompts for interactive cleanup by default.',
      readValue: (config) => config.checkInteractiveByDefault,
      writeValue: (config, value) =>
          config.copyWith(checkInteractiveByDefault: value),
    ),
    'get-all.tree': BooleanConfigSettingSpec(
      key: 'get-all.tree',
      description:
          'Controls whether "dh get-all" uses tree view output by default.',
      readValue: (config) => config.getAllTreeByDefault,
      writeValue: (config, value) =>
          config.copyWith(getAllTreeByDefault: value),
    ),
    'color': BooleanConfigSettingSpec(
      key: 'color',
      description: 'Controls ANSI-colored CLI output.',
      readValue: (config) => config.colorEnabled,
      writeValue: (config, value) => config.copyWith(colorEnabled: value),
    ),
    'check.exclude-pattern': StringListConfigSettingSpec(
      key: 'check.exclude-pattern',
      description:
          'Global file patterns appended to the "dh check" exclude-pattern list.',
      readValue: (config) => List<String>.from(config.checkExcludePatterns),
      writeValue: (config, values) =>
          config.copyWith(checkExcludePatterns: values),
    ),
    'check.exclude-folder': StringListConfigSettingSpec(
      key: 'check.exclude-folder',
      description:
          'Global folders appended to the "dh check" exclude-folder list.',
      readValue: (config) => List<String>.from(config.checkExcludeFolders),
      writeValue: (config, values) =>
          config.copyWith(checkExcludeFolders: values),
    ),
    'reverse.ports': IntListConfigSettingSpec(
      key: 'reverse.ports',
      description:
          'Ports used by "dh reverse" for sequential adb reverse commands.',
      readValue: (config) => List<int>.from(config.reversePorts),
      writeValue: (config, values) => config.copyWith(reversePorts: values),
    ),
  };

  ConfigSettingSpec? operator [](String key) => _settings[key];
}
