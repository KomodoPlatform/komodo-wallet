import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/blocs/trading_entities_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/my_orders/my_order.dart';
import 'package:web_dex/shared/ui/ui_light_button.dart';
import 'package:web_dex/shared/utils/utils.dart';

class OrderCancelButton extends StatefulWidget {
  const OrderCancelButton({
    Key? key,
    required this.order,
  }) : super(key: key);

  final MyOrder order;

  @override
  State<OrderCancelButton> createState() => _OrderCancelButtonState();
}

class _OrderCancelButtonState extends State<OrderCancelButton> {
  bool _isCancelling = false;

  @override
  Widget build(BuildContext context) {
    return UiLightButton(
      text: LocaleKeys.cancel.tr(),
      width: 80,
      height: 22,
      prefix: _isCancelling ? const UiSpinner(width: 12, height: 12) : null,
      backgroundColor: Colors.transparent,
      border: Border.all(
        color: const Color.fromRGBO(234, 234, 234, 1),
        width: 1.0,
      ),
      textStyle: const TextStyle(fontSize: 12),
      onPressed: _isCancelling
          ? null
          : () => onCancel(widget.order), //isCancelling ? null : onCancel,
    );
  }

  Future<void> onCancel(MyOrder order) async {
    setState(() {
      _isCancelling = true;
    });
    final tradingEntitiesBloc =
        RepositoryProvider.of<TradingEntitiesBloc>(context);
    final String? error = await tradingEntitiesBloc.cancelOrder(order.uuid);
    setState(() {
      _isCancelling = false;
    });
    if (error != null) {
      // TODO(Francois): move to bloc / data layer?
      log(
        'Error order cancellation: ${error.toString()}',
        path: 'order_item => _onCancel',
        isError: true,
      );
    }
  }
}
