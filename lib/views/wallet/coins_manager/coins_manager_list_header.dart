import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/coins_manager/coins_manager_sort.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

class CoinsManagerListHeader extends StatelessWidget {
  const CoinsManagerListHeader({
    Key? key,
    required this.sortData,
    required this.isAddAssets,
    required this.onSortChange,
  }) : super(key: key);
  final CoinsManagerSortData sortData;
  final bool isAddAssets;
  final void Function(CoinsManagerSortData) onSortChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 1,
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 60, right: 20.0),
              child: SizedBox(),
            ),
            Expanded(
              flex: 2,
              child: UiSortListButton<CoinsManagerSortType>(
                onClick: _onSortChange,
                value: CoinsManagerSortType.name,
                sortData: sortData,
                text: LocaleKeys.assetName.tr(),
              ),
            ),
            Expanded(
              flex: isAddAssets ? 2 : 1,
              child: UiSortListButton<CoinsManagerSortType>(
                onClick: _onSortChange,
                value: CoinsManagerSortType.protocol,
                sortData: sortData,
                text: LocaleKeys.protocol.tr(),
              ),
            ),
            if (!isAddAssets)
              Expanded(
                flex: 2,
                child: UiSortListButton<CoinsManagerSortType>(
                  onClick: _onSortChange,
                  value: CoinsManagerSortType.balance,
                  sortData: sortData,
                  text: LocaleKeys.balance.tr(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onSortChange(SortData<CoinsManagerSortType> sortData) {
    onSortChange(
      CoinsManagerSortData(
        sortType: sortData.sortType,
        sortDirection: sortData.sortDirection,
      ),
    );
  }
}
