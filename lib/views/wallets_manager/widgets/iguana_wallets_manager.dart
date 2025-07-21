import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/analytics/events/user_acquisition_events.dart';
import 'package:web_dex/bloc/analytics/analytics_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
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
import 'package:web_dex/views/wallets_manager/widgets/wallet_rename_dialog.dart';
import 'package:web_dex/blocs/wallets_repository.dart';

class IguanaWalletsManager extends StatefulWidget {
  const IguanaWalletsManager({
    required this.eventType,
    required this.close,
    required this.onSuccess,
    this.initialWallet,
    this.initialHdMode = false,
    super.key,
  });

  final WalletsManagerEventType eventType;
  final VoidCallback close;
  final void Function(Wallet) onSuccess;
  final Wallet? initialWallet;
  final bool initialHdMode;

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

  @override
  void initState() {
    super.initState();
    _selectedWallet = widget.initialWallet;
    _initialHdMode = widget.initialWallet?.config.type == WalletType.hdwallet
        ? true
        : widget.initialHdMode;
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
                    onWalletClick: (
                      Wallet wallet,
                      WalletsManagerExistWalletAction existWalletAction,
                    ) {
                      setState(() {
                        _selectedWallet = wallet;
                        _existWalletAction = existWalletAction;
                      });
                    },
                  ),
                  Divider(height: 32, thickness: 2),
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
  }) {
    setState(() => _isLoading = true);
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
  }) {
    setState(() {
      _isLoading = true;
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

  Future<void> _logInToWallet(String password, Wallet wallet) async {
    setState(() {
      _isLoading = true;
    });

    final walletsRepository = RepositoryProvider.of<WalletsRepository>(context);
    if (wallet.isLegacyWallet) {
      final String? error = walletsRepository.validateWalletName(wallet.name);
      if (error != null) {
        final newName = await walletRenameDialog(
          context,
          initialName: wallet.name,
        );
        if (newName == null) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }
        wallet.name = newName;
      }
    }

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
      widget.onSuccess(currentWallet);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
