import 'package:app_theme/app_theme.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/coins_bloc/asset_coin_extension.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/bloc/coins_manager/coins_manager_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin_type.dart';
import 'package:web_dex/model/wallet.dart';

class CoinsManagerFiltersDropdown extends StatefulWidget {
  @override
  State<CoinsManagerFiltersDropdown> createState() =>
      _CoinsManagerFiltersDropdownState();
}

class _CoinsManagerFiltersDropdownState
    extends State<CoinsManagerFiltersDropdown> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CoinsManagerBloc>();

    return UiDropdown(
      borderRadius: BorderRadius.circular(16),
      switcher: _Switcher(isOpen: _isOpen),
      dropdown: _Dropdown(bloc: bloc),
      onSwitch: (bool isOpen) => setState(() {
        _isOpen = isOpen;
      }),
    );
  }
}

class _Switcher extends StatelessWidget {
  const _Switcher({required this.isOpen});
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('filters-dropdown'),
      width: 100,
      height: 30,
      decoration: BoxDecoration(
        border: Border.all(color: theme.custom.specificButtonBorderColor),
        color: theme.custom.specificButtonBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          children: [
            isOpen
                ? Icon(
                    Icons.close,
                    color: Theme.of(context).textTheme.labelLarge?.color,
                    size: 14,
                  )
                : SvgPicture.asset(
                    '$assetsPath/ui_icons/filters.svg',
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).textTheme.labelLarge?.color ??
                          Colors.white,
                      BlendMode.srcIn,
                    ),
                    width: 14,
                  ),
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Text(
                isOpen ? LocaleKeys.close.tr() : LocaleKeys.filters.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({required this.bloc});
  final CoinsManagerBloc bloc;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CoinsManagerBloc, CoinsManagerState>(
      bloc: bloc,
      builder: (context, state) {
        final List<CoinType> selectedCoinTypes = bloc.state.selectedCoinTypes;
        final List<CoinType> listTypes = CoinType.values
            .where((CoinType type) => _filterTypes(context, type))
            .toList();
        onTap(CoinType type) =>
            bloc.add(CoinsManagerCoinTypeSelect(type: type));

        final bool isLongListTypes = listTypes.length > 2;

        return Container(
            constraints:
                BoxConstraints(maxWidth: isLongListTypes ? 320.0 : 140.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(color: theme.custom.specificButtonBorderColor),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                theme.custom.coinsManagerTheme.filtersPopupShadow,
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: listTypes
                  .map((type) => FractionallySizedBox(
                        widthFactor: isLongListTypes ? 0.5 : 1,
                        child: _DropdownItem(
                          type: type,
                          isSelected: selectedCoinTypes.contains(type),
                          onTap: onTap,
                          isFirst: listTypes.indexOf(type) == 0,
                          isWide: !isLongListTypes,
                        ),
                      ))
                  .toList(),
            ));
      },
    );
  }

  bool _filterTypes(BuildContext context, CoinType type) {
    final coinsBloc = context.read<CoinsBloc>();
    final currentWallet = context.read<AuthBloc>().state.currentUser?.wallet;
    switch (currentWallet?.config.type) {
      case WalletType.iguana:
      case WalletType.hdwallet:
        return coinsBloc.state.coins.values
                .firstWhereOrNull((coin) => coin.type == type) !=
            null;
      case WalletType.trezor:
        return coinsBloc.state.coins.values
                .firstWhereOrNull((coin) => coin.type == type) !=
            null;
      case WalletType.metamask:
      case WalletType.keplr:
      case null:
        return false;
    }
  }
}

class _DropdownItem extends StatelessWidget {
  const _DropdownItem({
    required this.type,
    required this.isSelected,
    required this.isFirst,
    required this.isWide,
    required this.onTap,
  });
  final CoinType type;
  final bool isSelected;
  final bool isFirst;
  final bool isWide;
  final Function(CoinType) onTap;

  @override
  Widget build(BuildContext context) {
    const double borderWidth = 2.0;
    const double topPadding = 6.0;

    return Container(
      alignment: Alignment.centerLeft,
      padding: isSelected
          ? EdgeInsets.only(top: isFirst ? 0.0 : topPadding)
          : EdgeInsets.fromLTRB(
              borderWidth,
              isFirst ? borderWidth : topPadding + borderWidth,
              borderWidth,
              borderWidth,
            ),
      child: InkWell(
        key: Key('filter-item-${type.name.toLowerCase()}'),
        onTap: () => onTap(type),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: isSelected
                ? Border.all(
                    color: theme
                        .custom.coinsManagerTheme.filterPopupItemBorderColor,
                    width: 2)
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 15),
          child: Row(
            mainAxisSize: isWide ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                type.toCoinSubClass().formatted,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
