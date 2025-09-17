import 'package:flutter/material.dart';

class ItemDecoration extends StatelessWidget {
  const ItemDecoration({required this.child});

  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
      child: child,
    );
  }
}
