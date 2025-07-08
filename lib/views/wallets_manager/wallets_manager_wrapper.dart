import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/views/wallets_manager/wallets_manager_events_factory.dart';
import 'package:web_dex/views/wallets_manager/widgets/wallets_manager.dart';
import 'package:web_dex/views/wallets_manager/widgets/wallets_type_list.dart';

class WalletsManagerWrapper extends StatefulWidget {
  const WalletsManagerWrapper({
    required this.eventType,
    this.onSuccess,
    super.key = const Key('wallets-manager-wrapper'),
  });

  final Function(Wallet)? onSuccess;
  final WalletsManagerEventType eventType;

  @override
  State<WalletsManagerWrapper> createState() => _WalletsManagerWrapperState();
}

class _WalletsManagerWrapperState extends State<WalletsManagerWrapper> {
  WalletType? _selectedWalletType;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final WalletType? selectedWalletType = _selectedWalletType;
    if (selectedWalletType == null) {
      return Column(
        children: [
          Text(
            LocaleKeys.walletsTypeListTitle.tr(),
            style:
                Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 30.0),
            child: WalletsTypeList(
              onWalletTypeClick: _onWalletTypeClick,
            ),
          ),
        ],
      );
    }

    return WalletsManager(
      eventType: widget.eventType,
      walletType: selectedWalletType,
      close: _closeWalletManager,
      onSuccess: widget.onSuccess ?? (_) {},
    );
  }

  Future<void> _onWalletTypeClick(WalletType type) async {
    setState(() {
      _selectedWalletType = type;
    });
  }

  Future<void> _closeWalletManager() async {
    setState(() {
      _selectedWalletType = null;
    });
  }
}
