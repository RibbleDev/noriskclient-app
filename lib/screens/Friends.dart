import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mcreal/config/Colors.dart';
import 'package:mcreal/utils/FriendListType.dart';
import 'package:mcreal/utils/NoRiskApi.dart';
import 'package:mcreal/utils/NoRiskIcon.dart';
import 'package:mcreal/widgets/LoadingIndicator.dart';
import 'package:mcreal/widgets/NoRiskFriend.dart';
import 'package:mcreal/widgets/NoRiskFriendsList.dart';

class Friends extends StatefulWidget {
  const Friends(
      {super.key,
      required this.userData,
      required this.cache,
      required this.updateStream});

  final Map<String, dynamic> userData;
  final Map<String, dynamic> cache;
  final StreamController<List> updateStream;

  @override
  State<Friends> createState() => FriendsState();
}

class FriendsState extends State<Friends> {
  StreamController<bool> friendUpdateStream = StreamController<bool>();
  List<NoRiskFriend>? friends;
  List<NoRiskFriend>? incoming;
  List<NoRiskFriend>? outgoing;
  List<NoRiskFriend>? blocked;

  @override
  void initState() {
    loadAll();
    friendUpdateStream.stream.listen((bool data) {
      if (data) {
        loadAll();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: McRealColors.background,
        body: RefreshIndicator(
          onRefresh: loadAll,
          child: Stack(
            children: [
              ListView(
                children: [
                  SizedBox(height: Platform.isAndroid ? 60 : 35),
                  friends == null ||
                          incoming == null ||
                          outgoing == null ||
                          blocked == null
                      ? const LoadingIndicator()
                      : friends!.isEmpty &&
                              incoming!.isEmpty &&
                              outgoing!.isEmpty &&
                              blocked!.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(top: 35),
                              child: Text(
                                  AppLocalizations.of(context)!
                                      .friends_noFriends,
                                  textAlign: TextAlign.center),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    NoRiskFriendsList(
                                        title: AppLocalizations.of(context)!
                                            .friends_friends,
                                        type: FriendListType.FRIENDS,
                                        friends: friends ?? []),
                                    NoRiskFriendsList(
                                        title: AppLocalizations.of(context)!
                                            .friends_incomingRequests,
                                        type: FriendListType.INCOMING_REQUESTS,
                                        friends: incoming ?? []),
                                    NoRiskFriendsList(
                                        title: AppLocalizations.of(context)!
                                            .friends_outgoingRequests,
                                        type: FriendListType.OUTGOING_REQUESTS,
                                        friends: outgoing ?? []),
                                    NoRiskFriendsList(
                                        title: AppLocalizations.of(context)!
                                            .friends_blocked,
                                        type: FriendListType.BLOCKED,
                                        friends: blocked ?? [])
                                  ]),
                            )
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  Stack(children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 15),
                            child: Text(
                                AppLocalizations.of(context)!.friends_title,
                                style: const TextStyle(
                                    fontSize: 25, fontWeight: FontWeight.w500)),
                          ),
                        ]),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 15),
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Transform.scale(
                                  scaleX: -1,
                                  child: NoRiskIcon.back,
                                ),
                              ),
                            ),
                          ),
                        ])
                  ])
                ],
              ),
            ],
          ),
        ));
  }

  Future<void> loadAll() async {
    loadFriends();
    loadIncoming();
    loadOutgoing();
    loadBlocked();
  }

  Future<void> loadFriends() async {
    http.Response res = await http.get(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(widget.userData['experimental'], 'friends')}/list?uuid=${widget.userData['uuid']}'),
        headers: {'Authorization': 'Bearer ${widget.userData['token']}'});
    if (res.statusCode != 200) {
      print(res.statusCode);
      return;
    }
    List friendsData = jsonDecode(utf8.decode(res.bodyBytes));

    List<NoRiskFriend> newFriends = [];
    for (var friendData in friendsData) {
      newFriends.add(NoRiskFriend(
        type: FriendListType.FRIENDS,
        fiendUserData: friendData,
        userData: widget.userData,
        cache: widget.cache,
        updateStream: widget.updateStream,
        friendUpdateStream: friendUpdateStream,
      ));
    }

    setState(() {
      friends = newFriends;
    });
  }

  Future<void> loadIncoming() async {
    http.Response res = await http.get(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(widget.userData['experimental'], 'friends')}/requests/incoming/list?uuid=${widget.userData['uuid']}'),
        headers: {'Authorization': 'Bearer ${widget.userData['token']}'});
    if (res.statusCode != 200) {
      print(res.statusCode);
      return;
    }
    List friendsData = jsonDecode(utf8.decode(res.bodyBytes));

    List<NoRiskFriend> newIncoming = [];
    for (var friendData in friendsData) {
      newIncoming.add(NoRiskFriend(
        type: FriendListType.INCOMING_REQUESTS,
        fiendUserData: friendData,
        userData: widget.userData,
        cache: widget.cache,
        updateStream: widget.updateStream,
        friendUpdateStream: friendUpdateStream,
      ));
    }

    setState(() {
      incoming = newIncoming;
    });
  }

  Future<void> loadOutgoing() async {
    http.Response res = await http.get(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(widget.userData['experimental'], 'friends')}/requests/outgoing/list?uuid=${widget.userData['uuid']}'),
        headers: {'Authorization': 'Bearer ${widget.userData['token']}'});
    if (res.statusCode != 200) {
      print(res.statusCode);
      return;
    }
    List friendsData = jsonDecode(utf8.decode(res.bodyBytes));

    List<NoRiskFriend> newOutgoing = [];
    for (var friendData in friendsData) {
      newOutgoing.add(NoRiskFriend(
        type: FriendListType.OUTGOING_REQUESTS,
        fiendUserData: friendData,
        userData: widget.userData,
        cache: widget.cache,
        updateStream: widget.updateStream,
        friendUpdateStream: friendUpdateStream,
      ));
    }

    setState(() {
      outgoing = newOutgoing;
    });
  }

  Future<void> loadBlocked() async {
    http.Response res = await http.get(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(widget.userData['experimental'], 'friends')}/blocked?uuid=${widget.userData['uuid']}'),
        headers: {'Authorization': 'Bearer ${widget.userData['token']}'});
    if (res.statusCode != 200) {
      print(res.statusCode);
      return;
    }
    List friendsData = jsonDecode(utf8.decode(res.bodyBytes));

    List<NoRiskFriend> newBlocked = [];
    for (var friendData in friendsData) {
      newBlocked.add(NoRiskFriend(
        type: FriendListType.BLOCKED,
        fiendUserData: friendData,
        userData: widget.userData,
        cache: widget.cache,
        updateStream: widget.updateStream,
        friendUpdateStream: friendUpdateStream,
      ));
    }

    setState(() {
      blocked = newBlocked;
    });
  }
}
