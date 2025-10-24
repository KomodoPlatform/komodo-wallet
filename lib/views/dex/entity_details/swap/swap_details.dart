import 'package:flutter/material.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/model/swap.dart';
import 'package:web_dex/views/dex/entity_details/swap/swap_details_step_list.dart';
import 'package:web_dex/views/dex/entity_details/swap/swap_recover_button.dart';
import 'package:web_dex/views/dex/entity_details/trading_details_coin_pair.dart';
import 'package:web_dex/views/dex/entity_details/trading_details_total_time.dart';
import 'package:web_dex/shared/widgets/copied_text.dart';

/// SwapDetails shows the basic information of a DEX swap including coin pairs,
/// timing and progress steps.  It now includes the swap UUID with a copy
/// button so users can easily copy it.  This version uses static strings
/// instead of translation keys for the “Swap UUID” label.
class SwapDetails extends StatelessWidget {
  const SwapDetails({Key? key, required this.swapStatus, required this.isFailed})
      : super(key: key);

  final Swap swapStatus;
  final bool isFailed;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: isMobile ? const EdgeInsets.symmetric(horizontal: 12) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (swapStatus.recoverable)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: SwapRecoverButton(
                uuid: swapStatus.uuid,
              ),
            ),
          // Coin pair and amounts
          TradingDetailsCoinPair(
            baseCoin:
                swapStatus.isTaker ? swapStatus.takerCoin : swapStatus.makerCoin,
            baseAmount: swapStatus.isTaker
                ? swapStatus.takerAmount
                : swapStatus.makerAmount,
            relCoin:
                swapStatus.isTaker ? swapStatus.makerCoin : swapStatus.takerCoin,
            relAmount: swapStatus.isTaker
                ? swapStatus.makerAmount
                : swapStatus.takerAmount,
            swapId: swapStatus.uuid,
          ),
          // Swap UUID row
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Swap UUID'),
                CopiedText(
                  copiedValue: swapStatus.uuid,
                  text: swapStatus.uuid,
                  isCopiedValueShown: false,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  fontSize: 11,
                  iconSize: 14,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (swapStatus.myInfo != null)
                TradingDetailsTotalTime(
                  startedTime: swapStatus.myInfo!.startedAt * 1000,
                  finishedTime: _finishedTime,
                ),
              const SizedBox(height: 24),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: SwapDetailsStepList(swapStatus: swapStatus),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  int? get _finishedTime {
    if (swapStatus.events.isEmpty) {
      return null;
    }
    if (swapStatus.events.last.event.type ==
            swapStatus.successEvents.last ||
        isFailed) {
      return swapStatus.events.last.timestamp;
    }
    return null;
  }
}
