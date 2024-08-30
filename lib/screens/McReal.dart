import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mcreal/config/Colors.dart';
import 'package:mcreal/config/Config.dart';
import 'package:mcreal/main.dart';
import 'package:mcreal/provider/localeProvider.dart';
import 'package:mcreal/screens/Profile.dart';
import 'package:mcreal/utils/McRealStatus.dart';
import 'package:mcreal/utils/NoRiskApi.dart';
import 'package:mcreal/widgets/LoadingIndicator.dart';
import 'package:mcreal/widgets/McRealPost.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class McReal extends StatefulWidget {
  const McReal({super.key});

  @override
  State<McReal> createState() => McRealState();
}

class McRealState extends State<McReal> {
  StreamController<bool> postUpdateStream = StreamController<bool>();
  bool friendsOnly = true;
  int page = 0;
  McRealPost? post;
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
    postUpdateStream.stream.listen((bool data) {
      if (data) {
        loadPosts();
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: NoRiskClientColors.background,
        body: RefreshIndicator(
          onRefresh: () => loadPosts(),
          child: Stack(
            children: [
              ListView(
                children: [
                  SizedBox(height: Platform.isAndroid ? 60 : 35),
                  posts.isEmpty && post == null
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
                                post ?? const SizedBox(height: 0, width: 0),
                                ...posts
                              ]),
                        )
                ],
              ),
              ClipRRect(
                child: SizedBox(
                  height: 85,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child:
                  Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: Platform.isAndroid ? 60 : 50),
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
          post = null;
        });
      } else if (res.statusCode == 401) {
        getUpdateStream.sink.add(['signOut']);
      }
      return;
    }
    Map<String, dynamic> postData = jsonDecode(utf8.decode(res.bodyBytes));

    if (postData['status'] != null) {
      if (postData['status'] == McRealStatus.REMOVED) {
        userData['mcRealStatus'] = McRealStatus.REMOVED;
        userData['mcRealStatusInfo'] = postData['statusInfo'];
      } else if (postData['status'] == McRealStatus.DELETED) {
        userData['mcRealStatus'] = McRealStatus.DELETED;
      }
    }

    setState(() {
      post = McRealPost(
          locked: false,
          postData: postData,
          postUpdateStream: postUpdateStream);
    });
  }

  Future<void> loadPosts() async {
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

    String lockedReason = '';
    if (userData['mcRealStatus'] == McRealStatus.REMOVED) {
      lockedReason = AppLocalizations.of(context)!.mcReal_status_removed;
    } else if (userData['mcRealStatus'] == McRealStatus.DELETED) {
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
          postUpdateStream: postUpdateStream));
    }

    setState(() {
      posts = [];
    });
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() {
      posts = newPosts;
    });
    print('New posts: ${posts.map((p) => p.postData['_id'])}');
  }

  void openProfilePage() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) =>
            Profile(uuid: userData['uuid'], isSettings: true)));
  }
}
