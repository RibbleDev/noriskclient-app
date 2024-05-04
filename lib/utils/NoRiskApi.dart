class NoRiskApi {
  static const String baseUrl = 'https://api.norisk.gg/';
  static const String baseExperimentalUrl = 'https://api-staging.norisk.gg/';

  String getBaseUrl(bool experimental, String project) {
    return (experimental ? baseExperimentalUrl : baseUrl) + project;
  }
}