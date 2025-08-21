import 'package:flutter/material.dart';
import 'package:noriskclient/l10n/app_localizations.dart';
import 'package:noriskclient/config/Colors.dart';
import 'package:noriskclient/main.dart';
import 'package:noriskclient/screens/ScanQRCode.dart';
import 'package:noriskclient/screens/mcreal/ImageViewer.dart';
import 'package:noriskclient/utils/NoRiskApi.dart';
import 'package:noriskclient/widgets/NoRiskContainer.dart';
import 'package:noriskclient/widgets/NoRiskText.dart';

class Gamescom extends StatefulWidget {
  const Gamescom({super.key});

  @override
  State<Gamescom> createState() => GamescomState();
}

class GamescomState extends State<Gamescom> {
  Map<String, dynamic>? gamescomInfos;

  @override
  void initState() {
    super.initState();
    loadGamescomInfos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: NoRiskClientColors.background,
        body: Padding(
          padding: const EdgeInsets.all(15),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(
                    top: 85,
                    bottom: 150 +
                        (isAndroid
                            ? MediaQuery.of(context).viewPadding.bottom
                            : 0),
                    left: 10,
                    right: 10),
                child: RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        gamescomInfos = null;
                      });
                      loadGamescomInfos();
                    },
                    child: ListView(children: gamescomInfos == null ? [
                      Center(
                        child: NoRiskText(
                          AppLocalizations.of(context)!.gamescom_no_infos.toLowerCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: NoRiskClientColors.textLight,
                              fontSize: 25),
                        ),
                      )
                    ] : [
                      NoRiskText(gamescomInfos!['text']?.toString().toLowerCase() ?? '',
                          spaceTop: false,
                          spaceBottom: false,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.normal,
                              height: 0.75,
                              color: NoRiskClientColors.text)),
                      const SizedBox(height: 5),
                      NoRiskText('~ ${gamescomInfos!['author']?.toString().toLowerCase() ?? 'unknown'} - ${gamescomInfos!['createdAt'] != null
                            ? DateTime.fromMillisecondsSinceEpoch(gamescomInfos!['createdAt']).toLocal().toString().split('.')[0].replaceAll('-', '.')
                            : 'unknown'}',
                      spaceTop: false,
                      spaceBottom: false,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                          color: NoRiskClientColors.text)),
                      const SizedBox(height: 20),
                      if (gamescomInfos!['images'] != null)
                        ...gamescomInfos!['images'].map<Widget>((image) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ImageViewer(image: Image.network(image)),
                                ),
                              ),
                              child: Image.network(
                                image,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: 200,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: NoRiskText(
                                      'Image could not be loaded',
                                      style: TextStyle(
                                          color: NoRiskClientColors.textLight,
                                          fontSize: 16),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }).toList(),
                    ])),
              ),
                  Padding(
                    padding: const EdgeInsets.only(top: 35),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: NoRiskText('gamescom',
                            spaceTop: false,
                            spaceBottom: false,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 45,
                                fontWeight: FontWeight.bold,
                                color: NoRiskClientColors.text)),
                    ),
                  ),
                            const SizedBox(height: 20),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: 55 +
                          (isAndroid
                              ? MediaQuery.of(context).viewPadding.bottom
                              : 0)),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (BuildContext context) {
                      return ScanQRCode();
                    })),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: NoRiskContainer(
                        height: 65,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: NoRiskClientColors.blue,
                            borderRadius: BorderRadius.circular(10)),
                        child: Center(
                          child: NoRiskText(
                              AppLocalizations.of(context)!
                                  .signIn_scanQrCode
                                  .toLowerCase(),
                              spaceTop: false,
                              spaceBottom: false,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 35,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  void loadGamescomInfos() async {
    Map<String, dynamic>? data = await NoRiskApi().getGamescomInfos();

    setState(() {
      gamescomInfos = data;
    });
  }
}
