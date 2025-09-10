import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/coins_manager/coins_manager_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin_type.dart';
import 'package:web_dex/model/coin_utils.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/views/wallet/coins_manager/coins_manager_filter_type_label.dart';

class CoinsManagerSelectedTypesList extends StatelessWidget {
  const CoinsManagerSelectedTypesList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return BlocSelector<CoinsManagerBloc, CoinsManagerState, List<CoinType>>(
      selector: (state) {
        return state.selectedCoinTypes;
      },
      builder: (context, types) {
        if (types.isEmpty) return const SizedBox();
        final scrollController = ScrollController();
        return Padding(
          padding: const EdgeInsets.only(top: 12.0, bottom: 20.0),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 28),
            child: DexScrollbar(
              isMobile: isMobile,
              scrollController: scrollController,
              child: ListView.builder(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: types.length,
                itemBuilder: (BuildContext context, int index) {
                  final type = types[index];
                  final Color protocolColor = getProtocolColor(type);
                  if (index == 0) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: CoinsManagerFilterTypeLabel(
                            text: LocaleKeys.resetAll.tr(),
                            textStyle: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: themeData.textTheme.labelLarge?.color,
                            ),
                            backgroundColor: themeData.colorScheme.surface,
                            border: Border.all(
                              color: theme.custom.specificButtonBorderColor,
                            ),
                            onTap: () {
                              context.read<CoinsManagerBloc>().add(
                                const CoinsManagerSelectedTypesReset(),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: CoinsManagerFilterTypeLabel(
                            text: getCoinTypeName(type),
                            backgroundColor: protocolColor,
                            border: Border.all(
                              color: type == CoinType.smartChain
                                  ? theme.custom.smartchainLabelBorderColor
                                  : protocolColor,
                            ),
                            onTap: () {
                              context.read<CoinsManagerBloc>().add(
                                CoinsManagerCoinTypeSelect(type: type),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: CoinsManagerFilterTypeLabel(
                      text: getCoinTypeName(type),
                      backgroundColor: protocolColor,
                      border: Border.all(
                        color: type == CoinType.smartChain
                            ? theme.custom.smartchainLabelBorderColor
                            : protocolColor,
                      ),
                      onTap: () {
                        context.read<CoinsManagerBloc>().add(
                          CoinsManagerCoinTypeSelect(type: type),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
