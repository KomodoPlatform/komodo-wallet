import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/blocs/orderbook_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/rpc/orderbook/orderbook_response.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/orderbook/order.dart';
import 'package:web_dex/model/orderbook/orderbook.dart';
import 'package:web_dex/model/orderbook_model.dart';
import 'package:web_dex/shared/ui/gradient_border.dart';
import 'package:web_dex/views/dex/orderbook/orderbook_error_message.dart';
import 'package:web_dex/views/dex/orderbook/orderbook_table.dart';
import 'package:web_dex/views/dex/orderbook/orderbook_table_title.dart';

class OrderbookView extends StatefulWidget {
  const OrderbookView({
    required this.base,
    required this.rel,
    this.myOrder,
    this.selectedOrderUuid,
    this.onBidClick,
    this.onAskClick,
  });

  final Coin? base;
  final Coin? rel;
  final Order? myOrder;
  final String? selectedOrderUuid;
  final Function(Order)? onBidClick;
  final Function(Order)? onAskClick;

  @override
  State<OrderbookView> createState() => _OrderbookViewState();
}

class _OrderbookViewState extends State<OrderbookView> {
  late OrderbookModel _model;

  @override
  void initState() {
    _model = OrderbookModel(
      base: widget.base,
      rel: widget.rel,
      orderBookRepository: RepositoryProvider.of<OrderbookBloc>(context),
    );

    super.initState();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant OrderbookView oldWidget) {
    if (widget.base != oldWidget.base) _model.base = widget.base;
    if (widget.rel != oldWidget.rel) _model.rel = widget.rel;

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OrderbookResponse?>(
      initialData: _model.response,
      stream: _model.outResponse,
      builder: (context, snapshot) {
        if (!_model.isComplete) return const SizedBox.shrink();

        final OrderbookResponse? response = snapshot.data;

        if (response == null) {
          return const Center(child: UiSpinner());
        }

        if (response.error != null) {
          return OrderbookErrorMessage(
            response,
            onReloadClick: _model.reload,
          );
        }

        final Orderbook? orderbook = response.result;
        if (orderbook == null) {
          return Center(
            child: Text(LocaleKeys.orderBookEmpty.tr()),
          );
        }

        return GradientBorder(
          innerColor: dexPageColors.frontPlate,
          gradient: dexPageColors.formPlateGradient,
          child: Container(
            constraints: BoxConstraints(maxWidth: theme.custom.dexFormWidth),
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: OrderbookTableTitle(
                    LocaleKeys.orderBook.tr(),
                    titleTextSize: 14,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: OrderbookTable(
                    orderbook,
                    myOrder: widget.myOrder,
                    selectedOrderUuid: widget.selectedOrderUuid,
                    onAskClick: widget.onAskClick,
                    onBidClick: widget.onBidClick,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
