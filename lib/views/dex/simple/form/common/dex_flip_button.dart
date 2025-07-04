import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:komodo_wallet/common/app_assets.dart';

class DexFlipButton extends StatefulWidget {
  final Future<bool> Function()? onTap;

  const DexFlipButton({
    Key? key,
    this.onTap,
  }) : super(key: key);

  @override
  DexFlipButtonState createState() => DexFlipButtonState();
}

class DexFlipButtonState extends State<DexFlipButton> {
  double _rotation = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: () async {
          if (widget.onTap != null) {
            if (await widget.onTap!()) {
              setState(() {
                _rotation = (_rotation + 180) % 360;
              });
            }
          }
        },
        child: Opacity(
          opacity: widget.onTap == null ? 0.5 : 1.0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer circle
              CircleAvatar(
                backgroundColor: dexPageColors.frontPlate,
                radius: 28,
              ),
              // Inner circle
              CircleAvatar(
                backgroundColor: dexPageColors.frontPlateInner,
                radius: 20,
              ),
              AnimatedRotation(
                turns: _rotation / 360,
                duration: const Duration(milliseconds: 300),
                child: const DexSvgImage(path: Assets.dexSwapCoins, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
