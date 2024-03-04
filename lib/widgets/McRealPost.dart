import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mcreal/config/Colors.dart';
import 'package:mcreal/config/Config.dart';
import 'package:mcreal/screens/PostDetails.dart';
import 'package:mcreal/screens/Profile.dart';
import 'package:mcreal/screens/Report.dart';
import 'package:mcreal/utils/McRealStatus.dart';
import 'package:mcreal/utils/NoRiskApi.dart';
import 'package:mcreal/utils/NoRiskIcon.dart';
import 'package:mcreal/utils/ReportTypes.dart';
import 'package:mcreal/widgets/LoadingIndicator.dart';
import 'package:mcreal/widgets/NoRiskIconButton.dart';

class McRealPost extends StatefulWidget {
  const McRealPost(
      {super.key,
      required this.locked,
      this.lockedReason = '',
      required this.userData,
      required this.postData,
      required this.postUpdateStream,
      this.commentUpdateStream,
      this.displayOnly = false});

  final bool locked;
  final String lockedReason;
  final Map<String, dynamic> userData;
  final Map<String, dynamic> postData;
  final StreamController<bool> postUpdateStream;
  final StreamController<bool>? commentUpdateStream;
  final bool displayOnly;

  @override
  State<McRealPost> createState() => McRealPostState();
}

class McRealPostState extends State<McRealPost> {
  bool ownPost = false;
  String username = '';
  Widget primary = Container();
  Widget secondary = Container();
  bool swapped = false;
  bool holdingMainImage = false;

