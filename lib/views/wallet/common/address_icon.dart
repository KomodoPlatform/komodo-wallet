import 'package:flutter/material.dart';
import 'package:komodo_wallet/common/screen.dart';

Color _generateColorFromString(String input) {
  final hash = input.hashCode;
  final r = (hash & 0xFF0000) >> 16;
  final g = (hash & 0x00FF00) >> 8;
  final b = (hash & 0x0000FF);
  return Color.fromARGB(255, r, g, b);
}

class AddressIcon extends StatelessWidget {
  const AddressIcon({
    super.key,
    required this.address,
    this.radius = 16,
  });

  final String address;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius * (isMobile ? 0.5 : 1),
      backgroundColor: _generateColorFromString(address),
    );
  }
}
