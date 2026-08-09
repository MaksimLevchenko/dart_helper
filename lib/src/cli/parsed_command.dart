class ParsedCommand {
  final bool showHelp;
  final String? name;
  final bool? useFvm;
  final bool force;
  final String? checkPath;
  final List<String> excludePatterns;
  final List<String> excludeFolders;
  final bool? showDetails;
  final bool? checkInteractive;
  final String? getAllPath;
  final bool? getAllUseFvm;
  final bool? getAllInteractive;
  final bool? getAllTreeView;
  final List<int>? reversePorts;
  final List<String> configArgs;

  const ParsedCommand({
    this.showHelp = false,
    required this.name,
    required this.useFvm,
    required this.force,
    this.checkPath,
    this.excludePatterns = const [],
    this.excludeFolders = const [],
    this.showDetails,
    this.checkInteractive,
    this.getAllPath,
    this.getAllUseFvm,
    this.getAllInteractive,
    this.getAllTreeView,
    this.reversePorts,
    this.configArgs = const [],
  });
}
