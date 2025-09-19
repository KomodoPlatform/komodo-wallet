import 'package:flutter/material.dart';
import 'package:web_dex/common/app_assets.dart';

class BackButtonMobile extends StatelessWidget {
  const BackButtonMobile({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: IconButton(
          key: const Key('back-button'),
          onPressed: onPressed,
          alignment: Alignment.center,
          splashRadius: 15,
          padding: const EdgeInsets.all(0),
          icon: const DexSvgImage(
            path: Assets.chevronLeftMobile,
            colorFilter: ColorFilterEnum.headerIconColor,
          )),
    );
  }
}
