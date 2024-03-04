import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mcreal/config/Colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mcreal/utils/NoRiskApi.dart';

class McRealCommentInput extends StatefulWidget {
  const McRealCommentInput(
      {super.key,
      required this.userData,
      required this.postId,
      this.parentCommentId,
      required this.refresh});

  final Map<String, dynamic> userData;
  final String postId;
  final String? parentCommentId;
  final Function() refresh;

  @override
  State<McRealCommentInput> createState() => McRealPostState();
}

class McRealPostState extends State<McRealCommentInput> {
  final TextEditingController commentController = TextEditingController();
  final FocusNode commentFocus = FocusNode();
  bool hasFocus = false;

  @override
  void initState() {
    commentFocus.addListener(() {
      setState(() {
        hasFocus = commentFocus.hasFocus;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(top: 15),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width *
                    (widget.parentCommentId != null ? 0.7 : 0.925),
                height: hasFocus ? 100 : 55,
                child: TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(7.5),
                        borderSide: const BorderSide(
                            color: McRealColors.light, width: 2)),
                    fillColor: McRealColors.background,
                    // hintText: ,
                    labelText:
                        AppLocalizations.of(context)!.mcReal_comment_hint,
                    labelStyle: const TextStyle(color: Colors.white),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(7.5),
                        gapPadding: 3.5,
                        borderSide:
                            const BorderSide(color: Colors.white, width: 2)),
                    filled: true,
                    isDense: true,
                  ),
                  enabled: true,
                  maxLines: 3,
                  controller: commentController,
                  focusNode: commentFocus,
                  keyboardType: TextInputType.text,
                  maxLength: 200,
                  cursorHeight: 12.5,
                  style: const TextStyle(color: Colors.white, fontSize: 12.5),
                  autofocus: true,
                  canRequestFocus: true,
                  scrollPadding: const EdgeInsets.all(0),
                  onSubmitted: (value) => create(value),
                  onTapOutside: (event) => commentFocus.unfocus(),
                ),
              )
            ]));
  }

  Future<void> create(String content) async {
    http.Response res = await http.post(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(widget.userData['experimental'])}/comments/?uuid=${widget.userData['uuid']}&postId=${widget.postId}${widget.parentCommentId != null ? '&parentCommentId=${widget.parentCommentId}' : ''}&text=$content'),
        headers: {'Authorization': 'Bearer ${widget.userData['noriskToken']}'});
    if (res.statusCode != 200) {
      print(res.statusCode);
      return;
    }
    widget.refresh();
  }
}
