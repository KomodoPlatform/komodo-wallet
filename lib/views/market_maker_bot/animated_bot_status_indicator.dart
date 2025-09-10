import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/bloc/market_maker_bot/market_maker_bot/market_maker_bot_status.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

class AnimatedBotStatusIndicator extends StatefulWidget {
  final MarketMakerBotStatus status;

  const AnimatedBotStatusIndicator({Key? key, required this.status})
    : super(key: key);

  @override
  State<AnimatedBotStatusIndicator> createState() =>
      _AnimatedBotStatusIndicatorState();
}

class _AnimatedBotStatusIndicatorState extends State<AnimatedBotStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(AnimatedBotStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status != oldWidget.status) {
      _controller.reset();
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (_, child) {
            return Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getStatusColor(
                  widget.status,
                ).withValues(alpha: _getOpacity(widget.status)),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        Text(
          widget.status.text,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }

  double _getOpacity(MarketMakerBotStatus status) {
    switch (status) {
      case MarketMakerBotStatus.starting:
      case MarketMakerBotStatus.stopping:
        return 0.3 + (_controller.value * 0.7);
      case MarketMakerBotStatus.running:
        return 1.0;
      case MarketMakerBotStatus.stopped:
        return 0.5;
    }
  }
}

Color _getStatusColor(MarketMakerBotStatus status) {
  switch (status) {
    case MarketMakerBotStatus.starting:
      return Colors.yellow;
    case MarketMakerBotStatus.stopping:
      return Colors.orange;
    case MarketMakerBotStatus.running:
      return Colors.green;
    case MarketMakerBotStatus.stopped:
      return Colors.red;
  }
}

extension on MarketMakerBotStatus {
  String get text {
    switch (this) {
      case MarketMakerBotStatus.running:
        return LocaleKeys.mmBotStatusRunning.tr();
      case MarketMakerBotStatus.stopped:
        return LocaleKeys.mmBotStatusStopped.tr();
      case MarketMakerBotStatus.starting:
        return LocaleKeys.mmBotStatusStarting.tr();
      case MarketMakerBotStatus.stopping:
        return LocaleKeys.mmBotStatusStopping.tr();
    }
  }
}
