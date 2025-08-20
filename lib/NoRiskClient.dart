import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:noriskclient/config/Colors.dart';
import 'package:noriskclient/config/Config.dart';
import 'package:noriskclient/main.dart';
import 'package:noriskclient/provider/localeProvider.dart';
import 'package:noriskclient/screens/Chats.dart';
import 'package:noriskclient/screens/Gamescom.dart';
import 'package:noriskclient/screens/McReal.dart';
import 'package:noriskclient/screens/News.dart';
import 'package:noriskclient/screens/NoRiskProfile.dart';
import 'package:noriskclient/utils/NoRiskApi.dart';
import 'package:noriskclient/widgets/BottomNavigationBar.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class NoRiskClient extends StatefulWidget {
  const NoRiskClient({super.key});

  @override
  State<NoRiskClient> createState() => NoRiskClientState();
}

class NoRiskClientState extends State<NoRiskClient> {
  StreamController<int> activeTabIndexController = StreamController<int>();
  PackageInfo? packageInfo;
  int tabIndex = activeTabIndex;
  int? lastCheckedAndroidRelease;

  void checkAndroidRelease() async {
    int now = DateTime.now().millisecondsSinceEpoch;

    if (lastCheckedAndroidRelease == null) {
      lastCheckedAndroidRelease = now;
      return;
    }

    int timeout = 1000 * 60 * 60;
    // int timeout = 1000;

    if (lastCheckedAndroidRelease! + timeout <= now) {
      lastCheckedAndroidRelease = now;

      String? isReleased = await NoRiskApi().isAndroidAppReleased();
      print('Android app released: $isReleased');
      if (isReleased == null) {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Android PlayStore Release'.toLowerCase(),
                    style: TextStyle(fontSize: 25, height: 0.85)),
                content: Text(
                    'The android app has now been released in the PlayStore! Please update your app.'
                        .toLowerCase(),
                    style: TextStyle(fontSize: 20, height: 0.75)),
                actions: [
                  TextButton(
                    onPressed: () => launchUrl(Config.playStoreUrl),
                    child: Text('Update!'.toLowerCase(),
                        style: const TextStyle(
                            fontSize: 25, color: NoRiskClientColors.blue)),
                  ),
                ],
              );
            });
      } else if (isReleased != packageInfo!.version) {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('New App Version Available!'.toLowerCase(),
                    style: TextStyle(fontSize: 25, height: 0.85)),
                content: Text(
                    'A new version of the app is available! Please update to the latest version ($isReleased).'
                        .toLowerCase(),
                    style: TextStyle(fontSize: 20, height: 0.75)),
                actions: [
                  TextButton(
                    onPressed: () async {
                      double progress = 0.0;
                      late StateSetter dialogSetState;

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return StatefulBuilder(
                            builder: (context, setState) {
                              dialogSetState = setState;
                              return AlertDialog(
                                title: Text('Downloading APK...'.toLowerCase()),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    LinearProgressIndicator(
                                      value: progress,
                                      color: NoRiskClientColors.blue,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                        '${(progress * 100).toStringAsFixed(2)}%'),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );

                      if (await Permission.manageExternalStorage
                              .request()
                              .isGranted &&
                          await Permission.requestInstallPackages
                              .request()
                              .isGranted) {
                        final dir = await getExternalStorageDirectory();
                        final apkPath = '${dir!.path}/noriskclient.apk';
                        await Dio().download(
                          'https://dl-staging.norisk.gg/noriskclient.apk',
                          apkPath,
                          onReceiveProgress: (rec, total) {
                            if (total != 0) {
                              dialogSetState(() {
                                progress = rec / total;
                              });
                            }
                          },
                        );
                        Navigator.of(context).pop(); // Close dialog
                        await OpenFile.open(apkPath);
                        Navigator.of(context).pop(); // Close dialog
                      } else {
                        Navigator.of(context).pop(); // Close dialog
                      }
                    },
                    child: Text('Download!'.toLowerCase(),
                        style: const TextStyle(
                            fontSize: 25, color: NoRiskClientColors.blue)),
                  ),
                ],
              );
            });
      }
    }
  }

  void loadAppInfo() async {
    PackageInfo _packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      packageInfo = _packageInfo;
    });
  }

  @override
  void dispose() {
    activeTabIndexController.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<LocaleProvider>(context, listen: false);
    provider.loadLocale();

    activeTabIndexController.stream.listen((index) {
      updateStream.add(["tabIndex", index]);
      setState(() {
        tabIndex = index;
      });
    });
    loadAppInfo();
  }

  Widget getActiveTab() {
    // android release check
    if (isAndroid) {
      checkAndroidRelease();
    }

    switch (tabIndex) {
      case 0:
        return News(); // News
      case 1:
        return Chats(); // Chat
      case 2:
        return McReal();
      case 3:
        return Gamescom(); // Placeholder
      case 4:
        return Profile(uuid: userData['uuid'], isSettings: true); // You
      default:
        return McReal();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(children: [
          getActiveTab(),
          Align(
              alignment: Alignment.bottomCenter,
              child: NoRiskBottomNavigationBar(
                  currentIndex: tabIndex,
                  currentIndexController: activeTabIndexController)),
        ]));
  }
}
