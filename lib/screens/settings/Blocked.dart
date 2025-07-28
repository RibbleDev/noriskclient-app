import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:noriskclient/l10n/app_localizations.dart';
import 'package:noriskclient/config/Colors.dart';
import 'package:noriskclient/main.dart';
import 'package:noriskclient/utils/BlockingManager.dart';
import 'package:noriskclient/utils/NoRiskIcon.dart';
import 'package:noriskclient/widgets/LoadingIndicator.dart';

class Blocked extends StatefulWidget {
  const Blocked({super.key, required this.postUpdateStream});

  final StreamController<String> postUpdateStream;

  @override
  State<Blocked> createState() => BlockedState();
}

class BlockedState extends State<Blocked> {
  Map<String, Map<String, dynamic>> cache = getCache;
  Map<String, dynamic> userData = getUserData;
  List<String>? blockedPlayers;

  @override
  void initState() {
    loadBlockedPlayers();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: NoRiskClientColors.background,
        body: Padding(
          padding: const EdgeInsets.all(15),
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
                    Text(AppLocalizations.of(context)!.settings_blockedPlayers,
                        style: const TextStyle(
                            color: NoRiskClientColors.text,
                            fontSize: 27.5,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.height - 190,
              child: blockedPlayers == null
                  ? const Center(child: LoadingIndicator())
                  : blockedPlayers!.isEmpty
                      ? Center(
                          child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                              AppLocalizations.of(context)!
                                  .mcReal_blocked_noBlockedPlayers,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red)),
                        ))
                      : ListView(
                      children: blockedPlayers!
                          .map((uuid) => GestureDetector(
                                onTap: () => unblock(uuid),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12.5),
                                  padding: const EdgeInsets.all(8.5),
                                  decoration: BoxDecoration(
                                    color: NoRiskClientColors.darkerBackground,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(2.5),
                                          child: cache['skins']?[uuid] ??
                                              const SizedBox(
                                                  height: 32,
                                                  width: 32,
                                                  child: LoadingIndicator())),
                                      const SizedBox(width: 10),
                                      Text(
                                        cache['usernames']?[uuid] ?? 'Unknown',
                                        style: const TextStyle(
                                            color: NoRiskClientColors.text,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const Spacer(),
                                      const Icon(Icons.handshake,
                                          color: Colors.green, size: 30)
                                    ],
                                  ),
                                ),
                              ))
                          .toList()),
            )
          ]),
        ));
  }

  void loadBlockedPlayers() async {
    List<String> _blockedPlayers = await BlockingManager().getBlocked();
    setState(() {
      blockedPlayers = _blockedPlayers;
    });

    for (String uuid in _blockedPlayers) {
      getUpdateStream.sink.add([
        'loadSkin',
        uuid,
        () => setState(() {
              cache = getCache;
            })
      ]);
      getUpdateStream.sink.add([
        'loadUsername',
        uuid,
        () => setState(() {
              cache = getCache;
            })
      ]);
    }
  }

  void unblock(String uuid) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Platform.isAndroid
              ? AlertDialog(
                  title: Text(AppLocalizations.of(context)!
                      .mcReal_profile_unblockUserPopupTitle),
                  content: Text(AppLocalizations.of(context)!
                      .mcReal_profile_unblockUserPopupContent),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                            AppLocalizations.of(context)!.mcReal_popup_cancel,
                            style: const TextStyle(color: Colors.red))),
                    TextButton(
                        onPressed: () async {
                          await BlockingManager().unblock(uuid);
                          loadBlockedPlayers();
                          widget.postUpdateStream.sink.add('*');
                          Navigator.of(context).pop();
                        },
                        child: Text(
                            AppLocalizations.of(context)!.mcReal_popup_yes,
                            style: const TextStyle(
                                color: NoRiskClientColors.blue))),
                  ],
                )
              : CupertinoAlertDialog(
                  title: Text(AppLocalizations.of(context)!
                      .mcReal_profile_unblockUserPopupTitle),
                  content: Text(AppLocalizations.of(context)!
                      .mcReal_profile_unblockUserPopupContent),
                  actions: [
                    CupertinoDialogAction(
                        isDestructiveAction: true,
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                            AppLocalizations.of(context)!.mcReal_popup_cancel)),
                    CupertinoDialogAction(
                        isDefaultAction: true,
                        onPressed: () async {
                          await BlockingManager().unblock(uuid);
                          loadBlockedPlayers();
                          widget.postUpdateStream.sink.add('*');
                          Navigator.of(context).pop();
                        },
                        child: Text(
                            AppLocalizations.of(context)!.mcReal_popup_yes))
                  ],
                );
        });
  }
}
