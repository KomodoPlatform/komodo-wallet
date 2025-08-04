import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/blocs/wallets_repository.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/services/storage/get_storage.dart';
import 'package:web_dex/shared/constants.dart';
import 'package:web_dex/shared/widgets/app_dialog.dart';
import 'package:web_dex/views/wallets_manager/wallets_manager_wrapper.dart';
import 'package:web_dex/views/wallets_manager/wallets_manager_events_factory.dart';

/// Service to handle remember wallet functionality
class RememberWalletService {
  static bool _hasShownRememberMeDialogThisSession = false;
  static bool _hasBeenLoggedInThisSession = false;

  /// Check and possibly show the remembered wallet dialog
  static Future<void> maybeShowRememberedWallet(BuildContext context) async {
    final authState = context.read<AuthBloc>().state;
    if (authState.mode != AuthorizeMode.noLogin ||
        _hasShownRememberMeDialogThisSession) {
      return;
    }

    // Mark that we've shown the dialog to prevent race conditions
    _hasShownRememberMeDialogThisSession = true;

    final storage = getStorage();
    final walletsRepo = context.read<WalletsRepository>();
    final storedWalletData = await storage.read(lastLoggedInWalletKey);
    if (storedWalletData == null) return;

    WalletId walletId;
    try {
      // Parse stored wallet data - handle both JSON string and Map formats
      if (storedWalletData is String) {
        // Try to parse as JSON string first (new format)
        try {
          final parsedData =
              jsonDecode(storedWalletData) as Map<String, dynamic>;
          walletId = WalletId.fromJson(parsedData);
        } catch (_) {
          // If JSON parsing fails, treat as legacy wallet name
          walletId = WalletId.fromName(
            storedWalletData,
            AuthOptions(derivationMethod: DerivationMethod.iguana),
          );
        }
      } else if (storedWalletData is Map<String, dynamic>) {
        walletId = WalletId.fromJson(storedWalletData);
      } else {
        // Unrecognized format, clear invalid data
        await storage.delete(lastLoggedInWalletKey);
        return;
      }
    } catch (e) {
      // Only clear data for actual parsing errors
      await storage.delete(lastLoggedInWalletKey);
      return;
    }

    try {
      final wallets = walletsRepo.wallets ?? await walletsRepo.getWallets();

      if (!context.mounted) return;

      // Match by wallet name and optionally by pubkey hash for more precise matching
      final wallet = wallets.where((w) {
        if (w.name != walletId.name) return false;
        // If we have a pubkey hash in the stored WalletId, ensure it matches
        if (walletId.hasFullIdentity && w.config.pubKey != null) {
          // Verify if wallet.config.pubKey corresponds to walletId.pubkeyHash
          final pubKeyHash = md5
              .convert(utf8.encode(w.config.pubKey!))
              .toString();
          if (pubKeyHash != walletId.pubkeyHash) return false;
        }
        return true;
      }).firstOrNull;

      if (wallet == null) return;

      if (!context.mounted) return;

      // Use AppDialog - a replacement for deprecated PopupDispatcher
      await AppDialog.showWithCallback<void>(
        context: context,
        width: 320,
        childBuilder: (closeDialog) => WalletsManagerWrapper(
          eventType: WalletsManagerEventType.header,
          selectedWallet: wallet,
          rememberMe: true,
          onSuccess: (wallet) => closeDialog(),
        ),
      );
    } catch (e) {
      // Don't clear stored data for UI/network errors that aren't parsing-related
      // The stored data is still valid, but we had an issue with the UI or wallet loading
      // Log the error if needed, but preserve the stored wallet data
    }
  }

  /// Track when user has been logged in
  static void trackUserLoggedIn() {
    _hasBeenLoggedInThisSession = true;
  }

  /// Reset remember me dialog state when user logs out
  static void resetOnLogout() {
    _hasShownRememberMeDialogThisSession = false;
    _hasBeenLoggedInThisSession = false;
  }

  /// Check if remember me dialog has been shown this session
  static bool get hasShownRememberMeDialogThisSession =>
      _hasShownRememberMeDialogThisSession;

  /// Check if user has been logged in this session
  static bool get hasBeenLoggedInThisSession => _hasBeenLoggedInThisSession;
}
