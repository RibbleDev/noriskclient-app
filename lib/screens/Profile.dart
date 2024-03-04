import 'package:flutter/material.dart';

class Profile extends StatefulWidget {
  const Profile({super.key, required this.uuid});

  final String uuid;

  @override
  State<Profile> createState() => ProfileState();
}

class ProfileState extends State<Profile> {
  @override
  void initState() {
    loadPinnedPosts();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(15),
            child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Image.network('https://mineskin.eu/armor/bust/${widget.uuid}/128.png')
      ],
    )));
  }

  Future<void> loadPinnedPosts() async {

  }
}
