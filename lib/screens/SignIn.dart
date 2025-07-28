import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:noriskclient/l10n/app_localizations.dart';
import 'package:noriskclient/config/Colors.dart';
import 'package:noriskclient/config/Config.dart';
import 'package:noriskclient/main.dart';
import 'package:noriskclient/provider/localeProvider.dart';
import 'package:noriskclient/utils/NoRiskApi.dart';
import 'package:noriskclient/widgets/LoadingIndicator.dart';
import 'package:noriskclient/widgets/NoRiskContainer.dart';
import 'package:noriskclient/widgets/NoRiskText.dart';
import 'package:noriskclient/widgets/QRScannerOverlayShape.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => SignInState();
}

class SignInState extends State<SignIn> {
  bool isProcessingResult = false;

  @override
  void initState() {
    loadLanguage();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: NoRiskClientColors.background,
        body: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisAlignment: isProcessingResult
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.125),
                  GestureDetector(
                      onLongPress: showDeveloperSignInPopup,
                      child: Image.asset('lib/assets/app/norisk_logo.png',
                          height: 150)),
                  NoRiskText('NoRisk Client'.toLowerCase(),
                      style: TextStyle(
                          color: NoRiskClientColors.text,
                          fontWeight: FontWeight.bold,
                          fontSize: 80,
                          letterSpacing: -1)),
                ],
              ),
              Column(children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                NoRiskText(
                  AppLocalizations.of(context)!
                      .signIn_explanation
                      .toLowerCase(),
                  spaceTop: false,
                  spaceBottom: false,
                  style: const TextStyle(
                      fontSize: 17, color: NoRiskClientColors.textLight),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                NoRiskText(
                  AppLocalizations.of(context)!.signIn_eula.toLowerCase(),
                  spaceTop: false,
                  spaceBottom: false,
                  style: const TextStyle(
                      fontSize: 15, color: NoRiskClientColors.textLight),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: scanQrCode,
                  child: Padding(
                    padding:
                        const EdgeInsets.only(left: 20, right: 20, bottom: 10),
                    child: NoRiskContainer(
                      height: 65,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: isProcessingResult
                              ? NoRiskClientColors.blue.withOpacity(0.5)
                              : NoRiskClientColors.blue,
                          borderRadius: BorderRadius.circular(10)),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: isProcessingResult
                              ? [
                                  const LoadingIndicator(color: Colors.white),
                                  const SizedBox(width: 10),
                                  NoRiskText(
                                      AppLocalizations.of(context)!
                                          .signIn_signingIn
                                          .toLowerCase(),
                                      style: const TextStyle(fontSize: 35))
                                ]
                              : [
                                  NoRiskText(
                                    AppLocalizations.of(context)!
                                        .signIn_scanQrCode
                                        .toLowerCase(),
                                    spaceTop: false,
                                    spaceBottom: false,
                                    style: TextStyle(
                                        color: isProcessingResult
                                            ? Colors.white.withOpacity(0.5)
                                            : Colors.white,
                                        fontSize: 35,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => launchUrl(Config.privacyUrl,
                            mode: LaunchMode.externalApplication),
                        child: NoRiskText(
                            AppLocalizations.of(context)!
                                .settings_privacyPolicy
                                .toLowerCase(),
                            style: TextStyle(
                                fontSize: 22.5,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.blue)),
                      ),
                      const SizedBox(width: 50),
                      GestureDetector(
                        onTap: () => launchUrl(Config.termsUrl,
                            mode: LaunchMode.externalApplication),
                        child: NoRiskText(
                            AppLocalizations.of(context)!
                                .settings_tos
                                .toLowerCase(),
                            style: TextStyle(
                                fontSize: 22.5,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.blue)),
                      ),
                    ]),
                const SizedBox(height: 10),
              ]),
            ],
          ),
        ));
  }

  Future<void> loadLanguage() async {
    // Ich schäme mich dafür aber juckt jz grad :skull:
    await Future.delayed(const Duration(seconds: 1));
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String language = prefs.getString('language') ??
        (Config.availableLanguages
                .contains(PlatformDispatcher.instance.locale.languageCode)
            ? PlatformDispatcher.instance.locale.languageCode
            : Config.fallbackLangauge);
    if (!mounted) return;
    final provider = Provider.of<LocaleProvider>(context, listen: false);
    provider.setLocale(language);

    if (prefs.getString('language') == null) {
      await prefs.setString('language', language);
    }
  }

  void scanQrCode() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (BuildContext context) {
      MobileScannerController controller = MobileScannerController();
      return Scaffold(
        backgroundColor: NoRiskClientColors.background,
        body: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: MobileScanner(
                fit: BoxFit.fitHeight,
                controller: controller,
                onDetect: (BarcodeCapture result) {
                  handleQrCodeResult(
                      controller, result.barcodes[0].rawValue ?? '');
                },
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: ShapeDecoration(
                  shape: QrScannerOverlayShape(
                    borderColor: NoRiskClientColors.light,
                    borderRadius: 10,
                    borderLength: 15,
                    borderWidth: 7.5,
                    cutOutSize: MediaQuery.of(context).size.width / 1.5,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10, top: 40),
              child: Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                      onPressed: () {
                        controller.stop();
                        controller.dispose();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 30))),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: IconButton(
                    onPressed: () async {
                      await controller.toggleTorch();
                    },
                    icon: const Icon(Icons.flash_on_rounded,
                        color: Colors.white, size: 50)),
              ),
            ),
          ],
        ),
      );
    }));
  }

  Future<void> handleQrCodeResult(
      MobileScannerController controller, String result) async {
    Map<String, dynamic> userData = jsonDecode(result);
    if (userData['uuid'] == null ||
        userData['experimental'] == null ||
        userData['token'] == null) {
      return;
    }
    Vibration.vibrate(duration: 500);

    controller.stop();
    controller.dispose();
    Navigator.of(context).pop();

    await signIn(userData);
  }

  void showDeveloperSignInPopup() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          TextEditingController uuidController = TextEditingController();
          TextEditingController tokenController = TextEditingController();

          Map<String, dynamic> userData = {
            'uuid': '',
            'experimental': false,
            'token': ''
          };

          uuidController
              .addListener(() => userData['uuid'] = uuidController.text);
          tokenController
              .addListener(() => userData['token'] = tokenController.text);

          return AlertDialog(
            title: const Text('Developer Sign In'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'If you are not a developer, please close this dialog and use the QR code scanner.'),
                const SizedBox(height: 10),
                TextField(
                  controller: uuidController,
                  decoration: const InputDecoration(labelText: 'UUID'),
                ),
                TextField(
                  controller: tokenController,
                  decoration: const InputDecoration(labelText: 'Token'),
                ),
                const SizedBox(height: 15),
                const Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Sign In Environment:',
                        textAlign: TextAlign.start,
                      )
                    ]),
                const SizedBox(height: 5),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ElevatedButton(
                          onPressed: () {
                            userData['experimental'] = true;
                            Navigator.of(context).pop();
                            signIn(userData);
                          },
                          child: const Text('Experimental')),
                      ElevatedButton(
                          onPressed: () {
                            userData['experimental'] = false;
                            Navigator.of(context).pop();
                            signIn(userData);
                          },
                          child: const Text('Production'))
                    ]),
              ],
            ),
          );
        });
  }

  Future<void> signIn(Map<String, dynamic> userData) async {
    http.Response res = await http.get(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/user/validateToken?uuid=${userData['uuid']}'),
        headers: {'Authorization': 'Bearer ${userData['token']}'});

    setState(() {
      isProcessingResult = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (res.statusCode != 200) {
      setState(() {
        isProcessingResult = false;
      });
      return;
    }

    updateStream.sink.add(['signIn', userData]);
  }
}
