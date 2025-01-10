import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/dex_repository.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/model/swap.dart';
import 'package:web_dex/model/text_error.dart';
import 'package:web_dex/services/orders_service/my_orders_service.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/views/dex/entity_details/maker_order/maker_order_details_page.dart';
import 'package:web_dex/views/dex/entity_details/swap/swap_details_page.dart';
import 'package:web_dex/views/dex/entity_details/taker_order/taker_order_details_page.dart';

class TradingDetails extends StatefulWidget {
  const TradingDetails({Key? key, required this.uuid}) : super(key: key);

  final String uuid;

  @override
  State<TradingDetails> createState() => _TradingDetailsState();
}

class _TradingDetailsState extends State<TradingDetails> {
  late Timer _statusTimer;
  Swap? _swapStatus;
  OrderStatus? _orderStatus;

  @override
  void initState() {
    final myOrdersService = RepositoryProvider.of<MyOrdersService>(context);
    final dexRepository = RepositoryProvider.of<DexRepository>(context);

    _statusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateStatus(dexRepository, myOrdersService);
    });

    super.initState();
  }

  @override
  void dispose() {
    _statusTimer.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dynamic entityStatus = _swapStatus ??
        _orderStatus?.takerOrderStatus ??
        _orderStatus?.makerOrderStatus;

    if (entityStatus == null) return const Center(child: UiSpinner());
    final scrollController = ScrollController();
    return DexScrollbar(
      scrollController: scrollController,
      isMobile: isMobile,
      child: SingleChildScrollView(
        controller: scrollController,
        child: Builder(builder: (context) {
          return Padding(
            padding: isMobile
                ? const EdgeInsets.all(0)
                : const EdgeInsets.fromLTRB(15, 23, 15, 20),
            child: _getDetailsPage(entityStatus),
          );
        }),
      ),
    );
  }

  Widget _getDetailsPage(dynamic entityStatus) {
    if (entityStatus is Swap) {
      return SwapDetailsPage(entityStatus);
    } else if (entityStatus is TakerOrderStatus) {
      return TakerOrderDetailsPage(entityStatus);
    } else if (entityStatus is MakerOrderStatus) {
      return MakerOrderDetailsPage(entityStatus);
    }

    return const SizedBox.shrink();
  }

  Future<void> _updateStatus(
    DexRepository dexRepository,
    MyOrdersService myOrdersService,
  ) async {
    Swap? swapStatus;
    try {
      swapStatus = await dexRepository.getSwapStatus(widget.uuid);
    } on TextError catch (e, s) {
      log(
        e.error,
        path: 'trading_details =>_updateStatus',
        trace: s,
        isError: true,
      );
      swapStatus = null;
    } catch (e, s) {
      log(
        e.toString(),
        path: 'trading_details =>_updateStatus',
        trace: s,
        isError: true,
      );
      swapStatus = null;
    }

    final OrderStatus? orderStatus =
        await myOrdersService.getStatus(widget.uuid);

    if (!mounted) return;
    setState(() {
      _swapStatus = swapStatus;
      _orderStatus = orderStatus;
    });
  }
}
