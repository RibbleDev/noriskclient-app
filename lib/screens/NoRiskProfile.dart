import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:noriskclient/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:noriskclient/config/Colors.dart';
import 'package:noriskclient/main.dart';
import 'package:noriskclient/screens/Settings.dart';
import 'package:noriskclient/utils/BlockingManager.dart';
import 'package:noriskclient/utils/NoRiskApi.dart';
import 'package:noriskclient/utils/NoRiskIcon.dart';
import 'package:noriskclient/widgets/NoRiskBackButton.dart';
import 'package:noriskclient/widgets/NoRiskContainer.dart';
import 'package:noriskclient/widgets/NoRiskProfileStatisticContainer.dart';
import 'package:noriskclient/widgets/NoRiskText.dart';
import 'package:noriskclient/widgets/ProfileMcRealPost.dart';

class Profile extends StatefulWidget {
  const Profile(
      {super.key,
      required this.uuid,
      this.isSettings = false,
      this.postUpdateStream});

  final String uuid;
  final bool isSettings;
  final StreamController<String>? postUpdateStream;

  @override
  State<Profile> createState() => ProfileState();
}

class ProfileState extends State<Profile> {
  List<ProfileMcRealPost>? pinns;
  StreamController<List> profilePostsUpdateStream = StreamController<List>();
  Map<String, Map<String, dynamic>> cache = getCache;
  Map<String, dynamic> userData = getUserData;
  bool noPinns = true;
  bool? blocked;

  //eastereggs
  bool PSJahn = false;
  bool Aim_shock = false;

  @override
  void initState() {
    loadPinnedPosts(null, null);
    loadBlockedState();

    getUpdateStream.sink.add([
      'loadUsername',
      widget.uuid,
      () => setState(() {
            cache = getCache;
          })
    ]);

    // profilePostsUpdateStream.stream
    //     .listen((List data) => loadPinnedPosts(data[0], data[1]));
    super.initState();
  }

