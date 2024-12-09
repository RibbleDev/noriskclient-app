import 'package:flutter/material.dart';

class NoRiskIconButton extends StatelessWidget {
  const NoRiskIconButton({super.key, required this.onTap, required this.icon});

  final Widget icon;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
          width: 30,
          height: 30,
          child: Center(child: icon)),
    );
  }
}