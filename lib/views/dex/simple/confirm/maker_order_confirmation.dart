import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:rational/rational.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/blocs/maker_form_bloc.dart';
import 'package:web_dex/blocs/trading_entities_bloc.dart';
import 'package:web_dex/bloc/analytics/analytics_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/trading_status/trading_status_bloc.dart';
import 'package:web_dex/analytics/events/transaction_events.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/text_error.dart';
import 'package:web_dex/model/trade_preimage.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/shared/ui/ui_light_button.dart';
import 'package:web_dex/shared/utils/balances_formatter.dart';
import 'package:web_dex/shared/utils/formatters.dart';
import 'package:web_dex/shared/widgets/coin_item/coin_item.dart';
import 'package:web_dex/shared/widgets/coin_item/coin_item_size.dart';
import 'package:web_dex/shared/widgets/segwit_icon.dart';
import 'package:web_dex/views/dex/dex_helpers.dart';
import 'package:web_dex/views/dex/simple/form/maker/maker_form_exchange_rate.dart';
import 'package:web_dex/views/dex/simple/form/maker/maker_form_total_fees.dart';

class MakerOrderConfirmation extends StatefulWidget {
  const MakerOrderConfirmation(
      {super.key, required this.onCreateOrder, required this.onCancel});

  final VoidCallback onCancel;
  final VoidCallback onCreateOrder;

  @override
  State<MakerOrderConfirmation> createState() => _MakerOrderConfirmationState();
}

class _MakerOrderConfirmationState extends State<MakerOrderConfirmation> {
  String? _errorMessage;
  bool _inProgress = false;

