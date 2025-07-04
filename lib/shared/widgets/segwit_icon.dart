import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:komodo_wallet/app_config/app_config.dart';
import 'package:komodo_wallet/bloc/settings/settings_bloc.dart';
import 'package:komodo_wallet/bloc/settings/settings_state.dart';

class SegwitIcon extends StatelessWidget {
  const SegwitIcon({super.key, this.width, this.height});
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SettingsBloc, SettingsState, ThemeMode>(
      selector: (state) {
        return state.themeMode;
      },
      builder: (context, themeMode) {
        return SvgPicture.asset(
          width: width,
          height: height,
          _getIconPath(themeMode),
        );
      },
    );
  }

  String _getIconPath(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return '$assetsPath/ui_icons/segwit_dark.svg';
      case ThemeMode.light:
        return '$assetsPath/ui_icons/segwit_light.svg';
      case ThemeMode.dark:
        return '$assetsPath/ui_icons/segwit_dark.svg';
    }
  }
}
