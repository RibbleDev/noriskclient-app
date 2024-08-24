import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mcreal/config/Colors.dart';
import 'package:mcreal/main.dart';
import 'package:mcreal/utils/NoRiskApi.dart';
import 'package:mcreal/utils/NoRiskIcon.dart';
import 'package:mcreal/widgets/LoadingIndicator.dart';
import 'package:mcreal/widgets/NoRiskIconButton.dart';

class PinndedMcRealPost extends StatefulWidget {
  const PinndedMcRealPost(
      {super.key,
      required this.postData,
      required this.pinnedIndex,
      required this.pinnedUuid});

  final int pinnedIndex;
  final Map<String, dynamic>? postData;
  final String pinnedUuid;

  @override
  State<PinndedMcRealPost> createState() => McRealPostState();
}

class McRealPostState extends State<PinndedMcRealPost> {
  Widget primary = Container();
  Widget secondary = Container();
  bool swapped = false;
  bool holdingMainImage = false;
  Map<String, dynamic> userData = getUserData;

  @override
  void initState() {
    primary = Container(
        height: 200,
        decoration: BoxDecoration(
          color: NoRiskClientColors.darkerBackground,
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Center(child: LoadingIndicator()));
    if (widget.postData != null) {
      loadImages();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: widget.postData == null
          ? Container(
              height: MediaQuery.of(context).size.width * 0.5,
              decoration: BoxDecoration(
                color: NoRiskClientColors.darkerBackground,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Center(
                  child: widget.pinnedUuid == userData['uuid']
                      ? NoRiskIconButton(onTap: pin, icon: NoRiskIcon.lock)
                      : const Text('?',
                          style: TextStyle(
                              fontSize: 30,
                              color: NoRiskClientColors.textLight,
                              fontWeight: FontWeight.bold))),
            )
          : Stack(children: [
              SizedBox(
                height: MediaQuery.of(context).size.width * 0.5,
                child: Center(
                  child: GestureDetector(
                    onLongPress: () => setState(() {
                      holdingMainImage = true;
                    }),
                    onLongPressEnd: (_) => setState(() {
                      holdingMainImage = false;
                    }),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Stack(
                          children: [
                            Stack(
                              children: [
                                Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color:
                                          NoRiskClientColors.darkerBackground,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: swapped ? secondary : primary),
                                if (!holdingMainImage)
                                  Positioned(
                                      top: 10,
                                      left: 10,
                                      child: GestureDetector(
                                          onTap: () => setState(() {
                                                swapped = !swapped;
                                              }),
                                          child: SizedBox(
                                              height: 75,
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                                child: swapped
                                                    ? primary
                                                    : secondary,
                                              )))),
                              ],
                            ),
                            if (!(primary is Container ||
                                secondary is Container))
                              Positioned(
                                  bottom: 5,
                                  left: 10,
                                  child: Text(getPostTime(),
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500))),
                            if (!(primary is Container ||
                                    secondary is Container) &&
                                widget.pinnedUuid == userData['uuid'])
                              Positioned(
                                  top: 10,
                                  right: 10,
                                  child: NoRiskIconButton(
                                      onTap: delete, icon: NoRiskIcon.delete)),
                          ],
                        )),
                  ),
                ),
              ),
            ]),
    );
  }

  String getPostTime() {
    DateTime uploadTime = DateTime.parse(widget.postData!['uploadDate'] +
        ' ' +
        widget.postData!['uploadTime'].toString().split('.')[0]);

    String postTime =
        '${uploadTime.hour < 9 ? '0' : ''}${uploadTime.hour}:${uploadTime.minute < 9 ? '0' : ''}${uploadTime.minute}:${uploadTime.second < 9 ? '0' : ''}${uploadTime.second}';

    return postTime;
  }

  Future<void> loadImages() async {
    http.Response primaryRes = await http.get(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/user/${widget.postData!['author']}/pinned/${widget.pinnedIndex}}?uuid=${userData['uuid']}&type=primary&index=${widget.pinnedIndex}'),
        headers: {'Authorization': 'Bearer ${userData['token']}'});

    http.Response secondaryRes = await http.get(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/user/${widget.postData!['author']}/pinned/${widget.pinnedIndex}}?uuid=${userData['uuid']}&type=secondary&index=${widget.pinnedIndex}'),
        headers: {'Authorization': 'Bearer ${userData['token']}'});
    if (primaryRes.statusCode != 200 || secondaryRes.statusCode != 200) {
      if (primaryRes.statusCode == 401 || secondaryRes.statusCode == 401) {
        Navigator.of(context).pop();
        getUpdateStream.sink.add(['signOut']);
      }
      return;
    }

    setState(() {
      primary = Image.memory(primaryRes.bodyBytes, fit: BoxFit.fill);
      secondary = Image.memory(secondaryRes.bodyBytes, fit: BoxFit.fill);
    });
  }

  Future<void> pin() async {
    http.Response res = await http.post(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/user/pinned/${widget.pinnedIndex}?uuid=${userData['uuid']}&index=${widget.pinnedIndex}'),
        headers: {'Authorization': 'Bearer ${userData['token']}'});
    if (res.statusCode != 200) {
      print(res.statusCode);
      if (res.statusCode == 401) {
        Navigator.of(context).pop();
        getUpdateStream.sink.add(['signOut']);
      }
      return;
    }
  }

  void delete() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Platform.isAndroid
              ? AlertDialog(
                  title: Text(AppLocalizations.of(context)!
                      .mcReal_unpinPostPopupTitle),
                  content: Text(AppLocalizations.of(context)!
                      .mcReal_unpinPostPopupContent),
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
                                  '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/user/pinned/${widget.pinnedIndex}?uuid=${userData['uuid']}&index=${widget.pinnedIndex}'),
                              headers: {
                                'Authorization':
                                    'Bearer ${userData['token']}'
                              });
                          if (res.statusCode != 200) {
                            print(res.statusCode);
                            if (res.statusCode == 401) {
                              Navigator.of(context).pop();
                              getUpdateStream.sink.add(['signOut']);
                            }
                            return;
                          }
                          Navigator.of(context).pop();
                        },
                        child: Text(
                            AppLocalizations.of(context)!.mcReal_popup_unpin,
                            style: const TextStyle(color: Colors.red)))
                  ],
                )
              : CupertinoAlertDialog(
                  title: Text(AppLocalizations.of(context)!
                      .mcReal_unpinPostPopupTitle),
                  content: Text(AppLocalizations.of(context)!
                      .mcReal_unpinPostPopupContent),
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
                                  '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/user/pinned/${widget.pinnedIndex}?uuid=${userData['uuid']}&index=${widget.pinnedIndex}'),
                              headers: {
                                'Authorization':
                                    'Bearer ${userData['token']}'
                              });
                          if (res.statusCode != 200) {
                            print(res.statusCode);
                            if (res.statusCode == 401) {
                              Navigator.of(context).pop();
                              getUpdateStream.sink.add(['signOut']);
                            }
                            return;
                          }
                          Navigator.of(context).pop();
                        },
                        child: Text(
                            AppLocalizations.of(context)!.mcReal_popup_unpin))
                  ],
                );
        });
  }
}
