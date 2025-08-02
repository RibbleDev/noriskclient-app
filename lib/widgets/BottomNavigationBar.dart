import 'dart:async';

import 'package:flutter/material.dart';
import 'package:noriskclient/config/Colors.dart';
import 'package:noriskclient/utils/NoRiskIcon.dart';
import 'package:noriskclient/widgets/NoRiskContainer.dart';
import 'package:noriskclient/widgets/NoRiskIconButton.dart';
import 'package:noriskclient/widgets/NoRiskText.dart';

class NoRiskBottomNavigationBar extends StatefulWidget {
  NoRiskBottomNavigationBar({
    super.key,
    required this.currentIndexController,
    this.currentIndex = 2,
  });

  final StreamController<int> currentIndexController;
  int currentIndex;

  @override
  State<NoRiskBottomNavigationBar> createState() =>
      NoRiskBottomNavigationBarState();
}

class NoRiskBottomNavigationBarState extends State<NoRiskBottomNavigationBar> {
  @override
  Widget build(BuildContext context) {
    return NoRiskContainer(
      height: 75,
      width: double.infinity,
      color: NoRiskClientColors.light,
      backgroundOpacity: 200,
      borderOpacity: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _BottomNavigationBarButton(
            index: 0,
            currentIndex: widget.currentIndex,
            icon: NoRiskIcon.comment,
            label: 'news',
            onTap: () => widget.currentIndexController.sink.add(0)
          ),
          _BottomNavigationBarButton(
            index: 1,
            currentIndex: widget.currentIndex,
            icon: NoRiskIcon.comment,
            label: 'chat',
            onTap: () => widget.currentIndexController.sink.add(1),
            disabled: true,
          ),
          _BottomNavigationBarButton(
            index: 2,
            currentIndex: widget.currentIndex,
            icon: NoRiskIcon.comment,
            label: 'mcreal',
            onTap: () => widget.currentIndexController.sink.add(2)
          ),
          _BottomNavigationBarButton(
            index: 3,
            currentIndex: widget.currentIndex,
            icon: NoRiskIcon.comment,
            label: 'friends',
            onTap: () => widget.currentIndexController.sink.add(3),
            disabled: true,
          ),
          _BottomNavigationBarButton(
            index: 4,
            currentIndex: widget.currentIndex,
            icon: NoRiskIcon.comment,
            label: 'you',
            onTap: () => widget.currentIndexController.sink.add(4)
          ),
        ],
      ),
    );
  }
}

class _BottomNavigationBarButton extends StatelessWidget {
  const _BottomNavigationBarButton({
    super.key,
    required this.onTap,
    required this.currentIndex,
    required this.label,
    required this.icon,
    required this.index,
    this.disabled = false,
  });

  final void Function() onTap;
  final int currentIndex;
  final String label;
  final Widget icon;
  final int index;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? () {} : onTap,
            child: Stack(
              children: [
                SizedBox(
            width: 65,
                  height: 75,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: NoRiskIconButton(
                    onTap: disabled ? () {} : onTap,
                          transparent: true,
                          height: 35,
                          width: 35,
                    icon: Opacity(
                        opacity: disabled
                            ? 0.4
                            : currentIndex == index
                                ? 1
                                : 0.75,
                        child: icon)),
                    ),
                  ),
                ),
                SizedBox(
            width: 65,
                  height: 75,
                  child: Center(
                    child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: NoRiskText(label,
                              spaceTop: false,
                              spaceBottom: false,
                              style: TextStyle(
                        fontSize: 25,
                        color: disabled
                            ? Colors.white.withAlpha((100).floor())
                            : currentIndex == index
                                      ? Colors.white
                                      : Colors.white
                                          .withAlpha((200).floor()))),
                        ),
                  ),
                ),
              ],
            ),
          );
  }
}