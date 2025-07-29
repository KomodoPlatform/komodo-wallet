import 'dart:convert';
import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/security_settings/security_settings_bloc.dart';
import 'package:web_dex/bloc/security_settings/security_settings_event.dart';
import 'package:web_dex/bloc/security_settings/security_settings_state.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/bloc/analytics/analytics_bloc.dart';
import 'package:web_dex/analytics/events/security_events.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/views/settings/widgets/security_settings/seed_settings/seed_back_button.dart';
import 'package:web_dex/views/wallet/wallet_page/common/expandable_private_key_list.dart';

/// Widget for displaying private keys in a secure manner.
///
/// **Security Architecture**: This widget implements the UI layer of the hybrid
/// security approach for private key handling:
/// - Receives private key data directly from parent widget (not from BLoC state)
/// - Visibility state is managed by [SecuritySettingsBloc] for consistency
/// - Private key data never passes through shared state
/// - Provides secure viewing, copying, and QR code functionality
///
/// **Security Features**:
/// - Private keys are hidden by default
/// - Toggle visibility controlled by BLoC state
/// - Individual and bulk copy functionality
/// - QR code display for easy import
/// - Proper cleanup when widget is disposed
class PrivateKeyShow extends StatelessWidget {
  /// Creates a new PrivateKeyShow widget.
  ///
  /// [privateKeys] Map of asset IDs to their corresponding private keys.
  /// **Security Note**: This data should be handled with extreme care and
  /// cleared from memory as soon as possible.
  const PrivateKeyShow({required this.privateKeys});

  /// Private keys organized by asset ID.
  ///
  /// **Security Note**: This data is intentionally passed directly to the UI
  /// rather than stored in BLoC state to minimize memory exposure and lifetime.
  final Map<AssetId, List<PrivateKey>> privateKeys;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        if (!isMobile)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: SeedBackButton(() {
              context.read<AnalyticsBloc>().add(
                AnalyticsBackupSkippedEvent(
                  stageSkipped: 'private_key_show',
                  walletType:
                      context
                          .read<AuthBloc>()
                          .state
                          .currentUser
                          ?.wallet
                          .config
                          .type
                          .name ??
                      '',
                ),
              );
              context.read<SecuritySettingsBloc>().add(const ResetEvent());
            }),
          ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _TitleRow(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _ShowingSwitcher(),
                _CopyAllPrivateKeysButton(privateKeys: privateKeys),
              ],
            ),
            const SizedBox(height: 16),
            ExpandablePrivateKeyList(privateKeys: privateKeys),

          ],
        ),
      ],
    );
  }
}

/// Widget displaying the title and security warning for private key export.
class _TitleRow extends StatelessWidget {
  const _TitleRow();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.privateKeyExportTitle.tr(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 6),
        Text(
          LocaleKeys.privateKeyExportDescription.tr(),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.custom.warningColor.withValues(alpha: 0.1),
            border: Border.all(color: theme.custom.warningColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: theme.custom.warningColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  LocaleKeys.copyWarning.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: theme.custom.warningColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Button for copying all private keys to clipboard.
class _CopyAllPrivateKeysButton extends StatelessWidget {
  const _CopyAllPrivateKeysButton({required this.privateKeys});
  final Map<AssetId, List<PrivateKey>> privateKeys;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SecuritySettingsBloc, SecuritySettingsState, bool>(
      selector: (state) => state.showPrivateKeys,
      builder: (context, showPrivateKeys) {
        return Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: showPrivateKeys
                ? () {
                    final jsonData =
                    {
                      for (final assetId in privateKeys.keys)
                        assetId.id: privateKeys[assetId]!.map((key) => key.toJson()).toList(),
                    };  
                    
                    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
                    copyToClipBoard(context, jsonString);
                    context.read<SecuritySettingsBloc>().add(
                      const ShowPrivateKeysCopiedEvent(),
                    );
                  }
                : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: showPrivateKeys
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1)
                    : Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: showPrivateKeys
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3)
                      : Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.copy,
                    size: 16,
                    color: showPrivateKeys
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    LocaleKeys.copyAllKeys.tr(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: showPrivateKeys
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Toggle switch for showing/hiding private keys.
class _ShowingSwitcher extends StatelessWidget {
  const _ShowingSwitcher();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SecuritySettingsBloc, SecuritySettingsState, bool>(
      selector: (state) => state.showPrivateKeys,
      builder: (context, showPrivateKeys) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              UiSwitcher(
                value: showPrivateKeys,
                onChanged: (isChecked) =>
                    context.read<SecuritySettingsBloc>().add(ShowPrivateKeysWordsEvent(isChecked)),
                width: 38,
                height: 21,
              ),
              const SizedBox(width: 8),
              Text(
                LocaleKeys.showPrivateKeys.tr(),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Button to confirm that private keys have been saved.
class _PrivateKeysConfirmButton extends StatelessWidget {
  const _PrivateKeysConfirmButton();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SecuritySettingsBloc>();

    void onPressed() => bloc.add(const PrivateKeyConfirmEvent());
    final text = LocaleKeys.iHaveSavedMyPrivateKeys.tr();

    final contentWidth = screenWidth - 80;
    final width = isMobile ? contentWidth : 207.0;
    final height = isMobile ? 52.0 : 40.0;

    return BlocSelector<SecuritySettingsBloc, SecuritySettingsState, bool>(
      selector: (state) => state.arePrivateKeysSaved,
      builder: (context, isSaved) {
        return UiPrimaryButton(
          width: width,
          height: height,
          text: text,
          onPressed: isSaved ? onPressed : null,
        );
      },
    );
  }
}
