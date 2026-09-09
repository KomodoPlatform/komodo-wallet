import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/security_settings/private_key_export_bloc.dart';
import 'package:web_dex/bloc/security_settings/private_key_export_event.dart';
import 'package:web_dex/bloc/security_settings/private_key_export_state.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/screenshot/screenshot_sensitivity.dart';
import 'package:web_dex/views/settings/widgets/security_settings/private_key_settings/private_key_actions_widget.dart';
import 'package:web_dex/views/settings/widgets/security_settings/private_key_settings/private_key_export_asset_section.dart';
import 'package:web_dex/views/settings/widgets/security_settings/seed_settings/seed_back_button.dart';

class PrivateKeyShow extends StatelessWidget {
  const PrivateKeyShow({super.key});

  @override
  Widget build(BuildContext context) => ScreenshotSensitive(
    child: BlocBuilder<PrivateKeyExportBloc, PrivateKeyExportState>(
      builder: (context, state) {
        if (state.phase != PrivateKeyExportPhase.ready) {
          return const SizedBox.shrink();
        }
        final bloc = context.read<PrivateKeyExportBloc>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMobile)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SeedBackButton(
                  () => bloc.add(const PrivateKeyExportCancelled()),
                ),
              ),
            Text(
              LocaleKeys.privateKeyExportTitle.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _Notice(
              text: LocaleKeys.privateKeySecurityWarning.tr(),
              warning: true,
            ),
            const SizedBox(height: 12),
            _Notice(text: LocaleKeys.copyWarning.tr(), warning: true),
            const SizedBox(height: 12),
            _Notice(text: LocaleKeys.privateKeyExportCoverageNotice.tr()),
            if (state.hasLimitedDisplayedCoverage) ...[
              const SizedBox(height: 12),
              _Notice(text: LocaleKeys.privateKeyExportActiveTronCoverage.tr()),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      key: const Key('private-key-export-visibility'),
                      value: state.showKeys,
                      onChanged: (visible) =>
                          bloc.add(PrivateKeyExportVisibilityChanged(visible)),
                    ),
                    Text(LocaleKeys.showPrivateKeys.tr()),
                  ],
                ),
                if (state.hasBlockedAssets)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: state.includeBlockedAssets,
                        onChanged: state.isDelivering
                            ? null
                            : (value) => bloc.add(
                                PrivateKeyExportBlockedAssetsChanged(
                                  value ?? false,
                                ),
                              ),
                      ),
                      Text(LocaleKeys.includeBlockedAssets.tr()),
                    ],
                  ),
                const PrivateKeyActionsWidget(),
              ],
            ),
            const SizedBox(height: 16),
            if (state.displayedOutcomes.isEmpty)
              Text(LocaleKeys.privateKeyExportNoAssets.tr()),
            for (final outcome in state.displayedOutcomes)
              PrivateKeyExportAssetSection(
                key: ValueKey((state.operationId, outcome.assetId)),
                outcome: outcome,
                showKeys: state.showKeys,
                canDeliver: state.canDeliver,
              ),
          ],
        );
      },
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.warning = false});
  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warning ? colors.errorContainer : colors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: warning ? colors.onErrorContainer : colors.onSurface,
        ),
      ),
    );
  }
}
