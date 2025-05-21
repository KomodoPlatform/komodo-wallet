import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/constants.dart';
import 'package:web_dex/shared/utils/formatters.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/shared/ui/ui_primary_button.dart';
import 'package:web_dex/shared/ui/ui_simple_border_button.dart';
import 'package:web_dex/shared/ui/custom_numeric_text_form_field.dart';

class PaymentRequestWidget extends StatefulWidget {
  const PaymentRequestWidget({
    required this.asset,
    required this.address,
    super.key,
  });

  final Asset asset;
  final String address;

  @override
  State<PaymentRequestWidget> createState() => _PaymentRequestWidgetState();
}

class _PaymentRequestWidgetState extends State<PaymentRequestWidget> {
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String get _link {
    final amount = _amountController.text.trim();
    final assetId = widget.asset.id.id;
    final address = widget.address;
    if (amount.isEmpty) {
      return 'komodowallet:$assetId/$address';
    }
    return 'komodowallet:$assetId/$address?amount=$amount';
  }

  void _copyLink() => copyToClipBoard(context, _link);

  Future<void> _shareLink() async {
    await Share.share(_link);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.paymentRequest.tr(),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        CustomNumericTextFormField(
          controller: _amountController,
          filteringRegExp: numberRegExp.pattern,
          hintText: LocaleKeys.setAmount.tr(),
          inputContentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: UiSimpleBorderButton(
                onPressed: _copyLink,
                child: Text(LocaleKeys.copyLink.tr()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: UiPrimaryButton(
                height: 40,
                onPressed: _shareLink,
                text: LocaleKeys.shareLink.tr(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
