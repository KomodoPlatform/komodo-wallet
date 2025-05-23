import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/views/wallet/wallet_page/common/wallet_coins_sort.dart';

class CoinsListHeader extends StatelessWidget {
  const CoinsListHeader({
    super.key,
    required this.isAuth,
    required this.sortData,
    required this.onSortChange,
  });

  final bool isAuth;
  final WalletCoinsSortData sortData;
  final void Function(WalletCoinsSortData) onSortChange;

  @override
  Widget build(BuildContext context) {
    return isMobile
        ? const SizedBox.shrink()
        : _CoinsListHeaderDesktop(
            isAuth: isAuth,
            sortData: sortData,
            onSortChange: onSortChange,
          );
  }
}

class _CoinsListHeaderDesktop extends StatelessWidget {
  const _CoinsListHeaderDesktop({
    required this.isAuth,
    required this.sortData,
    required this.onSortChange,
  });

  final bool isAuth;
  final WalletCoinsSortData sortData;
  final void Function(WalletCoinsSortData) onSortChange;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall ??
        DefaultTextStyle.of(context).style;

    if (isAuth) {
      return Row(
        children: [
          const SizedBox(width: 32),
          Container(
            constraints: const BoxConstraints(maxWidth: 180),
            width: double.infinity,
            alignment: Alignment.centerLeft,
            child: UiSortListButton<WalletCoinsSortType>(
              text: LocaleKeys.asset.tr(),
              value: WalletCoinsSortType.name,
              sortData: sortData,
              onClick: _onSortChange,
            ),
          ),
          Expanded(
            child: UiSortListButton<WalletCoinsSortType>(
              text: LocaleKeys.price.tr(),
              value: WalletCoinsSortType.price,
              sortData: sortData,
              onClick: _onSortChange,
            ),
          ),
          Expanded(
            flex: 2,
            child: UiSortListButton<WalletCoinsSortType>(
              text: LocaleKeys.balance.tr(),
              value: WalletCoinsSortType.value,
              sortData: sortData,
              onClick: _onSortChange,
            ),
          ),
          Container(
            width: 68,
            alignment: Alignment.centerLeft,
            child: UiSortListButton<WalletCoinsSortType>(
              text: LocaleKeys.change24hRevert.tr(),
              value: WalletCoinsSortType.change24h,
              sortData: sortData,
              onClick: _onSortChange,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      );
    }

    return DefaultTextStyle(
      style: style,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: UiSortListButton<WalletCoinsSortType>(
                text: LocaleKeys.asset.tr(),
                value: WalletCoinsSortType.name,
                sortData: sortData,
                onClick: _onSortChange,
              ),
            ),
            Expanded(
              flex: 2,
              child: UiSortListButton<WalletCoinsSortType>(
                text: LocaleKeys.price.tr(),
                value: WalletCoinsSortType.price,
                sortData: sortData,
                onClick: _onSortChange,
              ),
            ),
            Expanded(
              flex: 2,
              child: UiSortListButton<WalletCoinsSortType>(
                text: LocaleKeys.change24hRevert.tr(),
                value: WalletCoinsSortType.change24h,
                sortData: sortData,
                onClick: _onSortChange,
              ),
            ),
            Expanded(flex: 2, child: Text(LocaleKeys.chart.tr())),
            Container(constraints: const BoxConstraints(minWidth: 48)),
          ],
        ),
      ),
    );
  }

  void _onSortChange(SortData<WalletCoinsSortType> data) {
    onSortChange(
      WalletCoinsSortData(
        sortType: data.sortType,
        sortDirection: data.sortDirection,
      ),
    );
  }
}
