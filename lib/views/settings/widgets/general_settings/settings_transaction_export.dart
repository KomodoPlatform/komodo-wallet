import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/views/wallet/transaction_export/transaction_export_page.dart';

class SettingsTransactionExport extends StatelessWidget {
  const SettingsTransactionExport({super.key});

  @override
  Widget build(BuildContext context) {
    return UiBorderButton(
      width: 160,
      height: 32,
      borderWidth: 1,
      borderColor: theme.custom.specificButtonBorderColor,
      backgroundColor: theme.custom.specificButtonBackgroundColor,
      fontWeight: FontWeight.w500,
      text: LocaleKeys.transactionExport.tr(),
      icon: Icon(
        Icons.file_download,
        color: Theme.of(context).textTheme.bodyMedium?.color,
        size: 18,
      ),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TransactionExportPage()),
        );
      },
    );
  }
}
