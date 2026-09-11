import 'dart:async';

import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:web_dex/services/security/private_key_export_delivery.dart';
import 'package:web_dex/services/security/private_key_export_service.dart';

const exportKeySentinel = 'synthetic-private-key-export-sentinel';
const exportPasswordSentinel = 'synthetic-password-export-sentinel';

AssetId exportTestAsset(String id) => AssetId(
  id: id,
  name: id,
  symbol: AssetSymbol(assetConfigId: id),
  chainId: AssetChainId(chainId: 0),
  derivationPath: "m/44'/0'/0'",
  subClass: CoinSubClass.utxo,
);

PrivateKeyExportResult exportTestResult({bool includeFailure = true}) {
  final btc = exportTestAsset('BTC');
  final trx = exportTestAsset('TRX');
  return PrivateKeyExportResult(
    outcomes: [
      PrivateKeyExportOutcome.success(
        assetId: btc,
        signingAssetId: btc,
        keys: [
          PrivateKey(
            assetId: btc,
            publicKeySecp256k1: 'synthetic-public-key',
            publicKeyAddress: 'synthetic-address',
            privateKey: exportKeySentinel,
            hdInfo: const PrivateKeyHdInfo(derivationPath: "m/44'/0'/0'/0/0"),
          ),
        ],
        coverage: const PrivateKeyExportCoverage(
          kind: PrivateKeyExportCoverageKind.offlineHdRange,
          accountIndex: 0,
          startIndex: 0,
          endIndex: 10,
          chain: 'External',
        ),
      ),
      PrivateKeyExportOutcome.success(
        assetId: trx,
        signingAssetId: trx,
        keys: [
          PrivateKey(
            assetId: trx,
            publicKeySecp256k1: 'synthetic-trx-public',
            publicKeyAddress: 'synthetic-trx-address',
            privateKey: 'synthetic-trx-private-key',
            hdInfo: const PrivateKeyHdInfo(derivationPath: "m/44'/195'/0'/0/3"),
          ),
        ],
        coverage: const PrivateKeyExportCoverage(
          kind: PrivateKeyExportCoverageKind.activeAddressOnly,
          accountIndex: 0,
          chain: 'External',
          derivationPath: "m/44'/195'/0'/0/3",
        ),
      ),
      if (includeFailure)
        PrivateKeyExportOutcome.unavailable(
          assetId: exportTestAsset('UNAVAILABLE'),
          failure: PrivateKeyExportFailure.activationPending,
        ),
    ],
  );
}

class FakePrivateKeyExportService implements PrivateKeyExportService {
  final changes = StreamController<void>.broadcast(sync: true);
  final access = PrivateKeyExportAccess(
    walletName: 'Synthetic wallet',
    token: Object(),
  );
  bool current = true;
  Object? authenticationError;
  PrivateKeyExportResult result = exportTestResult();
  int authentications = 0;
  int checks = 0;
  Completer<PrivateKeyExportAccess>? pendingBegin;
  Completer<PrivateKeyExportResult>? pendingExport;
  Completer<void>? pendingCheck;

  @override
  Stream<void> get sessionChanges => changes.stream;

  @override
  Future<PrivateKeyExportAccess> begin() async =>
      pendingBegin == null ? access : await pendingBegin!.future;

  @override
  void ensureCurrentSync(PrivateKeyExportAccess access) {
    if (!current || !identical(access, this.access)) {
      throw const PrivateKeyExportException(
        PrivateKeyExportError.sessionChanged,
      );
    }
  }

  @override
  Future<void> ensureCurrent(PrivateKeyExportAccess access) async {
    checks++;
    await pendingCheck?.future;
    if (!current || !identical(access, this.access)) {
      throw const PrivateKeyExportException(
        PrivateKeyExportError.sessionChanged,
      );
    }
  }

  @override
  Future<PrivateKeyExportResult> authenticateAndExport(
    PrivateKeyExportAccess access,
    SensitiveString password,
  ) async {
    authentications++;
    if (authenticationError case final error?) throw error;
    return pendingExport == null ? result : await pendingExport!.future;
  }
}

class FakePrivateKeyExportDelivery implements PrivateKeyExportDelivery {
  PrivateKeyExportDeliveryOutcome outcome =
      PrivateKeyExportDeliveryOutcome.completed;
  Completer<void>? picker;
  SensitiveString? delivered;
  int calls = 0;

  @override
  Future<PrivateKeyExportDeliveryOutcome> deliver({
    required PrivateKeyExportAction action,
    required SensitiveString content,
    required Future<void> Function() beforeWrite,
    required void Function() beforeCommit,
  }) async {
    calls++;
    await picker?.future;
    if (outcome == PrivateKeyExportDeliveryOutcome.cancelled) return outcome;
    await beforeWrite();
    beforeCommit();
    delivered = content;
    return outcome;
  }
}
