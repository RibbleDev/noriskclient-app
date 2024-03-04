import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mcreal/config/Colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mcreal/screens/Profile.dart';
import 'package:mcreal/utils/NoRiskApi.dart';
import 'package:mcreal/utils/NoRiskIcon.dart';
import 'package:mcreal/widgets/LoadingIndicator.dart';
import 'package:mcreal/widgets/McRealComment.dart';
import 'package:mcreal/widgets/McRealCommentInput.dart';
import 'package:mcreal/widgets/McRealPost.dart';
import 'package:mcreal/widgets/NoRiskIconButton.dart';

class PostDetails extends StatefulWidget {
  const PostDetails(
      {super.key,
      required this.userData,
      required this.postData,
      required this.postUpdateStream});

  final Map<String, dynamic> userData;
  final Map<String, dynamic> postData;
  final StreamController<bool> postUpdateStream;

  @override
  State<PostDetails> createState() => McRealState();
}

class McRealState extends State<PostDetails> {
  StreamController<bool> commentUpdateStream = StreamController<bool>();
  int page = 0;
  List<McRealComment> comments = [];
  Widget commentInput = Container();

  @override
  void initState() {
    loadComments();
    commentUpdateStream.stream.listen((bool data) {
      if (data) {
        loadComments();
      } else {
        setState(() {
          commentInput = commentInput is McRealCommentInput
              ? Container()
              : McRealCommentInput(
                  userData: widget.userData,
                  postId: widget.postData['_id'],
                  refresh: () {
                    loadComments();
                    setState(() {
                      commentInput = Container();
                    });
                  });
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: McRealColors.darkerBackground,
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: loadComments,
              child: ListView(
                children: [
                  const SizedBox(height: 335),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: comments.isNotEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                                commentInput,
                                ...comments,
                                const SizedBox(height: 50)
                              ])
                        : const Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: LoadingIndicator()),
                  )
                ],
              ),
            ),
            Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(height: 65, color: McRealColors.darkerBackground),
                  Container(
                    color: McRealColors.darkerBackground,
                    child: Stack(children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 10, top: 7.5),
                              child: NoRiskIconButton(
                                  onTap: () => Navigator.of(context).pop(),
                                  icon: NoRiskIcon.back),
                            )
                          ]),
                      Center(
                        child: Text(
                            AppLocalizations.of(context)!.postDetails_title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                      )
                    ]),
                  ),
                  Container(height: 10, color: McRealColors.darkerBackground),
                  McRealPost(
                      locked: false,
                      userData: widget.userData,
                      postData: widget.postData,
                      postUpdateStream: widget.postUpdateStream,
                      commentUpdateStream: commentUpdateStream,
                      displayOnly: true),
                ])
          ],
        ));
  }

  Future<void> loadComments() async {
    setState(() {
      comments = [];
    });
    http.Response res = await http.get(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(widget.userData['experimental'])}/comments/?uuid=${widget.userData['uuid']}&page=$page&postId=${widget.postData['_id']}'),
        headers: {'Authorization': 'Bearer ${widget.userData['noriskToken']}'});
    if (res.statusCode != 200) {
      print(res.statusCode);
      return;
    }
    Map<String, dynamic> commentsData = jsonDecode(utf8.decode(res.bodyBytes));

    List<McRealComment> newComments = [];
    for (var commentData in commentsData['comments']) {
      newComments.add(McRealComment(
          userData: widget.userData,
          commentData: commentData,
          commentUpdateStream: commentUpdateStream));
    }

    setState(() {
      comments = newComments;
    });
  }

  void openProfilePage(String uuid) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) => Profile(uuid: uuid)));
  }

  void openReportPage(String uuid) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) => Profile(uuid: uuid)));
  }
}
