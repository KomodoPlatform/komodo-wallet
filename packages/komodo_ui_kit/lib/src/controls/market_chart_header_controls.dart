import 'package:flutter/material.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui_kit/src/controls/selected_coin_graph_control.dart';
import 'package:komodo_ui_kit/src/inputs/time_period_selector.dart';
import 'package:komodo_ui_kit/src/utils/gap.dart';

class MarketChartHeaderControls extends StatelessWidget {
  final Widget title;
  final Widget? leadingIcon;
  final Widget leadingText;
  final List<AssetId> availableCoins;
  final String? selectedCoinId;
  final void Function(String?)? onCoinSelected;
  final double centreAmount;
  final double percentageIncrease;
  final List<Duration> timePeriods;
  final Duration selectedPeriod;
  final void Function(Duration?) onPeriodChanged;
  final DropdownMenuItem<AssetId> Function(AssetId coinId)?
      customCoinItemBuilder;
  final bool emptySelectAllowed;

  const MarketChartHeaderControls({
    super.key,
    required this.title,
    this.leadingIcon,
    required this.leadingText,
    required this.availableCoins,
    this.selectedCoinId,
    this.onCoinSelected,
    required this.centreAmount,
    required this.percentageIncrease,
    this.timePeriods = const [
      Duration(hours: 1),
      Duration(days: 1),
      Duration(days: 7),
      Duration(days: 30),
      Duration(days: 365),
    ],
    required this.selectedPeriod,
    required this.onPeriodChanged,
    this.customCoinItemBuilder,
    this.emptySelectAllowed = false,
  });

  @override
  Widget build(BuildContext context) {
    final defaultTextStyle = Theme.of(context).textTheme.labelLarge;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DefaultTextStyle(
              style: Theme.of(context).textTheme.labelMedium!,
              child: title,
            ),
            const Gap(4),
            Row(
              children: [
                if (leadingIcon != null) ...[
                  leadingIcon!,
                  const Gap(4),
                ],
                DefaultTextStyle(
                  style: defaultTextStyle!,
                  child: leadingText,
                ),
              ],
            ),
          ],
        ),
        Flexible(
          flex: 2,
          child: SelectedCoinGraphControl(
            emptySelectAllowed: emptySelectAllowed,
            centreAmount: centreAmount,
            percentageIncrease: percentageIncrease,
            selectedCoinId: selectedCoinId,
            availableCoins: availableCoins,
            onCoinSelected: onCoinSelected,
            customCoinItemBuilder: customCoinItemBuilder,
          ),
        ),
        Flexible(
          child: TimePeriodSelector(
            selectedPeriod: selectedPeriod,
            onPeriodChanged: onPeriodChanged,
            intervals: timePeriods,
          ),
        ),
      ],
    );
  }
}
