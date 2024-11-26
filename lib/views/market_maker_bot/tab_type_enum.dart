import 'package:web_dex/bloc/dex_tab_bar/dex_tab_bar_bloc.dart';

abstract class ITabTypeEnum {
  String get key;
  String name(DexTabBarState bloc);
}
