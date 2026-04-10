class CliConfig {
  static const List<int> defaultReversePorts = [
    8080,
    8081,
    8082,
    8083,
    8084,
    8085,
    8086,
    8087,
    8088,
    8089,
    8090,
    8091,
    8092,
  ];

  final bool fluttergenEnabled;
  final bool useFvmByDefault;
  final bool updateChecksEnabled;
  final bool checkDetailsByDefault;
  final bool checkInteractiveByDefault;
  final bool getAllTreeByDefault;
  final List<String> checkExcludePatterns;
  final List<String> checkExcludeFolders;
  final List<int> reversePorts;
  final bool colorEnabled;

  const CliConfig({
    this.fluttergenEnabled = true,
    this.useFvmByDefault = false,
    this.updateChecksEnabled = true,
    this.checkDetailsByDefault = true,
    this.checkInteractiveByDefault = false,
    this.getAllTreeByDefault = true,
    this.checkExcludePatterns = const [],
    this.checkExcludeFolders = const [],
    this.reversePorts = defaultReversePorts,
    this.colorEnabled = true,
  });

  factory CliConfig.fromJson(Map<String, dynamic> json) {
    return CliConfig(
      fluttergenEnabled: _readBool(json, 'fluttergenEnabled', true),
      useFvmByDefault: _readBool(json, 'useFvmByDefault', false),
      updateChecksEnabled: _readBool(json, 'updateChecksEnabled', true),
      checkDetailsByDefault: _readBool(json, 'checkDetailsByDefault', true),
      checkInteractiveByDefault:
          _readBool(json, 'checkInteractiveByDefault', false),
      getAllTreeByDefault: _readBool(json, 'getAllTreeByDefault', true),
      checkExcludePatterns:
          _readStringList(json, 'checkExcludePatterns', const []),
      checkExcludeFolders:
          _readStringList(json, 'checkExcludeFolders', const []),
      reversePorts: _readPortList(json, 'reversePorts', defaultReversePorts),
      colorEnabled: _readColorEnabled(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fluttergenEnabled': fluttergenEnabled,
      'useFvmByDefault': useFvmByDefault,
      'updateChecksEnabled': updateChecksEnabled,
      'checkDetailsByDefault': checkDetailsByDefault,
      'checkInteractiveByDefault': checkInteractiveByDefault,
      'getAllTreeByDefault': getAllTreeByDefault,
      'checkExcludePatterns': checkExcludePatterns,
      'checkExcludeFolders': checkExcludeFolders,
      'reversePorts': reversePorts,
      'color': colorEnabled ? 'on' : 'off',
    };
  }

  CliConfig copyWith({
    bool? fluttergenEnabled,
    bool? useFvmByDefault,
    bool? updateChecksEnabled,
    bool? checkDetailsByDefault,
    bool? checkInteractiveByDefault,
    bool? getAllTreeByDefault,
    List<String>? checkExcludePatterns,
    List<String>? checkExcludeFolders,
    List<int>? reversePorts,
    bool? colorEnabled,
  }) {
    return CliConfig(
      fluttergenEnabled: fluttergenEnabled ?? this.fluttergenEnabled,
      useFvmByDefault: useFvmByDefault ?? this.useFvmByDefault,
      updateChecksEnabled: updateChecksEnabled ?? this.updateChecksEnabled,
      checkDetailsByDefault:
          checkDetailsByDefault ?? this.checkDetailsByDefault,
      checkInteractiveByDefault:
          checkInteractiveByDefault ?? this.checkInteractiveByDefault,
      getAllTreeByDefault: getAllTreeByDefault ?? this.getAllTreeByDefault,
      checkExcludePatterns:
          checkExcludePatterns ?? List<String>.from(this.checkExcludePatterns),
      checkExcludeFolders:
          checkExcludeFolders ?? List<String>.from(this.checkExcludeFolders),
      reversePorts: reversePorts ?? List<int>.from(this.reversePorts),
      colorEnabled: colorEnabled ?? this.colorEnabled,
    );
  }

  static bool _readBool(
    Map<String, dynamic> json,
    String key,
    bool defaultValue,
  ) {
    final value = json[key];
    if (value == null) {
      return defaultValue;
    }
    if (value is bool) {
      return value;
    }
    throw FormatException('Invalid value for "$key": expected boolean.');
  }

  static List<String> _readStringList(
    Map<String, dynamic> json,
    String key,
    List<String> defaultValue,
  ) {
    final value = json[key];
    if (value == null) {
      return defaultValue;
    }
    if (value is List) {
      if (value.every((item) => item is String)) {
        return List<String>.from(value);
      }
      throw FormatException(
        'Invalid value for "$key": expected a list of strings.',
      );
    }
    throw FormatException('Invalid value for "$key": expected a list.');
  }

  static List<int> _readPortList(
    Map<String, dynamic> json,
    String key,
    List<int> defaultValue,
  ) {
    final value = json[key];
    if (value == null) {
      return defaultValue;
    }
    if (value is! List) {
      throw FormatException('Invalid value for "$key": expected a list.');
    }

    final ports = <int>[];
    for (final item in value) {
      if (item is! int) {
        throw FormatException(
          'Invalid value for "$key": expected a list of integer ports.',
        );
      }
      if (item < 1 || item > 65535) {
        throw FormatException(
          'Invalid value for "$key": port $item is out of range.',
        );
      }
      ports.add(item);
    }

    return ports;
  }

  static bool _readColorEnabled(Map<String, dynamic> json) {
    final value = json['color'];
    if (value == null) {
      return true;
    }
    if (value == 'on') {
      return true;
    }
    if (value == 'off') {
      return false;
    }
    throw const FormatException(
        'Invalid value for "color": use "on" or "off".');
  }
}
