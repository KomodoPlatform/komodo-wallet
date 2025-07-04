import 'package:flutter/material.dart';
import 'package:app_theme/app_theme.dart';

class AdaptiveDexFlipButtonWrapper extends StatefulWidget {
  final Future<bool> Function()? onTap;
  final Widget topWidget;
  final Widget bottomWidget;
  final double spacing;

  const AdaptiveDexFlipButtonWrapper({
    Key? key,
    required this.onTap,
    required this.topWidget,
    required this.bottomWidget,
    this.spacing = 12,
  }) : super(key: key);

  @override
  State<AdaptiveDexFlipButtonWrapper> createState() => _AdaptiveDexFlipButtonWrapperState();
}

class _AdaptiveDexFlipButtonWrapperState extends State<AdaptiveDexFlipButtonWrapper> {
  final GlobalKey _topWidgetKey = GlobalKey();
  double _calculatedOffset = 84;
  double _rotation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateOffset();
    });
  }

  void _calculateOffset() {
    final RenderBox? topRenderBox = 
        _topWidgetKey.currentContext?.findRenderObject() as RenderBox?;
    
    if (topRenderBox != null) {
      final topHeight = topRenderBox.size.height;
      final newOffset = topHeight + (widget.spacing / 2) - 24;
      
      if (newOffset != _calculatedOffset) {
        setState(() {
          _calculatedOffset = newOffset;
        });
      }
    }
  }

  Widget _buildCustomButton(BuildContext context) {
    final theme = Theme.of(context);
    
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
              CircleAvatar(
                backgroundColor: dexPageColors.frontPlate,
                radius: 28,
              ),
              CircleAvatar(
                backgroundColor: dexPageColors.frontPlateInner,
                radius: 20,
              ),
              AnimatedRotation(
                turns: _rotation / 360,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.arrow_downward, 
                  color: theme.colorScheme.primary, 
                  size: 20
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _calculateOffset();
        });

        return Stack(
          children: [
            Column(
              children: [
                Container(
                  key: _topWidgetKey,
                  child: widget.topWidget,
                ),
                SizedBox(height: widget.spacing),
                widget.bottomWidget,
              ],
            ),
            Positioned(
              top: _calculatedOffset,
              left: 0,
              right: 0,
              child: _buildCustomButton(context),
            ),
          ],
        );
      },
    );
  }
}