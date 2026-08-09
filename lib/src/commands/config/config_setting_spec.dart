import '../../models/cli_config.dart';

abstract class ConfigSettingSpec {
  final String key;
  final String description;

  const ConfigSettingSpec({
    required this.key,
    required this.description,
  });
}

class BooleanConfigSettingSpec extends ConfigSettingSpec {
  final bool Function(CliConfig config) readValue;
  final CliConfig Function(CliConfig config, bool value) writeValue;

  const BooleanConfigSettingSpec({
    required super.key,
    required super.description,
    required this.readValue,
    required this.writeValue,
  });
}

class StringListConfigSettingSpec extends ConfigSettingSpec {
  final List<String> Function(CliConfig config) readValue;
  final CliConfig Function(CliConfig config, List<String> values) writeValue;

  const StringListConfigSettingSpec({
    required super.key,
    required super.description,
    required this.readValue,
    required this.writeValue,
  });
}

class IntListConfigSettingSpec extends ConfigSettingSpec {
  final List<int> Function(CliConfig config) readValue;
  final CliConfig Function(CliConfig config, List<int> values) writeValue;

  const IntListConfigSettingSpec({
    required super.key,
    required super.description,
    required this.readValue,
    required this.writeValue,
  });
}
