import 'dart:async';

import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/fiat/base_fiat_provider.dart';
import 'package:web_dex/bloc/fiat/fiat_onramp_form/fiat_form_bloc.dart';
import 'package:web_dex/bloc/fiat/fiat_order_status.dart';
import 'package:web_dex/bloc/fiat/models/fiat_mode.dart';
import 'package:web_dex/bloc/fiat/models/i_currency.dart';
import 'package:web_dex/blocs/blocs.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/forms/fiat/fiat_amount_input.dart';
import 'package:web_dex/shared/ui/gradient_border.dart';
import 'package:web_dex/shared/widgets/connect_wallet/connect_wallet_wrapper.dart';
import 'package:web_dex/views/fiat/fiat_action_tab.dart';
import 'package:web_dex/views/fiat/fiat_inputs.dart';
import 'package:web_dex/views/fiat/fiat_payment_methods_grid.dart';
import 'package:web_dex/views/fiat/webview_dialog.dart';
import 'package:web_dex/views/wallets_manager/wallets_manager_events_factory.dart';

class FiatForm extends StatefulWidget {
  const FiatForm({super.key});

  @override
  State<FiatForm> createState() => _FiatFormState();
}

class _FiatFormState extends State<FiatForm> {
  bool _isLoggedIn = currentWalletBloc.wallet != null;

  StreamSubscription<List<Coin>>? _walletCoinsListener;
  StreamSubscription<bool>? _loginActivationListener;

  @override
  void dispose() {
    _walletCoinsListener?.cancel();
    _loginActivationListener?.cancel();

    super.dispose();
  }

  void _setActiveTab(int i) =>
      context.read<FiatFormBloc>().add(FiatModeChanged.fromTabIndex(i));

  Future<void> _handleAccountStatusChange(bool isLoggedIn) async {
    if (_isLoggedIn != isLoggedIn) {
      setState(() => _isLoggedIn = isLoggedIn);
    }

    if (isLoggedIn) {
      await fillAccountInformation();
    } else {
      context
          .read<FiatFormBloc>()
          .add(const ClearAccountInformationRequested());
    }
  }

  @override
  void initState() {
    super.initState();

    _walletCoinsListener = coinsBloc.outWalletCoins.listen((walletCoins) async {
      await _handleAccountStatusChange(walletCoins.isNotEmpty);
    });

    _loginActivationListener =
        coinsBloc.outLoginActivationFinished.listen((isLoggedIn) async {
      await _handleAccountStatusChange(isLoggedIn);
    });

    context.read<FiatFormBloc>()
      ..add(const LoadCurrencyListsRequested())
      ..add(const RefreshFormRequested(forceRefresh: true));
  }

  Future<void> fillAccountInformation() async {
    context.read<FiatFormBloc>().add(const AccountInformationChanged());
  }

