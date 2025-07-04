import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_wallet/bloc/coins_bloc/coins_bloc.dart';
import 'package:komodo_wallet/bloc/settings/settings_bloc.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_wallet/views/dex/simple/form/tables/nothing_found.dart';
import 'package:komodo_wallet/views/dex/simple/form/tables/orders_table/grouped_list_view.dart';
import 'package:komodo_wallet/views/dex/simple/form/tables/table_utils.dart';

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
    return BlocBuilder<CoinsBloc, CoinsState>(
      builder: (context, state) {
        final coins = prepareCoinsForTable(
          context,
          state.coins.values.toList(),
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
