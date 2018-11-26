import 'package:flutter/material.dart';
import 'package:myagenda/widgets/ui/raised_button_colored.dart';

class LargeRoundedButton extends StatelessWidget {
  final String text;
  final Function onPressed;

  const LargeRoundedButton({Key key, this.text, this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26.0, 22.0, 26.0, 22.0),
      child: RaisedButtonColored(
        onPressed: onPressed,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(100.0)),
        ),
        padding: const EdgeInsets.fromLTRB(36.0, 14.0, 36.0, 14.0),
        text: text,
      ),
    );
  }
}