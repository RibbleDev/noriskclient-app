class NoRiskApi {
  static const String baseUrl = 'https://api.norisk.gg/api/v1/';
  static const String baseExperimentalUrl =
      'https://api-staging.norisk.gg/api/v1/';

  String getBaseUrl(bool experimental, String project) {
    return (experimental ? baseExperimentalUrl : baseUrl) + project;
  }

  String getAssetUrl() {
    return 'https://assets.norisk.gg/api/v1/assets/mcreal';
  }
}