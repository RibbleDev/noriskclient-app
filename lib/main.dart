import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:mcreal/App.dart';
import 'package:mcreal/provider/localeProvider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => AppState();
}

class AppState extends State<App> {
  @override
  void initState() {
    removeSplashScreen();
    super.initState();
  }

  Future<void> removeSplashScreen() async {
    await Future.delayed(const Duration(seconds: 2));
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LocaleProvider(),
      builder: (context, child) {
        final provider = Provider.of<LocaleProvider>(context);
          return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  locale: provider.locale,
                  theme: ThemeData(
                      useMaterial3: true,
                      brightness: Brightness.dark,
                      textTheme: Theme.of(context).textTheme.apply(
                        fontFamily: 'Roboto',
                        displayColor: Colors.white,
                        bodyColor: Colors.white),
                      appBarTheme: const AppBarTheme(
                          backgroundColor: Colors.black)),
                  home: MediaQuery(
                    data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
                    child: McRealApp(language: provider.locale.languageCode),
                  ),
                );
      }
    );
  }
}
