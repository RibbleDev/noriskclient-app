import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:mcreal/config/Colors.dart';
import 'package:mcreal/main.dart';
import 'package:mcreal/screens/Settings.dart';
import 'package:mcreal/utils/NoRiskApi.dart';
import 'package:mcreal/widgets/LoadingIndicator.dart';
import 'package:mcreal/widgets/PinnedMcRealPost.dart';

class Profile extends StatefulWidget {
  const Profile(
      {super.key,
      required this.uuid,
      this.isSettings = false});

  final String uuid;
  final bool isSettings;

  @override
  State<Profile> createState() => ProfileState();
}

class ProfileState extends State<Profile> {
  List<PinndedMcRealPost>? pinns;
  StreamController<bool> pinnedPostsUpdateStream = StreamController<bool>();
  Map<String, Map<String, dynamic>> cache = {};
  Map<String, dynamic> userData = getUserData;

  @override
  void initState() {
    loadPinnedPosts();
    getUpdateStream.sink.add([
      'loadUsername',
      widget.uuid,
      () => setState(() {
            cache = getCache;
          })
    ]);

    pinnedPostsUpdateStream.stream.listen((_) => loadPinnedPosts());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: NoRiskClientColors.background,
        body: Padding(
            padding: const EdgeInsets.all(15),
            child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: loadPinnedPosts,
                  child: ListView(
                    children: [
                      const SizedBox(height: 20),
                      Text(cache['usernames']?[widget.uuid] ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 20,
                              color: NoRiskClientColors.text,
                              fontWeight: FontWeight.bold)),
                      Center(
                          child: cache['armorSkins']?[widget.uuid] ??
                              const SizedBox()),
                      const SizedBox(height: 25),
                      Column(
                          children: pinns == null
                              ? [const LoadingIndicator()]
                              : pinns!.isEmpty
                                  ? [
                                      Text(
                                          AppLocalizations.of(context)!
                                              .mcRealProfile_notPosted,
                                          style: const TextStyle(
                                              color: NoRiskClientColors.text))
                                    ]
                                  : pinns!),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 67.5),
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: SizedBox(
                          height: 30,
                          width: 30,
                          child: Icon(
                              isIOS ? CupertinoIcons.back : Icons.arrow_back,
                              color: NoRiskClientColors.text,
                              size: 30),
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.isSettings)
                  Positioned(
                      top: 70,
                      right: 5,
                      child: GestureDetector(
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (BuildContext context) =>
                                      const Settings())),
                          child: const SizedBox(
                              height: 30,
                              width: 30,
                              child: Center(
                                child: Icon(Icons.settings,
                                    color: NoRiskClientColors.text, size: 30),
                              ))))
              ],
            )));
  }

  Future<void> loadPinnedPosts() async {
    setState(() {
      pinns = null;
    });
    http.Response res = await http.get(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/user/${widget.uuid}/pinned?uuid=${userData['uuid']}'),
        headers: {'Authorization': 'Bearer ${userData['token']}'});
    if (res.statusCode != 200) {
      print(res.statusCode);
      if (res.statusCode == 401) {
        Navigator.of(context).pop();
        getUpdateStream.sink.add(['signOut']);
      }
      if (res.body.contains('hochladen')) {
        setState(() {
          pinns = [];
        });
      }
      return;
    }
    List pinnedPostsData = jsonDecode(utf8.decode(res.bodyBytes));

    List<PinndedMcRealPost> newPinnedPosts = [];
    int index = 0;
    for (var pinnedPostData in pinnedPostsData) {
      newPinnedPosts.add(PinndedMcRealPost(
          postData: pinnedPostData,
          pinnedIndex: index,
          pinnedUuid: widget.uuid,
          pinnedPostsUpdateStream: pinnedPostsUpdateStream));
      index++;
    }

    setState(() {
      pinns = [];
    });
    setState(() {
      pinns = newPinnedPosts;
    });
  }
}
