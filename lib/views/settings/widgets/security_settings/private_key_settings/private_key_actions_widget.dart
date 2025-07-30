import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:share_plus/share_plus.dart';
import 'package:web_dex/bloc/security_settings/security_settings_bloc.dart';
import 'package:web_dex/bloc/security_settings/security_settings_event.dart';
import 'package:web_dex/bloc/security_settings/security_settings_state.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/services/file_loader/file_loader.dart';
import 'package:web_dex/shared/utils/utils.dart';

/// A reusable widget that provides copy, download, and share actions for private keys.
///
/// This widget groups all private key actions in a consistent, reusable component
/// that can be used across different parts of the application.
class PrivateKeyActionsWidget extends StatelessWidget {
  /// Creates a new PrivateKeyActionsWidget.
  ///
  /// [privateKeys] Map of asset IDs to their corresponding private keys.
  /// [showCopy] Whether to show the copy button (default: true).
  /// [showDownload] Whether to show the download button (default: true).
  /// [showShare] Whether to show the share button (default: true).
  const PrivateKeyActionsWidget({
    super.key,
    required this.privateKeys,
    this.showCopy = true,
    this.showDownload = true,
    this.showShare = true,
  });

  /// Private keys organized by asset ID.
  final Map<AssetId, List<PrivateKey>> privateKeys;

  /// Whether to show the copy button.
  final bool showCopy;

  /// Whether to show the download button.
  final bool showDownload;

  /// Whether to show the share button.
  final bool showShare;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SecuritySettingsBloc, SecuritySettingsState, bool>(
      selector: (state) => state.showPrivateKeys,
      builder: (context, showPrivateKeys) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (showShare) _ShareAllPrivateKeysButton(privateKeys: privateKeys),
            if (showCopy) _CopyAllPrivateKeysButton(privateKeys: privateKeys),
            if (showDownload)
              _DownloadAllPrivateKeysButton(privateKeys: privateKeys),
          ],
        );
      },
    );
  }

  /// Converts private keys to JSON string format.
  static String _privateKeysToJsonString(
    Map<AssetId, List<PrivateKey>> privateKeys,
  ) {
    final jsonData = {
      for (final assetId in privateKeys.keys)
        assetId.id: privateKeys[assetId]!.map((key) => key.toJson()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(jsonData);
  }
}

/// Button for sharing all private keys.
class _ShareAllPrivateKeysButton extends StatelessWidget {
  const _ShareAllPrivateKeysButton({required this.privateKeys});
  final Map<AssetId, List<PrivateKey>> privateKeys;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SecuritySettingsBloc, SecuritySettingsState, bool>(
      selector: (state) => state.showPrivateKeys,
      builder: (context, showPrivateKeys) {
        return _ActionButton(
          onPressed: showPrivateKeys ? () => _sharePrivateKeys(context) : null,
          icon: Icons.share,
          label: LocaleKeys.shareAllKeys.tr(),
          isEnabled: showPrivateKeys,
        );
      },
    );
  }

  Future<void> _sharePrivateKeys(BuildContext context) async {
    final jsonString = PrivateKeyActionsWidget._privateKeysToJsonString(
      privateKeys,
    );

    try {
      await Share.share(jsonString, subject: 'Private Keys Export');
      // ignore: use_build_context_synchronously
      context.read<SecuritySettingsBloc>().add(
        const PrivateKeysDownloadRequestedEvent(),
      );
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to share private keys');
    }
  }
}

/// Button for downloading all private keys to a file.
class _DownloadAllPrivateKeysButton extends StatelessWidget {
  const _DownloadAllPrivateKeysButton({required this.privateKeys});
  final Map<AssetId, List<PrivateKey>> privateKeys;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SecuritySettingsBloc, SecuritySettingsState, bool>(
      selector: (state) => state.showPrivateKeys,
      builder: (context, showPrivateKeys) {
        return _ActionButton(
          onPressed: showPrivateKeys
              ? () => _downloadPrivateKeys(context)
              : null,
          icon: Icons.download,
          label: LocaleKeys.downloadAllKeys.tr(),
          isEnabled: showPrivateKeys,
        );
      },
    );
  }

  Future<void> _downloadPrivateKeys(BuildContext context) async {
    final jsonString = PrivateKeyActionsWidget._privateKeysToJsonString(
      privateKeys,
    );
    final fileLoader = FileLoader.fromPlatform();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'private_keys_$timestamp';

    try {
      await fileLoader.save(
        fileName: fileName,
        data: jsonString,
        type: LoadFileType.text,
      );

      // ignore: use_build_context_synchronously
      context.read<SecuritySettingsBloc>().add(
        const PrivateKeysDownloadRequestedEvent(),
      );
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to download private keys');
    }
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
        return _ActionButton(
          onPressed: showPrivateKeys ? () => _copyPrivateKeys(context) : null,
          icon: Icons.copy,
          label: LocaleKeys.copyAllKeys.tr(),
          isEnabled: showPrivateKeys,
        );
      },
    );
  }

  void _copyPrivateKeys(BuildContext context) async {
    final jsonString = PrivateKeyActionsWidget._privateKeysToJsonString(
      privateKeys,
    );
    await copyToClipBoard(context, jsonString);
    context.read<SecuritySettingsBloc>().add(
      const ShowPrivateKeysCopiedEvent(),
    );
  }
}

void _showErrorSnackBar(BuildContext context, String messageText) async {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(messageText),
      backgroundColor: Theme.of(context).colorScheme.error,
    ),
  );
}

/// Common action button widget with consistent styling.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.isEnabled,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onPressed,
      avatar: Icon(
        icon,
        size: 16,
        color: isEnabled
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      ),
      label: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
      ),
      backgroundColor: isEnabled
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
          : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
      side: BorderSide(
        color: isEnabled
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
      ),
    );
  }
}
