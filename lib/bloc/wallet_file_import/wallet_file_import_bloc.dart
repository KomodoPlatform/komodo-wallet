import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/shared/utils/encryption_tool.dart';

part 'wallet_file_import_event.dart';
part 'wallet_file_import_state.dart';

/// BLoC handling wallet file import including legacy desktop `.seed` files
class WalletFileImportBloc
    extends Bloc<WalletFileImportEvent, WalletFileImportState> {
  WalletFileImportBloc({
    required KomodoDefiSdk sdk,
    EncryptionTool? encryptionTool,
  }) : _sdk = sdk,
       _encryptionTool = encryptionTool ?? EncryptionTool(),
       super(const WalletFileImportState()) {
    on<WalletFileImportSubmitted>(_onSubmitted);
  }

  final KomodoDefiSdk _sdk;
  final EncryptionTool _encryptionTool;

  Future<void> _onSubmitted(
    WalletFileImportSubmitted event,
    Emitter<WalletFileImportState> emit,
  ) async {
    emit(state.copyWith(status: WalletFileImportStatus.loading, error: null));

    // Try JSON-based export first when text is available
    if (event.fileText != null && event.fileText!.isNotEmpty) {
      final jsonOutcome = await _tryParseJsonExport(
        encryptedText: event.fileText!,
        password: event.password,
        isHdMode: event.isHdMode,
        allowCustomSeed: event.allowCustomSeed,
      );

      if (jsonOutcome != null) {
        emit(jsonOutcome);
        return;
      }
    }

    // Fallback to legacy seed flow when bytes are present
    if (event.fileBytes != null && event.fileBytes!.isNotEmpty) {
      final legacyOutcome = await _tryParseLegacySeed(
        encryptedBytes: event.fileBytes!,
        password: event.password,
        isHdMode: event.isHdMode,
        allowCustomSeed: event.allowCustomSeed,
      );

      emit(legacyOutcome);
      return;
    }

    emit(
      state.copyWith(
        status: WalletFileImportStatus.failure,
        error: WalletFileImportFailureType.invalidFile,
      ),
    );
  }

  Future<WalletFileImportState?> _tryParseJsonExport({
    required String encryptedText,
    required String password,
    required bool isHdMode,
    required bool allowCustomSeed,
  }) async {
    final String? decryptedPayload = await _encryptionTool.decryptData(
      password,
      encryptedText,
    );
    if (decryptedPayload == null) {
      return null;
    }

    try {
      final dynamic walletJson = json.decode(decryptedPayload);
      if (walletJson is! Map<String, dynamic>) {
        return state.copyWith(
          status: WalletFileImportStatus.failure,
          error: WalletFileImportFailureType.invalidFile,
        );
      }

      final WalletConfig walletConfig = WalletConfig.fromJson(walletJson);
      final String? decryptedSeed = await _encryptionTool.decryptData(
        password,
        walletConfig.seedPhrase,
      );
      if (decryptedSeed == null) {
        return state.copyWith(
          status: WalletFileImportStatus.failure,
          error: WalletFileImportFailureType.incorrectPassword,
        );
      }

      return _buildValidatedOutcome(
        walletConfig: walletConfig,
        decryptedSeed: decryptedSeed,
        isHdMode: isHdMode,
        allowCustomSeed: allowCustomSeed,
      );
    } catch (_) {
      return state.copyWith(
        status: WalletFileImportStatus.failure,
        error: WalletFileImportFailureType.invalidFile,
      );
    }
  }

  Future<WalletFileImportState> _tryParseLegacySeed({
    required Uint8List encryptedBytes,
    required String password,
    required bool isHdMode,
    required bool allowCustomSeed,
  }) async {
    final String? seed = await _encryptionTool.decryptLegacyDesktopSeed(
      password: password,
      encryptedBytes: encryptedBytes,
    );

    if (seed == null) {
      return state.copyWith(
        status: WalletFileImportStatus.failure,
        error: WalletFileImportFailureType.incorrectPassword,
      );
    }

    final WalletConfig walletConfig = WalletConfig(
      seedPhrase: seed,
      activatedCoins: List<String>.from(enabledByDefaultCoins),
      hasBackup: true,
      type: WalletType.iguana,
    );

    return _buildValidatedOutcome(
      walletConfig: walletConfig,
      decryptedSeed: seed,
      isHdMode: isHdMode,
      allowCustomSeed: allowCustomSeed,
    );
  }

  WalletFileImportState _buildValidatedOutcome({
    required WalletConfig walletConfig,
    required String decryptedSeed,
    required bool isHdMode,
    required bool allowCustomSeed,
  }) {
    final List<String> activatedCoins = walletConfig.activatedCoins.isEmpty
        ? List<String>.from(enabledByDefaultCoins)
        : List<String>.from(walletConfig.activatedCoins);

    walletConfig
      ..type = isHdMode ? WalletType.hdwallet : WalletType.iguana
      ..seedPhrase = decryptedSeed
      ..activatedCoins = activatedCoins;

    if ((isHdMode || !allowCustomSeed) &&
        !_sdk.mnemonicValidator.validateBip39(decryptedSeed)) {
      return state.copyWith(
        status: WalletFileImportStatus.failure,
        error: WalletFileImportFailureType.invalidSeed,
      );
    }

    return state.copyWith(
      status: WalletFileImportStatus.success,
      walletConfig: walletConfig,
      error: null,
    );
  }
}
