import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/src/buttons/ui_border_button.dart';

class UploadButton extends StatelessWidget {
  const UploadButton({
    required this.uploadFile,
    this.buttonText = 'Select a file',
    super.key,
  });

  final String buttonText;
  final Future<void> Function() uploadFile;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return UiBorderButton(
      onPressed: uploadFile,
      text: buttonText,
      width: double.infinity,
      textColor: themeData.colorScheme.primary,
      borderColor: themeData.colorScheme.primary.withValues(alpha: 0.3),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }
}
