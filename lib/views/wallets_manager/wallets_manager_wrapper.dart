import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/blocs/wallets_repository.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/services/onboarding/onboarding_service.dart';
import 'package:web_dex/views/wallets_manager/wallets_manager_events_factory.dart';
import 'package:web_dex/views/wallets_manager/widgets/onboarding/start_screen.dart';
import 'package:web_dex/views/wallets_manager/widgets/wallets_manager.dart';
import 'package:web_dex/views/wallets_manager/widgets/wallets_type_list.dart';

class WalletsManagerWrapper extends StatefulWidget {
  const WalletsManagerWrapper({
    required this.eventType,
    this.onSuccess,
    this.selectedWallet,
    this.initialHdMode = false,
    this.rememberMe = false,
    super.key = const Key('wallets-manager-wrapper'),
  });

  final Function(Wallet)? onSuccess;
  final WalletsManagerEventType eventType;
  final Wallet? selectedWallet;
  final bool initialHdMode;
  final bool rememberMe;

  @override
  State<WalletsManagerWrapper> createState() => _WalletsManagerWrapperState();
}

class _WalletsManagerWrapperState extends State<WalletsManagerWrapper> {
  WalletType? _selectedWalletType;
  bool _showStartScreen = false;
  bool _isCheckingFirstLaunch = true;

  @override
  void initState() {
    super.initState();
    _selectedWalletType = widget.selectedWallet?.config.type;
    _checkFirstLaunch();
  }

  /// Check if this is first launch (no existing wallets).
  Future<void> _checkFirstLaunch() async {
    final walletsRepo = context.read<WalletsRepository>();
    final onboardingService = OnboardingService();

    final wallets = walletsRepo.wallets;
    final hasSeenStart = await onboardingService.hasSeenStartScreen();

    if (mounted) {
      setState(() {
        // Show start screen if: no existing wallets AND haven't seen it before
        _showStartScreen =
            (wallets == null || wallets.isEmpty) && !hasSeenStart;
        _isCheckingFirstLaunch = false;
      });
    }
  }

  /// Called when user selects an option from start screen.
  void _onStartScreenAction({required bool isImport}) {
    setState(() {
      _showStartScreen = false;
    });
    // Mark start screen as seen
    OnboardingService().markStartScreenSeen().ignore();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking first launch status
    if (_isCheckingFirstLaunch) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show start screen for first-time users
    if (_showStartScreen) {
      return StartScreen(
        onCreateWallet: () => _onStartScreenAction(isImport: false),
        onImportWallet: () => _onStartScreenAction(isImport: true),
      );
    }

    final WalletType? selectedWalletType = _selectedWalletType;
    if (selectedWalletType == null) {
      return Column(
        children: [
          Text(
            LocaleKeys.walletsTypeListTitle.tr(),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 16),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 30.0),
            child: WalletsTypeList(onWalletTypeClick: _onWalletTypeClick),
          ),
        ],
      );
    }

    return WalletsManager(
      eventType: widget.eventType,
      walletType: selectedWalletType,
      close: _closeWalletManager,
      onSuccess: widget.onSuccess ?? (_) {},
      selectedWallet: widget.selectedWallet,
      initialHdMode: widget.selectedWallet?.config.type == WalletType.hdwallet
          ? true
          : widget.initialHdMode,
      rememberMe: widget.rememberMe,
    );
  }

  Future<void> _onWalletTypeClick(WalletType type) async {
    setState(() {
      _selectedWalletType = type;
    });
  }

  Future<void> _closeWalletManager() async {
    setState(() {
      _selectedWalletType = null;
    });
  }
}
