import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/forms/coin_select_input.dart';
import 'package:web_dex/model/forms/coin_trade_amount_input.dart';
import 'package:web_dex/model/forms/trade_volume_input.dart';
import 'package:web_dex/views/dex/common/front_plate.dart';
import 'package:web_dex/views/market_maker_bot/coin_selection_and_amount_input.dart';
import 'package:web_dex/views/market_maker_bot/coin_trade_amount_form_field.dart';
import 'package:web_dex/views/market_maker_bot/market_maker_form_error_message_extensions.dart';

class SellCoinSelectDropdown extends StatelessWidget {
  const SellCoinSelectDropdown({
    required this.sellCoin,
    required this.sellAmount,
    required this.coins,
    required this.minimumTradeVolume,
    required this.maximumTradeVolume,
    this.onItemSelected,
    this.onTradeVolumeChanged,
    super.key,
    this.padding = EdgeInsets.zero,
  });
  final CoinSelectInput sellCoin;
  final CoinTradeAmountInput sellAmount;
  final TradeVolumeInput minimumTradeVolume;
  final TradeVolumeInput maximumTradeVolume;
  final List<Coin> coins;
  final EdgeInsets padding;
  final Function(Coin?)? onItemSelected;
  final Function(RangeValues)? onTradeVolumeChanged;

  @override
  Widget build(BuildContext context) {
    return FrontPlate(
      child: Column(
        children: [
          CoinSelectionAndAmountInput(
            title: LocaleKeys.sell.tr(),
            selectedCoin: sellCoin.value,
            coins: coins,
            onItemSelected: onItemSelected,
            useFrontPlate: false,
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CoinTradeAmountFormField(
                  coin: sellCoin.value,
                  initialValue: sellAmount.value,
                  isEnabled: false,
                  errorText: sellCoin.displayError?.text(sellCoin.value),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 18),
                  child: Text(
                    '* ${LocaleKeys.mmBotFirstTradeEstimate.tr()}',
                    style: TextStyle(
                      color: dexPageColors.inactiveText,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          PercentageRangeSlider(
            title: AutoScrollText(
              text: LocaleKeys.mmBotVolumePerTrade.tr(
                args: [sellCoin.value?.abbr ?? ''],
              ),
              style: TextStyle(
                color: dexPageColors.activeText,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            values: RangeValues(
              minimumTradeVolume.value,
              maximumTradeVolume.value,
            ),
            onChanged: onTradeVolumeChanged,
            min: 0.01,
          ),
        ],
      ),
    );
  }
}
