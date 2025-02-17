import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRCodeAddress extends StatelessWidget {
  const QRCodeAddress({
    required this.currentAddress,
    this.size = 145,
    this.borderRadius,
    this.backgroundColor = Colors.white,
    this.foregroundColor = Colors.black,
    this.padding = const EdgeInsets.all(8.0),
  });
  final String currentAddress;
  final double size;
  final BorderRadiusGeometry? borderRadius;
  final Color backgroundColor;
  final Color foregroundColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final address = currentAddress;

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(18.0),
      child: QrImageView(
        size: size,
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        data: address,
        padding: padding,
      ),
    );
  }
}