  void _showOrderFailedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocaleKeys.orderFailedTryAgain.tr()),
      ),
    );
  }

  void completeOrder() =>
      context.read<FiatFormBloc>().add(FormSubmissionRequested());

  Future<void> openCheckoutPage(String checkoutUrl, String orderId) async {
    if (checkoutUrl.isEmpty) return;

    // Only web requires the intermediate html page to satisfy cors rules and
    // allow for console.log and postMessage events to be handled.
    final url =
        kIsWeb ? BaseFiatProvider.fiatWrapperPageUrl(checkoutUrl) : checkoutUrl;

    return WebViewDialog.show(
      context,
      url: url,
      title: LocaleKeys.buy.tr(),
      onConsoleMessage: _onConsoleMessage,
      onCloseWindow: _onCloseWebView,
    );
  }

  void _onConsoleMessage(String message) => context
      .read<FiatFormBloc>()
      .add(FiatOnRampPaymentStatusMessageReceived(message));

  void _onCloseWebView() {
    // TODO: decide whether to consider a closed webview as "failed"
  }

  Future<void> _handlePaymentStatusUpdate(FiatFormState stateSnapshot) async {
    //TODO? We can still show the alerts if we're no mounted by using the
    // app's navigator key. This will be useful if the user has navigated
    // to another page before completing the order.
    if (!mounted) return;

    final status = stateSnapshot.fiatOrderStatus;
    if (status == FiatOrderStatus.submitted) {
      // ignore: use_build_context_synchronously
      context.read<FiatFormBloc>().add(const WatchOrderStatusRequested());
      await openCheckoutPage(stateSnapshot.checkoutUrl, stateSnapshot.orderId);
      return;
    }

    if (status == FiatOrderStatus.failed) {
      _showOrderFailedSnackbar();
    }

    if (status != FiatOrderStatus.pending) {
      showPaymentStatusDialog(status);
    }
  }

  void showPaymentStatusDialog(FiatOrderStatus status) {
    if (!mounted) return;

    String? title;
    String? content;

    // TODO: Use theme-based semantic colors
    Icon? icon;

    switch (status) {
      case FiatOrderStatus.pending:
        throw Exception('Pending status should not be shown in dialog.');

      case FiatOrderStatus.submitted:
        title = LocaleKeys.fiatPaymentSubmittedTitle.tr();
        content = LocaleKeys.fiatPaymentSubmittedMessage.tr();
        icon = const Icon(Icons.open_in_new);

      case FiatOrderStatus.success:
        title = LocaleKeys.fiatPaymentSuccessTitle.tr();
        content = LocaleKeys.fiatPaymentSuccessMessage.tr();
        icon = const Icon(Icons.check_circle_outline);

      case FiatOrderStatus.failed:
        title = LocaleKeys.fiatPaymentFailedTitle.tr();
        // TODO: If we implement provider-specific error messages,
        // we can include support details.
        content = LocaleKeys.fiatPaymentFailedMessage.tr();
        icon = const Icon(Icons.error_outline, color: Colors.red);

      case FiatOrderStatus.inProgress:
        title = LocaleKeys.fiatPaymentInProgressTitle.tr();
        content = LocaleKeys.fiatPaymentInProgressMessage.tr();
        icon = const Icon(Icons.hourglass_bottom_outlined);
    }

    showAdaptiveDialog<void>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: Text(title!),
        icon: icon,
        content: Text(content!),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(LocaleKeys.ok.tr()),
          ),
        ],
      ),
    ).ignore();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Add optimisations to re-use the generated checkout URL if the user
    // submits the form again without changing any data. When the user presses
    // the "Buy Now" button, we create the checkout URL and open it in a new
    // tab.
    // Previously we would also navigate them to a separate page with a button
    // in case they needed to open the checkout page again, but we removed that
    // because it confused users on how to return and was not needed since user
    // can just press the "Buy Now" button again.
    // However! This may cause issues in the future when implement the order
    // history tab since some providers require creating an order before
    // creating the checkout URL. This could clutter up the order history with
    // orders that were never completed.

    final scrollController = ScrollController();
    return BlocConsumer<FiatFormBloc, FiatFormState>(
      listenWhen: (previous, current) =>
          previous.fiatOrderStatus != current.fiatOrderStatus,
      listener: (context, state) => _handlePaymentStatusUpdate(state),
      builder: (context, state) => DexScrollbar(
        isMobile: isMobile,
        scrollController: scrollController,
        child: SingleChildScrollView(
          key: const Key('fiat-form-scroll'),
          controller: scrollController,
          child: Column(
            children: [
              FiatActionTabBar(
                currentTabIndex: state.fiatMode.tabIndex,
                onTabClick: _setActiveTab,
              ),
              const SizedBox(height: 16),
              if (state.fiatMode == FiatMode.offramp)
                Center(child: Text(LocaleKeys.comingSoon.tr()))
              else
                GradientBorder(
                  innerColor: dexPageColors.frontPlate,
                  gradient: dexPageColors.formPlateGradient,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                    child: Column(
                      children: [
                        FiatInputs(
                          onFiatCurrencyChanged: _onFiatChanged,
                          onCoinChanged: _onCoinChanged,
                          onFiatAmountUpdate: _onFiatAmountChanged,
                          initialFiat: state.selectedFiat.value!,
                          initialCoin: state.selectedCoin.value!,
                          initialFiatAmount: state.fiatAmount.valueAsDouble,
                          fiatList: state.fiatList,
                          coinList: state.coinList,
                          selectedPaymentMethodPrice:
                              state.selectedPaymentMethod.priceInfo,
                          receiveAddress: state.coinReceiveAddress,
                          isLoggedIn: _isLoggedIn,
                          fiatMinAmount: state.minFiatAmount,
                          fiatMaxAmount: state.maxFiatAmount,
                          boundariesError: state.fiatAmount.error?.text(state),
                        ),
                        const SizedBox(height: 16),
                        FiatPaymentMethodsGrid(state: state),
                        const SizedBox(height: 16),
                        ConnectWalletWrapper(
                          key: const Key('connect-wallet-fiat-form'),
                          eventType: WalletsManagerEventType.fiat,
                          child: UiPrimaryButton(
                            key: const Key('fiat-onramp-submit-button'),
                            height: 40,
                            text: state.fiatOrderStatus.isSubmitting
                                ? '${LocaleKeys.submitting.tr()}...'
                                : LocaleKeys.buyNow.tr(),
                            onPressed: state.canSubmit ? completeOrder : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isLoggedIn
                              ? state.fiatOrderStatus.isFailed
                                  ? LocaleKeys.fiatCantCompleteOrder.tr()
                                  : LocaleKeys.fiatPriceCanChange.tr()
                              : LocaleKeys.fiatConnectWallet.tr(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onFiatChanged(ICurrency value) => context.read<FiatFormBloc>()
    ..add(SelectedFiatCurrencyChanged(value))
    ..add(const RefreshFormRequested(forceRefresh: true));

  void _onCoinChanged(ICurrency value) => context.read<FiatFormBloc>()
    ..add(SelectedCoinChanged(value))
    ..add(const RefreshFormRequested(forceRefresh: true));

  void _onFiatAmountChanged(String? value) => context.read<FiatFormBloc>()
    ..add(FiatAmountChanged(value ?? '0'))
    ..add(const RefreshFormRequested(forceRefresh: true));
}

extension on FiatAmountValidationError {
  String? text(FiatFormState state) {
    final fiatId = state.selectedFiat.value?.symbol ?? '';
    switch (this) {
      case FiatAmountValidationError.aboveMaximum:
        return LocaleKeys.fiatMaximumAmount
            .tr(args: [state.maxFiatAmount?.toString() ?? '', fiatId]);
      case FiatAmountValidationError.invalid:
      case FiatAmountValidationError.belowMinimum:
        return LocaleKeys.fiatMinimumAmount.tr(
          args: [
            state.minFiatAmount?.toString() ?? '',
            fiatId,
          ],
        );
      case FiatAmountValidationError.empty:
        return null;
    }
  }
}
