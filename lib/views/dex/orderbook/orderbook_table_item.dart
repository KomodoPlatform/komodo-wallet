import 'dart:async';

import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/model/orderbook/order.dart';
import 'package:web_dex/shared/utils/formatters.dart';

class OrderbookTableItem extends StatefulWidget {
  const OrderbookTableItem(
    this.order, {
    Key? key,
    required this.volumeFraction,
    this.isSelected = false,
    this.onClick,
  }) : super(key: key);

  final Order order;
  final double volumeFraction;
  final bool isSelected;
  final Function(Order)? onClick;

  @override
  State<OrderbookTableItem> createState() => _OrderbookTableItemState();
}

class _OrderbookTableItemState extends State<OrderbookTableItem> {
  static final Set<String> _pubkeysRequested = <String>{};

  double _scale = 0.1;
  late Color _color;
  late TextStyle _style;
  late bool _isPreview;
  late bool _isTradeWithSelf;
  StreamSubscription<CoinsState>? _coinsSubscription;

  @override
  void initState() {
    super.initState();
    final coinsBloc = context.read<CoinsBloc>();
    _isPreview = widget.order.uuid == orderPreviewUuid;
    _style = const TextStyle(fontSize: 11, fontWeight: FontWeight.w500);
    _color = _isPreview
        ? theme.custom.targetColor
        : widget.order.direction == OrderDirection.ask
        ? theme.custom.asksColor
        : theme.custom.bidsColor;
    _isTradeWithSelf = _computeTradeWithSelf(coinsBloc.state);

    _maybeRequestPubkeys(coinsBloc);
    _coinsSubscription = coinsBloc.stream.listen((CoinsState state) {
      final bool nextValue = _computeTradeWithSelf(state);
      if (!mounted || nextValue == _isTradeWithSelf) return;
      setState(() {
        _isTradeWithSelf = nextValue;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _scale = 1;
      });
    });
  }

  @override
  void didUpdateWidget(covariant OrderbookTableItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.uuid == widget.order.uuid &&
        oldWidget.order.rel == widget.order.rel &&
        oldWidget.order.address == widget.order.address) {
      return;
    }

    final coinsBloc = context.read<CoinsBloc>();
    _maybeRequestPubkeys(coinsBloc);
    final bool nextValue = _computeTradeWithSelf(coinsBloc.state);
    if (nextValue != _isTradeWithSelf) {
      setState(() {
        _isTradeWithSelf = nextValue;
      });
    }
  }

  @override
  void dispose() {
    _coinsSubscription?.cancel();
    super.dispose();
  }

  bool _computeTradeWithSelf(CoinsState state) {
    final String? orderAddress = widget.order.address;
    if (orderAddress == null || orderAddress.isEmpty) {
      return false;
    }

    final AssetPubkeys? assetPubkeys = state.pubkeys[widget.order.rel];
    if (assetPubkeys == null || assetPubkeys.isEmpty) {
      return false;
    }

    return assetPubkeys.keys.any((pubkey) => pubkey.address == orderAddress);
  }

  void _maybeRequestPubkeys(CoinsBloc coinsBloc) {
    final String? orderAddress = widget.order.address;
    if (orderAddress == null || orderAddress.isEmpty) return;
    if (coinsBloc.state.pubkeys.containsKey(widget.order.rel)) return;
    if (_pubkeysRequested.contains(widget.order.rel)) return;

    _pubkeysRequested.add(widget.order.rel);
    coinsBloc.add(CoinsPubkeysRequested(widget.order.rel));
  }

  @override
  Widget build(BuildContext context) {
    if (_isPreview) {
      return AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: _scale,
        child: _buildItem(),
      );
    }

    return _buildItem();
  }

  Widget _buildItem() {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: widget.onClick == null || _isPreview
            ? null
            : () {
                widget.onClick!(widget.order);
              },
        child: Stack(
          alignment: Alignment.centerRight,
          clipBehavior: Clip.none,
          children: [
            _buildPointerIfNeeded(),
            _buildChartBar(),
            _buildTextData(),
          ],
        ),
      ),
    );
  }

  Widget _buildPointerIfNeeded() {
    if (_isTradeWithSelf) {
      return Positioned(
        left: 2,
        child: Icon(Icons.circle, size: 4, color: _color),
      );
    }

    if (_isPreview || widget.isSelected) {
      return Positioned(
        left: 0,
        child: Icon(Icons.forward, size: 8, color: _color),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildChartBar() {
    return FractionallySizedBox(
      widthFactor: widget.volumeFraction,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 21),
        child: Container(color: _color.withValues(alpha: 0.1)),
      ),
    );
  }

  Widget _buildTextData() {
    return Container(
      decoration: BoxDecoration(
        border: _isPreview
            ? Border(
                bottom: BorderSide(
                  width: 0.5,
                  color: _color.withValues(alpha: 0.3),
                ),
                top: BorderSide(
                  width: 0.5,
                  color: _color.withValues(alpha: 0.3),
                ),
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          const SizedBox(width: 10),
          Expanded(
            child: AutoScrollText(
              text: widget.order.price.toDouble().toStringAsFixed(8),
              style: _style.copyWith(color: _color),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            formatAmt(widget.order.maxVolume.toDouble()),
            style: _style.copyWith(color: _isPreview ? _color : null),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
