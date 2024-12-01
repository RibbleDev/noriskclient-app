import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:mcreal/config/Colors.dart';
import 'package:mcreal/main.dart';
import 'package:mcreal/screens/Settings.dart';
import 'package:mcreal/utils/NoRiskApi.dart';
import 'package:mcreal/utils/NoRiskIcon.dart';
import 'package:mcreal/widgets/LoadingIndicator.dart';
import 'package:mcreal/widgets/NoRiskIconButton.dart';
import 'package:mcreal/widgets/ProfileMcRealPost.dart';

class Profile extends StatefulWidget {
  const Profile({super.key, required this.uuid, this.isSettings = false});

  final String uuid;
  final bool isSettings;

  @override
  State<Profile> createState() => ProfileState();
}

class ProfileState extends State<Profile> {
  List<ProfileMcRealPost>? pinns;
  StreamController<int> profilePostsUpdateStream = StreamController<int>();
  Map<String, Map<String, dynamic>> cache = getCache;
  Map<String, dynamic> userData = getUserData;
  bool noPinns = true;

  //eastereggs
  bool PSJahn = false;
  bool Aim_shock = false;

  @override
  void initState() {
    loadPinnedPosts(null);
    loadStreak();

    if (!widget.isSettings) {
    getUpdateStream.sink.add([
      'loadUsername',
      widget.uuid,
      () => setState(() {
            cache = getCache;
          })
    ]);
    }

    profilePostsUpdateStream.stream
        .listen((int index) => loadPinnedPosts(index));
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                          children: [
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: SizedBox(
                                height: 30,
                                width: 30,
                                child: NoRiskIcon.back,
                              ),
                            ),
                            const Spacer(),
                            Text(
                                widget.uuid == userData['uuid']
                                    ? AppLocalizations.of(context)!
                                        .profile_yourProfile
                                    : (cache['usernames']?[widget.uuid] ??
                                            'Unknown') +
                                        AppLocalizations.of(context)!
                                            .profile_usersProfile,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 20,
                                    color: NoRiskClientColors.text,
                                    fontWeight: FontWeight.bold)),
                            const Spacer(),
                            if (widget.isSettings)
                              GestureDetector(
                                  onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (BuildContext context) =>
                                              const Settings())),
                                  child: const SizedBox(
                                      height: 30,
                                      width: 30,
                                      child: Center(
                                        child: Icon(Icons.settings,
                                            color: NoRiskClientColors.text,
                                            size: 30),
                                      ))),
                            if (!widget.isSettings) const Spacer(),
                            const SizedBox(width: 10),
                          ],
                        ),
                        Center(
                            child: cache['armorSkins']?[widget.uuid] != null
                                ? GestureDetector(
                                    child: cache['armorSkins']?[widget.uuid],
                                    onTap: toggleEasteregg)
                                : const SizedBox()),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                                'McReal ${cache['streaks']?[widget.uuid]?['mcreal'] ?? '?'}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w900)),
                            const SizedBox(width: 5),
                            NoRiskIconButton(
                                onTap: () {}, icon: NoRiskIcon.streak),
                            const SizedBox(width: 25),
                            Text(
                                'Login ${cache['streaks']?[widget.uuid]?['nrc'] ?? '?'}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w900)),
                            const SizedBox(width: 5),
                            NoRiskIconButton(
                                onTap: () {}, icon: NoRiskIcon.streak)
                          ],
                        )
                      ]),
                      Padding(
                        padding: const EdgeInsets.only(top: 300),
                        child: RefreshIndicator(
                          onRefresh: () => loadPinnedPosts(null),
                          child: ListView(
                              children: pinns == null
                                  ? [const LoadingIndicator()]
                                  : noPinns
                                      ? [
                                          SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height -
                                                500,
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            child: Center(
                                                child: Text(
                                                    (cache['usernames']?[
                                                                widget.uuid] ??
                                                            'Unknown') +
                                                        AppLocalizations.of(
                                                                context)!
                                                            .profile_noPinnedPosts,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.red))),
                                          )
                                        ]
                                      : pinns!),
                        ),
                      ),
                    ],
                  ),
                ],
              )),
        ));
  }

  void loadStreak() async {
    if (cache['streaks']?[widget.uuid] != null) {
      return;
    }
    var res = await http.get(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/user/streak/${widget.uuid}?uuid=${userData['uuid']}'),
        headers: {'Authorization': 'Bearer ${userData['token']}'});
    Map<String, dynamic> streakData = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode != 200) {
      print(res.statusCode);
      if (res.statusCode == 401) {
        Navigator.of(context).pop();
        getUpdateStream.sink.add(['signOut']);
      }
      return;
    }

    getUpdateStream.sink.add([
      'cacheStreak',
      widget.uuid,
      streakData,
      () => setState(() {
            cache = getCache;
          })
    ]);
  }

  Future<void> loadPinnedPosts(int? refreshPostIndex) async {
    // only clear if we refresh all posts
    if (refreshPostIndex == null) {
      setState(() {
        pinns = null;
        noPinns = true;
      });
    }
    http.Response res = await http.get(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/user/profile/${widget.uuid}?uuid=${userData['uuid']}'),
        headers: {'Authorization': 'Bearer ${userData['token']}'});
    if (res.statusCode != 200) {
      print(res.statusCode);
      if (res.statusCode == 401) {
        Navigator.of(context).pop();
        getUpdateStream.sink.add(['signOut']);
      }
      return;
    }
    Map<String, dynamic> profileData = jsonDecode(utf8.decode(res.bodyBytes));

    List<ProfileMcRealPost> newPinnedPosts = [];
    int index = 0;
    for (var pinnedPost in profileData['pinnedPosts']) {
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
    } else {
      // update all posts if we refresh all posts
      setState(() {
        pinns = [];
      });
      setState(() {
        pinns = newPinnedPosts;
      });
    }
  }
}
