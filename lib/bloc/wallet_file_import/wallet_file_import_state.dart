part of 'wallet_file_import_bloc.dart';

enum WalletFileImportStatus { initial, loading, success, failure }

enum WalletFileImportFailureType { incorrectPassword, invalidFile, invalidSeed }

class WalletFileImportState extends Equatable {
  const WalletFileImportState({
    this.status = WalletFileImportStatus.initial,
    this.walletConfig,
    this.error,
  });

  final WalletFileImportStatus status;
  final WalletConfig? walletConfig;
  final WalletFileImportFailureType? error;

  WalletFileImportState copyWith({
    WalletFileImportStatus? status,
    WalletConfig? walletConfig,
    WalletFileImportFailureType? error,
  }) {
    return WalletFileImportState(
      status: status ?? this.status,
      walletConfig: walletConfig ?? this.walletConfig,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, walletConfig, error];
}
