import 'dart:math';

import 'package:collection/collection.dart';
import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/swap.dart';
import 'package:web_dex/views/dex/entity_details/swap/swap_details.dart';
import 'package:web_dex/views/dex/entity_details/trading_details_header.dart';
import 'package:web_dex/views/dex/entity_details/trading_progress_status.dart';

class SwapDetailsPage extends StatelessWidget {
  const SwapDetailsPage(this.swapStatus, {Key? key}) : super(key: key);

  final Swap swapStatus;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TradingDetailsHeader(
          title: _headerText,
        ),
        SwapProgressStatus(progress: _progress, isFailed: _isFailed),
        SwapDetails(swapStatus: swapStatus, isFailed: _isFailed),
      ],
    );
  }

  String get _headerText {
    if (_isFailed) return LocaleKeys.tradingDetailsTitleFailed.tr();

    final haveEvents = swapStatus.events.isNotEmpty;

    if (haveEvents) {
      final isSuccess =
          swapStatus.events.last.event.type == swapStatus.successEvents.last;

      if (isSuccess) return LocaleKeys.tradingDetailsTitleCompleted.tr();
      return LocaleKeys.tradingDetailsTitleInProgress.tr();
    }
    return LocaleKeys.tradingDetailsTitleOrderMatching.tr();
  }

  bool get _isFailed {
    return swapStatus.events.firstWhereOrNull(
            (event) => swapStatus.errorEvents.contains(event.event.type)) !=
        null;
  }

  int get _progress {
    // successEvents has MakerPaymentSpent and MakerPaymentSpentByWatcher
    // But events can have only one of them so we have -1 here
    return min(
            100,
            100 *
                swapStatus.events.length /
                (swapStatus.successEvents.length - 1))
        .ceil();
  }
}
