import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:mcreal/utils/FriendListType.dart';
import 'package:mcreal/widgets/LoadingIndicator.dart';

class NoRiskFriend extends StatefulWidget {
  const NoRiskFriend(
      {super.key,
      required this.type,
      required this.fiendUserData,
      required this.userData,
      required this.cache,
      required this.updateStream,
      required this.friendUpdateStream});

  final FriendListType type;
  final Map<String, dynamic> fiendUserData;
  final Map<String, dynamic> userData;
  final Map<String, dynamic> cache;
  final StreamController<List> updateStream;
  final StreamController<bool> friendUpdateStream;

  @override
  State<NoRiskFriend> createState() => NoRiskFriendState();
}

class NoRiskFriendState extends State<NoRiskFriend> {
  String uuid = '';
  String username = '';
  String rank = '';

  @override
  void initState() {
    uuid = widget.fiendUserData['uuid'];
    username = widget.fiendUserData['ign'];
    rank = widget.fiendUserData['rank'];
    widget.updateStream.sink.add(['loadSkin', uuid]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(7.5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 25,
              width: 25,
              child: widget.cache['skins']?[uuid] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(3.5),
                      child: widget.cache['skins']?[uuid],
                    )
                  : const LoadingIndicator(),
            ),
            const SizedBox(width: 10),
            Text('$username ${rank != 'Default' ? '($rank)' : ''}',
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w400)),
            const SizedBox(width: 10),
            const Spacer()
          ],
        ));
  }
}
