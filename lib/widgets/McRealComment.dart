import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mcreal/config/Colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mcreal/screens/Profile.dart';
import 'package:mcreal/screens/Report.dart';
import 'package:mcreal/utils/NoRiskApi.dart';
import 'package:mcreal/utils/NoRiskIcon.dart';
import 'package:mcreal/utils/ReportTypes.dart';
import 'package:mcreal/widgets/LoadingIndicator.dart';
import 'package:mcreal/widgets/McRealCommentInput.dart';
import 'package:mcreal/widgets/NoRiskIconButton.dart';

class McRealComment extends StatefulWidget {
  const McRealComment(
      {super.key,
      required this.userData,
      required this.commentData,
      required this.cache,
      required this.updateStream,
      required this.commentUpdateStream,
      this.parentId = ''});

  final Map<String, dynamic> userData;
  final Map<String, dynamic> commentData;
  final Map<String, dynamic> cache;
  final StreamController<List> updateStream;
  final StreamController<bool> commentUpdateStream;
  final String parentId;

  @override
  State<McRealComment> createState() => McRealPostState();
}

class McRealPostState extends State<McRealComment> {
  int page = 0;
  bool ownComment = false;
  int likes = 0;
  int dislikes = 0;
  bool? ownRating;
  List<McRealComment> replys = [];
  bool showReplys = false;
  Widget commentInput = Container();

