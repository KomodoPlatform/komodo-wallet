import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_rpc_methods/komodo_defi_rpc_methods.dart'
    show ZhtlcSyncParams;
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart'
    show
        ZhtlcUserConfig,
        ZcashParamsDownloader,
        ZcashParamsDownloaderFactory,
        DownloadProgress,
        DownloadResultSuccess;
import 'package:komodo_defi_types/komodo_defi_types.dart' show Asset;
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';

/// Shows ZHTLC configuration dialog similar to handleZhtlcConfigDialog from SDK example
/// This is bad practice (UI logic in utils), but necessary for now because of
/// auto-coin activations from multiple sources in BLoCs.
Future<ZhtlcUserConfig?> confirmZhtlcConfiguration(
  BuildContext context, {
  required Asset asset,
}) async {
  String? prefilledZcashPath;

  // On desktop platforms, try to download Zcash parameters first
  if (ZcashParamsDownloaderFactory.requiresDownload) {
    ZcashParamsDownloader? downloader;
    try {
      downloader = ZcashParamsDownloaderFactory.create();

      // Check if parameters are already available
      final areAvailable = await downloader.areParamsAvailable();
      if (!areAvailable) {
        // Show download progress dialog
        final downloadResult = await _showZcashDownloadDialog(
          context,
          downloader,
        );

        if (downloadResult == false) {
          // User cancelled the download
          return null;
        }
      }

      prefilledZcashPath = await downloader.getParamsPath();
    } catch (e) {
      // Error creating downloader or getting params path
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleKeys.zhtlcErrorSettingUpZcash.tr(args: ['$e'])),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      // Always dispose the downloader to release resources
      downloader?.dispose();
    }
  }

  return showDialog<ZhtlcUserConfig?>(
    context: context,
    barrierDismissible: false,
    builder: (context) => ZhtlcConfigurationDialog(
      asset: asset,
      prefilledZcashPath: prefilledZcashPath,
    ),
  );
}

/// Stateful widget for ZHTLC configuration dialog
class ZhtlcConfigurationDialog extends StatefulWidget {
  const ZhtlcConfigurationDialog({
    super.key,
    required this.asset,
    this.prefilledZcashPath,
  });

  final Asset asset;
  final String? prefilledZcashPath;

  @override
  State<ZhtlcConfigurationDialog> createState() =>
      _ZhtlcConfigurationDialogState();
}

class _ZhtlcConfigurationDialogState extends State<ZhtlcConfigurationDialog> {
  late final TextEditingController zcashPathController;
  late final TextEditingController blocksPerIterController;
  late final TextEditingController intervalMsController;
  late final TextEditingController syncValueController;
  StreamSubscription<AuthBlocState>? _authSubscription;
  bool _dismissedDueToAuthChange = false;

  String syncType = 'date';
  DateTime? selectedDateTime;

  @override
  void initState() {
    super.initState();

    // On web, use './zcash-params' as default, otherwise use prefilledZcashPath
    final defaultZcashPath = kIsWeb
        ? './zcash-params'
        : widget.prefilledZcashPath;
    zcashPathController = TextEditingController(text: defaultZcashPath);
    blocksPerIterController = TextEditingController(text: '1000');
    intervalMsController = TextEditingController(text: '0');
    syncValueController = TextEditingController();

    // Initialize with default date (2 days ago)
    selectedDateTime = DateTime.now().subtract(const Duration(days: 2));
    syncValueController.text = formatDate(selectedDateTime!);

    _subscribeToAuthChanges();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    zcashPathController.dispose();
    blocksPerIterController.dispose();
    intervalMsController.dispose();
    syncValueController.dispose();
    super.dispose();
  }

  String formatDate(DateTime dateTime) {
    return dateTime.toIso8601String().split('T')[0];
  }

