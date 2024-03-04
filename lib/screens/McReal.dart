import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mcreal/config/Colors.dart';
import 'package:mcreal/utils/McRealStatus.dart';
import 'package:mcreal/utils/NoRiskApi.dart';
import 'package:mcreal/widgets/McRealPost.dart';

class McReal extends StatefulWidget {
  const McReal({super.key, required this.userData, required this.updateStream});

  final Map<String, dynamic> userData;
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
                  SizedBox(height: Platform.isAndroid ? 50 : 25),
                  posts.isEmpty && post == null
                      ? Padding(
                        padding: const EdgeInsets.only(top: 35),
                        child: Text(widget.userData['mcRealStatus'] == null ? AppLocalizations.of(context)!.mcReal_noPosts : AppLocalizations.of(context)!.mcReal_noPostsPlain,
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
                children: [
                  const SizedBox(height: 55),
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
                              AppLocalizations.of(context)!.mcReal_friendsOnly,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: friendsOnly
                                      ? FontWeight.bold
                                      : FontWeight.w400)),
                        ),
                        const SizedBox(width: 7.5),
                        const Text('|', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 7.5),
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
            '${NoRiskApi().getBaseUrl(widget.userData['experimental'])}/post?uuid=${widget.userData['uuid']}'),
        headers: {'Authorization': 'Bearer ${widget.userData['noriskToken']}'});
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
          postUpdateStream: postUpdateStream);
    });
  }

  Future<void> loadPosts(bool fullReload) async {
    if (post == null || fullReload) {
      await loadPlayerPost();
    }
    http.Response res = await http.get(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(widget.userData['experimental'])}/posts?uuid=${widget.userData['uuid']}&page=$page&friendsOnly=$friendsOnly'),
        headers: {'Authorization': 'Bearer ${widget.userData['noriskToken']}'});
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
          postUpdateStream: postUpdateStream));
    }

    setState(() {
      posts = newPosts;
    });
  }
}
