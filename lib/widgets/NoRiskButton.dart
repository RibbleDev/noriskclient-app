import 'package:flutter/material.dart';

class NoRiskButton extends StatelessWidget {
  const NoRiskButton({super.key, this.height = 50, this.width = 200, required this.onTap, required this.child});

  final Widget child;
  final void Function() onTap;
  final int height;
  final int width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        width: 200,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/widgets/button.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}
