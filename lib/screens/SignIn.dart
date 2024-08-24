import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mcreal/config/Colors.dart';
import 'package:mcreal/config/Config.dart';
import 'package:mcreal/main.dart';
import 'package:mcreal/provider/localeProvider.dart';
import 'package:mcreal/utils/NoRiskApi.dart';
import 'package:mcreal/widgets/LoadingIndicator.dart';
import 'package:mcreal/widgets/QRScannerOverlayShape.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
                  Image.asset('lib/assets/app/norisk_logo.png', height: 150),
                  const Text('NoRiskClient',
                      style: TextStyle(
                          color: NoRiskClientColors.text,
                          fontWeight: FontWeight.bold,
                          fontSize: 50,
                          letterSpacing: -1)),
                ],
              ),
              Column(children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                Text(
                  AppLocalizations.of(context)!.signIn_explanation,
                  style: const TextStyle(
                      fontSize: 12, color: NoRiskClientColors.textLight),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: scanQrCode,
                  child: Container(
                    height: 65,
                    margin:
                        const EdgeInsets.only(left: 20, right: 20, bottom: 10),
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
                                Text(
                                    AppLocalizations.of(context)!
                                        .signIn_signingIn,
                                    style: const TextStyle(fontSize: 15))
                              ]
                            : [
                                Icon(Icons.qr_code_rounded,
                                    color: isProcessingResult
                                        ? Colors.white.withOpacity(0.5)
                                        : Colors.white),
                                const SizedBox(width: 10),
                                Text(
                                  AppLocalizations.of(context)!
                                      .signIn_scanQrCode,
                                  style: TextStyle(
                                      color: isProcessingResult
                                          ? Colors.white.withOpacity(0.5)
                                          : Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                      ),
                    ),
                  ),
                )
              ])
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
                      controller, result.raw[0]?['rawValue'].toString() ?? '');
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
    setState(() {
      isProcessingResult = true;
    });
    controller.stop();
    controller.dispose();
    Navigator.of(context).pop();

    http.Response res = await http.get(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/user/validateToken?uuid=${userData['uuid']}'),
        headers: {'Authorization': 'Bearer ${userData['token']}'});

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
