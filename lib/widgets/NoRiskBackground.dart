import 'package:flutter/material.dart';
import 'package:mcreal/config/Colors.dart';

class NoRiskBackground extends StatelessWidget {
  const NoRiskBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
            decoration: BoxDecoration(
              color: McRealColors.background,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: McRealColors.darkerBackground, width: 2),
                  ),
                  child: Container(),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        height: 30,
                        width: 30,
                        color: McRealColors.background,
                      ),
                      const Spacer(),
                      Container(
                        height: 30,
                        width: 30,
                        color: McRealColors.background,
                      )
                    ]),
                    const Spacer(),
                    Row(children: [
                      Container(
                        height: 30,
                        width: 30,
                        color: McRealColors.background,
                      ),
                      const Spacer(),
                      Container(
                        height: 30,
                        width: 30,
                        color: McRealColors.background,
                      )
                    ]),
                  ],
                ),
              ],
            )),
        Padding(
          padding: const EdgeInsets.all(25),
          child: child,
        )
      ],
    );
  }
}
