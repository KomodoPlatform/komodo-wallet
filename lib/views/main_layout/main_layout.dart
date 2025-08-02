import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_theme/app_theme.dart';
import 'package:collection/collection.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_dex/bloc/trading_status/trading_status_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/blocs/update_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/dispatchers/popup_dispatcher.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/router/navigators/main_layout/main_layout_router.dart';
import 'package:web_dex/router/state/routing_state.dart';
import 'package:web_dex/services/alpha_version_alert_service/alpha_version_alert_service.dart';
import 'package:web_dex/services/feedback/feedback_service.dart';
import 'package:web_dex/services/storage/get_storage.dart';
import 'package:web_dex/shared/constants.dart';
import 'package:web_dex/bloc/coins_manager/coins_manager_bloc.dart';
import 'package:web_dex/router/state/wallet_state.dart';
import 'package:web_dex/model/main_menu_value.dart';
import 'package:web_dex/shared/utils/window/window.dart';
import 'package:web_dex/views/common/header/app_header.dart';
import 'package:web_dex/views/common/main_menu/main_menu_bar_mobile.dart';
import 'package:web_dex/blocs/wallets_repository.dart';
import 'package:web_dex/views/wallets_manager/wallets_manager_wrapper.dart';
import 'package:web_dex/views/wallets_manager/wallets_manager_events_factory.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  PopupDispatcher? _rememberMeDispatcher;
  @override
  void initState() {
    // TODO: localize
    if (kIsWeb) {
      showMessageBeforeUnload('Are you sure you want to leave?');
    }
    final tradingStatusBloc = context.read<TradingStatusBloc>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AlphaVersionWarningService().run();
      await updateBloc.init();

      await _maybeShowRememberedWallet();

      if (!mounted) return;
      final tradingEnabled = tradingStatusBloc.state is TradingEnabled;
      if (tradingEnabled &&
          kShowTradingWarning &&
          !await _hasAgreedNoTrading()) {
        _showNoTradingWarning().ignore();
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _rememberMeDispatcher?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthBlocState>(
      listener: (context, state) {
        if (state.mode == AuthorizeMode.noLogin) {
          routingState.resetOnLogOut();
        }
      },
      builder: (context, state) {
        final isAuthenticated = state.mode == AuthorizeMode.logIn;

        return LayoutBuilder(
          builder: (context, constraints) {
            return Scaffold(
              key: scaffoldKey,
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.endFloat,
              appBar: null,
              body: SafeArea(child: MainLayoutRouter()),
              bottomNavigationBar: (isMobile || isTablet)
                  ? MainMenuBarMobile()
                  : null,
              floatingActionButton: MainLayoutFab(
                showAddCoinButton:
                    routingState.selectedMenu == MainMenuValue.wallet &&
                    routingState.walletState.selectedCoin.isEmpty &&
                    routingState.walletState.action.isEmpty &&
                    context.watch<AuthBloc>().state.mode == AuthorizeMode.logIn,
                isMini: isMobile,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _maybeShowRememberedWallet() async {
    final authState = context.read<AuthBloc>().state;
    if (authState.mode != AuthorizeMode.noLogin) return;

    final storage = getStorage();
    final String? lastWalletName =
        await storage.read(lastLoggedInWalletKey) as String?;
    if (lastWalletName == null) return;

    final walletsRepo = context.read<WalletsRepository>();
    final wallets = walletsRepo.wallets ?? await walletsRepo.getWallets();
    final wallet = wallets.firstWhereOrNull((w) => w.name == lastWalletName);
    if (wallet == null) return;

    _rememberMeDispatcher = PopupDispatcher(
      borderColor: theme.custom.specificButtonBorderColor,
      barrierColor: isMobile ? Theme.of(context).colorScheme.onSurface : null,
      width: 320,
      context: scaffoldKey.currentContext ?? context,
      popupContent: WalletsManagerWrapper(
        eventType: WalletsManagerEventType.header,
        selectedWallet: wallet,
        rememberMe: true,
      ),
    );
    _rememberMeDispatcher?.show();
  }

  // Method to show an alert dialog with an option to agree if the app is in
  // debug mode stating that trading features may not be used for actual trading
  // and that only test assets/networks may be used.
  Future<void> _showNoTradingWarning() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(LocaleKeys.showNoTradingWarning.tr()),
          content: Text(LocaleKeys.showNoTradingWarningMessage.tr()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveAgreedState().ignore();
              },
              child: Text(LocaleKeys.showNoTradingWarningButton.tr()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveAgreedState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('wallet_only_agreed', DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> _hasAgreedNoTrading() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('wallet_only_agreed') != null;
  }
}

class MainLayoutFab extends StatelessWidget {
  const MainLayoutFab({
    super.key,
    required this.showAddCoinButton,
    required this.isMini,
  });

  final bool showAddCoinButton;
  final bool isMini;

  @override
  Widget build(BuildContext context) {
    final Widget? addAssetsFab = showAddCoinButton
        ? Tooltip(
            message: LocaleKeys.addAssets.tr(),
            child: SizedBox.square(
              dimension: isMini ? 56.0 : 64.0,
              child: UiGradientButton(
                onPressed: () {
                  context.read<CoinsManagerBloc>().add(
                    const CoinsManagerCoinsListReset(CoinsManagerAction.add),
                  );
                  routingState.walletState.action =
                      coinsManagerRouteAction.addAssets;
                },
                child: const Icon(Icons.add_rounded, size: 36),
              ),
            ),
          )
        : null;

    final Widget? feedbackFab = context.isFeedbackAvailable
        ? Tooltip(
            message: 'Report a bug or feedback',
            child: SizedBox.square(
              dimension: isMini ? 48 : 58,
              child: UiGradientButton(
                isMini: isMini,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor,
                  ],
                ),
                onPressed: () => context.showFeedback(),
                child: const Icon(Icons.bug_report, size: 24),
              ),
            ),
          )
        : null;

    if (feedbackFab != null && addAssetsFab != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [feedbackFab, const SizedBox(height: 16), addAssetsFab],
      );
    }

    return addAssetsFab ?? feedbackFab ?? const SizedBox.shrink();
  }
}
