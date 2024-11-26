import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/analytics/analytics_bloc.dart';
import 'package:web_dex/bloc/analytics/analytics_event.dart';
import 'package:web_dex/bloc/analytics/analytics_repo.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc_event.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc_state.dart';
import 'package:web_dex/blocs/blocs.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/model/wallets_manager_models.dart';
import 'package:web_dex/views/wallets_manager/wallets_manager_events_factory.dart';
import 'package:web_dex/views/wallets_manager/widgets/wallet_creation.dart';
import 'package:web_dex/views/wallets_manager/widgets/wallet_deleting.dart';
import 'package:web_dex/views/wallets_manager/widgets/wallet_import_wrapper.dart';
import 'package:web_dex/views/wallets_manager/widgets/wallet_login.dart';
import 'package:web_dex/views/wallets_manager/widgets/wallets_list.dart';
import 'package:web_dex/views/wallets_manager/widgets/wallets_manager_controls.dart';

class IguanaWalletsManager extends StatefulWidget {
  const IguanaWalletsManager({
    Key? key,
    required this.eventType,
    required this.close,
    required this.onSuccess,
  }) : super(key: key);
  final WalletsManagerEventType eventType;
  final VoidCallback close;
  final Function(Wallet) onSuccess;

  @override
  State<IguanaWalletsManager> createState() => _IguanaWalletsManagerState();
}

class _IguanaWalletsManagerState extends State<IguanaWalletsManager> {
  bool _isLoading = false;
  WalletsManagerAction _action = WalletsManagerAction.none;
  String? _errorText;
  Wallet? _selectedWallet;
  WalletsManagerExistWalletAction _existWalletAction =
      WalletsManagerExistWalletAction.none;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthBlocState>(
      listener: (context, state) {
        if (state.mode == AuthorizeMode.logIn) {
          _onLogIn();
        }
      },
      child: Builder(
        builder: (context) {
          if (_action == WalletsManagerAction.none &&
              _existWalletAction == WalletsManagerExistWalletAction.none) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                children: [
                  WalletsList(
                    walletType: WalletType.iguana,
                    onWalletClick: (Wallet wallet,
                        WalletsManagerExistWalletAction existWalletAction) {
                      setState(() {
                        _selectedWallet = wallet;
                        _existWalletAction = existWalletAction;
                      });
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: WalletsManagerControls(onTap: (newAction) {
                      setState(() {
                        _action = newAction;
                      });
                    }),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: UiUnderlineTextButton(
                      text: LocaleKeys.cancel.tr(),
                      onPressed: widget.close,
                    ),
                  )
                ],
              ),
            );
          }

          return Center(
            child: isMobile ? _buildMobileContent() : _buildNormalContent(),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    final selectedWallet = _selectedWallet;
    if (selectedWallet != null &&
        _existWalletAction != WalletsManagerExistWalletAction.none) {
      switch (_existWalletAction) {
        case WalletsManagerExistWalletAction.delete:
          return WalletDeleting(
            wallet: selectedWallet,
            close: _cancel,
          );
        case WalletsManagerExistWalletAction.logIn:
        case WalletsManagerExistWalletAction.none:
          return WalletLogIn(
            wallet: selectedWallet,
            onLogin: _logInToWallet,
            onCancel: _cancel,
            errorText: _errorText,
          );
      }
    }
    switch (_action) {
      case WalletsManagerAction.import:
        return WalletImportWrapper(
          key: const Key('wallet-import'),
          onImport: _importWallet,
          onCreate: _createWallet,
          onCancel: _cancel,
        );
      case WalletsManagerAction.create:
      case WalletsManagerAction.none:
        return WalletCreation(
          action: _action,
          key: const Key('wallet-creation'),
          onCreate: _createWallet,
          onCancel: _cancel,
        );
    }
  }

  Widget _buildMobileContent() {
    return SingleChildScrollView(
      controller: ScrollController(),
      child: Stack(
        children: [
          _buildContent(),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.transparent,
                alignment: Alignment.center,
                child: const UiSpinner(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNormalContent() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 530),
      child: Stack(
        children: [
          _buildContent(),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.transparent,
                alignment: Alignment.center,
                child: const UiSpinner(),
              ),
            ),
        ],
      ),
    );
  }

  void _cancel() {
    setState(() {
      _errorText = null;
      _selectedWallet = null;
      _action = WalletsManagerAction.none;
      _existWalletAction = WalletsManagerExistWalletAction.none;
    });
  }

  Future<void> _createWallet({
    required String name,
    required String password,
    required String seed,
  }) async {
    setState(() {
      _isLoading = true;
    });
    final Wallet? newWallet = await walletsBloc.createNewWallet(
      name: name,
      password: password,
      seed: seed,
    );

    if (newWallet == null) {
      setState(() {
        _errorText =
            LocaleKeys.walletsManagerStepBuilderCreationWalletError.tr();
      });

      return;
    }

    await _reLogin(
      seed,
      newWallet,
      walletsManagerEventsFactory.createEvent(
          widget.eventType, WalletsManagerEventMethod.create),
      password,
    );
  }

  Future<void> _importWallet({
    required String name,
    required String password,
    required WalletConfig walletConfig,
  }) async {
    setState(() {
      _isLoading = true;
    });
    final Wallet? newWallet = await walletsBloc.importWallet(
      name: name,
      password: password,
      walletConfig: walletConfig,
    );

    if (newWallet == null) {
      setState(() {
        _errorText =
            LocaleKeys.walletsManagerStepBuilderCreationWalletError.tr();
      });

      return;
    }

    await _reLogin(
      walletConfig.seedPhrase,
      newWallet,
      walletsManagerEventsFactory.createEvent(
          widget.eventType, WalletsManagerEventMethod.import),
      password,
    );
  }

  Future<void> _logInToWallet(String password, Wallet wallet) async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final String seed = await wallet.getSeed(password);
    if (seed.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorText = LocaleKeys.invalidPasswordError.tr();
      });

      return;
    }
    await _reLogin(
      seed,
      wallet,
      walletsManagerEventsFactory.createEvent(
          widget.eventType, WalletsManagerEventMethod.loginExisting),
      password,
    );
  }

  void _onLogIn() {
    final wallet = currentWalletBloc.wallet;
    _action = WalletsManagerAction.none;
    if (wallet != null) {
      widget.onSuccess(wallet);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _reLogin(
    String seed,
    Wallet wallet,
    AnalyticsEventData analyticsEventData,
    String password,
  ) async {
    final AnalyticsBloc analyticsBloc = context.read<AnalyticsBloc>();
    final AuthBloc authBloc = context.read<AuthBloc>();
    if (await authBloc.isLoginAllowed(wallet)) {
      analyticsBloc.add(AnalyticsSendDataEvent(analyticsEventData));
      authBloc.add(AuthReLogInEvent(
        seed: seed,
        wallet: wallet,
        password: password,
      ));
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
