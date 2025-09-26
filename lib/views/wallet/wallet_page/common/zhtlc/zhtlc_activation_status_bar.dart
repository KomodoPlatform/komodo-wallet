import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart' show AssetId;
import 'package:web_dex/generated/codegen_loader.g.dart' show LocaleKeys;
import 'package:web_dex/services/arrr_activation/arrr_activation_service.dart';
import 'package:web_dex/services/arrr_activation/arrr_config.dart';

/// Status bar widget to display ZHTLC activation progress for multiple coins
class ZhtlcActivationStatusBar extends StatefulWidget {
  const ZhtlcActivationStatusBar({super.key, required this.activationService});

  final ArrrActivationService activationService;

  @override
  State<ZhtlcActivationStatusBar> createState() =>
      _ZhtlcActivationStatusBarState();
}

class _ZhtlcActivationStatusBarState extends State<ZhtlcActivationStatusBar> {
  Timer? _refreshTimer;
  Map<AssetId, ArrrActivationStatus> _cachedStatuses = {};

  @override
  void initState() {
    super.initState();
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _refreshStatuses();
    });
  }

  void _refreshStatuses() {
    final newStatuses = widget.activationService.activationStatuses;

    if (mounted) {
      setState(() {
        _cachedStatuses = newStatuses;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter out completed or error statuses older than 5 seconds
    final activeStatuses = _cachedStatuses.entries.where((entry) {
      final status = entry.value;
      return status.when(
        inProgress:
            (
              assetId,
              startTime,
              progressPercentage,
              currentStep,
              statusMessage,
            ) => true,
        completed: (coinId, completionTime) =>
            DateTime.now().difference(completionTime).inSeconds < 5,
        error: (coinId, errorMessage, errorTime) =>
            DateTime.now().difference(errorTime).inSeconds < 5,
      );
    }).toList();

    if (activeStatuses.isEmpty) {
      return const SizedBox.shrink();
    }

    final coinNames = activeStatuses.map((entry) => entry.key.id).join(', ');
    final coinCount = activeStatuses.length;
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                LocaleKeys.activatingZhtlcCoins.plural(
                  coinCount,
                  args: [coinNames],
                ),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
