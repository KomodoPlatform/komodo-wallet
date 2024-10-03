import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/settings/settings_bloc.dart';
import 'package:web_dex/blocs/blocs.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/shared/widgets/coin_icon.dart';
import 'package:web_dex/shared/widgets/coin_item/coin_item_body.dart';
import 'package:web_dex/shared/widgets/coin_item/coin_item_size.dart';
import 'package:web_dex/shared/widgets/coin_item/coin_logo.dart';
import 'package:web_dex/views/dex/common/front_plate.dart';
import 'package:web_dex/views/dex/simple/form/common/dex_form_group_header.dart';
import 'package:web_dex/views/dex/simple/form/tables/table_utils.dart';
import 'package:web_dex/views/dex/simple/form/taker/coin_item/balance_text.dart';
import 'package:web_dex/views/dex/simple/form/taker/coin_item/coin_name_and_protocol.dart';
import 'package:web_dex/views/market_maker_bot/coin_search_dropdown.dart';

class CoinSelectionAndAmountInput extends StatefulWidget {
  const CoinSelectionAndAmountInput({
    super.key,
    required this.coins,
    this.selectedCoin,
    required this.title,
    this.trailing,
    this.onItemSelected,
    this.useFrontPlate = true,
  });

  final Coin? selectedCoin;
  final List<Coin> coins;
  final String title;
  final Widget? trailing;
  final Function(Coin?)? onItemSelected;
  final bool useFrontPlate;

  @override
  State<CoinSelectionAndAmountInput> createState() =>
      _CoinSelectionAndAmountInputState();
}

class _CoinSelectionAndAmountInputState
    extends State<CoinSelectionAndAmountInput> {
  late List<CoinSelectItem> _items;

  @override
  void initState() {
    super.initState();
    _prepareItems();
  }

  @override
  void didUpdateWidget(CoinSelectionAndAmountInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.coins != oldWidget.coins) {
      _prepareItems();
    }
  }

  void _prepareItems() {
    _items = prepareCoinsForTable(
      widget.coins,
      null,
      testCoinsEnabled: context.read<SettingsBloc>().state.testCoinsEnabled,
    )
        .map(
          (coin) => CoinSelectItem(
            name: coin.name,
            coinId: coin.abbr,
            coinProtocol: coin.typeNameWithTestnet,
            trailing: BalanceText(coin),
            title: CoinItemBody(coin: coin, size: CoinItemSize.large),
            leading: CoinIcon(
              coin.abbr,
              size: CoinItemSize.large.coinLogo,
            ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DexFormGroupHeader(
          title: widget.title,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 8, 0, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CoinLogo(coin: widget.selectedCoin),
                  const SizedBox(width: 9),
                  CoinNameAndProtocol(widget.selectedCoin, true),
                  const SizedBox(width: 9),
                ],
              ),
              const SizedBox(width: 5),
              Expanded(child: widget.trailing ?? const SizedBox.shrink()),
            ],
          ),
        ),
      ],
    );

    if (widget.useFrontPlate) {
      content = FrontPlate(child: content);
    }

    return CoinDropdown(
      items: _items,
      onItemSelected: (item) =>
          widget.onItemSelected?.call(coinsBloc.getCoin(item.coinId)),
      child: content,
    );
  }
}
