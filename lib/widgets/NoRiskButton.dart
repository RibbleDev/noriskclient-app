import 'package:flutter/material.dart';
import 'package:noriskclient/config/Colors.dart';

class NoRiskButton extends StatelessWidget {
  const NoRiskButton(
      {super.key,
      this.height = 50,
      this.width = 200,
      required this.onTap,
      required this.child});

  final Widget child;
  final void Function() onTap;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: NoRiskClientColors.darkerBackground,
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          border: Border.all(color: Colors.black, width: 1.5),
        ),
        child: Center(child: child),
      ),
    );
  }
}
