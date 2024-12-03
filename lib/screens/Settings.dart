import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mcreal/config/Colors.dart';
import 'package:mcreal/main.dart';
import 'package:mcreal/config/Config.dart';
import 'package:mcreal/provider/localeProvider.dart';
import 'package:mcreal/screens/Blocked.dart';
import 'package:mcreal/utils/NoRiskIcon.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class Settings extends StatefulWidget {
  const Settings({super.key, required this.postUpdateStream});

  final StreamController<String> postUpdateStream;

  @override
  State<Settings> createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  PackageInfo? packageInfo;

  @override
  void initState() {
    loadAppInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: NoRiskClientColors.background,
        body: Padding(
            padding: const EdgeInsets.all(15),
            child: Center(
              child: Column(children: [
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
                                child: NoRiskIcon.back,
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
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height - 160,
                  child: ListView(children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(width: 5),
                        Text(AppLocalizations.of(context)!.settings_language,
                            style: const TextStyle(
                                color: NoRiskClientColors.text,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
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
                                  color: AppLocalizations.of(context)!
                                              .localeName ==
                                          'de'
                                      ? NoRiskClientColors.textLight
                                      : NoRiskClientColors.text,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
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
                                  color: AppLocalizations.of(context)!
                                              .localeName ==
                                          'en'
                                      ? NoRiskClientColors.textLight
                                      : NoRiskClientColors.text,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(width: 5),
                        Text(
                            AppLocalizations.of(context)!
                                .settings_blockedPlayers,
                            style: const TextStyle(
                                color: NoRiskClientColors.text,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Blocked(
                                  postUpdateStream: widget.postUpdateStream))),
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                            color: NoRiskClientColors.darkerBackground,
                            borderRadius: BorderRadius.circular(10)),
                        child: Center(
                          child: Text(
                              AppLocalizations.of(context)!
                                  .settings_blockedPlayers,
                              style: const TextStyle(
                                  color: NoRiskClientColors.text,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(width: 5),
                        Text(AppLocalizations.of(context)!.settings_legal,
                            style: const TextStyle(
                                color: NoRiskClientColors.text,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: () => launchUrl(
                          mode: LaunchMode.externalApplication,
                          Config.termsUrl),
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                            color: NoRiskClientColors.darkerBackground,
                            borderRadius: BorderRadius.circular(10)),
                        child: Center(
                          child: Text(
                              AppLocalizations.of(context)!.settings_tos,
                              style: const TextStyle(
                                  color: NoRiskClientColors.text,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: () => launchUrl(
                          mode: LaunchMode.externalApplication,
                          Config.privacyUrl),
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                            color: NoRiskClientColors.darkerBackground,
                            borderRadius: BorderRadius.circular(10)),
                        child: Center(
                          child: Text(
                              AppLocalizations.of(context)!
                                  .settings_privacyPolicy,
                              style: const TextStyle(
                                  color: NoRiskClientColors.text,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: () => launchUrl(
                          mode: LaunchMode.externalApplication,
                          Config.imprintUrl),
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                            color: NoRiskClientColors.darkerBackground,
                            borderRadius: BorderRadius.circular(10)),
                        child: Center(
                          child: Text(
                              AppLocalizations.of(context)!.settings_imprint,
                              style: const TextStyle(
                                  color: NoRiskClientColors.text,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(width: 5),
                        Text(AppLocalizations.of(context)!.settings_support,
                            style: const TextStyle(
                                color: NoRiskClientColors.text,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: () => launchUrl(
                          mode: LaunchMode.externalApplication,
                          Config.supportUrl),
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                            color: NoRiskClientColors.darkerBackground,
                            borderRadius: BorderRadius.circular(10)),
                        child: Center(
                          child: Text(
                              "🛟 ${AppLocalizations.of(context)!.settings_support}",
                              style: const TextStyle(
                                  color: NoRiskClientColors.text,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
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
                    const SizedBox(height: 20),
                    if (packageInfo != null)
                      Center(
                        child: Text(
                            "Version ${packageInfo!.version} - ${packageInfo!.buildNumber}",
                            style: const TextStyle(
                                color: NoRiskClientColors.textLight,
                                fontSize: 15)),
                      ),
                  ]),
                )
              ]),
            )));
  }

  Future<void> setLanguage(String language) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    final provider = Provider.of<LocaleProvider>(context, listen: false);
    provider.setLocale(language);
  }

  void loadAppInfo() async {
    PackageInfo _packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      packageInfo = _packageInfo;
    });
  }
}
