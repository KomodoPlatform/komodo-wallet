import 'package:flutter/material.dart';

class ActionTextButton extends StatelessWidget {
  const ActionTextButton({
    required this.text,
    required this.onTap,
    this.secondaryText = '',
    super.key,
  });

  final String text;
  final String secondaryText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.5),
        child: Row(
          children: <Widget>[
            Text(
              text,
              style:
                  // fontSize: 14,
                  // color:
                  Theme.of(context).textTheme.bodyLarge!,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                secondaryText,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Theme.of(context).textTheme.labelLarge?.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
