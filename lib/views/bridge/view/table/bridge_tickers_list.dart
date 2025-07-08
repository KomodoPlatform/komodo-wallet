import 'package:app_theme/app_theme.dart';
import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/bridge_form/bridge_bloc.dart';
import 'package:web_dex/bloc/bridge_form/bridge_event.dart';
import 'package:web_dex/bloc/bridge_form/bridge_state.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/typedef.dart';
import 'package:web_dex/shared/ui/borderless_search_field.dart';
import 'package:web_dex/shared/ui/ui_flat_button.dart';
import 'package:web_dex/views/bridge/bridge_ticker_selector.dart';
import 'package:web_dex/views/bridge/bridge_tickers_list_item.dart';
import 'package:web_dex/views/dex/simple/form/tables/nothing_found.dart';

class BridgeTickersList extends StatefulWidget {
  const BridgeTickersList({
    required this.onSelect,
    Key? key,
  }) : super(key: key);

  final Function(Coin) onSelect;

  @override
  State<BridgeTickersList> createState() => _BridgeTickersListState();
}

class _BridgeTickersListState extends State<BridgeTickersList> {
  String? _searchTerm;

  @override
  void initState() {
    context.read<BridgeBloc>().add(const BridgeUpdateTickers());

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: bridgeTickerSelectWidthExpanded,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(width: 1, color: theme.currentGlobal.primaryColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            children: [
              const BridgeTickerSelector(),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: BorderLessSearchField(
                  onChanged: (String value) {
                    if (_searchTerm == value) return;

                    setState(() => _searchTerm = value);
                  },
                ),
              ),
            ],
          ),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Flexible(child: _buildItems()),
                const SizedBox(height: 10),
                UiFlatButton(
                  text: LocaleKeys.close.tr(),
                  height: 40,
                  onPressed: () => context
                      .read<BridgeBloc>()
                      .add(const BridgeShowTickerDropdown(false)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItems() {
    return BlocSelector<BridgeBloc, BridgeState, CoinsByTicker?>(
      selector: (state) => state.tickers,
      builder: (context, tickers) {
        if (tickers == null) return const UiSpinnerList();

        final Coins coinsList =
            tickers.entries.fold([], (previousValue, element) {
          previousValue.add(element.value.first);
          return previousValue;
        });

        if (_searchTerm != null && _searchTerm!.isNotEmpty) {
          final String searchTerm = _searchTerm!.toLowerCase();
          coinsList.removeWhere((t) {
            if (t.abbr.toLowerCase().contains(searchTerm)) return false;
            if (t.name.toLowerCase().contains(searchTerm)) return false;

            return true;
          });
        }

        if (coinsList.isEmpty) return const NothingFound();
        final scrollController = ScrollController();

        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: DexScrollbar(
            scrollController: scrollController,
            isMobile: isMobile,
            child: ListView.builder(
              controller: scrollController,
              shrinkWrap: true,
              itemBuilder: (BuildContext context, int index) {
                final Coin coin = coinsList[index];
                return BridgeTickersListItem(
                  coin: coin,
                  onSelect: () => widget.onSelect(coin),
                );
              },
              itemCount: coinsList.length,
            ),
          ),
        );
      },
    );
  }
}
