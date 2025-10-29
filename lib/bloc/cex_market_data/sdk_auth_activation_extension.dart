import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:logging/logging.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/shared/constants.dart';

extension SdkAuthActivationExtension on KomodoDefiSdk {
  /// Waits for the enabled coins to pass the provided threshold of the provided
  /// wallet coins list until the provided timeout. This is used to delay the
  /// portfolio growth chart loading attempt until at least x% of the expected
  /// wallet coins are enabled.
  /// Returns true if the enabled coins have passed the threshold, false if the
  /// timeout was reached.
  Future<bool> waitForEnabledCoinsToPassThreshold(
    List<Coin> walletCoins, {
    double threshold = 0.5,
    Duration timeout = const Duration(seconds: 30),
    Duration delay = kActivationPollingInterval,
  }) async {
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'is negative');
    }
    if (delay <= Duration.zero) {
      throw ArgumentError.value(delay, 'delay', 'is negative');
    }

    final log = Logger('SdkAuthActivationExtension');
    final walletCoinIds = walletCoins.map((e) => e.id).toSet();
    final stopwatch = Stopwatch()..start();
    while (true) {
      final isAboveThreshold = await _areEnabledCoinsAboveThreshold(
        walletCoinIds,
        threshold,
      );
      if (isAboveThreshold) {
        log.fine(
          'Enabled coins have passed the threshold in '
          '${stopwatch.elapsedMilliseconds}ms.',
        );
        stopwatch.stop();
        return true;
      }

      if (stopwatch.elapsed >= timeout) {
        log.warning(
          'Timeout of ${timeout.inSeconds}s reached while waiting for enabled '
          'coins to pass the threshold.',
        );
        stopwatch.stop();
        return false;
      }

      await Future<void>.delayed(delay);
    }
  }

  Future<bool> _areEnabledCoinsAboveThreshold(
    Set<AssetId> walletCoins,
    double threshold,
  ) async {
    if (walletCoins.isEmpty) {
      throw ArgumentError.value(walletCoins, 'walletCoins', 'is empty');
    }

    if (threshold <= 0 || threshold > 1) {
      throw ArgumentError.value(threshold, 'threshold', 'is out of range');
    }

    final enabledCoins = await assets.getActivatedAssets();
    final enabledCoinsMap = enabledCoins.map((e) => e.id).toSet();

    final enabledWalletCoins = walletCoins.intersection(enabledCoinsMap);
    final enabledWalletCoinsPercentage =
        enabledWalletCoins.length / walletCoins.length;
    return enabledWalletCoinsPercentage >= threshold;
  }
}
