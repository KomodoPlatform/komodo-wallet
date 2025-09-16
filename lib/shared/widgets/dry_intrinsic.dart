// Using dry intrinsic workaround to fix TextFormField inside SimpleDialog error
// https://github.com/flutter/flutter/issues/71687

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DryIntrinsicWidth extends SingleChildRenderObjectWidget {
  const DryIntrinsicWidth({Key? key, Widget? child})
      : super(key: key, child: child);

  @override
  RenderDryIntrinsicWidth createRenderObject(BuildContext context) =>
      RenderDryIntrinsicWidth();
}

class RenderDryIntrinsicWidth extends RenderIntrinsicWidth {
  @override
  Size computeDryLayout(BoxConstraints constraints) {
    if (child != null) {
      final width = child!.computeMinIntrinsicWidth(constraints.maxHeight);
      final height = child!.computeMinIntrinsicHeight(width);
      return Size(width, height);
    } else {
      return Size.zero;
    }
  }
}

class DryIntrinsicHeight extends SingleChildRenderObjectWidget {
  const DryIntrinsicHeight({Key? key, Widget? child})
      : super(key: key, child: child);

  @override
  RenderDryIntrinsicHeight createRenderObject(BuildContext context) =>
      RenderDryIntrinsicHeight();
}

class RenderDryIntrinsicHeight extends RenderIntrinsicHeight {
  @override
  Size computeDryLayout(BoxConstraints constraints) {
    if (child != null) {
      final height = child!.computeMinIntrinsicHeight(constraints.maxWidth);
      final width = child!.computeMinIntrinsicWidth(height);
      return Size(width, height);
    } else {
      return Size.zero;
    }
  }
}
