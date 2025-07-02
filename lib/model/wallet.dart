import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:uuid/uuid.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/shared/utils/encryption_tool.dart';

class Wallet {
  Wallet({
    required this.id,
    required this.name,
    required this.config,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        config: WalletConfig.fromJson(
          json['config'] as Map<String, dynamic>? ?? {},
        ),
      );

  /// Creates a wallet from a name and the optional parameters.
  /// [name] - The name of the wallet.
  /// [walletType] - The [WalletType] of the wallet. Defaults to [WalletType.iguana].
  /// [activatedCoins] - The list of activated coins. If not provided, the
  /// default list of enabled coins ([enabledByDefaultCoins]) will be used.
  /// [hasBackup] - Whether the wallet has been backed up. Defaults to false.
  factory Wallet.fromName({
    required String name,
    WalletType walletType = WalletType.hdwallet,
    List<String>? activatedCoins,
    bool hasBackup = false,
  }) {
    return Wallet(
      id: const Uuid().v1(),
      name: name,
      config: WalletConfig(
        activatedCoins: activatedCoins ?? enabledByDefaultCoins,
        hasBackup: hasBackup,
        type: walletType,
        seedPhrase: '',
      ),
    );
  }

  /// Creates a wallet from a name and the optional parameters.
  factory Wallet.fromConfig({
    required String name,
    required WalletConfig config,
  }) {
    return Wallet(
      id: const Uuid().v1(),
      name: name,
      config: config,
    );
  }

  String id;
  String name;
  WalletConfig config;

  bool get isHW =>
      config.type != WalletType.iguana && config.type != WalletType.hdwallet;
  bool get isLegacyWallet => config.isLegacyWallet;
  Future<String> getLegacySeed(String password) async =>
      await EncryptionTool().decryptData(password, config.seedPhrase) ?? '';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'config': config.toJson(),
      };

  Wallet copy() {
    return Wallet(
      id: id,
      name: name,
      config: config.copy(),
    );
  }
}

class WalletConfig {
  WalletConfig({
    required this.seedPhrase,
    required this.activatedCoins,
    required this.hasBackup,
    this.pubKey,
    this.type = WalletType.iguana,
    this.isLegacyWallet = false,
  });

  factory WalletConfig.fromJson(Map<String, dynamic> json) {
    return WalletConfig(
      type: WalletType.fromJson(
        json['type'] as String? ?? WalletType.iguana.name,
      ),
      seedPhrase: json['seed_phrase'] as String? ?? '',
      pubKey: json['pub_key'] as String?,
      activatedCoins:
          List<String>.from(json['activated_coins'] as List? ?? <String>[])
              .toList(),
      hasBackup: json['has_backup'] as bool? ?? false,
    );
  }

  String seedPhrase;
  String? pubKey;
  List<String> activatedCoins;
  bool hasBackup;
  WalletType type;
  bool isLegacyWallet;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type.name,
      'seed_phrase': seedPhrase,
      'pub_key': pubKey,
      'activated_coins': activatedCoins,
      'has_backup': hasBackup,
    };
  }

  WalletConfig copy() {
    return WalletConfig(
      activatedCoins: [...activatedCoins],
      hasBackup: hasBackup,
      type: type,
      seedPhrase: seedPhrase,
      pubKey: pubKey,
    );
  }
}

enum WalletType {
  iguana,
  hdwallet,
  trezor,
  metamask,
  keplr;

  factory WalletType.fromJson(String json) {
    switch (json) {
      case 'trezor':
        return WalletType.trezor;
      case 'metamask':
        return WalletType.metamask;
      case 'keplr':
        return WalletType.keplr;
      case 'hdwallet':
        return WalletType.hdwallet;
      default:
        return WalletType.iguana;
    }
  }
}

extension KdfUserWalletExtension on KdfUser {
  Wallet get wallet {
    final walletType =
        WalletType.fromJson(metadata['type'] as String? ?? 'iguana');
    return Wallet(
      id: walletId.name,
      name: walletId.name,
      config: WalletConfig(
        seedPhrase: '',
        pubKey: walletId.pubkeyHash,
        activatedCoins:
            metadata.valueOrNull<List<String>>('activated_coins') ?? [],
        hasBackup: metadata['has_backup'] as bool? ?? false,
        type: walletType,
      ),
    );
  }
}

extension KdfSdkWalletExtension on KomodoDefiSdk {
  Future<Iterable<Wallet>> get wallets async =>
      (await auth.getUsers()).map((user) => user.wallet);
}