  @override
  void initState() {
    widget.updateStream.sink
        .add(['loadSkin', widget.commentData['comment']['author']]);
    ownComment =
        widget.userData['uuid'] == widget.commentData['comment']['author'];
    if (!ownComment) {
      widget.updateStream.sink
          .add(['loadUsername', widget.commentData['comment']['author']]);
    }
    likes = widget.commentData['likes'];
    dislikes = widget.commentData['dislikes'];
    if (widget.commentData['userRating'] != null) {
      ownRating = widget.commentData['userRating']?['isPositive'] == null;
    }
    loadReplys();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(7.5),
        child: Column(
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
                    borderRadius: BorderRadius.circular(2.5),
                    child: widget.cache['skins']
                            [widget.commentData['comment']['author']] ??
                        const SizedBox(
                            height: 32, width: 32, child: LoadingIndicator()),
                  ),
                ),
                const SizedBox(width: 5),
                SizedBox(
                    height: 40,
                    child: Stack(children: [
                      Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                ownComment
                                    ? AppLocalizations.of(context)!
                                        .mcRealComment_you
                                    : widget.cache['usernames'][
                                            widget.commentData['comment']
                                                ['author']] ??
                                        '',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: ownComment
                                        ? McRealColors.blue
                                        : Colors.white)),
                            const Spacer(),
                          ]),
                      Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Spacer(),
                            Text(
                                widget.commentData['comment']['time']
                                    .toString()
                                    .split('.')[0],
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: McRealColors.light)),
                          ])
                    ]))
              ],
            ),
            const SizedBox(height: 5),
            Text(widget.commentData['comment']['text']),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                NoRiskIconButton(
                    onTap: ownRating == true ? deleteRating : upvote,
                    icon: ownRating == true
                        ? NoRiskIcon.upvoted
                        : NoRiskIcon.upvote),
                const SizedBox(width: 7.5),
                Text('${likes - dislikes}',
                    style: TextStyle(
                        color: likes - dislikes > 0
                            ? Colors.green
                            : likes - dislikes < 0
                                ? Colors.red
                                : Colors.white)),
                const SizedBox(width: 7.5),
                NoRiskIconButton(
                    onTap: ownRating == false ? deleteRating : downvote,
                    icon: ownRating == false
                        ? NoRiskIcon.downvoted
                        : NoRiskIcon.downvote),
                const SizedBox(width: 15),
                NoRiskIconButton(onTap: reply, icon: NoRiskIcon.comment),
                if (!ownComment) const SizedBox(width: 15),
                if (!ownComment)
                  NoRiskIconButton(onTap: report, icon: NoRiskIcon.report),
                const SizedBox(width: 15),
                if (ownComment)
                  NoRiskIconButton(onTap: delete, icon: NoRiskIcon.delete),
              ],
            ),
            SizedBox(
                height: replys.isNotEmpty && commentInput is Container ? 5 : 0),
            commentInput,
            if (replys.isNotEmpty)
              GestureDetector(
                  onTap: () {
                    setState(() {
                      showReplys = !showReplys;
                    });
                  },
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          child: RotatedBox(
                              quarterTurns: showReplys ? 1 : 0,
                              child: Image.asset('lib/assets/icons/arrow.png',
                                  height: 12.5, width: 12.5)),
                        ),
                        const SizedBox(width: 7.5),
                        Text(
                            '${replys.length} ${replys.length > 1 ? AppLocalizations.of(context)!.mcRealComment_replys : AppLocalizations.of(context)!.mcRealComment_reply}',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w500))
                      ])),
            if (showReplys)
              Padding(
                  padding:
                      EdgeInsets.only(left: widget.parentId.isEmpty ? 15 : 0),
                  child: Column(children: [
                    const SizedBox(height: 7.5),
                    AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        child: Column(children: replys)),
                  ]))
          ],
        ),
      ),
    );
  }

  Future<void> loadReplys() async {
    http.Response res = await http.get(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(widget.userData['experimental'], 'mcreal')}/comments/?uuid=${widget.userData['uuid']}&page=$page&postId=${widget.commentData['comment']['postId']}&parentCommentId=${widget.commentData['comment']['_id']}'),
        headers: {'Authorization': 'Bearer ${widget.userData['token']}'});
    if (res.statusCode != 200) {
      print(res.statusCode);
      return;
    }
    Map<String, dynamic> commentsData = jsonDecode(utf8.decode(res.bodyBytes));

    List<McRealComment> newReplys = [];
    for (var commentData in commentsData['comments']) {
      newReplys.add(McRealComment(
          userData: widget.userData,
          commentData: commentData,
          cache: widget.cache,
          updateStream: widget.updateStream,
          commentUpdateStream: widget.commentUpdateStream,
          parentId: widget.commentData['comment']['_id']));
    }

    setState(() {
      replys = newReplys;
    });
  }

  void openProfilePage() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) =>
            Profile(
            uuid: widget.commentData['comment']['author'],
            userData: widget.userData,
            cache: widget.cache,
            updateStream: widget.updateStream)));
  }

  Future<void> reply() async {
    setState(() {
      commentInput = commentInput is McRealCommentInput
          ? Container()
          : McRealCommentInput(
              userData: widget.userData,
              postId: widget.commentData['comment']['postId'],
              parentCommentId: widget.commentData['comment']['_id'],
              refresh: () => widget.commentUpdateStream.sink.add(true));
    });
  }

  Future<void> upvote() async {
    http.Response res = await http.post(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(widget.userData['experimental'], 'mcreal')}/comments/rating?uuid=${widget.userData['uuid']}&commentId=${widget.commentData['comment']['_id']}&isPositive=true'),
        headers: {'Authorization': 'Bearer ${widget.userData['token']}'});
    if (res.statusCode != 200) {
      print(res.statusCode);
      return;
    }
    setState(() {
      likes++;
      if (ownRating == false) {
        dislikes--;
      }
      ownRating = true;
    });
  }

  Future<void> downvote() async {
    http.Response res = await http.post(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(widget.userData['experimental'], 'mcreal')}/comments/rating?uuid=${widget.userData['uuid']}&commentId=${widget.commentData['comment']['_id']}&isPositive=false'),
        headers: {'Authorization': 'Bearer ${widget.userData['token']}'});
    if (res.statusCode != 200) {
      print(res.statusCode);
      return;
    }
    setState(() {
      dislikes++;
      if (ownRating == true) {
        likes--;
      }
      ownRating = false;
    });
  }

  Future<void> deleteRating() async {
    http.Response res = await http.delete(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(widget.userData['experimental'], 'mcreal')}/comments/rating?uuid=${widget.userData['uuid']}&commentId=${widget.commentData['comment']['_id']}'),
        headers: {'Authorization': 'Bearer ${widget.userData['token']}'});
    if (res.statusCode != 200) {
      print(res.statusCode);
      return;
    }
    setState(() {
      if (ownRating == true) {
        likes--;
      } else {
        dislikes--;
      }
      ownRating = null;
    });
  }

  Future<void> report() async {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) => Report(
            type: ReportType.COMMENT,
            contentId: widget.commentData['comment']['_id'],
            userData: widget.userData)));
  }

  Future<void> delete() async {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Platform.isAndroid
              ? AlertDialog(
                  title: Text(AppLocalizations.of(context)!
                      .mcReal_deleteCommentPopupTitle),
                  content: Text(AppLocalizations.of(context)!
                      .mcReal_deleteCommentPopupContent),
                  backgroundColor: McRealColors.darkerBackground,
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                            AppLocalizations.of(context)!.mcReal_popup_cancel,
                            style: const TextStyle(color: McRealColors.blue))),
                    TextButton(
                        onPressed: () async {
                          http.Response res = await http.delete(
                              Uri.parse(
                                  '${NoRiskApi().getBaseUrl(widget.userData['experimental'], 'mcreal')}/comments/?uuid=${widget.userData['uuid']}&commentId=${widget.commentData['comment']['_id']}'),
                              headers: {
                                'Authorization':
                                    'Bearer ${widget.userData['token']}'
                              });
                          if (res.statusCode != 200) {
                            print(res.statusCode);
                            return;
                          }
                          widget.commentUpdateStream.sink.add(true);
                          Navigator.of(context).pop();
                        },
                        child: Text(
                            AppLocalizations.of(context)!.mcReal_popup_delete,
                            style: const TextStyle(color: Colors.red)))
                  ],
                )
              : CupertinoAlertDialog(
                  title: Text(AppLocalizations.of(context)!
                      .mcReal_deleteCommentPopupTitle),
                  content: Text(AppLocalizations.of(context)!
                      .mcReal_deleteCommentPopupContent),
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
                                  '${NoRiskApi().getBaseUrl(widget.userData['experimental'], 'mcreal')}/comments/?uuid=${widget.userData['uuid']}&commentId=${widget.commentData['comment']['_id']}'),
                              headers: {
                                'Authorization':
                                    'Bearer ${widget.userData['token']}'
                              });
                          if (res.statusCode != 200) {
                            print(res.statusCode);
                            return;
                          }
                          widget.commentUpdateStream.sink.add(true);
                          Navigator.of(context).pop();
                        },
                        child: Text(
                            AppLocalizations.of(context)!.mcReal_popup_delete))
                  ],
                );
        });
  }
}
