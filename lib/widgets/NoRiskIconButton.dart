import 'package:flutter/cupertino.dart';

class NoRiskIconButton extends StatelessWidget {
  const NoRiskIconButton({super.key, required this.onTap, required this.icon});

  final Widget icon;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Center(child: icon),
    );
  }
}