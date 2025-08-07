import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:noriskclient/config/Colors.dart';
import 'package:noriskclient/config/Config.dart';
import 'package:noriskclient/main.dart';
import 'package:noriskclient/provider/localeProvider.dart';
import 'package:noriskclient/screens/NoRiskProfile.dart';
import 'package:noriskclient/utils/BlockingManager.dart';
import 'package:noriskclient/utils/NoRiskApi.dart';
import 'package:noriskclient/widgets/ChatListItem.dart';
import 'package:noriskclient/widgets/NoRiskText.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Chats extends StatefulWidget {
  const Chats({super.key});

  @override
  State<Chats> createState() => ChatsState();
}

class ChatsState extends State<Chats> {
  StreamController<String> chatUpdateStream = StreamController<String>();
  List<ChatListItem> chats = [];

  @override
  void initState() {
    loadLanguage();
    loadChats();
    chatUpdateStream.stream.listen((String data) async {
      if (data == '*') {
        setState(() {
          chats = [];
        });
        loadChats();
        return;
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    chatUpdateStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
        backgroundColor: NoRiskClientColors.background,
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              chats = [];
            });
            loadChats();
          },
          child: ListView(
            children: [
              // SizedBox(height: Platform.isAndroid ? 60 : 35),
              NoRiskText('chats',
                  spaceTop: false,
                  spaceBottom: false,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 45, fontWeight: FontWeight.bold, color: NoRiskClientColors.text)),
              chats.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 35),
                      child: NoRiskText('no open chats found',
                          spaceTop: false,
                          spaceBottom: false,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 20,
                              color: NoRiskClientColors.textLight)),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [const SizedBox(height: 10), ...chats]),
                    ),
              const SizedBox(height: 80),
            ],
          ),
        ));
  }

  Future<void> loadLanguage() async {
    // Ich schäme mich dafür aber juckt jz grad :skull:
    await Future.delayed(const Duration(seconds: 1));
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String language = prefs.getString('language') ??
        (Config.availableLanguages
                .contains(PlatformDispatcher.instance.locale.languageCode)
            ? PlatformDispatcher.instance.locale.languageCode
            : Config.fallbackLangauge);
    if (!mounted) return;
    final provider = Provider.of<LocaleProvider>(context, listen: false);
    provider.setLocale(language);

    if (prefs.getString('language') == null) {
      await prefs.setString('language', language);
    }
  }

  Future<void> loadChats() async {
    List<dynamic> chatsData = await NoRiskApi().getPrivateChats();

    List<ChatListItem> newChats = [];
    for (var chatData in chatsData) {
      String participantId = (chatData['participants'] as List)
          .firstWhere((p) => p['userId'] != userData['uuid'])['userId'];
      bool isBlocked = await BlockingManager().checkBlocked(participantId);

      if (isBlocked) {
        print(
            'Skipped blocked ChatListItem ${chatData['_id']} ($participantId)');
        continue;
      }

      newChats.add(ChatListItem(
          chatId: chatData['_id'],
          participantId: participantId,
          lastMessage: chatData['latestMessage']?['content'] ?? '',
          lastMessageTimestamp: chatData['latestMessage']?['sentAt'],
          unreadMessages: chatData['unreadMessages'],
          chatUpdateStream: chatUpdateStream));
    }

    newChats.sort((a, b) {
      if (a.lastMessageTimestamp == null && b.lastMessageTimestamp == null) {
        return 0;
      } else if (a.lastMessageTimestamp == null) {
        return 1;
      } else if (b.lastMessageTimestamp == null) {
        return -1;
      }
      return b.lastMessageTimestamp!.compareTo(a.lastMessageTimestamp!);
    });

    await Future.delayed(const Duration(milliseconds: 10));
    setState(() {
      chats = newChats;
    });
  }

  void openProfilePage() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) => Profile(
            uuid: userData['uuid'],
            isSettings: true,
            postUpdateStream: chatUpdateStream)));
  }
}
