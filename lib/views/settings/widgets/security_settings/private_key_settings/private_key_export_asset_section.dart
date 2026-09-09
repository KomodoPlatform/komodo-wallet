import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/bloc/security_settings/private_key_export_bloc.dart';
import 'package:web_dex/bloc/security_settings/private_key_export_event.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/services/security/private_key_export_delivery.dart';
import 'package:web_dex/views/settings/widgets/security_settings/private_key_settings/private_key_export_labels.dart';

class PrivateKeyExportAssetSection extends StatelessWidget {
  const PrivateKeyExportAssetSection({
    required this.outcome,
    required this.showKeys,
    required this.canDeliver,
    super.key,
  });

  final PrivateKeyExportOutcome outcome;
  final bool showKeys;
  final bool canDeliver;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            outcome.assetId.id,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (outcome.coverage case final coverage?)
            Text(privateKeyExportCoverageText(coverage)),
          if (outcome.signingAssetId != null &&
              outcome.signingAssetId != outcome.assetId)
            Text(
              LocaleKeys.privateKeyExportSharedSigningKey.tr(
                namedArgs: {'asset': outcome.signingAssetId!.id},
              ),
            ),
          if (outcome.failure case final failure?)
            Text(privateKeyExportFailureText(failure)),
          if (outcome.keys.isNotEmpty)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                LocaleKeys.privateKeyExportKeyCount.tr(
                  namedArgs: {'count': '${outcome.keys.length}'},
                ),
              ),
              children: [
                for (var index = 0; index < outcome.keys.length; index++)
                  _ExportKeyTile(
                    key: ValueKey(index),
                    privateKey: outcome.keys[index],
                    assetId: outcome.assetId,
                    index: index,
                    showKeys: showKeys,
                    canDeliver: canDeliver,
                  ),
              ],
            ),
        ],
      ),
    ),
  );
}

class _ExportKeyTile extends StatelessWidget {
  const _ExportKeyTile({
    required this.privateKey,
    required this.assetId,
    required this.index,
    required this.showKeys,
    required this.canDeliver,
    super.key,
  });

  final PrivateKey privateKey;
  final AssetId assetId;
  final int index;
  final bool showKeys;
  final bool canDeliver;

  @override
  Widget build(BuildContext context) {
    final key = privateKey;
    final revealed = context.select<PrivateKeyExportBloc, bool>(
      (bloc) => bloc.state.revealedKeys.contains((assetId, index)),
    );
    final bloc = context.read<PrivateKeyExportBloc>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (key.hdInfo?.derivationPath case final String path)
            SelectableText(path),
          Text(LocaleKeys.address.tr()),
          SelectableText(key.publicKeyAddress),
          if (key.publicKeySecp256k1.isNotEmpty) ...[
            Text(LocaleKeys.privateKeyExportPublicKey.tr()),
            SelectableText(key.publicKeySecp256k1),
          ],
          const SizedBox(height: 8),
          SelectableText(showKeys && revealed ? key.privateKey : '••••••••'),
          Wrap(
            children: [
              IconButton(
                tooltip: LocaleKeys.showPrivateKeys.tr(),
                onPressed: showKeys
                    ? () => bloc.add(
                        PrivateKeyExportKeyVisibilityToggled(assetId, index),
                      )
                    : null,
                icon: Icon(revealed ? Icons.visibility_off : Icons.visibility),
              ),
              IconButton(
                tooltip: LocaleKeys.copyDisplayedKey.tr(),
                onPressed: canDeliver
                    ? () => bloc.add(
                        PrivateKeyExportDeliveryRequested(
                          PrivateKeyExportAction.copy,
                          assetId: assetId,
                          keyIndex: index,
                        ),
                      )
                    : null,
                icon: const Icon(Icons.copy),
              ),
              IconButton(
                tooltip: LocaleKeys.privateKeyExportShowQr.tr(),
                onPressed: canDeliver
                    ? () =>
                          bloc.add(PrivateKeyExportQrRequested(assetId, index))
                    : null,
                icon: const Icon(Icons.qr_code),
              ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }
}
