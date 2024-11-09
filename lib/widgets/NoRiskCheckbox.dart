import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mcreal/config/Colors.dart';

// ignore: must_be_immutable
class NoRiskCheckbox extends StatefulWidget {
  NoRiskCheckbox(
      {super.key,
      this.defaultValue = false,
      required this.onChanged,
      this.name = ''});

  bool defaultValue;
  Function(bool) onChanged = (bool value) {};
  String name;

  @override
  State<NoRiskCheckbox> createState() => McRealPostState();
}

class McRealPostState extends State<NoRiskCheckbox> {
  bool value = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          value = !value;
        });
        widget.onChanged(value);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(value
                    ? 'lib/assets/widgets/checkbox_checked.png'
                    : 'lib/assets/widgets/checkbox.png'),
                fit: BoxFit.fill,
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (widget.name.isNotEmpty)
            Text(widget.name,
                style: const TextStyle(
                    fontSize: 17.5,
                    color: NoRiskClientColors.text,
                    fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
