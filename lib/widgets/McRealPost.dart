import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mcreal/config/Colors.dart';
import 'package:mcreal/config/Config.dart';
import 'package:mcreal/main.dart';
import 'package:mcreal/screens/McReal.dart';
import 'package:mcreal/screens/PostDetails.dart';
import 'package:mcreal/screens/Profile.dart';
import 'package:mcreal/screens/ReportMcReal.dart';
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
      required this.postData,
      required this.postUpdateStream,
      this.commentUpdateStream,
      this.displayOnly = false});

  final bool locked;
  final String lockedReason;
  final Map<String, dynamic> postData;
  final StreamController<bool> postUpdateStream;
  final StreamController<bool>? commentUpdateStream;
  final bool displayOnly;

  @override
  State<McRealPost> createState() => McRealPostState();
}

class McRealPostState extends State<McRealPost> {
  bool isOwnPost = false;
  Widget primary = Container();
  Widget secondary = Container();
  bool swapped = false;
  bool holdingMainImage = false;
  Map<String, dynamic> userData = getUserData;
  Map<String, Map<String, dynamic>> cache = getCache;

  @override
  void initState() {
    print(widget.postData);
    getUpdateStream.sink.add([
      'loadSkin',
      widget.postData['post']['author'],
      () => setState(() {
            cache = getCache;
          })
    ]);
    isOwnPost = userData['uuid'] == widget.postData['post']['author'];
    primary = Container(
        height: 200,
        decoration: BoxDecoration(
          color: widget.displayOnly
              ? NoRiskClientColors.background
              : NoRiskClientColors.darkerBackground,
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Center(child: LoadingIndicator()));
    if (!isOwnPost) {
      getUpdateStream.sink.add([
        'loadUsername',
        widget.postData['post']['author'],
        () => setState(() {
              cache = getCache;
            })
      ]);
    }
    loadImages();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: GestureDetector(
        onTap: isOwnPost && userData['mcRealStatus'] == McRealStatus.REMOVED
            ? openPostRemovedPopup
            : () {},
        child: Container(
          padding: EdgeInsets.only(
              top: isOwnPost && userData['mcRealStatus'] != McRealStatus.OK
                  ? 12
                  : 5,
              left: 12,
              right: 12,
              bottom: isOwnPost && userData['mcRealStatus'] != McRealStatus.OK
                  ? 12
                  : 0),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: NoRiskClientColors.darkerBackground),
          child: isOwnPost && userData['mcRealStatus'] == McRealStatus.REMOVED
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                      const Icon(Icons.info, color: Colors.red, size: 25),
                      const SizedBox(width: 10),
                      Text(AppLocalizations.of(context)!.mcReal_removedPost,
                          style: const TextStyle(
                              fontSize: 15,
                              color: NoRiskClientColors.text,
                              fontWeight: FontWeight.w500)),
                    ])
              : isOwnPost && userData['mcRealStatus'] == McRealStatus.DELETED
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                          const Icon(Icons.info,
                              color: NoRiskClientColors.blue, size: 25),
                          const SizedBox(width: 10),
                          Text(
                              AppLocalizations.of(context)!
                                  .mcReal_status_deleted,
                              style: const TextStyle(
                                  fontSize: 15,
                                  color: NoRiskClientColors.text,
                                  fontWeight: FontWeight.w500)),
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
                                    child: cache['skins']
                                            ?[widget
                                            .postData['post']['author']] ??
                                        const SizedBox(
                                            height: 32,
                                            width: 32,
                                            child: LoadingIndicator()),
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
                                            isOwnPost
                                                ? AppLocalizations.of(context)!
                                                    .mcReal_yourMcReal
                                                : cache['usernames']?[widget
                                                        .postData['post']
                                                            ['author']] ??
                                                    '',
                                            style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                                color: isOwnPost
                                                    ? NoRiskClientColors.blue
                                                    : Colors.white))
                                      ]),
                                  Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(getPostTime(),
                                            style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white)),
                                            const SizedBox(width: 5),
                                            if (!isOwnPost &&
                                                ownPostData != null &&
                                                ownPostData?['post']
                                                        ?['region'] !=
                                                    widget.postData['post']
                                                        ['region'])
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                      CupertinoIcons.globe,
                                                      color: NoRiskClientColors
                                                          .textLight,
                                                      size: 13.5),
                                                  Text(
                                                      widget.postData['post']
                                                          ['region'],
                                                      style: const TextStyle(
                                                          fontSize: 13.5,
                                                          color:
                                                              NoRiskClientColors
                                                                  .textLight,
                                                          fontWeight:
                                                              FontWeight.w500)),
                                                ],
                                              )
                                          ],
                                        )
                                      ])
                                ]),
                                const Spacer(),
                                if (isOwnPost)
                                  NoRiskIconButton(
                                      onTap: delete, icon: NoRiskIcon.delete),
                                const SizedBox(width: 5)
                              ]),
                        ),
                        const SizedBox(height: 5),
                        Stack(children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.width * 0.5,
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
                                child: Stack(
                                  children: [
                                    Stack(
                                      children: [
                                        Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: NoRiskClientColors
                                                  .darkerBackground,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                                child: swapped
                                                    ? getSecondary()
                                                    : getPrimary())),
                                        if (!holdingMainImage)
                                          Positioned(
                                              top: 10,
                                              left: 10,
                                              child: GestureDetector(
                                                  onTap: widget.locked
                                                      ? () {}
                                                      : () => setState(() {
                                                            swapped = !swapped;
                                                          }),
                                                  child: SizedBox(
                                                      height: 75,
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5),
                                                        child: swapped
                                                            ? getPrimary()
                                                            : getSecondary(),
                                                      )))),
                                      ],
                                    ),
                                    if (!(getPrimary() is Container ||
                                        getSecondary() is Container))
                                      Positioned(
                                          bottom: isOwnPost ? 10 : 45,
                                          right: 10,
                                          child: NoRiskIconButton(
                                              onTap: widget.displayOnly
                                                  ? openCommentBox
                                                  : openDetailsPage,
                                              icon: NoRiskIcon.comment)),
                                    if (!isOwnPost &&
                                        !(getPrimary() is Container ||
                                            getSecondary() is Container))
                                      Positioned(
                                          bottom: 10,
                                          right: 10,
                                          child: NoRiskIconButton(
                                              onTap: openReportPage,
                                              icon: NoRiskIcon.report)),
                                    if (!(getPrimary() is Container ||
                                        getSecondary() is Container))
                                      Positioned(
                                          bottom: 10,
                                          left: 10,
                                          child: Row(
                                            children: [
                                              NoRiskIconButton(
                                                  onTap: (widget.postData[
                                                                  'userRating']
                                                              ?['isPositive'] ??
                                                          false)
                                                      ? deleteRating
                                                      : upvote,
                                                  icon: (widget.postData[
                                                                  'userRating']
                                                              ?['isPositive'] ??
                                                          false)
                                                      ? NoRiskIcon.upvoted
                                                      : NoRiskIcon.upvote),
                                              const SizedBox(width: 5),
                                              Text(
                                                  (widget.postData['likes'] -
                                                          widget.postData[
                                                              'dislikes'])
                                                      .toString(),
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      color: widget.postData[
                                                                      'likes'] -
                                                                  widget.postData[
                                                                      'dislikes'] >
                                                              0
                                                          ? Colors.green
                                                          : widget.postData[
                                                                          'likes'] -
                                                                      widget.postData[
                                                                          'dislikes'] <
                                                                  0
                                                              ? Colors.red
                                                              : NoRiskClientColors
                                                                  .text,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              const SizedBox(width: 5),
                                              NoRiskIconButton(
                                                  onTap: widget.postData[
                                                                  'userRating']
                                                              ?['isPositive'] ==
                                                          false
                                                      ? deleteRating
                                                      : downvote,
                                                  icon: widget.postData[
                                                                  'userRating']
                                                              ?['isPositive'] ==
                                                          false
                                                      ? NoRiskIcon.downvoted
                                                      : NoRiskIcon.downvote),
                                            ],
                                          ))
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (widget.locked)
                            ClipRect(
                                child: SizedBox(
                              height: MediaQuery.of(context).size.width * 0.5,
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
                                              color: NoRiskClientColors.text,
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ))),
                            )),
                        ]),
                        const SizedBox(height: 5),
                        Text(widget.postData['post']['title'],
                            style: const TextStyle(
                                fontSize: 15,
                                color: NoRiskClientColors.text,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 5),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget getPrimary() =>
      cache['posts']?[widget.postData['post']['_id']]?['primary'] ?? primary;
  Widget getSecondary() =>
      cache['posts']?[widget.postData['post']['_id']]?['secondary'] ??
      secondary;

  String getPostTime() {
    DateTime mcRealTime = DateTime.parse(widget.postData['post']['mcRealDate'] +
        ' ' +
        widget.postData['post']['mcRealTime'].toString().split('.')[0]);
    DateTime uploadTime = DateTime.parse(widget.postData['post']['uploadDate'] +
        ' ' +
        widget.postData['post']['uploadTime'].toString().split('.')[0]);

    Duration difference = uploadTime
        .subtract(Duration(minutes: Config.mcRealTimeframe))
        .difference(mcRealTime);

    String postTime = '';

    if (widget.postData['post']['serverIp'] != null) {
      postTime += widget.postData['post']['serverIp'];
      postTime += ' • ';
    }

    if (difference.inMinutes <= 0) {
      postTime +=
          '${uploadTime.hour}:${uploadTime.minute}:${uploadTime.second}';
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

  Future<void> loadImages() async {
    if (cache['posts']?[widget.postData['post']['_id']] != null) {
      return;
    }

    http.Response primaryRes = await http.get(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/post/${widget.postData['post']['_id']}/image?uuid=${userData['uuid']}&type=primary'),
        headers: {'Authorization': 'Bearer ${userData['token']}'});

    http.Response secondaryRes = await http.get(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/post/${widget.postData['post']['_id']}/image?uuid=${userData['uuid']}&type=secondary'),
        headers: {'Authorization': 'Bearer ${userData['token']}'});
    if (primaryRes.statusCode != 200 || secondaryRes.statusCode != 200) {
      if (primaryRes.statusCode == 401 || secondaryRes.statusCode == 401) {
        if (widget.commentUpdateStream != null) {
          Navigator.of(context).pop();
        }
        getUpdateStream.sink.add(['signOut']);
      }
      return;
    }

    getUpdateStream.sink.add([
      'cachePost',
      widget.postData['post']['_id'],
      Image.memory(primaryRes.bodyBytes, fit: BoxFit.fill),
      Image.memory(secondaryRes.bodyBytes, fit: BoxFit.fill),
      () => setState(() {
            cache = getCache;
          })
    ]);
  }

  void openProfilePage() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) =>
            Profile(uuid: widget.postData['post']['author'])));
  }

  void openDetailsPage() {
    if (widget.locked) return;
    Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) => PostDetails(
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
        builder: (BuildContext context) => ReportMcReal(
            type: ReportType.POST, contentId: widget.postData['post']['_id'])));
  }

  void upvote() {
    http.post(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/post/rate?postId=${widget.postData['post']['_id']}&isPositive=true&uuid=${userData['uuid']}'),
        headers: {
          'Authorization': 'Bearer ${userData['token']}',
          'Content-Type': 'application/json'
        }).then((http.Response res) {
      if (res.statusCode != 200) {
        print(res.statusCode);
        if (res.statusCode == 401) {
          if (widget.commentUpdateStream != null) {
            Navigator.of(context).pop();
          }
          getUpdateStream.sink.add(['signOut']);
        }
        return;
      }
      widget.postUpdateStream.sink.add(true);
    });
  }

  void downvote() async {
    http.Response res = await http.post(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/post/rate?postId=${widget.postData['post']['_id']}&isPositive=false&uuid=${userData['uuid']}'),
        headers: {
          'Authorization': 'Bearer ${userData['token']}',
          'Content-Type': 'application/json'
        });
    if (res.statusCode != 200) {
      print(res.statusCode);
      if (res.statusCode == 401) {
        if (widget.commentUpdateStream != null) {
          Navigator.of(context).pop();
        }
        getUpdateStream.sink.add(['signOut']);
      }
      return;
    }
    widget.postUpdateStream.sink.add(true);
  }

  void deleteRating() async {
    http.Response res = await http.delete(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/post/rate?postId=${widget.postData['post']['_id']}&uuid=${userData['uuid']}'),
        headers: {
          'Authorization': 'Bearer ${userData['token']}',
          'Content-Type': 'application/json'
        });
    if (res.statusCode != 200) {
      print(res.statusCode);
      if (res.statusCode == 401) {
        if (widget.commentUpdateStream != null) {
          Navigator.of(context).pop();
        }
        getUpdateStream.sink.add(['signOut']);
      }
      return;
    }
    widget.postUpdateStream.sink.add(true);
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
                      '${AppLocalizations.of(context)!.mcReal_removedPostReason}: ${widget.postData['post']['mcRealStatusInfo']}'),
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
                      '${AppLocalizations.of(context)!.mcReal_removedPostReason}: ${userData['mcRealStatusInfo']}'),
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
                  backgroundColor: NoRiskClientColors.darkerBackground,
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                            AppLocalizations.of(context)!.mcReal_popup_cancel,
                            style: const TextStyle(
                                color: NoRiskClientColors.blue))),
                    TextButton(
                        onPressed: () async {
                          http.Response res = await http.delete(
                              Uri.parse(
                                  '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/post?uuid=${userData['uuid']}'),
                              headers: {
                                'Authorization': 'Bearer ${userData['token']}'
                              });
                          if (res.statusCode != 200) {
                            print(res.statusCode);
                            if (res.statusCode == 401) {
                              if (widget.commentUpdateStream != null) {
                                Navigator.of(context).pop();
                              }
                              getUpdateStream.sink.add(['signOut']);
                            }
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
                            AppLocalizations.of(context)!.mcReal_popup_cancel,
                            style: const TextStyle(
                                color: CupertinoColors.activeBlue))),
                    CupertinoDialogAction(
                        isDestructiveAction: true,
                        onPressed: () async {
                          http.Response res = await http.delete(
                              Uri.parse(
                                  '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/post?uuid=${userData['uuid']}'),
                              headers: {
                                'Authorization': 'Bearer ${userData['token']}'
                              });
                          if (res.statusCode != 200) {
                            print(res.statusCode);
                            if (res.statusCode == 401) {
                              if (widget.commentUpdateStream != null) {
                                Navigator.of(context).pop();
                              }
                              getUpdateStream.sink.add(['signOut']);
                            }
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
