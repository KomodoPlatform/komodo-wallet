import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/settings/settings_bloc.dart';
import 'package:web_dex/bloc/taker_form/taker_bloc.dart';
import 'package:web_dex/bloc/taker_form/taker_event.dart';
import 'package:web_dex/bloc/taker_form/taker_state.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/mm2/mm2_api/rpc/best_orders/best_orders.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/views/dex/simple/form/tables/nothing_found.dart';
import 'package:web_dex/views/dex/simple/form/tables/orders_table/grouped_list_view.dart';
import 'package:web_dex/views/dex/simple/form/tables/table_utils.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

class OrdersTableContent extends StatelessWidget {
  const OrdersTableContent({
    required this.onSelect,
    required this.searchString,
    this.maxHeight = 200,
  });

  final Function(BestOrder) onSelect;
  final String? searchString;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TakerBloc, TakerState, BestOrders?>(
      selector: (state) => state.bestOrders,
      builder: (context, bestOrders) {
        if (bestOrders == null) {
          return Container(
            padding: const EdgeInsets.fromLTRB(0, 30, 0, 10),
            alignment: const Alignment(0, 0),
            child: const UiSpinner(),
          );
        }

        final BaseError? error = bestOrders.error;
        if (error != null) return _ErrorMessage(error);

        final Map<String, List<BestOrder>> ordersMap = bestOrders.result!;
        final AuthorizeMode mode = context.watch<AuthBloc>().state.mode;
        final List<BestOrder> orders = prepareOrdersForTable(
          context,
          ordersMap,
          searchString,
          mode,
          testCoinsEnabled: context.read<SettingsBloc>().state.testCoinsEnabled,
        );

        if (orders.isEmpty) return const NothingFound();

        return GroupedListView<BestOrder>(
          items: orders,
          onSelect: onSelect,
          maxHeight: maxHeight,
        );
      },
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage(this.error);
  final BaseError error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 30, 12, 10),
      alignment: const Alignment(0, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber, size: 14, color: Colors.orange),
              const SizedBox(width: 4),
              Flexible(
                  child: SelectableText(
                error.message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              )),
              const SizedBox(height: 4),
              UiSimpleButton(
                child: Text(
                  LocaleKeys.retryButtonText.tr(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onPressed: () =>
                    context.read<TakerBloc>().add(TakerUpdateBestOrders()),
              )
            ],
          ),
        ],
      ),
    );
  }
}
