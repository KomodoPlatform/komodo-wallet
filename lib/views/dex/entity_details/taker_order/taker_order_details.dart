import 'package:flutter/material.dart';
import 'package:komodo_wallet/services/orders_service/my_orders_service.dart';
import 'package:komodo_wallet/views/dex/entity_details/swap/swap_details_step.dart';
import 'package:komodo_wallet/views/dex/entity_details/trading_details_coin_pair.dart';

class TakerOrderDetails extends StatelessWidget {
  const TakerOrderDetails({
    Key? key,
    required this.takerOrderStatus,
    required this.isFailed,
  }) : super(key: key);

  final TakerOrderStatus takerOrderStatus;
  final bool isFailed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TradingDetailsCoinPair(
            baseCoin: takerOrderStatus.order.base,
            baseAmount: takerOrderStatus.order.baseAmount,
            relCoin: takerOrderStatus.order.rel,
            relAmount: takerOrderStatus.order.relAmount,
          ),
          const SizedBox(height: 40),
          SwapDetailsStep(
            event: 'Started',
            isCurrentStep: true,
            isFailedStep: isFailed,
            isLastStep: true,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
