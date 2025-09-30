import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/views/common/page_header/page_header.dart';

class MessageSigningHeader extends StatelessWidget {
  final VoidCallback? onBackButtonPressed;
  final String title;

  const MessageSigningHeader({
    super.key,
    required this.title,
    this.onBackButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return PageHeader(
      title: title,
      backText: LocaleKeys.backToWallet.tr(),
      onBackButtonPressed: onBackButtonPressed,
    );
  }
}
