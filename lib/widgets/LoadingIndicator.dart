import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator(
      {super.key,
      this.height = 15,
      this.width = 15,
      this.color = Colors.white});

  final double height;
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Platform.isAndroid
        ? SizedBox(
            height: height,
            width: width,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 1.5, color: color),
            ),
          )
        : const Center(child: CupertinoActivityIndicator());
  }
}
