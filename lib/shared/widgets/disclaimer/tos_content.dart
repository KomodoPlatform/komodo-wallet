import 'package:flutter/material.dart';

class TosContent extends StatelessWidget {
  const TosContent({
    super.key,
    required this.disclaimerToSText,
  });

  final List<TextSpan> disclaimerToSText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SelectableText.rich(
        TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: disclaimerToSText,
        ),
      ),
    );
  }
}