  /// Creates a Material 3 theme for the date picker based on the current Material 2 theme
  ThemeData _createMaterial3DatePickerTheme(BuildContext context) {
    final currentTheme = Theme.of(context);
    final currentColorScheme = currentTheme.colorScheme;

    // Use the current theme's primary color as the seed color
    // This works for both light and dark themes since primary is set appropriately in each
    final material3ColorScheme = ColorScheme.fromSeed(
      seedColor: currentColorScheme.primary,
      brightness: currentColorScheme.brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: material3ColorScheme,
      fontFamily: currentTheme.textTheme.bodyMedium?.fontFamily,
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2018), // first arrr block in 2018
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: _createMaterial3DatePickerTheme(context),
          child: child ?? const SizedBox(),
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDateTime = DateTime(picked.year, picked.month, picked.day);
        syncValueController.text = formatDate(selectedDateTime!);
      });
    }
  }

  void _onSyncTypeChanged(String? newSyncType) {
    if (newSyncType == null) return;
    setState(() {
      syncType = newSyncType;
      // Clear the input when switching sync types
      if (syncType == 'date') {
        // Set default date (2 days ago) for date type
        selectedDateTime = DateTime.now().subtract(const Duration(days: 2));
        syncValueController.text = formatDate(selectedDateTime!);
      } else if (syncType == 'height') {
        // Clear input for block height
        syncValueController.clear();
      } else {
        // Clear input for earliest (no input needed)
        syncValueController.clear();
      }
    });
  }

  Widget _buildSyncForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(LocaleKeys.zhtlcStartSyncFromLabel.tr()),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: syncType,
              items: [
                DropdownMenuItem(
                  value: 'earliest',
                  child: Text(LocaleKeys.zhtlcEarliestSaplingOption.tr()),
                ),
                DropdownMenuItem(
                  value: 'height',
                  child: Text(LocaleKeys.zhtlcBlockHeightOption.tr()),
                ),
                DropdownMenuItem(
                  value: 'date',
                  child: Text(LocaleKeys.zhtlcDateTimeOption.tr()),
                ),
              ],
              onChanged: _onSyncTypeChanged,
            ),
          ],
        ),
        if (syncType != 'earliest') ...[
          const SizedBox(height: 12),
          TextField(
            controller: syncValueController,
            decoration: InputDecoration(
              labelText: syncType == 'height'
                  ? LocaleKeys.zhtlcBlockHeightOption.tr()
                  : LocaleKeys.zhtlcSelectDateTimeLabel.tr(),
              suffixIcon: syncType == 'date'
                  ? IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _selectDate,
                    )
                  : null,
            ),
            keyboardType: syncType == 'height'
                ? TextInputType.number
                : TextInputType.none,
            readOnly: syncType == 'date',
            onTap: syncType == 'date' ? _selectDate : null,
          ),
          if (syncType == 'date') ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 4.0),
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 12.0,
              ),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                LocaleKeys.zhtlcDateSyncHint.tr(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ],
    );
  }

  void _handleSave() {
    final path = zcashPathController.text.trim();
    // On web, allow empty path, otherwise require it
    if (!kIsWeb && path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleKeys.zhtlcZcashParamsRequired.tr())),
      );
      return;
    }

    // Create sync params based on type
    ZhtlcSyncParams? syncParams;
    if (syncType == 'earliest') {
      syncParams = ZhtlcSyncParams.earliest();
    } else if (syncType == 'height') {
      final v = int.tryParse(syncValueController.text.trim());
      if (v == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocaleKeys.zhtlcInvalidBlockHeight.tr())),
        );
        return;
      }
      syncParams = ZhtlcSyncParams.height(v);
    } else if (syncType == 'date') {
      if (selectedDateTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocaleKeys.zhtlcSelectDateTimeRequired.tr())),
        );
        return;
      }
      // Convert to Unix timestamp (seconds since epoch)
      final unixTimestamp = selectedDateTime!.millisecondsSinceEpoch ~/ 1000;
      syncParams = ZhtlcSyncParams.date(unixTimestamp);
    }

    final result = ZhtlcUserConfig(
      zcashParamsPath: path,
      scanBlocksPerIteration:
          int.tryParse(blocksPerIterController.text) ?? 1000,
      scanIntervalMs: int.tryParse(intervalMsController.text) ?? 0,
      syncParams: syncParams,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        LocaleKeys.zhtlcConfigureTitle.tr(args: [widget.asset.id.id]),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!kIsWeb) ...[
              TextField(
                controller: zcashPathController,
                readOnly: widget.prefilledZcashPath != null,
                decoration: InputDecoration(
                  labelText: LocaleKeys.zhtlcZcashParamsPathLabel.tr(),
                  helperText: widget.prefilledZcashPath != null
                      ? LocaleKeys.zhtlcPathAutomaticallyDetected.tr()
                      : LocaleKeys.zhtlcSaplingParamsFolder.tr(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: blocksPerIterController,
              decoration: InputDecoration(
                labelText: LocaleKeys.zhtlcBlocksPerIterationLabel.tr(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: intervalMsController,
              decoration: InputDecoration(
                labelText: LocaleKeys.zhtlcScanIntervalLabel.tr(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _buildSyncForm(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(LocaleKeys.cancel.tr()),
        ),
        FilledButton(onPressed: _handleSave, child: Text(LocaleKeys.ok.tr())),
      ],
    );
  }

  void _subscribeToAuthChanges() {
    _authSubscription = context.read<AuthBloc>().stream.listen((state) {
      if (state.currentUser == null) {
        _handleAuthSignedOut();
      }
    });
  }

  void _handleAuthSignedOut() {
    if (_dismissedDueToAuthChange || !mounted) {
      return;
    }

    _dismissedDueToAuthChange = true;
    Navigator.of(context).maybePop<ZhtlcUserConfig?>(null);
  }
}

/// Shows a download progress dialog for Zcash parameters
Future<bool?> _showZcashDownloadDialog(
  BuildContext context,
  ZcashParamsDownloader downloader,
) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => ZcashDownloadProgressDialog(downloader: downloader),
  );
}

/// Stateful widget for Zcash download progress dialog
class ZcashDownloadProgressDialog extends StatefulWidget {
  const ZcashDownloadProgressDialog({required this.downloader, super.key});

  final ZcashParamsDownloader downloader;

  @override
  State<ZcashDownloadProgressDialog> createState() =>
      _ZcashDownloadProgressDialogState();
}

class _ZcashDownloadProgressDialogState
    extends State<ZcashDownloadProgressDialog> {
  static const downloadTimeout = Duration(minutes: 10);
  bool downloadComplete = false;
  bool downloadSuccess = false;
  bool dialogClosed = false;
  late Future<void> downloadFuture;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  void _startDownload() {
    downloadFuture = widget.downloader
        .downloadParams()
        .timeout(
          downloadTimeout,
          onTimeout: () => throw TimeoutException(
            'Download timed out after ${downloadTimeout.inMinutes} minutes',
            downloadTimeout,
          ),
        )
        .then((result) {
          if (!downloadComplete && !dialogClosed && mounted) {
            downloadComplete = true;
            downloadSuccess = result is DownloadResultSuccess;

            // Close the dialog with the result
            dialogClosed = true;
            Navigator.of(context).pop(downloadSuccess);
          }
        })
        .catchError((Object e, StackTrace? stackTrace) {
          if (!downloadComplete && !dialogClosed && mounted) {
            downloadComplete = true;
            downloadSuccess = false;

            debugPrint('Zcash parameters download failed: $e');
            if (stackTrace != null) {
              debugPrint('Stack trace: $stackTrace');
            }

            // Indicate download failed (null result)
            dialogClosed = true;
            Navigator.of(context).pop();
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(LocaleKeys.zhtlcDownloadingZcashParams.tr()),
      content: SizedBox(
        height: 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            StreamBuilder<DownloadProgress>(
              stream: widget.downloader.downloadProgress,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final progress = snapshot.data;
                  return Column(
                    children: [
                      Text(
                        progress?.displayText ?? '',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (progress?.percentage ?? 0) / 100,
                      ),
                      Text(
                        '${(progress?.percentage ?? 0).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                }
                return Text(LocaleKeys.zhtlcPreparingDownload.tr());
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            if (!dialogClosed) {
              dialogClosed = true;
              await widget.downloader.cancelDownload();
              Navigator.of(context).pop(false); // Cancelled
            }
          },
          child: Text(LocaleKeys.cancel.tr()),
        ),
      ],
    );
  }
}
