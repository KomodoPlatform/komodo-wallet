import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/dex_repository.dart';
import 'package:web_dex/bloc/analytics/analytics_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/analytics/events/transaction_events.dart';
import 'package:web_dex/analytics/events/cross_chain_events.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/model/swap.dart';
import 'package:web_dex/model/text_error.dart';
import 'package:web_dex/shared/utils/extensions/kdf_user_extensions.dart';
import 'package:web_dex/services/orders_service/my_orders_service.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/views/dex/entity_details/maker_order/maker_order_details_page.dart';
import 'package:web_dex/views/dex/entity_details/swap/swap_details_page.dart';
import 'package:web_dex/views/dex/entity_details/taker_order/taker_order_details_page.dart';

/// Distinguishes what entity the uuid represents
enum TradingEntityKind {
  order,
  swap,
}

class TradingDetails extends StatefulWidget {
  const TradingDetails({super.key, required this.uuid, this.kind = TradingEntityKind.swap});

  final String uuid;
  final TradingEntityKind? kind;

  @override
  State<TradingDetails> createState() => _TradingDetailsState();
}

class _TradingDetailsState extends State<TradingDetails> {
  late Timer _statusTimer;
  Swap? _swapStatus;
  OrderStatus? _orderStatus;
  bool _loggedSuccess = false;
  bool _loggedFailure = false;

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
    final dynamic entityStatus =
        _swapStatus ??
        _orderStatus?.takerOrderStatus ??
        _orderStatus?.makerOrderStatus;

    if (entityStatus == null) return const Center(child: UiSpinner());
    final scrollController = ScrollController();
    return DexScrollbar(
      scrollController: scrollController,
      isMobile: isMobile,
      child: SingleChildScrollView(
        controller: scrollController,
        child: Builder(
          builder: (context) {
            return Padding(
              padding: isMobile
                  ? const EdgeInsets.all(0)
                  : const EdgeInsets.fromLTRB(15, 23, 15, 20),
              child: _getDetailsPage(entityStatus),
            );
          },
        ),
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
    Swap? swapStatus = null;
    OrderStatus? orderStatus = null;
    try {
      if (widget.kind == TradingEntityKind.swap) {
        swapStatus = await dexRepository.getSwapStatus(widget.uuid);
      } else if (widget.kind == TradingEntityKind.order) {
        orderStatus = await myOrdersService.getStatus(widget.uuid);
      }
    } catch (e, s) {
      log(
        e.toString(),
        path: 'trading_details =>_updateStatus ${widget.kind ?? TradingEntityKind.swap} error | uuid=${widget.uuid}',
        trace: s,
        isError: true,
      );
    }

    if (!mounted) return;
    setState(() {
      _swapStatus = swapStatus;
      _orderStatus = orderStatus;
    });

    if (swapStatus != null) {
      final authBloc = context.read<AuthBloc>();
      final walletType = authBloc.state.currentUser?.type;
      final fromAsset = swapStatus.sellCoin;
      final toAsset = swapStatus.buyCoin;
      final int? durationMs =
          swapStatus.events.isNotEmpty && swapStatus.myInfo != null
          ? swapStatus.events.last.timestamp -
                swapStatus.myInfo!.startedAt * 1000
          : null;
      if (swapStatus.isSuccessful && !_loggedSuccess) {
        _loggedSuccess = true;
        // Find trade fee from events
        double fee = 0;
        for (var event in swapStatus.events) {
          if (event.event.data?.feeToSendTakerFee != null) {
            fee = event.event.data?.feeToSendTakerFee?.amount ?? 0;
            break;
          } else if (event.event.data?.takerPaymentTradeFee != null) {
            fee = event.event.data?.takerPaymentTradeFee?.amount ?? 0;
            break;
          } else if (event.event.data?.makerPaymentSpendTradeFee != null) {
            fee = event.event.data?.makerPaymentSpendTradeFee?.amount ?? 0;
            break;
          }
        }
        final coinsRepo = RepositoryProvider.of<CoinsRepo>(context);
        final fromNetwork =
            coinsRepo.getCoin(fromAsset)?.protocolType ?? 'unknown';
        final toNetwork = coinsRepo.getCoin(toAsset)?.protocolType ?? 'unknown';
        context.read<AnalyticsBloc>().logEvent(
          SwapSucceededEventData(
            asset: fromAsset,
            secondaryAsset: toAsset,
            network: fromNetwork,
            secondaryNetwork: toNetwork,
            amount: swapStatus.sellAmount.toDouble(),
            fee: fee,
            hdType: walletType ?? 'unknown',
            durationMs: durationMs,
          ),
        );
        if (swapStatus.isTheSameTicker) {
          context.read<AnalyticsBloc>().logEvent(
            BridgeSucceededEventData(
              asset: fromAsset,
              secondaryAsset: toAsset,
              network: fromNetwork,
              secondaryNetwork: toNetwork,
              amount: swapStatus.sellAmount.toDouble(),
              hdType: walletType ?? 'unknown',
              durationMs: durationMs,
            ),
          );
        }
      } else if (swapStatus.isFailed && !_loggedFailure) {
        _loggedFailure = true;
        final coinsRepo = RepositoryProvider.of<CoinsRepo>(context);
        final fromNetwork =
            coinsRepo.getCoin(fromAsset)?.protocolType ?? 'unknown';
        final toNetwork = coinsRepo.getCoin(toAsset)?.protocolType ?? 'unknown';
        context.read<AnalyticsBloc>().logEvent(
          SwapFailedEventData(
            asset: fromAsset,
            secondaryAsset: toAsset,
            network: fromNetwork,
            secondaryNetwork: toNetwork,
            failureStage: swapStatus.status.name,
            hdType: walletType ?? 'unknown',
            durationMs: durationMs,
          ),
        );
        if (swapStatus.isTheSameTicker) {
          context.read<AnalyticsBloc>().logEvent(
            BridgeFailedEventData(
              asset: fromAsset,
              secondaryAsset: toAsset,
              network: fromNetwork,
              secondaryNetwork: toNetwork,
              failureStage: swapStatus.status.name,
              failureDetail: swapStatus.status.name,
              hdType: walletType ?? 'unknown',
              durationMs: durationMs,
            ),
          );
        }
      }
    }
  }
}
