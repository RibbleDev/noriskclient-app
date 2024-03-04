class NoRiskApi {
  static const String baseUrl = 'https://api.norisk.gg/mcreal';
  static const String baseExperimentalUrl = 'https://api-staging.norisk.gg/mcreal';

  String getBaseUrl(bool experimental) {
    return experimental ? baseExperimentalUrl : baseUrl;
  }
}