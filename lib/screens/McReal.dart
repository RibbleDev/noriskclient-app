import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:noriskclient/l10n/app_localizations.dart';
import 'package:noriskclient/config/Colors.dart';
import 'package:noriskclient/config/Config.dart';
import 'package:noriskclient/main.dart';
import 'package:noriskclient/provider/localeProvider.dart';
import 'package:noriskclient/screens/Profile.dart';
import 'package:noriskclient/utils/BlockingManager.dart';
import 'package:noriskclient/utils/McRealStatus.dart';
import 'package:noriskclient/utils/NoRiskApi.dart';
import 'package:noriskclient/utils/NoRiskIcon.dart';
import 'package:noriskclient/widgets/LoadingIndicator.dart';
import 'package:noriskclient/widgets/McRealPost.dart';
import 'package:noriskclient/widgets/NoRiskIconButton.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic>? ownPostData;

class McReal extends StatefulWidget {
  const McReal({super.key});

  @override
  State<McReal> createState() => McRealState();
}

class McRealState extends State<McReal> {
  ScrollController scrollController = ScrollController();
  StreamController<String> postUpdateStream = StreamController<String>();
  bool friendsOnly = true;
  int page = 0;
  bool hitEnd = false;
  bool isLoadingNewPosts = false;
  McRealPost? ownPost;
  List<McRealPost> posts = [];
  Map<String, Map<String, dynamic>> cache = getCache;
  Map<String, dynamic> userData = getUserData;

