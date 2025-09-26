import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
            content: Text('Error setting up Zcash parameters: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      // Always dispose the downloader to release resources
      downloader?.dispose();
    }
  }

  // On web, use './zcash-params' as default, otherwise use prefilledZcashPath
  final defaultZcashPath = kIsWeb ? './zcash-params' : prefilledZcashPath;
  final zcashPathController = TextEditingController(text: defaultZcashPath);
  final blocksPerIterController = TextEditingController(text: '1000');
  final intervalMsController = TextEditingController(text: '0');

  var syncType = 'date'; // earliest | height | date
  final syncValueController = TextEditingController();
  DateTime? selectedDateTime;

  String formatDate(DateTime dateTime) {
    return dateTime.toIso8601String().split('T')[0];
  }

  Future<void> selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2018), // first arrr block in 2018
      lastDate: DateTime.now(),
      builder: (context, child) {
        return child ?? const SizedBox();
      },
    );

    if (picked != null) {
      selectedDateTime = DateTime(picked.year, picked.month, picked.day);
      syncValueController.text = formatDate(selectedDateTime!);
    }
  }

  // Initialize with default date (2 days ago)
  selectedDateTime = DateTime.now().subtract(const Duration(days: 2));
  syncValueController.text = formatDate(selectedDateTime!);

  ZhtlcUserConfig? result;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setInnerState) {
          return AlertDialog(
            title: Text('Configure ${asset.id.id}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!kIsWeb) ...[
                    TextField(
                      controller: zcashPathController,
                      readOnly: prefilledZcashPath != null,
                      decoration: InputDecoration(
                        labelText: 'Zcash parameters path',
                        helperText: prefilledZcashPath != null
                            ? 'Path automatically detected'
                            : 'Folder containing sapling params',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: blocksPerIterController,
                    decoration: const InputDecoration(
                      labelText: 'Blocks per iteration',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: intervalMsController,
                    decoration: const InputDecoration(
                      labelText: 'Scan interval (ms)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Start sync from:'),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: syncType,
                        items: const [
                          DropdownMenuItem(
                            value: 'earliest',
                            child: Text('Earliest (sapling)'),
                          ),
                          DropdownMenuItem(
                            value: 'height',
                            child: Text('Block height'),
                          ),
                          DropdownMenuItem(
                            value: 'date',
                            child: Text('Date & Time'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setInnerState(() => syncType = v);
                        },
                      ),
                      const SizedBox(width: 8),
                      if (syncType != 'earliest')
                        Expanded(
                          child: TextField(
                            controller: syncValueController,
                            decoration: InputDecoration(
                              labelText: syncType == 'height'
                                  ? 'Block height'
                                  : 'Select date & time',
                              suffixIcon: syncType == 'date'
                                  ? IconButton(
                                      icon: const Icon(Icons.calendar_today),
                                      onPressed: () => selectDate(context),
                                    )
                                  : null,
                            ),
                            keyboardType: syncType == 'height'
                                ? TextInputType.number
                                : TextInputType.none,
                            readOnly: syncType == 'date',
                            onTap: syncType == 'date'
                                ? () => selectDate(context)
                                : null,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final path = zcashPathController.text.trim();
                  // On web, allow empty path, otherwise require it
                  if (!kIsWeb && path.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Zcash params path is required'),
                      ),
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
                        const SnackBar(
                          content: Text('Enter a valid block height'),
                        ),
                      );
                      return;
                    }
                    syncParams = ZhtlcSyncParams.height(v);
                  } else if (syncType == 'date') {
                    if (selectedDateTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a date and time'),
                        ),
                      );
                      return;
                    }
                    // Convert to Unix timestamp (seconds since epoch)
                    final unixTimestamp =
                        selectedDateTime!.millisecondsSinceEpoch ~/ 1000;
                    syncParams = ZhtlcSyncParams.date(unixTimestamp);
                  }

                  result = ZhtlcUserConfig(
                    zcashParamsPath: path,
                    scanBlocksPerIteration:
                        int.tryParse(blocksPerIterController.text) ?? 1000,
                    scanIntervalMs:
                        int.tryParse(intervalMsController.text) ?? 0,
                    syncParams: syncParams,
                  );
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );

  return result;
}

/// Shows a download progress dialog for Zcash parameters
Future<bool?> _showZcashDownloadDialog(
  BuildContext context,
  ZcashParamsDownloader downloader,
) async {
  const downloadTimeout = Duration(minutes: 10);

  // Start the download
  final downloadFuture = downloader.downloadParams().timeout(
    downloadTimeout,
    onTimeout: () => throw TimeoutException(
      'Download timed out after ${downloadTimeout.inMinutes} minutes',
      downloadTimeout,
    ),
  );

  var downloadComplete = false;
  var downloadSuccess = false;
  var dialogClosed = false;

  // Show the progress dialog that monitors download completion
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          // Listen for download completion and close dialog automatically
          downloadFuture
              .then((result) {
                if (!downloadComplete && !dialogClosed && context.mounted) {
                  downloadComplete = true;
                  downloadSuccess = result is DownloadResultSuccess;

                  // Close the dialog with the result
                  dialogClosed = true;
                  Navigator.of(context).pop(downloadSuccess);
                }
              })
              .catchError((Object e, StackTrace? stackTrace) {
                if (!downloadComplete && !dialogClosed && context.mounted) {
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

          return AlertDialog(
            title: const Text('Downloading Zcash Parameters'),
            content: SizedBox(
              height: 120,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  StreamBuilder<DownloadProgress>(
                    stream: downloader.downloadProgress,
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
                      return const Text('Preparing download...');
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
                    await downloader.cancelDownload();
                    Navigator.of(context).pop(false); // Cancelled
                  }
                },
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    },
  );
}
