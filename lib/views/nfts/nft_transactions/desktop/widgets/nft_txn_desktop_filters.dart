import 'package:app_theme/app_theme.dart';
import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/nft_transactions/bloc/nft_transactions_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/rpc/nft_transaction/nft_transactions_response.dart';
import 'package:web_dex/model/nft.dart';

const double _itemHeight = 42;

class NftTxnDesktopFilters extends StatelessWidget {
  const NftTxnDesktopFilters({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<ColorSchemeExtension>();
    final chipColorScheme = UIChipColorScheme(
      emptyContainerColor: colorScheme?.surfCont,
      emptyTextColor: colorScheme?.s70,
      pressedContainerColor: colorScheme?.surfContLowest,
      selectedContainerColor: colorScheme?.primary,
      selectedTextColor: colorScheme?.surf,
    );
    return BlocBuilder<NftTransactionsBloc, NftTxnState>(
      builder: (context, state) {
        return Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: colorScheme?.surfContHighest,
          ),
          child: Row(children: [
            Flexible(
                flex: 3,
                child: SizedBox(
                  height: 40,
                  child: CupertinoSearchTextField(
                    controller: state.filters.searchLine.isEmpty
                        ? TextEditingController()
                        : null,
                    onSubmitted: (value) {
                      context
                          .read<NftTransactionsBloc>()
                          .add(NftTxnEventSearchChanged(value));
                    },
                    style: Theme.of(context).textTheme.bodySmall,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: colorScheme?.surfCont,
                    ),
                    prefixInsets: const EdgeInsets.only(left: 16, right: 8),
                    prefixIcon: SvgPicture.asset(
                      '$assetsPath/custom_icons/16px/search.svg',
                      width: 16,
                      height: 16,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.secondary,
                        BlendMode.srcIn,
                      ),
                    ),
                    suffixInsets: const EdgeInsets.only(left: 16, right: 8),
                    suffixIcon: Icon(
                      Icons.clear,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 18,
                    ),
                    onSuffixTap: () {
                      context
                          .read<NftTransactionsBloc>()
                          .add(const NftTxnEventSearchChanged(''));
                    },
                  ),
                )),
            const SizedBox(width: 24),
            MultiSelectDropdownButton<NftTransactionStatuses>(
              title: 'Status',
              items: NftTransactionStatuses.values,
              displayItem: (p0) => p0.toString(),
              selectedItems: state.filters.statuses,
              onChanged: (value) {
                context
                    .read<NftTransactionsBloc>()
                    .add(NftTxnEventStatusesChanged(value));
              },
              colorScheme: chipColorScheme,
            ),
            const SizedBox(width: 8),
            MultiSelectDropdownButton<NftBlockchains>(
              title: 'Blockchain',
              items: NftBlockchains.values,
              displayItem: (p0) => p0.toString(),
              selectedItems: state.filters.blockchain,
              onChanged: (value) {
                context
                    .read<NftTransactionsBloc>()
                    .add(NftTxnEventBlockchainChanged(value));
              },
              colorScheme: chipColorScheme,
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: 120, maxHeight: _itemHeight),
              child: UiDatePicker(
                formatter: DateFormat('dd.MM.yyyy').format,
                date: state.filters.dateFrom,
                text: LocaleKeys.fromDate.tr(),
                endDate: state.filters.dateTo,
                onDateSelect: (time) {
                  context
                      .read<NftTransactionsBloc>()
                      .add(NftTxnEventStartDateChanged(time));
                },
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: 120, maxHeight: _itemHeight),
              child: UiDatePicker(
                formatter: DateFormat('dd.MM.yyyy').format,
                date: state.filters.dateTo,
                text: LocaleKeys.toDate.tr(),
                startDate: state.filters.dateFrom,
                onDateSelect: (time) {
                  context
                      .read<NftTransactionsBloc>()
                      .add(NftTxnEventEndDateChanged(time));
                },
              ),
            ),
            const SizedBox(width: 24),
            const Flex(direction: Axis.horizontal),
            state.filters.isEmpty
                ? UiSecondaryButton(
                    height: _itemHeight,
                    width: 72,
                    text: LocaleKeys.reset.tr(),
                    borderColor: colorScheme?.s70,
                    textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme?.s70,
                          fontSize: 14,
                        ),
                    onPressed: null,
                  )
                : UiPrimaryButton(
                    width: 72,
                    height: _itemHeight,
                    text: LocaleKeys.reset.tr(),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      context
                          .read<NftTransactionsBloc>()
                          .add(const NftTxnClearFilters());
                    },
                  ),
          ]),
        );
      },
    );
  }
}
