import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:rational/rational.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/bridge_form/bridge_bloc.dart';
import 'package:web_dex/bloc/bridge_form/bridge_event.dart';
import 'package:web_dex/bloc/bridge_form/bridge_state.dart';
import 'package:web_dex/bloc/analytics/analytics_bloc.dart';
import 'package:web_dex/bloc/trading_status/trading_status_bloc.dart';
import 'package:web_dex/analytics/events/cross_chain_events.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/blocs/trading_entities_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/dex_form_error.dart';
import 'package:web_dex/model/trade_preimage.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/router/state/routing_state.dart';
import 'package:web_dex/shared/ui/ui_light_button.dart';
import 'package:web_dex/shared/utils/balances_formatter.dart';
import 'package:web_dex/shared/utils/formatters.dart';
import 'package:web_dex/shared/widgets/coin_item/coin_item.dart';
import 'package:web_dex/shared/widgets/coin_item/coin_item_size.dart';
import 'package:web_dex/views/bridge/bridge_total_fees.dart';
import 'package:web_dex/views/bridge/view/bridge_exchange_rate.dart';
import 'package:web_dex/views/dex/dex_helpers.dart';

class BridgeConfirmation extends StatefulWidget {
  const BridgeConfirmation({super.key});

  @override
  State<BridgeConfirmation> createState() => _BridgeOrderConfirmationState();
}

class _BridgeOrderConfirmationState extends State<BridgeConfirmation> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BridgeBloc, BridgeState>(
      listener: (BuildContext context, BridgeState state) async {
        final String? swapUuid = state.swapUuid;
        if (swapUuid == null) return;

        context.read<BridgeBloc>().add(const BridgeClear());
        routingState.bridgeState.setDetailsAction(swapUuid);

        final tradingEntitiesBloc =
            RepositoryProvider.of<TradingEntitiesBloc>(context);
        await tradingEntitiesBloc.fetch();
      },
      builder: (BuildContext context, BridgeState state) {
        final TradePreimage? preimage = state.preimageData?.data;
        if (preimage == null) return const UiSpinner();
        final coinsRepo = RepositoryProvider.of<CoinsRepo>(context);

        final Coin? sellCoin = coinsRepo.getCoin(preimage.request.base);
        final Coin? buyCoin = coinsRepo.getCoin(preimage.request.rel);
        final Rational? sellAmount = preimage.request.volume;
        final Rational buyAmount =
            (sellAmount ?? Rational.zero) * preimage.request.price;

        if (sellCoin == null || buyCoin == null) {
          return Center(child: Text('${LocaleKeys.somethingWrong.tr()} :('));
        }

        final confirmDto = _ConfirmDTO(
          sellCoin: sellCoin,
          buyCoin: buyCoin,
          sellAmount: sellAmount,
          buyAmount: buyAmount,
        );

        final scrollController = ScrollController();
        return Container(
          padding: EdgeInsets.only(top: isMobile ? 18.0 : 30),
          constraints: BoxConstraints(maxWidth: theme.custom.dexFormWidth),
          child: DexScrollbar(
            scrollController: scrollController,
            isMobile: isMobile,
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const _ConfirmTitle(),
                  const SizedBox(height: 10),
                  _ReceiveGroup(confirmDto),
                  _FiatReceive(confirmDto),
                  const SizedBox(height: 23),
                  _SendGroup(confirmDto),
                  const SizedBox(height: 24),
                  const BridgeExchangeRate(),
                  const SizedBox(height: 10),
                  const BridgeTotalFees(),
                  const SizedBox(height: 24),
                  const _ErrorGroup(),
                  _ButtonsRow(onCancel, startSwap),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> startSwap() async {
    final bloc = context.read<BridgeBloc>();
    final state = bloc.state;
    final sellCoin = state.sellCoin;
    final buyCoin = RepositoryProvider.of<CoinsRepo>(context)
        .getCoin(state.bestOrder?.coin ?? '');
    if (sellCoin != null && buyCoin != null) {
      context.read<AnalyticsBloc>().logEvent(
            BridgeInitiatedEventData(
              fromChain: sellCoin.protocolType,
              toChain: buyCoin.protocolType,
              asset: sellCoin.abbr,
              walletType: context
                      .read<AuthBloc>()
                      .state
                      .currentUser
                      ?.wallet
                      .config
                      .type
                      .name ??
                  'unknown',
            ),
          );
    }

    bloc.add(const BridgeStartSwap());
  }

  void onCancel() {
    context.read<BridgeBloc>().add(const BridgeBackClick());
  }
}

class _ConfirmDTO {
  _ConfirmDTO(
      {required this.sellCoin,
      required this.buyCoin,
      this.sellAmount,
      this.buyAmount});

  final Coin sellCoin;
  final Coin buyCoin;
  final Rational? sellAmount;
  final Rational? buyAmount;
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: UiSpinner(
        color: Theme.of(context).textTheme.bodyMedium?.color,
        width: 10,
        height: 10,
        strokeWidth: 1,
      ),
    );
  }
}

class _ReceiveGroup extends StatelessWidget {
  const _ReceiveGroup(this.dto);

  final _ConfirmDTO dto;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SelectableText(
          LocaleKeys.swapConfirmationYouReceive.tr(),
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: theme.custom.dexSubTitleColor),
        ),
        SelectableText.rich(
          TextSpan(
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: theme.custom.balanceColor),
            children: [
              TextSpan(
                  text: '${formatDexAmt(dto.buyAmount)} ',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  )),
              TextSpan(text: dto.buyCoin.abbr),
            ],
          ),
        ),
      ],
    );
  }
}