  @override
  Widget build(BuildContext context) {
    final makerFormBloc = RepositoryProvider.of<MakerFormBloc>(context);
    final coinsRepository = RepositoryProvider.of<CoinsRepo>(context);

    return Container(
      padding: isMobile
          ? const EdgeInsets.only(top: 18.0)
          : const EdgeInsets.only(top: 9.0),
      constraints: BoxConstraints(maxWidth: theme.custom.dexFormWidth),
      child: StreamBuilder<TradePreimage?>(
          initialData: makerFormBloc.preimage,
          stream: makerFormBloc.outPreimage,
          builder: (BuildContext context,
              AsyncSnapshot<TradePreimage?> preimageSnapshot) {
            final preimage = preimageSnapshot.data;
            if (preimage == null) return const UiSpinner();

            final Coin? sellCoin =
                coinsRepository.getCoin(preimage.request.base);
            final Coin? buyCoin = coinsRepository.getCoin(preimage.request.rel);
            final Rational? sellAmount = preimage.request.volume;
            final Rational buyAmount =
                (sellAmount ?? Rational.zero) * preimage.request.price;

            if (sellCoin == null || buyCoin == null) {
              return Center(child: Text(LocaleKeys.dexErrorMessage.tr()));
            }

            return SingleChildScrollView(
              key: const Key('maker-order-conformation-scroll'),
              controller: ScrollController(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildTitle(),
                  const SizedBox(height: 37),
                  _buildReceive(buyCoin, buyAmount),
                  _buildFiatReceive(
                    sellCoin: sellCoin,
                    buyCoin: buyCoin,
                    sellAmount: sellAmount,
                    buyAmount: buyAmount,
                  ),
                  const SizedBox(height: 23),
                  _buildSend(sellCoin, sellAmount),
                  const SizedBox(height: 24),
                  const MakerFormExchangeRate(),
                  const SizedBox(height: 10),
                  const MakerFormTotalFees(),
                  const SizedBox(height: 24),
                  _buildError(),
                  Flexible(
                    child: _buildButtons(),
                  )
                ],
              ),
            );
          }),
    );
  }

  Widget _buildBackButton() {
    return UiLightButton(
      onPressed: _inProgress ? null : widget.onCancel,
      text: LocaleKeys.back.tr(),
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Flexible(
          child: _buildBackButton(),
        ),
        const SizedBox(width: 23),
        Flexible(
          child: _buildConfirmButton(),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    final tradingState = context.watch<TradingStatusBloc>().state;
    final bool tradingEnabled = tradingState.isEnabled;

    return Opacity(
      opacity: _inProgress ? 0.8 : 1,
      child: UiPrimaryButton(
          key: const Key('make-order-confirm-button'),
          prefix: _inProgress
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: UiSpinner(
                    height: 10,
                    width: 10,
                    strokeWidth: 1,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                )
              : null,
          onPressed: _inProgress || !tradingEnabled ? null : _startSwap,
          text: tradingEnabled
              ? LocaleKeys.confirm.tr()
              : LocaleKeys.tradingDisabled.tr()),
    );
  }

  Widget _buildError() {
    final String? message = _errorMessage;
    if (message == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
      child: Text(
        message,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  Widget _buildFiatReceive({
    required Coin sellCoin,
    Rational? sellAmount,
    required Coin buyCoin,
    Rational? buyAmount,
  }) {
    if (sellAmount == null || buyAmount == null) return const SizedBox();

    Color? color = Theme.of(context).textTheme.bodyMedium?.color;
    double? percentage;

    final double sellAmtFiat = getFiatAmount(sellCoin, sellAmount);
    final double receiveAmtFiat = getFiatAmount(buyCoin, buyAmount);

    if (sellAmtFiat < receiveAmtFiat) {
      color = theme.custom.increaseColor;
    } else if (sellAmtFiat > receiveAmtFiat) {
      color = theme.custom.decreaseColor;
    }

    if (sellAmtFiat > 0 && receiveAmtFiat > 0) {
      percentage = (receiveAmtFiat - sellAmtFiat) * 100 / sellAmtFiat;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FiatAmount(coin: buyCoin, amount: buyAmount),
        if (percentage != null)
          Text(' (${percentage > 0 ? '+' : ''}${formatAmt(percentage)}%)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w200,
                  )),
      ],
    );
  }

  Widget _buildFiatSend(Coin coin, Rational? amount) {
    if (amount == null) return const SizedBox();
    return Container(
        padding: const EdgeInsets.fromLTRB(0, 0, 2, 0),
        child: FiatAmount(coin: coin, amount: amount));
  }

  Widget _buildReceive(Coin coin, Rational? amount) {
    return Column(
      children: [
        SelectableText(
          LocaleKeys.swapConfirmationYouReceive.tr(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: theme.custom.dexSubTitleColor,
              ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SelectableText('${formatDexAmt(amount)} ',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                )),
            SelectableText(
              Coin.normalizeAbbr(coin.abbr),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: theme.custom.balanceColor),
            ),
            if (coin.mode == CoinMode.segwit)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: SegwitIcon(height: 16),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSend(Coin coin, Rational? amount) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.custom.subCardBackgroundColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            LocaleKeys.swapConfirmationYouSending.tr(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: theme.custom.dexSubTitleColor,
                ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              CoinItem(coin: coin, size: CoinItemSize.large),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SelectableText(
                    formatDexAmt(amount),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  _buildFiatSend(coin, amount),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return SelectableText(
      LocaleKeys.swapConfirmationTitle.tr(),
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16),
    );
  }

  Future<void> _startSwap() async {
    setState(() {
      _errorMessage = null;
      _inProgress = true;
    });

    final authBloc = context.read<AuthBloc>();
    final walletType =
        authBloc.state.currentUser?.wallet.config.type.name ?? '';
    final makerFormBloc = RepositoryProvider.of<MakerFormBloc>(context);
    final sellCoin = makerFormBloc.sellCoin!.abbr;
    final buyCoin = makerFormBloc.buyCoin!.abbr;
    final networks =
        '${makerFormBloc.sellCoin!.protocolType},${makerFormBloc.buyCoin!.protocolType}';
    context.read<AnalyticsBloc>().logEvent(
          SwapInitiatedEventData(
            fromAsset: sellCoin,
            toAsset: buyCoin,
            networks: networks,
            walletType: walletType,
          ),
        );

    final int callStart = DateTime.now().millisecondsSinceEpoch;
    final TextError? error = await makerFormBloc.makeOrder();
    final int durationMs = DateTime.now().millisecondsSinceEpoch - callStart;

    final tradingEntitiesBloc =
        // ignore: use_build_context_synchronously
        RepositoryProvider.of<TradingEntitiesBloc>(context);
    await tradingEntitiesBloc.fetch();

    // Delay helps to avoid buttons enabled/disabled state blinking
    // if setprice RPC was proceeded very fast
    await Future<dynamic>.delayed(const Duration(milliseconds: 500));
    setState(() => _inProgress = false);

    if (error != null) {
      context.read<AnalyticsBloc>().logEvent(
            SwapFailedEventData(
              fromAsset: sellCoin,
              toAsset: buyCoin,
              failStage: 'order_submission',
              walletType: walletType,
              durationMs: durationMs,
            ),
          );
      setState(() => _errorMessage = error.error);
      return;
    }

    context.read<AnalyticsBloc>().logEvent(
          SwapSucceededEventData(
            fromAsset: sellCoin,
            toAsset: buyCoin,
            amount: makerFormBloc.sellAmount!.toDouble(),
            fee: 0, // Fee data not available
            walletType: walletType,
            durationMs: durationMs,
          ),
        );
    makerFormBloc.clear();
    widget.onCreateOrder();
  }
}
