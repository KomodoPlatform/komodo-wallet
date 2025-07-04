import 'package:app_theme/app_theme.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:komodo_wallet/common/app_assets.dart';
import 'package:komodo_wallet/common/screen.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_wallet/model/hd_account/hd_account.dart';
import 'package:komodo_wallet/shared/utils/utils.dart';
import 'package:komodo_wallet/shared/widgets/truncate_middle_text.dart';

class AddressSelect extends StatefulWidget {
  const AddressSelect({
    Key? key,
    required this.coin,
    required this.addresses,
    required this.selectedAddress,
    required this.onChanged,
    this.maxWidth,
    this.maxHeight,
  }) : super(key: key);

  final Coin coin;
  final List<HdAddress>? addresses;
  final String selectedAddress;
  final Function(String) onChanged;
  final double? maxWidth;
  final double? maxHeight;

  @override
  State<AddressSelect> createState() => _AddressSelectState();
}

class _AddressSelectState extends State<AddressSelect> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final List<HdAddress>? addresses = widget.addresses;
    if (addresses == null || addresses.isEmpty) return const SizedBox.shrink();

    return addresses.length > 1
        ? UiDropdown(
            onSwitch: _onSwitch,
            isOpen: _isOpen,
            borderRadius: BorderRadius.circular(18),
            switcher: _buildSelectedAddress(showDropdownIcon: true),
            dropdown: _buildDropdown(addresses),
          )
        : _buildSelectedAddress(showDropdownIcon: false);
  }

  void _onSwitch(bool isOpen) {
    if (isOpen == _isOpen) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _isOpen = isOpen);
    });
  }

  Widget _buildDropdown(List<HdAddress> addresses) {
    final scrollController = ScrollController();
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: widget.maxWidth ?? double.infinity,
        maxHeight: widget.maxHeight ?? double.infinity,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(boxShadow: [
          BoxShadow(
            offset: const Offset(0, 1),
            blurRadius: 8,
            color: theme.custom.tabBarShadowColor,
          )
        ]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.currentGlobal.colorScheme.surface,
              border: Border.all(
                width: 1,
                color: theme.custom.filterItemBorderColor,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: DexScrollbar(
              isMobile: isMobile,
              scrollController: scrollController,
              child: ListView.builder(
                controller: scrollController,
                shrinkWrap: true,
                itemCount: addresses.length,
                itemBuilder: (context, i) =>
                    _buildDropdownItem(addresses[i].address),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownItem(String address) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () {
          widget.onChanged(address);
          setState(() => _isOpen = false);
        },
        child: Container(
          height: 40,
          padding: const EdgeInsets.fromLTRB(12, 0, 22, 0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Flexible(
                child: TruncatedMiddleText(
                  address,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 32),
              Text(
                doubleToString(_getAddressBalance(address)),
                style: TextStyle(
                  fontSize: 12,
                  color: theme.currentGlobal.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedAddress({required bool showDropdownIcon}) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.maxWidth ?? double.infinity),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          border:
              Border.all(width: 1, color: theme.custom.filterItemBorderColor),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: const Alignment(-1, 0),
        padding: const EdgeInsets.fromLTRB(12, 0, 22, 0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Flexible(
                child: TruncatedMiddleText(widget.selectedAddress,
                    style: const TextStyle(fontSize: 14))),
            if (showDropdownIcon) _buildDropdownIcon()
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownIcon() {
    return Padding(
      padding: const EdgeInsets.only(left: 32),
      child: DexSvgImage(
        path: _isOpen ? Assets.chevronUp : Assets.chevronDown,
      ),
    );
  }

  double _getAddressBalance(String address) {
    final HdAccount? defaultAccount = widget.coin.accounts?.first;
    if (defaultAccount == null) return 0.0;

    final HdAddress? hdAddress = defaultAccount.addresses
        .firstWhereOrNull((item) => item.address == address);
    if (hdAddress == null) return 0.0;

    return hdAddress.balance.spendable;
  }
}
