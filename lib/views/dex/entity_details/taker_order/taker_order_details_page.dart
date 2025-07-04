import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/mm2/mm2_api/rpc/order_status/cancellation_reason.dart';
import 'package:komodo_wallet/services/orders_service/my_orders_service.dart';
import 'package:komodo_wallet/views/dex/entity_details/taker_order/taker_order_details.dart';
import 'package:komodo_wallet/views/dex/entity_details/trading_details_header.dart';
import 'package:komodo_wallet/views/dex/entity_details/trading_progress_status.dart';

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
