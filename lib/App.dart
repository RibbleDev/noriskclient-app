import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mcreal/screens/McReal.dart';
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
    'noriskToken': ''
  };
  final StreamController<List> updateStream = StreamController<List>();

  @override
  void initState() {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    // clearUserData();
    saveUserData({
      'uuid': '625dd22b-bad2-4b82-a0bc-e43ba1c1a7fd',
      'experimental': true,
      'noriskToken': ''
    });
    loadUserData();
    updateStream.stream.listen((List data) {
      String event = data[0];
      if (event == 'signIn') {
        saveUserData(data[1]);
      } else if (event == 'signOut') {
        saveUserData({});
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return validUserData()
        ? McReal(userData: userData, updateStream: updateStream)
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
        'noriskToken': prefs.getString('noriskToken') ?? ''
      };
    });
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('uuid', userData['uuid'] ?? '');
    await prefs.setBool('experimental', userData['experimental'] ?? false);
    await prefs.setString('noriskToken', userData['noriskToken'] ?? '');
    loadUserData();
  }

  Future<void> clearUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('uuid');
    await prefs.remove('experimental');
    await prefs.remove('noriskToken');
    loadUserData();
  }
}
