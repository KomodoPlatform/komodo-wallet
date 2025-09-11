import 'package:flutter/material.dart';

class AiTradingView extends StatelessWidget {
  const AiTradingView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'AI Trading',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Center(
            child: Text(
              'AI trade ideas will appear here',
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ),
      ],
    );
  }
}

