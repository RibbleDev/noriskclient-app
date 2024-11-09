import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mcreal/config/Colors.dart';
import 'package:mcreal/main.dart';
import 'package:mcreal/screens/Profile.dart';
import 'package:mcreal/screens/ReportMcReal.dart';
import 'package:mcreal/utils/NoRiskApi.dart';
import 'package:mcreal/utils/NoRiskIcon.dart';
import 'package:mcreal/utils/ReportTypes.dart';
import 'package:mcreal/widgets/LoadingIndicator.dart';
import 'package:mcreal/widgets/McRealComment.dart';
import 'package:mcreal/widgets/McRealCommentInput.dart';
import 'package:mcreal/widgets/McRealPost.dart';
import 'package:mcreal/widgets/NoRiskIconButton.dart';

class PostDetails extends StatefulWidget {
  const PostDetails(
      {super.key,
      required this.postData,
      required this.postUpdateStream});

  final Map<String, dynamic> postData;
  final StreamController<bool> postUpdateStream;

  @override
  State<PostDetails> createState() => McRealState();
}

class McRealState extends State<PostDetails> {
  StreamController<bool> commentUpdateStream = StreamController<bool>();
  int page = 0;
  List<McRealComment>? comments;
  Widget commentInput = Container();
  Map<String, Map<String, dynamic>> cache = getCache;
  Map<String, dynamic> userData = getUserData;

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
                  userData: userData,
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
        backgroundColor: NoRiskClientColors.darkerBackground,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: loadComments,
              child: ListView(
                children: [
                  SizedBox(
                      height: MediaQuery.of(context).size.width * 0.9),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: comments != null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                                commentInput,
                                if (comments!.isNotEmpty) ...comments!,
                                if (comments!.isEmpty &&
                                    commentInput is Container)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 50),
                                    child: Text(
                                        AppLocalizations.of(context)!
                                            .mcReal_noComments,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: NoRiskClientColors.text)),
                                  ),
                                const SizedBox(height: 50)
                              ])
                        : const Center(
                            child: Padding(
                                padding: EdgeInsets.only(top: 50),
                                child: LoadingIndicator()),
                          ),
                  )
                ],
              ),
            ),
            Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                      height: 65, color: NoRiskClientColors.darkerBackground),
                  Container(
                    color: NoRiskClientColors.darkerBackground,
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
                  Container(
                      height: 10, color: NoRiskClientColors.darkerBackground),
                  McRealPost(
                      locked: false,
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
            '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/comments?uuid=${userData['uuid']}&page=$page&postId=${widget.postData['_id']}'),
        headers: {'Authorization': 'Bearer ${userData['token']}'});
    if (res.statusCode != 200) {
      print(res.statusCode);
      if (res.statusCode == 401) {
        Navigator.of(context).pop();
        getUpdateStream.sink.add(['signOut']);
      }
      if (res.body.contains('hochladen')) {
        Navigator.of(context).pop();
        widget.postUpdateStream.sink.add(true);
      }
      return;
    }
    Map<String, dynamic> commentsData = jsonDecode(utf8.decode(res.bodyBytes));

    List<McRealComment> newComments = [];
    for (var commentData in commentsData['comments']) {
      newComments.add(McRealComment(
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
        builder: (BuildContext context) => ReportMcReal(
            type: ReportType.POST, contentId: widget.postData['_id'])));
  }
}
