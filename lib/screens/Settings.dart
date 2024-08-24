import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mcreal/config/Colors.dart';
import 'package:mcreal/main.dart';
import 'package:mcreal/provider/localeProvider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: NoRiskClientColors.background,
        body: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  Stack(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 7.5),
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: Center(
                                  child: Icon(
                                      isIOS
                                          ? CupertinoIcons.back
                                          : Icons.arrow_back,
                                      color: NoRiskClientColors.text,
                                      size: 30),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(AppLocalizations.of(context)!.settings_title,
                              style: const TextStyle(
                                  color: NoRiskClientColors.text,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setLanguage('de'),
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                          color: NoRiskClientColors.darkerBackground,
                          borderRadius: BorderRadius.circular(10)),
                      child: Center(
                        child: Text('🇩🇪 Deutsch',
                            style: TextStyle(
                                color:
                                    AppLocalizations.of(context)!.localeName ==
                                            'de'
                                        ? NoRiskClientColors.textLight
                                        : NoRiskClientColors.text,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => setLanguage('en'),
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                          color: NoRiskClientColors.darkerBackground,
                          borderRadius: BorderRadius.circular(10)),
                      child: Center(
                        child: Text('🇺🇸 English',
                            style: TextStyle(
                                color:
                                    AppLocalizations.of(context)!.localeName ==
                                            'en'
                                        ? NoRiskClientColors.textLight
                                        : NoRiskClientColors.text,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      getUpdateStream.sink.add(['signOut']);
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                          color: NoRiskClientColors.darkerBackground,
                          borderRadius: BorderRadius.circular(10)),
                      child: Center(
                        child: Text(
                            AppLocalizations.of(context)!.settings_signOut,
                            style: const TextStyle(
                                color: Colors.red,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const Spacer(),
                ])));
  }

  Future<void> setLanguage(String language) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    final provider = Provider.of<LocaleProvider>(context, listen: false);
    provider.setLocale(language);
  }
}