class _FiatReceive extends StatelessWidget {
  const _FiatReceive(this.dto);

  final _ConfirmDTO dto;

  @override
  Widget build(BuildContext context) {
    if (dto.sellAmount == null || dto.buyAmount == null) {
      return const SizedBox();
    }

    double? percentage;

    final double sellAmtFiat = getFiatAmount(dto.sellCoin, dto.sellAmount!);
    final double receiveAmtFiat = getFiatAmount(dto.buyCoin, dto.buyAmount!);

    if (sellAmtFiat > 0 && receiveAmtFiat > 0) {
      percentage = (receiveAmtFiat - sellAmtFiat) * 100 / sellAmtFiat;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FiatAmount(coin: dto.buyCoin, amount: dto.buyAmount!),
        _Percentage(percentage: percentage),
      ],
    );
  }
}

class _Percentage extends StatelessWidget {
  final double? percentage;
  const _Percentage({this.percentage});

  @override
  Widget build(BuildContext context) {
    final percentage = this.percentage;
    if (percentage == null) {
      return const SizedBox();
    } else {
      final text = ' (${percentage > 0 ? '+' : ''}${formatAmt(percentage)}%)';
      final style = Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w200,
          );
      return Text(text, style: style);
    }
  }
}

class _SendGroup extends StatelessWidget {
  const _SendGroup(this.dto);

  final _ConfirmDTO dto;

  @override
  Widget build(BuildContext context) {
    final style1 = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: theme.custom.dexSubTitleColor,
        );
    final style3 = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
        );
    final coinsBloc = RepositoryProvider.of<CoinsRepo>(context);
    final Coin? coin = coinsBloc.getCoin(dto.sellCoin.abbr);
    if (coin == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.custom.subCardBackgroundColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(LocaleKeys.swapConfirmationYouSending.tr(),
              style: style1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CoinItem(coin: coin, size: CoinItemSize.large),
                  const SizedBox(width: 8),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SelectableText(
                    formatDexAmt(dto.sellAmount),
                    style: style3,
                  ),
                  _FiatSend(dto),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfirmTitle extends StatelessWidget {
  const _ConfirmTitle();

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      LocaleKeys.swapConfirmationTitle.tr(),
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16),
    );
  }
}

class _ErrorGroup extends StatelessWidget {
  const _ErrorGroup();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<BridgeBloc, BridgeState, DexFormError?>(
      selector: (state) => state.error,
      builder: (context, error) {
        if (error == null) return const SizedBox();

        final style = Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.error);
        return Container(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
          child: Text(error.error, style: style),
        );
      },
    );
  }
}

class _ButtonsRow extends StatelessWidget {
  const _ButtonsRow(this.onCancel, this.startSwap);

  final void Function()? onCancel;
  final void Function()? startSwap;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        children: [
          _BackButton(onCancel),
          const SizedBox(width: 23),
          _ConfirmButton(startSwap),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton(this.onPressed);

  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: BlocSelector<BridgeBloc, BridgeState, bool>(
          selector: (state) => state.inProgress,
          builder: (context, inProgress) {
            return Opacity(
              opacity: inProgress ? 0.8 : 1,
              child: UiLightButton(
                key: const Key('bridge-order-cancel-button'),
                height: 40,
                onPressed: inProgress ? null : onPressed,
                text: LocaleKeys.back.tr(),
              ),
            );
          }),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton(this.onPressed);

  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final tradingStatusState = context.watch<TradingStatusBloc>().state;
    final tradingEnabled = tradingStatusState.isEnabled;

    return Flexible(
        child: BlocSelector<BridgeBloc, BridgeState, bool>(
            selector: (state) => state.inProgress,
            builder: (context, inProgress) {
              return Opacity(
                opacity: inProgress ? 0.8 : 1,
                child: UiPrimaryButton(
                  key: const Key('bridge-order-confirm-button'),
                  height: 40,
                  prefix: inProgress ? const _ProgressIndicator() : null,
                  text: tradingEnabled
                      ? LocaleKeys.confirm.tr()
                      : LocaleKeys.tradingDisabled.tr(),
                  onPressed: inProgress || !tradingEnabled ? null : onPressed,
                ),
              );
            }));
  }
}

class _FiatSend extends StatelessWidget {
  const _FiatSend(this.dto);

  final _ConfirmDTO dto;

  @override
  Widget build(BuildContext context) {
    if (dto.sellAmount == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 2, 0),
      child: FiatAmount(coin: dto.sellCoin, amount: dto.sellAmount!),
    );
  }
}
