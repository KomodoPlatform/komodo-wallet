import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/performance_analytics/performance_analytics.dart';
import 'package:web_dex/services/performance/performance_optimizer.dart';
import 'package:web_dex/services/lazy_loading/lazy_loading_service.dart';
import 'package:web_dex/services/asset_optimization/asset_optimizer.dart';

/// Performance monitoring widget for debug mode
class PerformanceMonitor extends StatefulWidget {
  const PerformanceMonitor({super.key});

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  Timer? _updateTimer;
  Map<String, dynamic> _metrics = {};

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _updateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _updateMetrics();
      });
      _updateMetrics();
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _updateMetrics() {
    if (mounted) {
      setState(() {
        _metrics = {
          ...PerformanceOptimizer.instance.getMetrics(),
          ...LazyLoadingService.instance.getModuleStats(),
          ...AssetOptimizer.instance.getAssetStats(),
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 50,
      right: 10,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.speed, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                const Text(
                  'Performance Monitor',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 16),
                  onPressed: () {
                    // Hide monitor
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 4),
            _buildMetricRow('Active Timers', _metrics['activeTimers']?.toString() ?? '0'),
            _buildMetricRow('Cache Size', '${_metrics['cacheSize']?.toString() ?? '0'} bytes'),
            _buildMetricRow('Cached Assets', _metrics['cachedAssets']?.toString() ?? '0'),
            _buildMetricRow('Preloaded Assets', _metrics['preloadedAssets']?.toString() ?? '0'),
            _buildMetricRow('Loaded Modules', _metrics['loadedModules']?.toString() ?? '0'),
            _buildMetricRow('Loading Modules', _metrics['loadingModules']?.toString() ?? '0'),
            _buildMetricRow('Cache Hits', _metrics['cacheHits']?.toString() ?? '0'),
            _buildMetricRow('Cache Misses', _metrics['cacheMisses']?.toString() ?? '0'),
            const SizedBox(height: 4),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              PerformanceOptimizer.instance.clearCache();
              AssetOptimizer.instance.clearCache();
              _updateMetrics();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 4),
            ),
            child: const Text(
              'Clear Cache',
              style: TextStyle(fontSize: 10),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              PerformanceOptimizer.instance.cancelAllTimers();
              _updateMetrics();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 4),
            ),
            child: const Text(
              'Stop Timers',
              style: TextStyle(fontSize: 10),
            ),
          ),
        ),
      ],
    );
  }
}