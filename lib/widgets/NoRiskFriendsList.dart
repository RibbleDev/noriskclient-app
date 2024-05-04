import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mcreal/utils/FriendListType.dart';
import 'package:mcreal/widgets/NoRiskFriend.dart';
import 'package:mcreal/widgets/NoRiskIconButton.dart';

class NoRiskFriendsList extends StatefulWidget {
  const NoRiskFriendsList(
      {super.key,
      required this.title,
      required this.type,
      required this.friends});

  final String title;
  final FriendListType type;
  final List<NoRiskFriend> friends;

  @override
  State<NoRiskFriendsList> createState() => NoRiskFriendsListState();
}

class NoRiskFriendsListState extends State<NoRiskFriendsList> {
  bool expanded = false;

  @override
  void initState() {
    setState(() {
      expanded = widget.friends.isNotEmpty;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, right: 5, left: 5, bottom: 15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              NoRiskIconButton(
                  onTap: () => setState(() {
                        expanded = !expanded;
                      }),
                  icon: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    child: RotatedBox(
                        quarterTurns: expanded ? 1 : 0,
                        child: Image.asset('lib/assets/icons/arrow.png',
                            height: 12.5, width: 12.5)),
                  )),
              const SizedBox(width: 10),
              Text(widget.title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w500))
            ],
          ),
          if (expanded) const SizedBox(height: 5),
          if (expanded)
            AnimatedSize(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                child: Column(
                    children: widget.friends.isEmpty
                        ? [
                            Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: Text(widget.type ==
                                        FriendListType.FRIENDS
                                    ? AppLocalizations.of(context)!
                                        .friends_noFriends
                                    : widget.type ==
                                            FriendListType.INCOMING_REQUESTS
                                        ? AppLocalizations.of(context)!
                                            .friends_noIncomingRequests
                                        : widget.type ==
                                                FriendListType.OUTGOING_REQUESTS
                                            ? AppLocalizations.of(context)!
                                                .friends_noOutgoingRequests
                                            : widget.type ==
                                                    FriendListType.BLOCKED
                                                ? AppLocalizations.of(context)!
                                                    .friends_noBlocked
                                                : 'Empty.'))
                          ]
                        : widget.friends)),
        ],
      ),
    );
  }
}
