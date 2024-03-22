import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/blocs/blocs.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_sw.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/services/storage/get_storage.dart';
import 'package:web_dex/views/wallets_manager/wallets_manager_events_factory.dart';
import 'package:web_dex/views/wallets_manager/widgets/wallets_manager.dart';
import 'package:web_dex/views/wallets_manager/widgets/wallets_type_list.dart';
import 'package:collection/collection.dart';

class WalletsManagerWrapper extends StatefulWidget {
  const WalletsManagerWrapper({
    required this.eventType,
    this.onSuccess,
    Key? key = const Key('wallets-manager-wrapper'),
  }) : super(key: key);

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
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (isRunningAsChromeExtension()) {
      await walletsBloc.fetchSavedWallets();
      final wallets = walletsBloc.wallets;
      if (wallets.isNotEmpty) {
        final lastLoginWalletId = await getStorage().read('lastLoginWalletId');
        Wallet? lastLoginWallet = wallets
            .firstWhereOrNull((wallet) => wallet.id == lastLoginWalletId);

        // Use the first wallet if it's the only one
        if (lastLoginWallet == null && wallets.length == 1) {
          lastLoginWallet = wallets.first;
        }

        if (lastLoginWallet != null) {
          setState(() {
            if (lastLoginWallet != null) {
              _selectedWalletType = lastLoginWallet.config.type;
            }
          });
        }
      }
    } else {
      walletsBloc.fetchSavedWallets();
    }
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
