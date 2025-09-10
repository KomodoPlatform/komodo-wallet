import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/views/market_maker_bot/trade_bot_update_interval.dart';

class UpdateIntervalDropdown extends StatelessWidget {
  const UpdateIntervalDropdown({
    required this.interval,
    required this.label,
    super.key,
    this.onChanged,
  });

  final TradeBotUpdateInterval interval;
  final Widget label;
  final void Function(TradeBotUpdateInterval?)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [label],
          ),
        ),
        Expanded(
          child: DropdownButtonFormField<TradeBotUpdateInterval>(
            value: interval,
            onChanged: onChanged,
            focusColor: Colors.transparent,
            items: TradeBotUpdateInterval.values
                .map(
                  (interval) => DropdownMenuItem(
                    value: interval,
                    alignment: Alignment.center,
                    child: Text(
                      '${interval.minutes} ${LocaleKeys.minutes.tr()}',
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
