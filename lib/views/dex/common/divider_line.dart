import 'package:flutter/material.dart';

class DividerDecoration extends BoxDecoration {
  DividerDecoration(Color color)
      : super(
          border: Border(
            bottom: BorderSide(
              width: 1,
              color: color,
            ),
          ),
        );
}
