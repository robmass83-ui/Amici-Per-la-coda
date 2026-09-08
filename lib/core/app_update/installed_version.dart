class InstalledVersion {
  const InstalledVersion({
    required this.versionName,
    required this.versionCode,
    required this.abis,
  });

  final String versionName;
  final int versionCode;
  final List<String> abis;

  String get label => '$versionName ($versionCode)';
}
