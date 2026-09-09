import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/security_settings/private_key_export_bloc.dart';
import 'package:web_dex/bloc/security_settings/private_key_export_event.dart';
import 'package:web_dex/bloc/security_settings/private_key_export_state.dart';
import 'package:web_dex/services/security/private_key_export_delivery.dart';

class PrivateKeyActionsWidget extends StatelessWidget {
  const PrivateKeyActionsWidget({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PrivateKeyExportBloc, PrivateKeyExportState>(
        builder: (context, state) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final action in PrivateKeyExportAction.values)
              ActionChip(
                key: Key('private-key-export-${action.name}'),
                onPressed: state.canDeliver
                    ? () => context.read<PrivateKeyExportBloc>().add(
                        PrivateKeyExportDeliveryRequested(action),
                      )
                    : null,
                avatar: Icon(switch (action) {
                  PrivateKeyExportAction.copy => Icons.copy,
                  PrivateKeyExportAction.download => Icons.download,
                  PrivateKeyExportAction.share => Icons.share,
                }, size: 18),
                label: Text(switch (action) {
                  PrivateKeyExportAction.copy =>
                    LocaleKeys.copyDisplayedKeys.tr(),
                  PrivateKeyExportAction.download =>
                    LocaleKeys.downloadDisplayedKeys.tr(),
                  PrivateKeyExportAction.share =>
                    LocaleKeys.shareDisplayedKeys.tr(),
                }),
              ),
            if (state.isDelivering)
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      );
}
