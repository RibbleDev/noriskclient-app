import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mcreal/config/Config.dart';

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
}
