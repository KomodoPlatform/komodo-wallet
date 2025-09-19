import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/rpc/orderbook/orderbook_response.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

class OrderbookErrorMessage extends StatefulWidget {
  const OrderbookErrorMessage(
    this.response, {
    Key? key,
    required this.onReloadClick,
  }) : super(key: key);

  final OrderbookResponse response;
  final VoidCallback onReloadClick;

  @override
  State<OrderbookErrorMessage> createState() => _OrderbookErrorMessageState();
}

class _OrderbookErrorMessageState extends State<OrderbookErrorMessage> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final String? error = widget.response.error;
    if (error == null) return const SizedBox.shrink();

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(LocaleKeys.orderBookFailedLoadError.tr()),
          const SizedBox(height: 8),
          Row(
            children: [
              UiSimpleButton(
                onPressed: widget.onReloadClick,
                child: Text(
                  LocaleKeys.reloadButtonText.tr(),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _isExpanded
                            ? LocaleKeys.close.tr()
                            : LocaleKeys.details.tr(),
                        style: const TextStyle(fontSize: 12),
                      ),
                      Icon(
                        _isExpanded
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        size: 16,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ],
                  )),
            ],
          ),
          if (_isExpanded)
            Flexible(
              child: SingleChildScrollView(
                controller: ScrollController(),
                child: Container(
                  padding: const EdgeInsets.only(top: 8),
                  child: SelectableText(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
