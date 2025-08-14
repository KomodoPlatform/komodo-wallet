import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/analytics/events/user_acquisition_events.dart';
import 'package:web_dex/bloc/analytics/analytics_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/blocs/wallets_repository.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/model/wallets_manager_models.dart';
import 'package:web_dex/services/storage/get_storage.dart';
import 'package:web_dex/shared/constants.dart';
import 'package:web_dex/views/wallets_manager/wallets_manager_events_factory.dart';
import 'package:web_dex/views/wallets_manager/widgets/wallet_creation.dart';
import 'package:web_dex/views/wallets_manager/widgets/wallet_deleting.dart';
import 'package:web_dex/views/wallets_manager/widgets/wallet_import_wrapper.dart';
import 'package:web_dex/views/wallets_manager/widgets/wallet_login.dart';
import 'package:web_dex/views/wallets_manager/widgets/wallets_list.dart';
import 'package:web_dex/views/wallets_manager/widgets/wallets_manager_controls.dart';

class IguanaWalletsManager extends StatefulWidget {
  const IguanaWalletsManager({
    required this.eventType,
    required this.close,
    required this.onSuccess,
    this.initialWallet,
    this.initialHdMode = false,
    this.rememberMe = false,
    super.key,
  });

  final WalletsManagerEventType eventType;
  final VoidCallback close;
  final void Function(Wallet) onSuccess;
  final Wallet? initialWallet;
  final bool initialHdMode;
  final bool rememberMe;

  @override
  State<IguanaWalletsManager> createState() => _IguanaWalletsManagerState();
}

class _IguanaWalletsManagerState extends State<IguanaWalletsManager> {
  bool _isLoading = false;
  WalletsManagerAction _action = WalletsManagerAction.none;
  Wallet? _selectedWallet;
  WalletsManagerExistWalletAction _existWalletAction =
      WalletsManagerExistWalletAction.none;
  bool _initialHdMode = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _selectedWallet = widget.initialWallet;
    _initialHdMode = widget.initialWallet?.config.type == WalletType.hdwallet
        ? true
        : widget.initialHdMode;
    _rememberMe = widget.rememberMe;
    if (_selectedWallet != null) {
      _existWalletAction = WalletsManagerExistWalletAction.logIn;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthBlocState>(
      listener: (context, state) {
        if (state.mode == AuthorizeMode.logIn) {
          _onLogIn();
        }

        if (state.isError) {
          setState(() => _isLoading = false);

          // Don't show a snackbar when the error is shown on the form.
          if (state.authError != null) return;

          final theme = Theme.of(context);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                LocaleKeys.somethingWrong.tr(),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
              backgroundColor: theme.colorScheme.errorContainer,
            ),
          );
        } else if (!state.isLoading) {
          setState(() => _isLoading = false);
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
                    onWalletClick:
                        (
                          Wallet wallet,
                          WalletsManagerExistWalletAction existWalletAction,
                        ) {
                          setState(() {
                            _selectedWallet = wallet;
                            _existWalletAction = existWalletAction;
                          });
                        },
                  ),
                  if (context.read<WalletsRepository>().wallets?.isNotEmpty ??
                      false)
                    const Divider(height: 32, thickness: 2),
                  WalletsManagerControls(
                    onTap: (newAction) {
                      setState(() {
                        _action = newAction;
                      });

                      final method = newAction == WalletsManagerAction.create
                          ? 'create'
                          : 'import';
                      context.read<AnalyticsBloc>().logEvent(
                        OnboardingStartedEventData(
                          method: method,
                          referralSource: widget.eventType.name,
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: UiUnderlineTextButton(
                      text: LocaleKeys.cancel.tr(),
                      onPressed: widget.close,
                    ),
                  ),
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
          return WalletDeleting(wallet: selectedWallet, close: _cancel);
        case WalletsManagerExistWalletAction.logIn:
        case WalletsManagerExistWalletAction.none:
          return WalletLogIn(
            wallet: selectedWallet,
            onLogin: _logInToWallet,
            onCancel: _cancel,
            initialHdMode: _initialHdMode,
            initialQuickLogin: _rememberMe,
          );
      }
    }
    switch (_action) {
      case WalletsManagerAction.import:
        return WalletImportWrapper(
          key: const Key('wallet-import'),
          onImport: _importWallet,
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
      _selectedWallet = null;
      _action = WalletsManagerAction.none;
      _existWalletAction = WalletsManagerExistWalletAction.none;
    });

    context.read<AuthBloc>().add(const AuthStateClearRequested());
  }

  void _createWallet({
    required String name,
    required String password,
    WalletType? walletType,
    required bool rememberMe,
  }) {
    setState(() {
      _isLoading = true;
      _rememberMe = rememberMe;
    });
    final Wallet newWallet = Wallet.fromName(
      name: name,
      walletType: walletType ?? WalletType.iguana,
    );

    context.read<AuthBloc>().add(
      AuthRegisterRequested(wallet: newWallet, password: password),
    );
  }

  void _importWallet({
    required String name,
    required String password,
    required WalletConfig walletConfig,
    required bool rememberMe,
  }) {
    setState(() {
      _isLoading = true;
      _rememberMe = rememberMe;
    });
    final Wallet newWallet = Wallet.fromConfig(
      name: name,
      config: walletConfig,
    );

    context.read<AuthBloc>().add(
      AuthRestoreRequested(
        wallet: newWallet,
        password: password,
        seed: walletConfig.seedPhrase,
      ),
    );
  }

  Future<void> _logInToWallet(
    String password,
    Wallet wallet,
    bool rememberMe,
  ) async {
    setState(() {
      _isLoading = true;
      _rememberMe = rememberMe;
    });

    final AnalyticsBloc analyticsBloc = context.read<AnalyticsBloc>();
    final analyticsEvent = walletsManagerEventsFactory.createEvent(
      widget.eventType,
      WalletsManagerEventMethod.loginExisting,
    );
    analyticsBloc.logEvent(analyticsEvent);

    context.read<AuthBloc>().add(
      AuthSignInRequested(wallet: wallet, password: password),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onLogIn() {
    final currentUser = context.read<AuthBloc>().state.currentUser;
    final currentWallet = currentUser?.wallet;
    final action = _action;
    _action = WalletsManagerAction.none;
    if (currentUser != null && currentWallet != null) {
      final analyticsBloc = context.read<AnalyticsBloc>();
      final source = isMobile ? 'mobile' : 'desktop';
      final walletType = currentWallet.config.type.name;
      if (action == WalletsManagerAction.create) {
        analyticsBloc.add(
          AnalyticsWalletCreatedEvent(source: source, walletType: walletType),
        );
      } else if (action == WalletsManagerAction.import) {
        analyticsBloc.add(
          AnalyticsWalletImportedEvent(
            source: source,
            importType: 'seed_phrase',
            walletType: walletType,
          ),
        );
      }
      context.read<CoinsBloc>().add(CoinsSessionStarted(currentUser));
      // Update remembered wallet before closing the dialog to avoid using
      // the context after the widget is disposed.
      unawaited(_updateRememberedWallet(currentUser));
      // Complete autofill session only after a successful login so that
      // password managers can save validated credentials.
      TextInput.finishAutofillContext(shouldSave: true);
      widget.onSuccess(currentWallet);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateRememberedWallet(KdfUser currentUser) async {
    final storage = getStorage();
    if (_rememberMe) {
      // Store the full WalletId JSON instead of just the name
      await storage.write(lastLoggedInWalletKey, currentUser.walletId.toJson());
    } else {
      await storage.delete(lastLoggedInWalletKey);
    }
  }
}
