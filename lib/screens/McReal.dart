import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mcreal/config/Colors.dart';
import 'package:mcreal/screens/Friends.dart';
import 'package:mcreal/screens/Profile.dart';
import 'package:mcreal/utils/McRealStatus.dart';
import 'package:mcreal/utils/NoRiskApi.dart';
import 'package:mcreal/widgets/LoadingIndicator.dart';
import 'package:mcreal/widgets/McRealPost.dart';

class McReal extends StatefulWidget {
  const McReal(
      {super.key,
      required this.userData,
      required this.cache,
      required this.updateStream});

  final Map<String, dynamic> userData;
  final Map<String, dynamic> cache;
  final StreamController<List> updateStream;

  @override
  State<McReal> createState() => McRealState();
}

class McRealState extends State<McReal> {
  StreamController<bool> postUpdateStream = StreamController<bool>();
  bool friendsOnly = true;
  int page = 0;
  McRealPost? post;
  List<McRealPost> posts = [];

  @override
  void initState() {
    widget.updateStream.sink.add(['loadSkin', widget.userData['uuid']]);
    loadPosts(true);
    postUpdateStream.stream.listen((bool data) {
      if (data) {
        loadPosts(true);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: McRealColors.background,
        body: RefreshIndicator(
          onRefresh: () => loadPosts(true),
          child: Stack(
            children: [
              ListView(
                children: [
                  SizedBox(height: Platform.isAndroid ? 60 : 35),
                  posts.isEmpty && post == null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 35),
                          child: Text(
                              widget.userData['mcRealStatus'] == null
                                  ? AppLocalizations.of(context)!.mcReal_noPosts
                                  : AppLocalizations.of(context)!
                                      .mcReal_noPostsPlain,
                              textAlign: TextAlign.center),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                post ?? const SizedBox(height: 0, width: 0),
                                ...posts
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
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: GestureDetector(
                                onTap: openFriendsPage,
                                child: const Icon(Icons.person_rounded,
                                    color: Colors.white, size: 35),
                              ),
                            ),
                          ),
                        ]),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (friendsOnly) return;
                              setState(() {
                                friendsOnly = true;
                              });
                              loadPosts(false);
                            },
                            child: Text(
                                AppLocalizations.of(context)!
                                    .mcReal_friendsOnly,
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: friendsOnly
                                        ? FontWeight.bold
                                        : FontWeight.w400)),
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.25),
                        ]),
                    const Center(
                        child: Text('|',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold))),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.3),
                          GestureDetector(
                            onTap: () {
                              if (!friendsOnly) return;
                              setState(() {
                                friendsOnly = false;
                              });
                              loadPosts(false);
                            },
                            child: Text(
                                AppLocalizations.of(context)!.mcReal_discovery,
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: friendsOnly
                                        ? FontWeight.w400
                                        : FontWeight.bold)),
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
                                onTap: openProfilePage,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: widget.cache['skins']
                                          [widget.userData['uuid']] ??
                                      const SizedBox(
                                          height: 32,
                                          width: 32,
                                          child: LoadingIndicator()),
                                ),
                              ),
                            ),
                          )
                        ])
                  ])
                ],
              ),
            ],
          ),
        ));
  }

  Future<void> loadPlayerPost() async {
    widget.userData.remove('mcRealStatus');
    widget.userData.remove('mcRealStatusInfo');
    http.Response res = await http.get(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(widget.userData['experimental'], 'mcreal')}/post?uuid=${widget.userData['uuid']}'),
        headers: {'Authorization': 'Bearer ${widget.userData['token']}'});
    if (res.statusCode != 200) {
      print(res.statusCode);
      return;
    }
    Map<String, dynamic> postData = jsonDecode(utf8.decode(res.bodyBytes));

    if (postData['status'] != null) {
      if (postData['status'] == McRealStatus.REMOVED) {
        widget.userData['mcRealStatus'] = McRealStatus.REMOVED;
        widget.userData['mcRealStatusInfo'] = postData['statusInfo'];
      } else if (postData['status'] == McRealStatus.DELETED) {
        widget.userData['mcRealStatus'] = McRealStatus.DELETED;
      }
    }

    setState(() {
      post = McRealPost(
          locked: false,
          postData: postData,
          userData: widget.userData,
          cache: widget.cache,
          updateStream: widget.updateStream,
          postUpdateStream: postUpdateStream);
    });
  }

  Future<void> loadPosts(bool fullReload) async {
    await loadPlayerPost();
    http.Response res = await http.get(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(widget.userData['experimental'], 'mcreal')}/posts?uuid=${widget.userData['uuid']}&page=$page&friendsOnly=$friendsOnly'),
        headers: {'Authorization': 'Bearer ${widget.userData['token']}'});
    if (res.statusCode != 200) {
      print(res.statusCode);
      return;
    }
    List postsData = jsonDecode(utf8.decode(res.bodyBytes));

    String lockedReason = '';
    if (widget.userData['mcRealStatus'] == McRealStatus.REMOVED) {
      lockedReason = AppLocalizations.of(context)!.mcReal_status_removed;
    } else if (widget.userData['mcRealStatus'] == McRealStatus.DELETED) {
      lockedReason = AppLocalizations.of(context)!.mcReal_status_deleted;
    } else if (post == null) {
      lockedReason = AppLocalizations.of(context)!.mcReal_status_noPost;
    }

    List<McRealPost> newPosts = [];
    for (var postData in postsData) {
      newPosts.add(McRealPost(
          locked: post == null || lockedReason != '',
          lockedReason: lockedReason,
          postData: postData,
          userData: widget.userData,
          cache: widget.cache,
          updateStream: widget.updateStream,
          postUpdateStream: postUpdateStream));
    }

    setState(() {
      posts = newPosts;
    });
  }

  void openProfilePage() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) => Profile(
            uuid: widget.userData['uuid'],
            userData: widget.userData,
            cache: widget.cache,
            updateStream: widget.updateStream)));
  }

  void openFriendsPage() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) => Friends(
            userData: widget.userData,
            cache: widget.cache,
            updateStream: widget.updateStream)));
  }
}