  @override
  void initState() {
    loadLanguage();
    getUpdateStream.sink.add([
      'loadSkin',
      userData['uuid'],
      () => setState(() {
            cache = getCache;
          })
    ]);
    loadPosts();
    postUpdateStream.stream.listen((String data) async {
      if (data == '*') {
        setState(() {
          ownPost = null;
          posts = [];
          cache['posts'] = {};
          page = 0;
        });
        loadPosts();
        return;
      }
      var res = await http.get(
          Uri.parse(
              '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/post/$data?uuid=${userData['uuid']}'),
          headers: {'Authorization': 'Bearer ${userData['token']}'});
      if (res.statusCode != 200) {
        print("Load player post: ${res.statusCode}");
        if (res.statusCode == 403) {
          setState(() {
            ownPost = null;
          });
        } else if (res.statusCode == 401) {
          getUpdateStream.sink.add(['signOut']);
        }
        return;
      }
      Map<String, dynamic> postData = jsonDecode(utf8.decode(res.bodyBytes));
      int index = posts.indexWhere(
          (post) => post.postData['post']['_id'] == postData['post']['_id']);

      McRealPost oldPost = index == -1 ? ownPost! : posts[index];
      McRealPost newPost = McRealPost(
          locked: oldPost.locked,
          lockedReason: oldPost.lockedReason,
          postData: postData,
          commentUpdateStream: oldPost.commentUpdateStream,
          displayOnly: oldPost.displayOnly,
          postUpdateStream: oldPost.postUpdateStream);
      setState(() {
        if (index == -1) {
          ownPost = newPost;
        } else {
          posts[index] = newPost;
        } 
      });
    });

    scrollController.addListener(() async {
      double maxScroll = scrollController.position.maxScrollExtent;
      double currentScroll = scrollController.position.pixels;
      double delta = 100.0;
      if ((maxScroll - currentScroll <= delta) &&
          isLoadingNewPosts != true &&
          hitEnd != true) {
        page++;
        await loadPosts();
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    postUpdateStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: NoRiskClientColors.background,
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              cache['posts'] = {};
              ownPost = null;
              ownPostData = null;
              posts = [];
              page = 0;
            });
            loadPlayerPost();
            loadPosts();
          },
          child: Stack(
            children: [
              ListView(
                controller: scrollController,
                children: [
                  SizedBox(height: Platform.isAndroid ? 60 : 35),
                  posts.isEmpty && ownPost == null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 35),
                          child: Text(
                              userData['mcRealStatus'] == null
                                  ? AppLocalizations.of(context)!.mcReal_noPosts
                                  : AppLocalizations.of(context)!
                                      .mcReal_noPostsPlain,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: NoRiskClientColors.textLight)),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 10),
                                ownPost ?? const SizedBox(height: 0, width: 0),
                                ...posts,
                                (ownPost != null ? 1 : 0) + posts.length <= 2
                                    ? SizedBox(
                                        height: 30,
                                        child: Center(
                                            child: NoRiskIconButton(
                                                onTap: () {
                                                  setState(() {
                                                    posts = [];
                                                    page = 0;
                                                  });
                                                  loadPosts();
                                                },
                                                icon: NoRiskIcon.reload)))
                                    : Container()
                              ]),
                        )
                ],
              ),
              ClipRRect(
                child: SizedBox(
                  height: 100,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: Platform.isAndroid ? 55 : 65),
                        Stack(children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(width: 5),
                                GestureDetector(
                                  onTap: () {
                                    if (friendsOnly) return;
                                    setState(() {
                                      friendsOnly = true;
                                      posts = [];
                                      page = 0;
                                    });
                                    loadPosts();
                                  },
                                  child: Text(
                                      AppLocalizations.of(context)!
                                          .mcReal_friendsOnly,
                                      style: TextStyle(
                                          fontSize: 20,
                                          color: NoRiskClientColors.text,
                                          fontWeight: friendsOnly
                                              ? FontWeight.bold
                                              : FontWeight.w400)),
                                ),
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.3),
                              ]),
                          const Center(
                              child: Text('|',
                                  style: TextStyle(
                                      fontSize: 20,
                                      color: NoRiskClientColors.text,
                                      fontWeight: FontWeight.bold))),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.35),
                                GestureDetector(
                                  onTap: () {
                                    if (!friendsOnly) return;
                                    setState(() {
                                      friendsOnly = false;
                                      posts = [];
                                      page = 0;
                                    });
                                    loadPosts();
                                  },
                                  child: Text(
                                      AppLocalizations.of(context)!
                                          .mcReal_discovery,
                                      style: TextStyle(
                                          fontSize: 20,
                                          color: NoRiskClientColors.text,
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
                                        child: cache['skins']
                                                ?[userData['uuid']] ??
                                            const SizedBox(
                                                height: 32,
                                                width: 32,
                                                child: LoadingIndicator()),
                                      ),
                                    ),
                                  ),
                                )
                              ])
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
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

  Future<void> loadPlayerPost() async {
    if (userData['mcRealStatus'] != McRealStatus.OK) {
      setState(() {
        cache['posts'] = {};
        ownPost = null;
        ownPostData = null;
      });
    }
    userData.remove('mcRealStatus');
    userData.remove('mcRealStatusInfo');
    http.Response res = await http.get(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/post?uuid=${userData['uuid']}'),
        headers: {'Authorization': 'Bearer ${userData['token']}'});
    if (res.statusCode != 200) {
      print("Load player post: ${res.statusCode}");
      if (res.statusCode == 403) {
        setState(() {
          ownPost = null;
        });
      } else if (res.statusCode == 401) {
        getUpdateStream.sink.add(['signOut']);
      }
      return;
    }
    Map<String, dynamic> postData = jsonDecode(utf8.decode(res.bodyBytes));

    if (postData['post']['status'] != null) {
      if (postData['post']['status'] == McRealStatus.REMOVED) {
        userData['mcRealStatus'] = McRealStatus.REMOVED;
        userData['mcRealStatusInfo'] = postData['post']['statusInfo'];
      } else if (postData['post']['status'] == McRealStatus.DELETED) {
        userData['mcRealStatus'] = McRealStatus.DELETED;
      }
    }

    setState(() {
      ownPostData = postData;
      ownPost = McRealPost(
          locked: false,
          postData: postData,
          postUpdateStream: postUpdateStream);
    });
  }

  Future<void> loadPosts() async {
    isLoadingNewPosts = true;
    await loadPlayerPost();
    http.Response res = await http.get(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/posts?uuid=${userData['uuid']}&page=$page&friendsOnly=$friendsOnly'),
        headers: {'Authorization': 'Bearer ${userData['token']}'});
    if (res.statusCode != 200) {
      print("Load posts: ${res.statusCode}");
      if (res.statusCode == 401) {
        getUpdateStream.sink.add(['signOut']);
      }
      return;
    }
    List postsData = jsonDecode(utf8.decode(res.bodyBytes));

    print(postsData.length);

    if (postsData.length < Config.maxPostsPerPage) {
      hitEnd = true;
      print('Hit end!!!');
    } else {
      hitEnd = false;
    }

    String lockedReason = '';
    if (userData['mcRealStatus'] == McRealStatus.REMOVED) {
      lockedReason = AppLocalizations.of(context)!.mcReal_status_removed;
    } else if (userData['mcRealStatus'] == McRealStatus.DELETED) {
      lockedReason = AppLocalizations.of(context)!.mcReal_status_deleted;
    } else if (ownPost == null) {
      lockedReason = AppLocalizations.of(context)!.mcReal_status_noPost;
    }

    List<McRealPost> newPosts = [];
    for (var postData in postsData) {
      bool isBlocked =
          await BlockingManager().checkBlocked(postData['post']['author']);
      if (isBlocked) {
        print(
            'Skipped blocked post ${postData['post']['_id']} (${postData['post']['author']})');
        continue;
      }
      
      newPosts.add(McRealPost(
          locked: ownPost == null || lockedReason != '',
          lockedReason: lockedReason,
          postData: postData,
          postUpdateStream: postUpdateStream));
    }

    List<McRealPost> existingPosts = posts;
    int scrollOffset = scrollController.offset.toInt();

    await Future.delayed(const Duration(milliseconds: 10));
    setState(() {
      posts = [...existingPosts, ...newPosts];
    });
    scrollController.jumpTo(scrollOffset.toDouble());
    print('New posts: ${posts.map((p) => p.postData['post']['_id'])}');

    isLoadingNewPosts = false;
  }

  void openProfilePage() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) =>
            Profile(
            uuid: userData['uuid'],
            isSettings: true,
            postUpdateStream: postUpdateStream)));
  }
}
