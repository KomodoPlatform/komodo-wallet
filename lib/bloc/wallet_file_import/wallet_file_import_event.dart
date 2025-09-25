part of 'wallet_file_import_bloc.dart';

abstract class WalletFileImportEvent extends Equatable {
  const WalletFileImportEvent();

  @override
  List<Object?> get props => [];
}

class WalletFileImportSubmitted extends WalletFileImportEvent {
  const WalletFileImportSubmitted({
    required this.password,
    required this.isHdMode,
    required this.allowCustomSeed,
    this.fileText,
    this.fileBytes,
  });

  final String password;
  final bool isHdMode;
  final bool allowCustomSeed;
  final String? fileText;
  final Uint8List? fileBytes;

  @override
  List<Object?> get props => [
    password,
    isHdMode,
    allowCustomSeed,
    fileText,
    fileBytes,
  ];
}
