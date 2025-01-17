import 'package:easy_localization/easy_localization.dart';
import 'package:web_dex/bloc/dex_tab_bar/dex_tab_bar_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/views/market_maker_bot/tab_type_enum.dart';
import 'package:web_dex/mm2/mm2_sw.dart';

/// The order in this enum is important.
/// When you rearrange the elements, the order of the tabs must change.
/// Remember to change the initial tab
enum DexListType implements TabTypeEnum {
  swap,
  inProgress,
  orders,
  history;

  @override
  String name(DexTabBarBloc bloc) {
    final isExtension = isRunningAsChromeExtension();
    switch (this) {
      case swap:
        return LocaleKeys.swap.tr();
      case orders:
        return '${LocaleKeys.orders.tr()}${isExtension ? '' : ' (${bloc.ordersCount})'}';
      case inProgress:
        return '${LocaleKeys.inProgress.tr()}${isExtension ? '' : ' (${bloc.inProgressCount})'}';
      case history:
        return '${LocaleKeys.history.tr()}${isExtension ? '' : ' (${bloc.completedCount})'}';
    }
  }

  @override
  String get key {
    switch (this) {
      case swap:
        return 'dex-swap-tab';
      case orders:
        return 'dex-orders-tab';
      case inProgress:
        return 'dex-in-progress-tab';
      case history:
        return 'dex-history-tab';
    }
  }
}
