// ignore: file_names
class Config {
  static const String fallbackLangauge = 'en';
  static const List<String> availableLanguages = ['de', 'en'];

  static int mcRealTimeframe = 15;
  static int maxPostsPerPage = 10;
  static int maxCommentsPerPage = 25;
  static int maxCommentContentLength = 150;
  static int maxReportContentLength = 200;

  static Uri privacyUrl = Uri.parse('https://norisk.gg/privacy-policy');
  static Uri termsUrl = Uri.parse('https://norisk.gg/terms-of-service');
  static Uri imprintUrl = Uri.parse('https://norisk.gg/imprint');
  static Uri supportUrl = Uri.parse('https://norisk.gg/support');
}
