import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:noriskclient/config/Config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = Locale(
      Config.availableLanguages.contains(PlatformDispatcher.instance.locale.languageCode)
          ? PlatformDispatcher.instance.locale.languageCode
          : Config.fallbackLangauge);
  Locale get locale => _locale;

  void setLocale(String languageCode) {
    _locale = Locale(languageCode.toLowerCase());
    notifyListeners();
  }

  void loadLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String language = prefs.getString('language') ??
        (Config.availableLanguages
                .contains(PlatformDispatcher.instance.locale.languageCode)
            ? PlatformDispatcher.instance.locale.languageCode
            : Config.fallbackLangauge);
    print('LANGUAGE: $language');
    setLocale(language);

    if (prefs.getString('language') == null) {
      await prefs.setString('language', language);
    }
  }
}
