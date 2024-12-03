import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mcreal/config/Colors.dart';
import 'package:mcreal/main.dart';
import 'package:mcreal/screens/ImageViewer.dart';
import 'package:mcreal/utils/NoRiskApi.dart';
import 'package:mcreal/utils/NoRiskIcon.dart';
import 'package:mcreal/widgets/LoadingIndicator.dart';
import 'package:mcreal/widgets/NoRiskIconButton.dart';

class ProfileMcRealPost extends StatefulWidget {
  ProfileMcRealPost(
      {super.key,
      required this.postData,
      required this.profilePostIndex,
      required this.profileUuid,
      required this.profilePostsUpdateStream});

  final int profilePostIndex;
  Map<String, dynamic>? postData;
  final String profileUuid;
  final StreamController<List> profilePostsUpdateStream;

  @override
  State<ProfileMcRealPost> createState() => McRealPostState();
}

class McRealPostState extends State<ProfileMcRealPost> {
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
      child: widget.postData == null && widget.profileUuid != userData['uuid']
          ? Container()
          : widget.postData == null && widget.profileUuid == userData['uuid']
              ? GestureDetector(
                  onTap: pin,
                  child: Container(
                    height: MediaQuery.of(context).size.width * 0.5,
                    decoration: BoxDecoration(
                      color: NoRiskClientColors.darkerBackground,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(
                        child: NoRiskIconButton(
                            onTap: pin, icon: NoRiskIcon.lock)),
                  ))
              : Container(
                  decoration: BoxDecoration(
                    color: NoRiskClientColors.darkerBackground,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  padding: const EdgeInsets.only(
                      top: 7.5, right: 5, left: 5, bottom: 5),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(getPostTime(),
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: NoRiskClientColors.text)),
                        ],
                      ),
                      const SizedBox(height: 7.5),
                      Stack(children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.width * 0.5,
                          child: Center(
                            child: GestureDetector(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return ImageViewer(
                                    image: cache['posts']
                                            ?[widget.postData!['post']['_id']]
                                        ?[swapped ? 'secondary' : 'primary']);
                              })),
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
                                                color: NoRiskClientColors
                                                    .darkerBackground,
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                              child: swapped
                                                  ? getSecondary()
                                                  : getPrimary()),
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
                                                              BorderRadius
                                                                  .circular(5),
                                                          child: swapped
                                                              ? getPrimary()
                                                              : getSecondary(),
                                                        )))),
                                        ],
                                      ),
                                      if (!(getPrimary() is Container ||
                                              getSecondary() is Container) &&
                                          widget.profileUuid ==
                                              userData['uuid'])
                                        Positioned(
                                            top: 10,
                                            right: 10,
                                            child: NoRiskIconButton(
                                                onTap: delete,
                                                icon: NoRiskIcon.delete)),
                                    ],
                                  )),
                            ),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
    );
  }

  Widget getPrimary() =>
      cache['posts']?[widget.postData?['post']?['_id']]?['primary'] ?? primary;
  Widget getSecondary() =>
      cache['posts']?[widget.postData?['post']?['_id']]?['secondary'] ??
      secondary;

  String getPostTime() {
    DateTime uploadTime = DateTime.parse(widget.postData!['post']
            ['uploadDate'] +
        ' ' +
        widget.postData!['post']['uploadTime'].toString().split('.')[0]);

    String postTime = '';

    if (widget.postData!['post']['serverIp'] != null) {
      postTime += widget.postData!['post']['serverIp'];
      postTime += ' • ';
    }

    postTime +=
        '${uploadTime.hour < 9 ? '0' : ''}${uploadTime.hour}:${uploadTime.minute < 9 ? '0' : ''}${uploadTime.minute}:${uploadTime.second < 9 ? '0' : ''}${uploadTime.second} - ${uploadTime.day < 9 ? '0' : ''}${uploadTime.day}.${uploadTime.month < 9 ? '0' : ''}${uploadTime.month}.${uploadTime.year}';

    return postTime;
  }

  Future<void> loadImages() async {
    if (widget.postData == null ||
        cache['posts']?[widget.postData!['post']['_id']] != null) {
      return;
    }

    http.Response primaryRes = await http.get(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/post/${widget.postData!['post']['_id']}/image?uuid=${userData['uuid']}&type=primary'),
        headers: {'Authorization': 'Bearer ${userData['token']}'});

    http.Response secondaryRes = await http.get(
        Uri.parse(
            '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/post/${widget.postData!['post']['_id']}/image?uuid=${userData['uuid']}&type=secondary'),
        headers: {'Authorization': 'Bearer ${userData['token']}'});
    if (primaryRes.statusCode != 200 || secondaryRes.statusCode != 200) {
      if (primaryRes.statusCode == 401 || secondaryRes.statusCode == 401) {
        Navigator.of(context).pop();
        getUpdateStream.sink.add(['signOut']);
      }
      return;
    }

    getUpdateStream.sink.add([
      'cachePost',
      widget.postData!['post']['_id'],
      Image.memory(primaryRes.bodyBytes, fit: BoxFit.fill),
      Image.memory(secondaryRes.bodyBytes, fit: BoxFit.fill),
      () => setState(() {
            cache = getCache;
          })
    ]);
  }

  void updateData(newData) {
    setState(() {
      widget.postData = newData;
    });
    loadImages();
    getPostTime();
  }

  void pin() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Platform.isAndroid
              ? AlertDialog(
                  title: Text(
                      AppLocalizations.of(context)!.mcReal_pinPostPopupTitle),
                  content: Text(
                      AppLocalizations.of(context)!.mcReal_pinPostPopupContent),
                  backgroundColor: NoRiskClientColors.darkerBackground,
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                            AppLocalizations.of(context)!.mcReal_popup_cancel,
                            style: const TextStyle(color: Colors.red))),
                    TextButton(
                        onPressed: () async {
                          http.Response res = await http.post(
                              Uri.parse(
                                  '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/user/pin?index=${widget.profilePostIndex}&uuid=${userData['uuid']}'),
                              headers: {
                                'Authorization': 'Bearer ${userData['token']}'
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
                          widget.profilePostsUpdateStream.sink
                              .add([widget.profilePostIndex, updateData]);
                        },
                        child: Text(
                            AppLocalizations.of(context)!.mcReal_popup_pin,
                            style: const TextStyle(
                                color: NoRiskClientColors.blue)))
                  ],
                )
              : CupertinoAlertDialog(
                  title: Text(
                      AppLocalizations.of(context)!.mcReal_pinPostPopupTitle),
                  content: Text(
                      AppLocalizations.of(context)!.mcReal_pinPostPopupContent),
                  actions: [
                    CupertinoDialogAction(
                        isDestructiveAction: true,
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                            AppLocalizations.of(context)!.mcReal_popup_cancel)),
                    CupertinoDialogAction(
                        isDefaultAction: true,
                        onPressed: () async {
                          http.Response res = await http.post(
                              Uri.parse(
                                  '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/user/${userData['uuid']}/pin?index=${widget.profilePostIndex}&uuid=${userData['uuid']}'),
                              headers: {
                                'Authorization': 'Bearer ${userData['token']}'
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
                          widget.profilePostsUpdateStream.sink
                              .add([widget.profilePostIndex, updateData]);
                        },
                        child: Text(
                            AppLocalizations.of(context)!.mcReal_popup_pin))
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
                  title: Text(
                      AppLocalizations.of(context)!.mcReal_unpinPostPopupTitle),
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
                                  '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/user/pin?index=${widget.profilePostIndex}&uuid=${userData['uuid']}'),
                              headers: {
                                'Authorization': 'Bearer ${userData['token']}'
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
                          widget.profilePostsUpdateStream.sink
                              .add([widget.profilePostIndex, updateData]);
                        },
                        child: Text(
                            AppLocalizations.of(context)!.mcReal_popup_unpin,
                            style: const TextStyle(color: Colors.red)))
                  ],
                )
              : CupertinoAlertDialog(
                  title: Text(
                      AppLocalizations.of(context)!.mcReal_unpinPostPopupTitle),
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
                                  '${NoRiskApi().getBaseUrl(userData['experimental'], 'mcreal')}/user/pin?index=${widget.profilePostIndex}&uuid=${userData['uuid']}'),
                              headers: {
                                'Authorization': 'Bearer ${userData['token']}'
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
                          widget.profilePostsUpdateStream.sink
                              .add([widget.profilePostIndex, updateData]);
                        },
                        child: Text(
                            AppLocalizations.of(context)!.mcReal_popup_unpin))
                  ],
                );
        });
  }
}
