import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/model/dex_list_type.dart';
import 'package:komodo_wallet/model/my_orders/my_order.dart';
import 'package:komodo_wallet/model/trading_entities_filter.dart';
import 'package:komodo_wallet/views/dex/dex_list_filter/common/dex_list_filter_type.dart';
import 'package:komodo_wallet/views/dex/dex_list_filter/mobile/dex_list_filter_coin_mobile.dart';
import 'package:komodo_wallet/views/dex/dex_list_filter/mobile/dex_list_filter_coins_list_mobile.dart';

class DexListFilterMobile extends StatefulWidget {
  const DexListFilterMobile({
    Key? key,
    required this.onApplyFilter,
    required this.listType,
    required this.filterData,
  }) : super(key: key);
  final TradingEntitiesFilter? filterData;
  final DexListType listType;
  final void Function(TradingEntitiesFilter?) onApplyFilter;

  @override
  State<DexListFilterMobile> createState() => _DexListFilterMobileState();
}

class _DexListFilterMobileState extends State<DexListFilterMobile> {
  bool _isSellCoin = false;
  bool _isCoinListShown = false;
  late TradingEntitiesFilter _filterData;

  @override
  void initState() {
    _update();

    super.initState();
  }

  @override
  void didUpdateWidget(covariant DexListFilterMobile oldWidget) {
    if (oldWidget.filterData != widget.filterData) _update();

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return _isCoinListShown ? _buildList(false) : _buildMobileFilters();
  }

  Widget _buildMobileFilters() {
    return SingleChildScrollView(
      controller: ScrollController(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DexListFilterCoinMobile(
            label: LocaleKeys.sellAsset.tr(),
            coinAbbr: _filterData.sellCoin,
            showCoinList: () {
              setState(() {
                _isCoinListShown = true;
                _isSellCoin = true;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: DexListFilterCoinMobile(
              label: LocaleKeys.buyAsset.tr(),
              coinAbbr: _filterData.buyCoin,
              showCoinList: () {
                setState(() {
                  _isCoinListShown = true;
                  _isSellCoin = false;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: DexListFilterType<TradeSide>(
              titile: 'Trade State',
              values: [
                DexListFilterTypeValue<TradeSide>(
                  label: LocaleKeys.taker.tr(),
                  value: TradeSide.taker,
                ),
                DexListFilterTypeValue<TradeSide>(
                  label: LocaleKeys.maker.tr(),
                  value: TradeSide.maker,
                ),
              ],
              selectedValues: _filterData.shownSides,
              onChange: (shownSides) => setState(() {
                _filterData.shownSides = shownSides;
              }),
              label: '${LocaleKeys.taker.tr()}/${LocaleKeys.maker.tr()}',
              isMobile: true,
            ),
          ),
          if (widget.listType == DexListType.history)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: DexListFilterType<TradingStatus>(
                titile: 'Trading Status',
                values: [
                  DexListFilterTypeValue<TradingStatus>(
                    label: LocaleKeys.successful.tr(),
                    value: TradingStatus.successful,
                  ),
                  DexListFilterTypeValue<TradingStatus>(
                    label: LocaleKeys.failed.tr(),
                    value: TradingStatus.failed,
                  ),
                ],
                selectedValues: _filterData.statuses,
                onChange: (statuses) => setState(() {
                  _filterData.statuses = statuses;
                }),
                label: LocaleKeys.status.tr(),
                isMobile: true,
              ),
            ),
          Container(
            padding: const EdgeInsets.only(top: 32),
            width: double.infinity,
            child: Wrap(
              runSpacing: 12.0,
              alignment: WrapAlignment.spaceBetween,
              children: [
                UiDatePicker(
                  formatter: DateFormat('dd.MM.yyyy').format,
                  date: _filterData.startDate,
                  text: LocaleKeys.fromDate.tr(),
                  endDate: _filterData.endDate,
                  onDateSelect: (time) {
                    setState(() {
                      _filterData.startDate = time;
                    });
                  },
                ),
                UiDatePicker(
                  formatter: DateFormat('dd.MM.yyyy').format,
                  date: _filterData.endDate,
                  text: LocaleKeys.toDate.tr(),
                  startDate: _filterData.startDate,
                  onDateSelect: (time) {
                    setState(() {
                      _filterData.endDate = time;
                    });
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 32.0),
            child: UiPrimaryButton(
              text: LocaleKeys.apply.tr(),
              onPressed: () => _applyFiltersData(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(bool isApply) {
    return DexListFilterCoinsList(
      listType: widget.listType,
      isSellCoin: _isSellCoin,
      anotherCoin: _isSellCoin ? _filterData.buyCoin : _filterData.sellCoin,
      onCoinSelect: (String? abbr) {
        if (_isSellCoin) {
          setState(() {
            _filterData.sellCoin = abbr;
            _isCoinListShown = false;
          });
        } else {
          setState(() {
            _filterData.buyCoin = abbr;
            _isCoinListShown = false;
          });
        }
        if (isApply) {
          _applyFiltersData();
        }
      },
    );
  }

  void _applyFiltersData() => widget.onApplyFilter(
        _filterData,
      );

  void _update() => setState(() {
        _filterData = TradingEntitiesFilter.from(widget.filterData);
      });
}
