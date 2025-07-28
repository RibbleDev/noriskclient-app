import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:noriskclient/l10n/app_localizations.dart';
import 'package:noriskclient/config/Colors.dart';
import 'package:noriskclient/config/Config.dart';
import 'package:noriskclient/main.dart';
import 'package:noriskclient/screens/mcreal/ImageViewer.dart';
import 'package:noriskclient/screens/McReal.dart';
import 'package:noriskclient/screens/mcreal/McRealPostDetails.dart';
import 'package:noriskclient/screens/NoRiskProfile.dart';
import 'package:noriskclient/screens/mcreal/ReportMcReal.dart';
import 'package:noriskclient/utils/McRealStatus.dart';
import 'package:noriskclient/utils/NoRiskApi.dart';
import 'package:noriskclient/utils/NoRiskIcon.dart';
import 'package:noriskclient/utils/ReportTypes.dart';
import 'package:noriskclient/widgets/LoadingIndicator.dart';
import 'package:noriskclient/widgets/NoRiskButton.dart';
import 'package:noriskclient/widgets/NoRiskContainer.dart';
import 'package:noriskclient/widgets/NoRiskIconButton.dart';
import 'package:noriskclient/widgets/NoRiskText.dart';
import 'package:noriskclient/utils/StringUtils.dart';

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
  final StreamController<String> postUpdateStream;
  final StreamController<String?>? commentUpdateStream;
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
  bool processingNewRating = false;
  bool animateUpvote = false;
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
                : NoRiskClientColors.darkerBackground),
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
    NoRiskApi()
        .getUserProfile(widget.postData['post']['author'])
        .then((Map profile) {
      setState(() {
        cache = getCache;
      });
    });
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
        child: NoRiskContainer(
          padding: EdgeInsets.only(
              top: isOwnPost && userData['mcRealStatus'] != McRealStatus.OK
                  ? 12
                  : 5,
              left: 12,
              right: 12,
              bottom: isOwnPost && userData['mcRealStatus'] != McRealStatus.OK
                  ? 0
                  : 0),
          child: isOwnPost && userData['mcRealStatus'] == McRealStatus.REMOVED
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                      const Icon(Icons.info, color: Colors.red, size: 25),
                      const SizedBox(width: 10),
                      NoRiskText(
                          AppLocalizations.of(context)!
                              .mcReal_removedPost
                              .toLowerCase(),
                          style: const TextStyle(
                              fontSize: 20,
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
                          NoRiskText(
                              AppLocalizations.of(context)!
                                  .mcReal_status_deleted
                                  .toLowerCase(),
                              style: const TextStyle(
                                  fontSize: 20,
                                  color: NoRiskClientColors.text,
                                  fontWeight: FontWeight.w500)),
                        ])
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: openProfilePage,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(1.5),
                                  child: cache['skins']?[widget.postData['post']
                                          ['author']] ??
                                      const SizedBox(
                                          height: 32,
                                          width: 32,
                                          child: LoadingIndicator()),
                                ),
                              ),
                              const SizedBox(width: 7.5),
                              SizedBox(
                                height: 32,
                                width: MediaQuery.of(context).size.width / 2,
                                child: Stack(children: [
                                  Positioned(
                                    top: -5,
                                    left: 0,
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          NoRiskText(
                                              isOwnPost
                                                  ? AppLocalizations.of(
                                                          context)!
                                                      .mcReal_yourMcReal
                                                      .toLowerCase()
                                                  : cache['usernames']?[widget
                                                                  .postData[
                                                              'post']['author']]
                                                          .toString()
                                                          .toLowerCase() ??
                                                      '',
                                              spaceBottom: false,
                                              spaceTop: false,
                                              style: TextStyle(
                                                  fontSize: 25,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white)),
                                          const SizedBox(width: 5),
                                          GestureDetector(
                                            child: SizedBox(
                                              height: 32,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  NoRiskText(
                                                      cache['profiles']?[widget.postData[
                                                                              'post']
                                                                          [
                                                                          'author']]
                                                                      ?[
                                                                      'mcRealStreak']
                                                                  ['days']
                                                              ?.toString() ??
                                                          '?',
                                                      spaceBottom: false,
                                                      spaceTop: false,
                                                      style: const TextStyle(
                                                          fontSize: 25,
                                                          color: Colors.red,
                                                          fontWeight:
                                                              FontWeight.w900)),
                                                  const SizedBox(width: 1.5),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 1.5),
                                                    child: NoRiskIconButton(
                                                        transparent: true,
                                                        width: 20,
                                                        height: 20,
                                                        onTap: () => Fluttertoast
                                                            .showToast(
                                                                msg:
                                                                    "McReal Streak: ${cache['profiles']?[widget.postData['post']['author']]?['mcRealStreak']['days'] ?? '?'}"),
                                                        icon:
                                                            NoRiskIcon.streak),
                                                  )
                                                ],
                                              ),
                                            ),
                                            onTap: () => Fluttertoast.showToast(
                                                msg:
                                                    "McReal Streak: ${cache['profiles']?[widget.postData['post']['author']]?['mcRealStreak']['days'] ?? '?'}"),
                                          )
                                        ]),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(top: 15),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        NoRiskText(getPostTime().toLowerCase(),
                                            spaceBottom: false,
                                            spaceTop: false,
                                            style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white)),
                                        const SizedBox(width: 5),
                                        if (!isOwnPost &&
                                            ownPostData != null &&
                                            ownPostData?['post']?['region'] !=
                                                widget.postData['post']
                                                    ['region'])
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 2.5),
                                                child: const Icon(
                                                    CupertinoIcons.globe,
                                                    color:
                                                        NoRiskClientColors.blue,
                                                    size: 13.5),
                                              ),
                                              const SizedBox(width: 2.5),
                                              NoRiskText(
                                                  widget.postData['post']
                                                          ['region']
                                                      .toString()
                                                      .toLowerCase(),
                                                  spaceTop: false,
                                                  spaceBottom: false,
                                                  style: const TextStyle(
                                                      fontSize: 20,
                                                      color: NoRiskClientColors
                                                          .blue,
                                                      fontWeight:
                                                          FontWeight.w500)),
                                            ],
                                          )
                                      ],
                                    ),
                                  )
                                ]),
                              ),
                              const Spacer(),
                              if (isOwnPost)
                                NoRiskIconButton(
                                    onTap: delete, icon: NoRiskIcon.delete),
                              if (!isOwnPost && !widget.locked)
                                NoRiskIconButton(
                                    onTap: openReportPage,
                                    icon: NoRiskIcon.report),
                            ]),
                        const SizedBox(height: 5),
                        Stack(children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.width * 0.5,
                            child: Center(
                              child: GestureDetector(
                                onTap: widget.locked
                                    ? () {}
                                    : widget.commentUpdateStream != null
                                        ? () => Navigator.push(context,
                                                MaterialPageRoute(
                                                    builder: (context) {
                                              return ImageViewer(
                                                  image: cache['posts']?[
                                                      widget.postData['post']
                                                          ['_id']]?[swapped
                                                      ? 'secondary'
                                                      : 'primary']);
                                            }))
                                        : openDetailsPage,
                                onDoubleTap: () => upvote(true),
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
                                                  BorderRadius.circular(1.5),
                                            ),
                                            child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(1.5),
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
                                                                .circular(1.5),
                                                        child: swapped
                                                            ? getPrimary()
                                                            : getSecondary(),
                                                      )))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          AnimatedPositioned(
                              duration: Duration(milliseconds: 500),
                              height: 35,
                              width: 40,
                              top: MediaQuery.of(context).size.width *
                                  (animateUpvote ? 0.3 : 0.35),
                              left: 5,
                              child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 300),
                                  opacity: animateUpvote ? 1 : 0,
                                  // CHANGE ME:
                                  child: Image.asset(
                                      'lib/assets/icons/upvoted.png',
                                      height: 35,
                                      width: 40,
                                      fit: BoxFit.fill))),
                          if (widget.locked)
                            ClipRect(
                                child: SizedBox(
                              height: MediaQuery.of(context).size.width * 0.5,
                              child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Center(
                                      child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      NoRiskIcon.lock,
                                      const SizedBox(height: 5),
                                      NoRiskText(
                                          widget.lockedReason.toLowerCase(),
                                          textAlign: TextAlign.center,
                                          spaceTop: false,
                                          spaceBottom: false,
                                          style: const TextStyle(
                                              fontSize: 20,
                                              color: NoRiskClientColors.text,
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ))),
                            )),
                        ]),
                        const SizedBox(height: 5),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              NoRiskText(
                                  StringUtils.enforceMaxLength(
                                      widget.postData['post']['title']
                                          .toString()
                                          .toUpperCase(),
                                      20),
                                  spaceTop: false,
                                  spaceBottom: false,
                                  style: const TextStyle(
                                      fontSize: 22.5,
                                      color: NoRiskClientColors.text,
                                      fontWeight: FontWeight.w500)),
                              if (!widget.locked)
                                Row(children: [
                                  if (widget.postData['likes'] -
                                          widget.postData['dislikes'] !=
                                      0)
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 5),
                                      child: NoRiskText(
                                          (widget.postData['likes'] -
                                                  widget.postData['dislikes'])
                                              .toString(),
                                          spaceTop: false,
                                          spaceBottom: false,
                                          style: TextStyle(
                                              fontSize: 35,
                                              color: widget.postData['likes'] -
                                                          widget.postData[
                                                              'dislikes'] >
                                                      0
                                                  ? Colors.green
                                                  : widget.postData['likes'] -
                                                              widget.postData[
                                                                  'dislikes'] <
                                                          0
                                                      ? Colors.red
                                                      : NoRiskClientColors.text,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  const SizedBox(width: 5),
                                  NoRiskButton(
                                      onTap: (widget.postData['userRating']
                                                  ?['isPositive'] ??
                                              false)
                                          ? deleteRating
                                          : () => upvote(false),
                                      height: 30,
                                      color: (widget.postData['userRating']
                                                  ?['isPositive'] ??
                                              false)
                                          ? Colors.green
                                          : NoRiskClientColors.text,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 2.5),
                                        child: NoRiskText("like",
                                            spaceTop: false,
                                            spaceBottom: false,
                                            style: TextStyle(
                                                fontSize: 20,
                                                color: NoRiskClientColors.text,
                                                fontWeight: FontWeight.bold)),
                                      )),
                                  const SizedBox(width: 5),
                                  NoRiskButton(
                                      onTap: widget.postData['userRating']
                                                  ?['isPositive'] ==
                                              false
                                          ? deleteRating
                                          : downvote,
                                      height: 30,
                                      color: widget.postData['userRating']
                                                  ?['isPositive'] ==
                                              false
                                          ? Colors.red
                                          : NoRiskClientColors.text,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 2.5),
                                        child: NoRiskText("dislike",
                                            spaceTop: false,
                                            spaceBottom: false,
                                            style: TextStyle(
                                                fontSize: 20,
                                                color: NoRiskClientColors.text,
                                                fontWeight: FontWeight.bold)),
                                      )),
                                  const SizedBox(width: 5),
                                  NoRiskIconButton(
                                      onTap: widget.displayOnly
                                          ? openCommentBox
                                          : openDetailsPage,
                                      icon: NoRiskIcon.comment)
                                ])
                            ]),
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
            '${NoRiskApi().getAssetUrl()}/post/${widget.postData['post']['_id']}/image?uuid=${userData['uuid']}&experimental=${userData['experimental'] ?? false}&type=primary'),
        headers: {'Authorization': 'Bearer ${userData['token']}'});

    http.Response secondaryRes = await http.get(
        Uri.parse(
            '${NoRiskApi().getAssetUrl()}/post/${widget.postData['post']['_id']}/image?uuid=${userData['uuid']}&experimental=${userData['experimental'] ?? false}&type=secondary'),
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
        builder: (BuildContext context) => Profile(
            uuid: widget.postData['post']['author'],
            postUpdateStream: widget.postUpdateStream)));
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
    widget.commentUpdateStream!.sink.add(null);
  }

  void openReportPage() {
    if (widget.locked) return;
    Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) => ReportMcReal(
            type: ReportType.POST, contentId: widget.postData['post']['_id'])));
  }

  void upvote(bool animate) {
    if (processingNewRating) return;
    int oldLikes = widget.postData['likes'];
    int oldDislikes = widget.postData['dislikes'];
    Map<String, dynamic>? oldUserRating = widget.postData['userRating'];
    setState(() {
      widget.postData['likes']++;
      if (widget.postData['userRating'] != null &&
          !widget.postData['userRating']!['isPositive']) {
        widget.postData['dislikes']--;
      }
      widget.postData['userRating'] = {'isPositive': true};
      processingNewRating = true;
    });
    if (animate) {
      animatedUpvote();
    }

    http.post(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/post/rate?postId=${widget.postData['post']['_id']}&isPositive=true&uuid=${userData['uuid']}'),
        headers: {
          'Authorization': 'Bearer ${userData['token']}',
          'Content-Type': 'application/json'
        }).then((http.Response res) {
      if (res.statusCode != 200) {
        print(res.statusCode);
        setState(() {
          widget.postData['likes'] = oldLikes;
          widget.postData['dislikes'] = oldDislikes;
          widget.postData['userRating'] = oldUserRating;
          processingNewRating = false;
        });
        if (res.statusCode == 401) {
          if (widget.commentUpdateStream != null) {
            Navigator.of(context).pop();
          }
          getUpdateStream.sink.add(['signOut']);
        }
        return;
      }
      widget.postUpdateStream.sink.add(widget.postData['post']['_id']);
      Future.delayed(
          const Duration(seconds: 1),
          () => setState(() {
                processingNewRating = false;
              }));
    });
  }

  void animatedUpvote() async {
    setState(() {
      animateUpvote = true;
    });
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      animateUpvote = false;
    });
  }

  void downvote() async {
    if (processingNewRating) return;
    int oldLikes = widget.postData['likes'];
    int oldDislikes = widget.postData['dislikes'];
    Map<String, dynamic>? oldUserRating = widget.postData['userRating'];
    setState(() {
      widget.postData['dislikes']++;
      if (widget.postData['userRating']?['isPositive'] == true) {
        widget.postData['likes']--;
      }
      widget.postData['userRating'] = {'isPositive': false};
      processingNewRating = true;
    });
    http.Response res = await http.post(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/post/rate?postId=${widget.postData['post']['_id']}&isPositive=false&uuid=${userData['uuid']}'),
        headers: {
          'Authorization': 'Bearer ${userData['token']}',
          'Content-Type': 'application/json'
        });
    if (res.statusCode != 200) {
      print(res.statusCode);
      setState(() {
        widget.postData['likes'] = oldLikes;
        widget.postData['dislikes'] = oldDislikes;
        widget.postData['userRating'] = oldUserRating;
        processingNewRating = false;
      });
      if (res.statusCode == 401) {
        if (widget.commentUpdateStream != null) {
          Navigator.of(context).pop();
        }
        getUpdateStream.sink.add(['signOut']);
      }
      return;
    }
    widget.postUpdateStream.sink.add(widget.postData['post']['_id']);
    Future.delayed(
        const Duration(seconds: 1),
        () => setState(() {
              processingNewRating = false;
            }));
  }

  void deleteRating() async {
    if (processingNewRating) return;
    int oldLikes = widget.postData['likes'];
    int oldDislikes = widget.postData['dislikes'];
    Map<String, dynamic>? oldUserRating = widget.postData['userRating'];
    setState(() {
      if (widget.postData['userRating']?['isPositive'] == true) {
        widget.postData['likes']--;
      } else {
        widget.postData['dislikes']--;
      }
      widget.postData['userRating'] = null;
      processingNewRating = true;
    });
    http.Response res = await http.delete(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/post/rate?postId=${widget.postData['post']['_id']}&uuid=${userData['uuid']}'),
        headers: {
          'Authorization': 'Bearer ${userData['token']}',
          'Content-Type': 'application/json'
        });
    if (res.statusCode != 200) {
      print(res.statusCode);
      setState(() {
        widget.postData['likes'] = oldLikes;
        widget.postData['dislikes'] = oldDislikes;
        widget.postData['userRating'] = oldUserRating;
        processingNewRating = false;
      });
      if (res.statusCode == 401) {
        if (widget.commentUpdateStream != null) {
          Navigator.of(context).pop();
        }
        getUpdateStream.sink.add(['signOut']);
      }
      return;
    }
    widget.postUpdateStream.sink.add(widget.postData['post']['_id']);
    Future.delayed(
        const Duration(seconds: 1),
        () => setState(() {
              processingNewRating = false;
            }));
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
                                  '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/post/${widget.postData['post']['_id']}?uuid=${userData['uuid']}'),
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
                          widget.postUpdateStream.sink.add('*');
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
                                  '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/post/${widget.postData['post']['_id']}?uuid=${userData['uuid']}'),
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
                          widget.postUpdateStream.sink.add('*');
                          Navigator.of(context).pop();
                        },
                        child: Text(
                            AppLocalizations.of(context)!.mcReal_popup_delete))
                  ],
                );
        });
  }
}
