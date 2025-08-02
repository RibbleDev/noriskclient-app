// ignore: file_names
class Config {
  static const String fallbackLangauge = 'en';
  static const List<String> availableLanguages = ['de', 'en'];

  static int mcRealTimeframe = 15;
  static int maxPostsPerPage = 10;
  static int maxCommentsPerPage = 25;
  static int maxCommentContentLength = 150;
  static int maxReportContentLength = 200;

  static Uri privacyUrl = Uri.parse('https://blog.norisk.gg/privacy-policy/');
  static Uri termsUrl = Uri.parse('https://blog.norisk.gg/en/terms-of-use/');
  static Uri imprintUrl = Uri.parse('https://blog.norisk.gg/impressum/');
  static Uri supportUrl = Uri.parse('mailto:support@norisk.gg');
}
