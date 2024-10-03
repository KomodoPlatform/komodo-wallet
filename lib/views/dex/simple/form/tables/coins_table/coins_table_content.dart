import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/settings/settings_bloc.dart';
import 'package:web_dex/blocs/blocs.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/views/dex/simple/form/tables/nothing_found.dart';
import 'package:web_dex/views/dex/simple/form/tables/orders_table/grouped_list_view.dart';
import 'package:web_dex/views/dex/simple/form/tables/table_utils.dart';

class CoinsTableContent extends StatelessWidget {
  const CoinsTableContent({
    required this.onSelect,
    required this.searchString,
    required this.maxHeight,
  });

  final Function(Coin) onSelect;
  final String? searchString;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Coin>>(
      stream: coinsBloc.outKnownCoins,
      initialData: coinsBloc.knownCoins,
      builder: (context, snapshot) {
        final coins = prepareCoinsForTable(
          coinsBloc.knownCoins,
          searchString,
          testCoinsEnabled: context.read<SettingsBloc>().state.testCoinsEnabled,
        );
        if (coins.isEmpty) return const NothingFound();

        return GroupedListView<Coin>(
          items: coins,
          onSelect: onSelect,
          maxHeight: maxHeight,
        );
      },
    );
  }
}
