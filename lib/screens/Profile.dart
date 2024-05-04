import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:mcreal/config/Colors.dart';
import 'package:mcreal/utils/NoRiskApi.dart';
import 'package:mcreal/widgets/LoadingIndicator.dart';
import 'package:mcreal/widgets/PinnedMcRealPost.dart';

class Profile extends StatefulWidget {
  const Profile(
      {super.key,
      required this.uuid,
      required this.userData,
      required this.cache,
      required this.updateStream});

  final String uuid;
  final Map<String, dynamic> userData;
  final Map<String, dynamic> cache;
  final StreamController<List> updateStream;

  @override
  State<Profile> createState() => ProfileState();
}

class ProfileState extends State<Profile> {
  List<PinndedMcRealPost>? pinns;

  @override
  void initState() {
    loadPinnedPosts();
    widget.updateStream.sink.add(['loadUsername', widget.uuid]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: McRealColors.background,
        body: Padding(
            padding: const EdgeInsets.all(15),
            child: RefreshIndicator(
              onRefresh: loadPinnedPosts,
              child: ListView(
                children: [
                  const SizedBox(height: 10),
                  Text(widget.cache['usernames']?[widget.uuid] ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  Center(
                      child: Image.network(
                          'https://mineskin.eu/armor/bust/${widget.uuid}/128.png',
                          height: 175,
                          width: 175)),
                  const SizedBox(height: 25),
                  Column(
                      children: pinns == null
                          ? [const LoadingIndicator()]
                          : pinns!.isEmpty
                              ? [
                                  Text(AppLocalizations.of(context)!
                                      .mcRealProfile_notPosted)
                                ]
                              : pinns!),
                ],
              ),
            )));
  }

  Future<void> loadPinnedPosts() async {
    setState(() {
      pinns = null;
    });
    http.Response res = await http.get(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(widget.userData['experimental'], 'mcreal')}/user/${widget.uuid}/pinned?uuid=${widget.userData['uuid']}'),
        headers: {'Authorization': 'Bearer ${widget.userData['token']}'});
    if (res.statusCode != 200) {
      if (res.body.contains('hochladen')) {
        setState(() {
          pinns = [];
        });
      }
      print(res.statusCode);
      return;
    }
    List pinnedPostsData = jsonDecode(utf8.decode(res.bodyBytes));

    List<PinndedMcRealPost> newPinnedPosts = [];
    int index = 0;
    for (var pinnedPostData in pinnedPostsData) {
      newPinnedPosts.add(PinndedMcRealPost(
          userData: widget.userData,
          postData: pinnedPostData,
          pinnedIndex: index,
          pinnedUuid: widget.uuid));
      index++;
    }

    setState(() {
      pinns = newPinnedPosts;
    });
  }
}