  @override
  void initState() {
    ownPost = widget.userData['uuid'] == widget.postData['author'];
    primary = Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: widget.displayOnly
              ? McRealColors.background
              : McRealColors.darkerBackground,
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Center(child: LoadingIndicator()));
    secondary = Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: widget.displayOnly
              ? McRealColors.background
              : McRealColors.darkerBackground,
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Center(child: LoadingIndicator()));
    if (!ownPost) {
      getUsername();
    }
    // getPostTime();
    loadImages();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: GestureDetector(
        onTap:
            ownPost && widget.userData['mcRealStatus'] == McRealStatus.REMOVED
                ? openPostRemovedPopup
                : () {},
        child: Container(
          padding: EdgeInsets.only(
              top: ownPost && widget.userData['mcRealStatus'] != McRealStatus.OK
                  ? 12
                  : 5,
              left: 12,
              right: 12,
              bottom:
                  ownPost && widget.userData['mcRealStatus'] != McRealStatus.OK
                      ? 12
                      : 0),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: McRealColors.darkerBackground),
          child: ownPost &&
                  widget.userData['mcRealStatus'] == McRealStatus.REMOVED
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                      const Icon(Icons.info, color: Colors.red, size: 25),
                      const SizedBox(width: 10),
                      Text(AppLocalizations.of(context)!.mcReal_removedPost,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500)),
                    ])
              : ownPost &&
                      widget.userData['mcRealStatus'] == McRealStatus.DELETED
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                          const Icon(Icons.info,
                              color: McRealColors.blue, size: 25),
                          const SizedBox(width: 10),
                          Text(
                              AppLocalizations.of(context)!
                                  .mcReal_status_deleted,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w500)),
                        ])
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 40,
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: openProfilePage,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(2.5),
                                    child: Image.network(
                                        'https://mineskin.eu/helm/${widget.postData['author']}/64',
                                        height: 32,
                                        width: 32),
                                  ),
                                ),
                                const SizedBox(width: 7.5),
                                Stack(children: [
                                  Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            ownPost
                                                ? AppLocalizations.of(context)!
                                                    .mcReal_yourMcReal
                                                : username,
                                            style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                                color: ownPost
                                                    ? McRealColors.blue
                                                    : Colors.white))
                                      ]),
                                  Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(getPostTime(),
                                            style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white)),
                                      ])
                                ]),
                                const Spacer(),
                                if (ownPost)
                                  NoRiskIconButton(
                                      onTap: delete, icon: NoRiskIcon.delete),
                                const SizedBox(width: 5)
                              ]),
                        ),
                        const SizedBox(height: 5),
                        Stack(children: [
                          SizedBox(
                            height: 210,
                            child: Center(
                              child: GestureDetector(
                                onLongPress: widget.locked
                                    ? () {}
                                    : () => setState(() {
                                          holdingMainImage = true;
                                        }),
                                onLongPressEnd: widget.locked
                                    ? (_) {}
                                    : (_) => setState(() {
                                          holdingMainImage = false;
                                        }),
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5),
                                    child: Stack(
                                      children: [
                                        Stack(
                                          children: [
                                            swapped ? secondary : primary,
                                            if (!holdingMainImage)
                                              Positioned(
                                                  top: 10,
                                                  left: 10,
                                                  child: GestureDetector(
                                                      onTap: widget.locked
                                                          ? () {}
                                                          : () => setState(() {
                                                                swapped =
                                                                    !swapped;
                                                              }),
                                                      child: SizedBox(
                                                          height: 75,
                                                          child: ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5),
                                                              child: swapped
                                                                  ? primary
                                                                  : secondary)))),
                                          ],
                                        ),
                                        if (!(primary is Container ||
                                            secondary is Container))
                                          Positioned(
                                              bottom: ownPost ? 10 : 45,
                                              right: 10,
                                              child: NoRiskIconButton(
                                                  onTap: widget.displayOnly
                                                      ? openCommentBox
                                                      : openDetailsPage,
                                                  icon: NoRiskIcon.comment)),
                                        if (!ownPost &&
                                            !(primary is Container ||
                                                secondary is Container))
                                          Positioned(
                                              bottom: 10,
                                              right: 10,
                                              child: NoRiskIconButton(
                                                  onTap: openReportPage,
                                                  icon: NoRiskIcon.report))
                                      ],
                                    )),
                              ),
                            ),
                          ),
                          if (widget.locked)
                            ClipRect(
                                child: SizedBox(
                              height: 210,
                              child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                  child: Center(
                                      child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      NoRiskIcon.lock,
                                      const SizedBox(height: 5),
                                      Text(widget.lockedReason,
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ))),
                            )),
                          if (widget.locked &&
                              widget.userData['mcRealStatus'] ==
                                  McRealStatus.REMOVED)
                            GestureDetector(
                              onTap: openPostRemovedPopup,
                              child: SizedBox(
                                height: 210,
                                width: double.infinity,
                                child: Container(
                                    height: 210,
                                    width: double.infinity,
                                    color: Colors.transparent),
                              ),
                            )
                        ]),
                        const SizedBox(height: 5),
                        Text(widget.postData['title'],
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 5),
                      ],
                    ),
        ),
      ),
    );
  }

  String getPostTime() {
    DateTime mcRealTime = DateTime.parse(widget.postData['mcRealDate'] +
        ' ' +
        widget.postData['mcRealTime'].toString().split('.')[0]);
    DateTime uploadTime = DateTime.parse(widget.postData['uploadDate'] +
        ' ' +
        widget.postData['uploadTime'].toString().split('.')[0]);
    DateTime now = DateTime.now();

    Duration difference = uploadTime
        .subtract(Duration(minutes: Config.mcRealTimeframe))
        .difference(mcRealTime);

    String postTime = '';

    if (widget.postData['serverIp'] != null) {
      postTime += widget.postData['serverIp'];
      postTime += ' • ';
    }

    if (difference.inMinutes == 0) {
      Duration uploadDifference = now.difference(mcRealTime);
      if (uploadDifference.inMinutes < Config.mcRealTimeframe) {
        postTime += AppLocalizations.of(context)!.mcReal_justNow;
      } else {
        postTime +=
            '${uploadTime.hour}:${uploadTime.minute}:${uploadTime.second}';
      }
    } else {
      if (difference.inHours > 0) {
        postTime = '${difference.inHours}h ';
      } else if (difference.inMinutes > 0) {
        postTime = '${difference.inMinutes}min ';
      } else {
        postTime = '${difference.inSeconds}s ';
      }
      postTime += AppLocalizations.of(context)!.mcReal_ago;
    }

    return postTime;
  }

  Future<void> getUsername() async {
    http.Response res = await http.get(Uri.parse(
        'https://sessionserver.mojang.com/session/minecraft/profile/${widget.postData['author']}'));
    if (res.statusCode != 200) {
      return;
    }
    setState(() {
      username = jsonDecode(res.body)['name'];
    });
  }

  Future<void> loadImages() async {
    http.Response primaryRes = await http.get(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(widget.userData['experimental'])}/post/${widget.postData['_id']}/image?uuid=${widget.userData['uuid']}&type=primary'),
        headers: {'Authorization': 'Bearer ${widget.userData['noriskToken']}'});

    http.Response secondaryRes = await http.get(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(widget.userData['experimental'])}/post/${widget.postData['_id']}/image?uuid=${widget.userData['uuid']}&type=secondary'),
        headers: {'Authorization': 'Bearer ${widget.userData['noriskToken']}'});
    if (primaryRes.statusCode != 200 || secondaryRes.statusCode != 200) {
      return;
    }

    setState(() {
      primary = Image.memory(primaryRes.bodyBytes, fit: BoxFit.fitHeight);
      secondary = Image.memory(secondaryRes.bodyBytes, fit: BoxFit.fitHeight);
    });
  }

  void openProfilePage() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) =>
            Profile(uuid: widget.postData['author'])));
  }

  void openDetailsPage() {
    if (widget.locked) return;
    Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) => PostDetails(
            userData: widget.userData,
            postData: widget.postData,
            postUpdateStream: widget.postUpdateStream)));
  }

  void openCommentBox() {
    if (widget.locked || widget.commentUpdateStream == null) return;
    widget.commentUpdateStream!.sink.add(false);
  }

  void openReportPage() {
    if (widget.locked) return;
    Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) => Report(
            type: ReportType.POST,
            contentId: widget.postData['_id'],
            userData: widget.userData)));
  }

  void openPostRemovedPopup() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Platform.isAndroid
              ? AlertDialog(
                  title: Text(AppLocalizations.of(context)!
                      .mcReal_removedPostPopupTitle),
                  content: Text(
                      '${AppLocalizations.of(context)!.mcReal_removedPostReason}: ${widget.postData['mcRealStatusInfo']}'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                            AppLocalizations.of(context)!.mcReal_popup_ok,
                            style: const TextStyle(color: Colors.white))),
                  ],
                )
              : CupertinoAlertDialog(
                  title: Text(AppLocalizations.of(context)!
                      .mcReal_removedPostPopupTitle),
                  content: Text(
                      '${AppLocalizations.of(context)!.mcReal_removedPostReason}: ${widget.userData['mcRealStatusInfo']}'),
                  actions: [
                    CupertinoDialogAction(
                        isDefaultAction: true,
                        onPressed: () => Navigator.of(context).pop(),
                        child:
                            Text(AppLocalizations.of(context)!.mcReal_popup_ok))
                  ],
                );
        });
  }

  void delete() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Platform.isAndroid
              ? AlertDialog(
                  title: Text(AppLocalizations.of(context)!
                      .mcReal_deletePostPopupTitle),
                  content: Text(AppLocalizations.of(context)!
                      .mcReal_deletePostPopupContent),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                            AppLocalizations.of(context)!.mcReal_popup_cancel,
                            style: const TextStyle(color: Colors.white))),
                    TextButton(
                        onPressed: () async {
                          http.Response res = await http.delete(
                              Uri.parse(
                                  '${NoRiskApi().getBaseUrl(widget.userData['experimental'])}/post?uuid=${widget.userData['uuid']}'),
                              headers: {
                                'Authorization':
                                    'Bearer ${widget.userData['noriskToken']}'
                              });
                          if (res.statusCode != 200) {
                            print(res.statusCode);
                            return;
                          }
                          widget.postUpdateStream.sink.add(true);
                          Navigator.of(context).pop();
                        },
                        child: Text(
                            AppLocalizations.of(context)!.mcReal_popup_delete,
                            style: const TextStyle(color: Colors.red)))
                  ],
                )
              : CupertinoAlertDialog(
                  title: Text(AppLocalizations.of(context)!
                      .mcReal_deletePostPopupTitle),
                  content: Text(AppLocalizations.of(context)!
                      .mcReal_deletePostPopupContent),
                  actions: [
                    CupertinoDialogAction(
                        isDefaultAction: true,
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                            AppLocalizations.of(context)!.mcReal_popup_cancel)),
                    CupertinoDialogAction(
                        isDestructiveAction: true,
                        onPressed: () async {
                          http.Response res = await http.delete(
                              Uri.parse(
                                  '${NoRiskApi().getBaseUrl(widget.userData['experimental'])}/post?uuid=${widget.userData['uuid']}'),
                              headers: {
                                'Authorization':
                                    'Bearer ${widget.userData['noriskToken']}'
                              });
                          if (res.statusCode != 200) {
                            print(res.statusCode);
                            return;
                          }
                          widget.postUpdateStream.sink.add(true);
                          Navigator.of(context).pop();
                        },
                        child: Text(
                            AppLocalizations.of(context)!.mcReal_popup_delete))
                  ],
                );
        });
  }
}
