import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_wallet/model/forms/coin_select_input.dart';
import 'package:komodo_wallet/model/forms/coin_trade_amount_input.dart';
import 'package:komodo_wallet/views/market_maker_bot/coin_selection_and_amount_input.dart';
import 'package:komodo_wallet/views/market_maker_bot/coin_trade_amount_form_field.dart';
import 'package:komodo_wallet/views/market_maker_bot/market_maker_form_error_message_extensions.dart';

class BuyCoinSelectDropdown extends StatelessWidget {
  const BuyCoinSelectDropdown({
    required this.buyCoin,
    required this.buyAmount,
    required this.coins,
    this.onItemSelected,
    super.key,
  });
  final CoinSelectInput buyCoin;
  final CoinTradeAmountInput buyAmount;
  final List<Coin> coins;
  final Function(Coin?)? onItemSelected;

  @override
  Widget build(BuildContext context) {
    return CoinSelectionAndAmountInput(
      coins: coins,
      title: LocaleKeys.buy.tr(),
      selectedCoin: buyCoin.value,
      onItemSelected: onItemSelected,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CoinTradeAmountFormField(
            coin: buyCoin.value,
            initialValue: buyAmount.value,
            isEnabled: false,
            errorText: buyCoin.displayError?.text(buyCoin.value),
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
    );
  }
}
