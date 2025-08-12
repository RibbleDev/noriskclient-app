import 'dart:async';
import 'package:flutter/material.dart';
import 'package:noriskclient/config/Colors.dart';
import 'package:noriskclient/config/Config.dart';
import 'package:noriskclient/l10n/app_localizations.dart';
import 'package:noriskclient/main.dart';
import 'package:noriskclient/screens/NoRiskProfile.dart';
import 'package:noriskclient/utils/NoRiskApi.dart';
import 'package:noriskclient/widgets/Message.dart';
import 'package:noriskclient/widgets/NoRiskBackButton.dart';
import 'package:noriskclient/widgets/NoRiskText.dart';
import 'package:noriskclient/widgets/NoRiskTextField.dart';

class Chat extends StatefulWidget {
  const Chat({
    super.key,
    required this.chatId,
    required this.participantId,
    required this.chatUpdateStream,
  });

  final String chatId;
  final String participantId;
  final StreamController<String> chatUpdateStream;

  @override
  State<Chat> createState() => ChatState();
}

class ChatState extends State<Chat> {
  ScrollController scrollController = ScrollController();
  StreamController<String> messagesUpdateStream = StreamController<String>();
  int page = 0;
  bool hitEnd = false;
  bool isLoadingNewChats = false;
  List<Message> messages = [];
  TextEditingController textController = TextEditingController();
  FocusNode focusNode = FocusNode();
  bool keyboardVisible = false;

  @override
  void initState() {
    for (int i = 0; i < 5; i++) {
      () async {
        while (isLoadingNewChats) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        setState(() {
          page = page + 1;
          messages = messages;
        });
        await loadMessages();
      }();
      if (hitEnd) {
        break;
      }
    }
    scrollController.addListener(() async {
      double maxScroll = scrollController.position.maxScrollExtent;
      double currentScroll = scrollController.position.pixels;
      double delta = 100.0;
      if ((maxScroll - currentScroll <= delta) &&
          isLoadingNewChats != true &&
          hitEnd != true) {
        page++;
        await loadMessages();
      }
    });

    messagesUpdateStream.stream.listen((String data) async {
      if (data == '*') {
        widget.chatUpdateStream.sink.add('*');
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }
    });

    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        setState(() {
          keyboardVisible = true;
        });
      } else {
        setState(() {
          keyboardVisible = false;
        });
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    messagesUpdateStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: NoRiskClientColors.background,
        body: Padding(
          padding: EdgeInsets.only(
              bottom:
                  isAndroid ? MediaQuery.of(context).viewPadding.bottom : 0),
          child: Column(children: [
            SizedBox(height: isAndroid ? 40 : 60),
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 15, top: 15, right: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 7.5),
                        child: NoRiskBackButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 15, top: 15, right: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: openProfilePage,
                        child: NoRiskText(
                            cache['profiles']?[widget.participantId]?['nrcUser']
                                        ?['ign']
                                    ?.toString()
                                    .toLowerCase() ??
                                '',
                            spaceTop: false,
                            spaceBottom: false,
                            style: const TextStyle(
                                color: NoRiskClientColors.text,
                                fontSize: 40,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
                width: MediaQuery.of(context).size.width - 2 * 15,
                height: MediaQuery.of(context).size.height -
                    195 +
                    (isAndroid ? 20 : 0) -
                    (keyboardVisible
                        ? isAndroid
                            ? 300
                            : 345
                        : 0),
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      messages = [];
                      page = 1;
                    });
                    loadMessages();
                  },
                  child: ListView(
                    controller: scrollController,
                    reverse: true,
                    children: [
                      messages.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(top: 35),
                              child: NoRiskText(
                                  AppLocalizations.of(context)!
                                      .chat_chat_empty
                                      .toLowerCase(),
                                  spaceTop: false,
                                  spaceBottom: false,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      color: NoRiskClientColors.textLight)),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                  ...messages,
                                  const SizedBox(height: 10),
                                ]),
                    ],
                  ),
                )),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(left: 15, right: 15),
              child: NoRiskTextField(
                controller: textController,
                focusNode: focusNode,
                width: MediaQuery.of(context).size.width - 2 * 10,
                hintText: 'Type a message',
                hasSendButton: true,
                onSubmitted: (String text, bool wasButtonPressed) {
                  if (text.isEmpty) {
                    return;
                  }
                  textController.clear();
                  focusNode.unfocus();
                  NoRiskApi()
                      .sendChatMessage(widget.chatId, text)
                      .then((Map<String, dynamic> data) {
                    setState(() {
                      messages.insert(
                        messages.length,
                        Message(
                          chatId: widget.chatId,
                          messageId: data['_id'],
                          content: data['content'],
                          senderId: getUserData['uuid'],
                          sentAt: data['sentAt'],
                          status: data['readAt'] != null
                              ? MessageStatus.READ
                              : data['recivedAt'] != data['sentAt']
                                  ? MessageStatus.RECIVED
                                  : data['sentAt'] != null
                                      ? MessageStatus.SENT
                                      : MessageStatus.PENDING,
                          chatUpdateStream: widget.chatUpdateStream,
                        ),
                      );
                    });
                    widget.chatUpdateStream.sink.add('*');
                  });
                },
              ),
            )
          ]),
        ));
  }

  Future<void> loadMessages() async {
    isLoadingNewChats = true;
    List<dynamic> messagesData =
        await NoRiskApi().getChatMessages(widget.chatId, page);

    if (messagesData.length < Config.messagesPerPage) {
      hitEnd = true;
      print('Hit end!!!');
    } else {
      hitEnd = false;
    }

    List<Message> newMessages = [];
    DateTime lastMessageTimestamp = DateTime.fromMillisecondsSinceEpoch(0);
    for (var messageData in messagesData.reversed) {
      if (messageData['deletedAt'] != null) {
        continue; // Skip deleted messages
      }

      DateTime sentAt =
          DateTime.fromMillisecondsSinceEpoch(messageData['sentAt']);

      if (sentAt.day != lastMessageTimestamp.day) {
        newMessages.add(Message(
            chatId: '',
            messageId: '',
            content: '${sentAt.day}.${sentAt.month}.${sentAt.year}',
            senderId: '',
            sentAt: 0,
            isSpacer: true,
            chatUpdateStream: widget.chatUpdateStream));
      }
      lastMessageTimestamp = sentAt;

      newMessages.add(Message(
          chatId: widget.chatId,
          messageId: messageData['_id'],
          content: messageData['content'],
          senderId: messageData['senderId'],
          sentAt: messageData['sentAt'],
          status: messageData['readAt'] != null
              ? MessageStatus.READ
              : messageData['recivedAt'] != sentAt
                  ? MessageStatus.RECIVED
                  : messageData['sentAt'] != null
                      ? MessageStatus.SENT
                      : MessageStatus.PENDING,
          chatUpdateStream: widget.chatUpdateStream));
    }

    List<Message> existingChats = messages;
    int scrollOffset = scrollController.offset.toInt();

    await Future.delayed(const Duration(milliseconds: 10));
    setState(() {
      messages = [...newMessages, ...existingChats];
    });
    scrollController.jumpTo(scrollOffset.toDouble());

    isLoadingNewChats = false;
  }

  void openProfilePage() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) => Profile(
            uuid: widget.participantId,
            postUpdateStream: messagesUpdateStream)));
  }
}