  void toggleEasteregg() {
    if (widget.uuid == '1245c340-8bdb-4796-838e-a247f1594796') {
      setState(() {
        PSJahn = !PSJahn;
      });
      print('Toggled PSJahn, now $PSJahn');
    } else if (widget.uuid == '625dd22b-bad2-4b82-a0bc-e43ba1c1a7fd') {
      setState(() {
        Aim_shock = !Aim_shock;
      });
      print('Toggled Aim_shock, now $Aim_shock');

      if (Aim_shock) {
        showDialog(
            context: context,
            builder: isAndroid
                ? (BuildContext context) {
                    return AlertDialog(
                      title: Text('Tea Time 🍵'),
                      content: Text(
                          'Welcome to the Tea Time!\nCome have a seat and calm down with a cup of tea 😊'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('Close',
                                style:
                                    TextStyle(color: NoRiskClientColors.blue)))
                      ],
                    );
                  }
                : (BuildContext context) {
                    return CupertinoAlertDialog(
                      title: Text('Tea Time 🍵'),
                      content: Text(
                          'Welcome to the Tea Time!\nCome have a seat and calm down with a cup of tea 😊'),
                      actions: [
                        CupertinoDialogAction(
                            isDefaultAction: true,
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('Close'))
                      ],
                    );
                  });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: NoRiskClientColors.background,
        body: Container(
          height: double.infinity,
          width: double.infinity,
          decoration: BoxDecoration(
            image: PSJahn
                ? DecorationImage(
                    image: Image.asset('lib/assets/app/gommehd.png',
                            repeat: ImageRepeat.repeat)
                        .image,
                    repeat: ImageRepeat.repeat)
                : null,
          ),
          child: Padding(
              padding: const EdgeInsets.all(15),
              child: Stack(
                children: [
                  Stack(
                    children: [
                      Column(children: [
                        const SizedBox(height: 65),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (!widget.isSettings)
                              NoRiskBackButton(
                                  onPressed: () => Navigator.of(context).pop()),
                            if (widget.isSettings) const SizedBox(width: 30),
                            Column(children: [
                              NoRiskText(
                                  (widget.uuid == userData['uuid']
                                          ? AppLocalizations.of(context)!
                                              .profile_yourProfile
                                          : (cache['usernames']?[widget.uuid] ??
                                              'Unknown'))
                                      .toString()
                                      .toLowerCase(),
                                  spaceTop: false,
                                  spaceBottom: false,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 30,
                                      color: NoRiskClientColors.text,
                                      fontWeight: FontWeight.bold)),
                              if (cache['profiles']?[widget.uuid] != null &&
                                  cache['profiles']![widget.uuid]['nrcUser']
                                      ['additionalNameTag']['isEnabled'])
                                NoRiskText(
                                    (cache['profiles']![widget.uuid]['nrcUser']
                                                ['additionalNameTag']['text'] ??
                                            'Unknown')
                                        .toLowerCase()
                                        .replaceAll(
                                            RegExp(r'[§&][0-9A-FK-OR]',
                                                caseSensitive: false),
                                            ''),
                                    maxLength:
                                        MediaQuery.of(context).size.width -
                                            2 * 15 -
                                            2 * 30 -
                                            2 * 15,
                                    spaceTop: false,
                                    spaceBottom: false,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 25,
                                        color: NoRiskClientColors.blue)),
                            ]),
                            if (blocked != null)
                              NoRiskContainer(
                                  child: GestureDetector(
                                      onTap: blocked! ? unblock : block,
                                      onLongPress: () => Fluttertoast.showToast(
                                          msg:
                                              "${blocked == false ? 'Block' : 'Unblock'} ${cache['usernames']?[widget.uuid] ?? 'Unknown'}"),
                                      child: SizedBox(
                                          height: 26.5,
                                          width: 26.5,
                                          child: Center(
                                            child: Icon(
                                                blocked == false
                                                    ? Icons.block
                                                    : Icons.handshake,
                                                color: blocked == false
                                                    ? Colors.red
                                                    : Colors.green,
                                                size: 20),
                                          )))),
                            if (widget.isSettings)
                              GestureDetector(
                                  onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (BuildContext context) =>
                                              Settings())),
                                  child: NoRiskContainer(
                                      child: SizedBox(
                                    height: 30,
                                    width: 30,
                                    child: Center(child: NoRiskIcon.settings),
                                  ))),
                            if (!widget.isSettings && blocked == null)
                              const SizedBox(width: 30),
                          ],
                        ),
                        Center(
                            child: cache['armorSkins']?[widget.uuid] != null
                                ? GestureDetector(
                                    child: cache['armorSkins']?[widget.uuid],
                                    onTap: toggleEasteregg)
                                : const SizedBox()),
                      ]),
                      Padding(
                        padding: const EdgeInsets.only(top: 275),
                        child: RefreshIndicator(
                          onRefresh: () => loadPinnedPosts(null, null),
                          child: ListView(children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                NoRiskProfileStatisticContainer(
                                  width: (MediaQuery.of(context).size.width -
                                          2 * 15 -
                                          1 * 10) /
                                      2,
                                  title: AppLocalizations.of(context)!
                                      .profile_stats_firstJoin,
                                  value: DateTime.fromMillisecondsSinceEpoch(
                                          cache['profiles']?[widget.uuid]
                                                  ?['firstJoinTimeStamp'] ??
                                              0)
                                      .toIso8601String()
                                      .toString()
                                      .split('T')[0]
                                      .replaceAll("-", ".")
                                      .split(".")
                                      .reversed
                                      .join("."),
                                ),
                                const SizedBox(width: 10),
                                NoRiskProfileStatisticContainer(
                                  width: (MediaQuery.of(context).size.width -
                                          2 * 15 -
                                          1 * 10) /
                                      2,
                                  title: AppLocalizations.of(context)!
                                      .profile_stats_lastJoin,
                                  value: DateTime.fromMillisecondsSinceEpoch(
                                          cache['profiles']?[widget.uuid]
                                                  ?['lastJoinTimeStamp'] ??
                                              0)
                                      .toIso8601String()
                                      .toString()
                                      .split('T')[0]
                                      .replaceAll("-", ".")
                                      .split(".")
                                      .reversed
                                      .join("."),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  NoRiskProfileStatisticContainer(
                                    width: (MediaQuery.of(context).size.width -
                                            2 * 15 -
                                            2 * 10) /
                                        3,
                                    title: AppLocalizations.of(context)!
                                        .profile_stats_loginStreak,
                                    value: cache['profiles']?[widget.uuid]
                                                    ?['nrcUser']['loginStreak']
                                                ['days']
                                            .toString() ??
                                        '?',
                                  ),
                                  const SizedBox(width: 10),
                                  NoRiskProfileStatisticContainer(
                                    width: (MediaQuery.of(context).size.width -
                                            2 * 15 -
                                            2 * 10) /
                                        3,
                                    title: AppLocalizations.of(context)!
                                        .profile_stats_mcReal,
                                    value: cache['profiles']?[widget.uuid]
                                                ?['mcRealStreak']['days']
                                            .toString() ??
                                        '?',
                                  ),
                                  const SizedBox(width: 10),
                                  NoRiskProfileStatisticContainer(
                                    width: (MediaQuery.of(context).size.width -
                                            2 * 15 -
                                            2 * 10) /
                                        3,
                                    title: AppLocalizations.of(context)!
                                        .profile_stats_playtime,
                                    value: Duration(
                                                    milliseconds: cache[
                                                                    'profiles']
                                                                ?[widget.uuid]
                                                            ?['playTime'] ??
                                                        0)
                                                .inDays >
                                            0
                                        ? '${Duration(milliseconds: cache['profiles']?[widget.uuid]?['playTime'] ?? 0).inDays}d'
                                        : '${Duration(milliseconds: cache['profiles']?[widget.uuid]?['playTime'] ?? 0).inHours}h',
                                  ),
                                ]),
                            const SizedBox(height: 15),
                            if (!noPinns && blocked != true)
                              Column(children: [
                                ...pinns!,
                                const SizedBox(height: 50)
                              ]),
                            if (noPinns || blocked == true)
                                          SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height -
                                                500,
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            child: Center(
                                                child: NoRiskText(
                                                    blocked == true
                                                        ? AppLocalizations.of(
                                                                context)!
                                                            .mcReal_profile_blockedPlayer
                                                            .toLowerCase()
                                                        : (cache['usernames']?[
                                                                        widget
                                                                            .uuid] ??
                                                                    'Unknown')
                                                                .toLowerCase() +
                                                            AppLocalizations.of(
                                                                    context)!
                                                                .profile_noPinnedPosts,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.red))),
                                          )
                          ]),
                        ),
                      ),
                    ],
                  ),
                ],
              )),
        ));
  }

  void loadBlockedState() {
    if (widget.uuid == userData['uuid']) return;
    BlockingManager().checkBlocked(widget.uuid).then((bool blocked) {
      setState(() {
        this.blocked = blocked;
      });
    });
  }

  void block() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Platform.isAndroid
              ? AlertDialog(
                  title: Text(AppLocalizations.of(context)!
                      .mcReal_profile_blockUserPopupTitle),
                  content: Text(AppLocalizations.of(context)!
                      .mcReal_profile_blockUserPopupContent),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                            AppLocalizations.of(context)!.mcReal_popup_cancel,
                            style: const TextStyle(color: Colors.red))),
                    TextButton(
                        onPressed: () async {
                          await BlockingManager().block(widget.uuid);
                          loadBlockedState();
                          widget.postUpdateStream?.sink.add('*');
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
                      .mcReal_profile_blockUserPopupTitle),
                  content: Text(AppLocalizations.of(context)!
                      .mcReal_profile_blockUserPopupContent),
                  actions: [
                    CupertinoDialogAction(
                        isDestructiveAction: true,
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                            AppLocalizations.of(context)!.mcReal_popup_cancel)),
                    CupertinoDialogAction(
                        isDefaultAction: true,
                        onPressed: () async {
                          await BlockingManager().block(widget.uuid);
                          loadBlockedState();
                          widget.postUpdateStream?.sink.add('*');
                          Navigator.of(context).pop();
                        },
                        child: Text(
                            AppLocalizations.of(context)!.mcReal_popup_yes))
                  ],
                );
        });
  }

  void unblock() {
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
                          await BlockingManager().unblock(widget.uuid);
                          loadBlockedState();
                          widget.postUpdateStream?.sink.add('*');
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
                          await BlockingManager().unblock(widget.uuid);
                          loadBlockedState();
                          widget.postUpdateStream?.sink.add('*');
                          Navigator.of(context).pop();
                        },
                        child: Text(
                            AppLocalizations.of(context)!.mcReal_popup_yes))
                  ],
                );
        });
  }

  void loadStreak() async {}

  Future<void> loadPinnedPosts(int? refreshPostIndex,
      void Function(Map<String, dynamic>? newData)? updateData) async {
    // only clear if we refresh all posts
    if (refreshPostIndex == null) {
      setState(() {
        pinns = null;
        noPinns = true;
      });
    }

    await NoRiskApi().getUserProfile(widget.uuid);

    // ahaha bro wie scuffed, aber sonst ist noch nt im cache 🥀🥀🥀
    await Future.delayed(const Duration(milliseconds: 100));

    setState(() {
      cache = getCache;
    });

    List<ProfileMcRealPost> newPinnedPosts = [];
    int index = 0;
    for (var pinnedPost
        in cache['profiles']?[widget.uuid]?['pinnedPosts'] ?? []) {
      newPinnedPosts.add(ProfileMcRealPost(
          postData: pinnedPost,
          profilePostIndex: index,
          profileUuid: widget.uuid,
          profilePostsUpdateStream: profilePostsUpdateStream));
      if (pinnedPost != null) {
        setState(() {
          noPinns = false;
        });
      }
      index++;
    }

    // update if we refresh a single post
    if (refreshPostIndex != null) {
      setState(() {
        pinns![refreshPostIndex] = newPinnedPosts[refreshPostIndex];
      });
      updateData!(pinns![refreshPostIndex].postData);
    } else {
      // update all posts if we refresh all posts
      setState(() {
        pinns = newPinnedPosts;
      });
    }
  }
}
