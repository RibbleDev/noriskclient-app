import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mcreal/screens/McReal.dart';
import 'package:http/http.dart' as http;
import 'package:mcreal/screens/SignIn.dart';
import 'package:shared_preferences/shared_preferences.dart';

class McRealApp extends StatefulWidget {
  const McRealApp({super.key, required this.language});

  final String language;

  @override
  State<McRealApp> createState() => McRealAppState();
}

class McRealAppState extends State<McRealApp> {
  Map<String, dynamic> userData = {
    'uuid': '',
    'experimental': false,
    'token': ''
  };
  Map<String, Map<String, dynamic>> cache = {
    'skins': {},
    'usernames': {},
    'posts': {}
  };
  final StreamController<List> updateStream = StreamController<List>();

  @override
  void initState() {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    // clearUserData();
    // saveUserData({
    //   'uuid': '625dd22b-bad2-4b82-a0bc-e43ba1c1a7fd',
    //   'experimental': true,
    //   'token':
    //       '7b18e0397581d2f08d3edb86f6d073a3df9d04d2230319526f5fac44e98d8e239fc5799b4768403fa51177baf81e55fc0cab405ac111ce702dcec7a0e52018770bcabddebc636a141fd9d1668650f9f4'
    // });
    loadUserData();
    updateStream.stream.listen((List data) {
      String event = data[0];
      if (event == 'signIn') {
        saveUserData(data[1]);
      } else if (event == 'signOut') {
        saveUserData({});
      } else if (event == 'loadSkin') {
        loadSkin(data[1]);
      } else if (event == 'loadUsername') {
        loadUsername(data[1]);
      } else if (event == 'cachePost') {
        setState(() {
          cache['posts']?[data[1]] = {};
          cache['posts']?[data[1]]?['primary'] = data[2];
          cache['posts']?[data[1]]?['secondary'] = data[3];
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return validUserData()
        ? McReal(userData: userData, cache: cache, updateStream: updateStream)
        : SignIn(updateStream: updateStream);
  }

  bool validUserData() {
    return userData['uuid'] != '' && userData['uuid'] != '';
  }

  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userData = {
        'uuid': prefs.getString('uuid') ?? '',
        'experimental': prefs.getBool('experimental') ?? false,
        'token': prefs.getString('token') ?? ''
      };
    });
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('uuid', userData['uuid'] ?? '');
    await prefs.setBool('experimental', userData['experimental'] ?? false);
    await prefs.setString('token', userData['token'] ?? '');
    loadUserData();
  }

  Future<void> clearUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('uuid');
    await prefs.remove('experimental');
    await prefs.remove('token');
    loadUserData();
  }

  void loadSkin(String uuid) {
    if (cache['skins']?[uuid] == null) {
      setState(() {
        cache['skins']?[uuid] = Image.network(
            'https://mineskin.eu/helm/$uuid/64',
            width: 32,
            height: 32);
      });
    }
  }

  Future<void> loadUsername(String uuid) async {
    if (cache['usernames']?[uuid] == null) {
      http.Response res = await http.get(Uri.parse(
          'https://sessionserver.mojang.com/session/minecraft/profile/$uuid'));
      if (res.statusCode != 200) {
        return;
      }
      setState(() {
        cache['usernames']?[uuid] = jsonDecode(res.body)['name'];
      });
    }
  }
}
