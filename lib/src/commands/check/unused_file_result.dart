class UnusedFileResult {
  final String projectPath;
  final List<String> unusedFiles;
  final int totalFiles;
  final int usedFiles;
  final int usedLineCount;
  final double totalSizeKb;
  final List<String> warnings;
  final List<String> unreadableFiles;

  UnusedFileResult({
    required this.projectPath,
    required this.unusedFiles,
    required this.totalFiles,
    required this.usedFiles,
    required this.usedLineCount,
    required this.totalSizeKb,
    required this.warnings,
    required this.unreadableFiles,
  });

  int get unusedCount => unusedFiles.length;
  int get warningCount => warnings.length;
  String get formattedSize => '${totalSizeKb.toStringAsFixed(2)} KB';
}
