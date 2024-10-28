import 'dart:async';

import 'package:flutter/material.dart';
import 'package:web_dex/app_config/app_config.dart';

class FiatIcon extends StatefulWidget {
  const FiatIcon({required this.symbol, super.key});

  static const _fiatAssetsFolder = '$assetsPath/fiat/fiat_icons_square';
  final String symbol;

  // Static map to memoize asset checks
  static final Map<String, bool> _assetExistenceCache = {};

  @override
  State<FiatIcon> createState() => _FiatIconState();
}

class _FiatIconState extends State<FiatIcon> {
  bool _assetExists = false;

  @override
  void initState() {
    super.initState();

    setOrFetchAssetExistence();
  }

  @override
  void didUpdateWidget(FiatIcon oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.symbol != widget.symbol) {
      setOrFetchAssetExistence();
    }
  }

  void setOrFetchAssetExistence() {
    if (_knownAssetExistence != null) {
      setState(() => _assetExists = _knownAssetExistence!);
    } else {
      _checkIfAssetExists(context).then((exists) {
        if (!mounted) return;

        setState(() => _assetExists = exists);
      });
    }
  }

  String get _assetPath =>
      '${FiatIcon._fiatAssetsFolder}/${widget.symbol.toLowerCase()}.webp';

  bool? get _knownAssetExistence => FiatIcon._assetExistenceCache[_assetPath];

  Future<bool> _checkIfAssetExists(BuildContext context) {
    return _knownAssetExistence != null
        ? Future.value(_knownAssetExistence)
        : Future<bool>(() async {
            if (!mounted) return false;

            // ignore: use_build_context_synchronously
            final assetExists = await _doesAssetExist(context, _assetPath);

            FiatIcon._assetExistenceCache[_assetPath] = assetExists;

            return assetExists;
          });
  }

  Future<bool> _doesAssetExist(BuildContext context, String assetPath) async {
    try {
      // Try to load the image asset
      await precacheImage(AssetImage(assetPath), context);
      return true;
    } catch (e) {
      // Asset could not be loaded, return false
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: Container(
        alignment: Alignment.center,
        width: 36,
        child: _assetExists
            ? Image.asset(
                '${FiatIcon._fiatAssetsFolder}/${widget.symbol.toLowerCase()}.webp',
                key: Key(widget.symbol),
                filterQuality: FilterQuality.high,
              )
            : Icon(
                Icons.attach_money_outlined,
                size: 24,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
      ),
    );
  }
}
