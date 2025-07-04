import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/rpc/order_status/cancellation_reason.dart';
import 'package:web_dex/services/orders_service/my_orders_service.dart';
import 'package:web_dex/views/dex/entity_details/taker_order/taker_order_details.dart';
import 'package:web_dex/views/dex/entity_details/trading_details_header.dart';
import 'package:web_dex/views/dex/entity_details/trading_progress_status.dart';

class TakerOrderDetailsPage extends StatefulWidget {
  const TakerOrderDetailsPage(this.takerOrderStatus, {Key? key})
      : super(key: key);

  final TakerOrderStatus takerOrderStatus;

  @override
  State<TakerOrderDetailsPage> createState() => _TakerOrderDetailsPageState();
}

class _TakerOrderDetailsPageState extends State<TakerOrderDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        TakerOrderDetails(
          takerOrderStatus: widget.takerOrderStatus,
          isFailed: _isFailed,
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        TradingDetailsHeader(
          title: LocaleKeys.tradingDetailsTitleOrderMatching.tr(),
        ),
        const SwapProgressStatus(progress: 0),
      ],
    );
  }

  bool get _isFailed {
    return ![
      TakerOrderCancellationReason.none,
      TakerOrderCancellationReason.fulfilled
    ].contains(widget.takerOrderStatus.cancellationReason);
  }
}
