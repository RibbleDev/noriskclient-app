import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mcreal/config/Colors.dart';
import 'package:mcreal/utils/NoRiskApi.dart';
import 'package:mcreal/widgets/LoadingIndicator.dart';
import 'package:mcreal/widgets/NoRiskButton.dart';
import 'package:mcreal/widgets/QRScannerOverlayShape.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key, required this.updateStream});

  final StreamController<List> updateStream;

  @override
  State<SignIn> createState() => SignInState();
}

class SignInState extends State<SignIn> {
  bool isProcessingResult = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: McRealColors.background,
        body: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
                mainAxisAlignment: isProcessingResult
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          Image.asset('lib/assets/app/norisk_logo.png', height: 150),
          const Text('McReal.',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 50,
                  letterSpacing: -3.5)),
          isProcessingResult
              ? Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  const SizedBox(height: 10),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const LoadingIndicator(),
                        const SizedBox(width: 10),
                        Text(AppLocalizations.of(context)!.signIn_signingIn,
                            style: const TextStyle(fontSize: 12))
                      ])
                ])
              : Column(children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                  Text(AppLocalizations.of(context)!.signIn_signIn,
                      style: const TextStyle(
                          fontSize: 25, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Text(
                    AppLocalizations.of(context)!.signIn_explanation,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 35),
                  NoRiskButton(
                      onTap: scanQrCode,
                      child:
                          Text(AppLocalizations.of(context)!.signIn_scanQrCode))
                ])
                ],
              ),
        ));
  }

  void scanQrCode() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (BuildContext context) {
      MobileScannerController controller = MobileScannerController();
      return Scaffold(
        backgroundColor: McRealColors.background,
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
                    borderColor: McRealColors.light,
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
                      onPressed: Navigator.of(context).pop,
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

    widget.updateStream.sink.add(['signIn', userData]);
  }
}
