/// Sorgente degli APK: GitHub Releases del repo di progetto.
abstract final class GithubUpdateConfig {
  static const owner = 'robmass83-ui';
  static const repo = 'Amici-Per-la-coda';

  /// Token solo-lettura opzionale, iniettato a build time se il repo è privato.
  /// Non mettere mai un token con permesso di scrittura.
  static const token = String.fromEnvironment('GITHUB_RELEASES_TOKEN');

  static const userAgent = 'AmiciPerLaCoda/1';
}
