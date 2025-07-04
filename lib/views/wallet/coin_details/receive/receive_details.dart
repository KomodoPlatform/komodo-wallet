import 'package:app_theme/app_theme.dart';
import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/coins_bloc/asset_coin_extension.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/shared/widgets/coin_type_tag.dart';
import 'package:web_dex/shared/widgets/segwit_icon.dart';
import 'package:web_dex/views/common/page_header/page_header.dart';
import 'package:web_dex/views/common/pages/page_layout.dart';
import 'package:web_dex/views/settings/widgets/security_settings/seed_settings/backup_seed_notification.dart';
import 'package:web_dex/views/wallet/coin_details/constants.dart';
import 'package:web_dex/views/wallet/coin_details/receive/qr_code_address.dart';
import 'package:web_dex/views/wallet/coin_details/receive/receive_address.dart';

class ReceiveDetails extends StatelessWidget {
  const ReceiveDetails({
    required this.asset,
    required this.pubkeys,
    required this.onBackButtonPressed,
    super.key,
  });

  final Asset asset;
  final AssetPubkeys pubkeys;
  final VoidCallback onBackButtonPressed;

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();
    return BlocBuilder<AuthBloc, AuthBlocState>(
      builder: (context, state) {
        return PageLayout(
          header: PageHeader(
            title: LocaleKeys.receive.tr(),
            widgetTitle: asset.id.isSegwit
                ? const Padding(
                    padding: EdgeInsets.only(left: 6.0),
                    child: SegwitIcon(height: 22),
                  )
                : null,
            backText: LocaleKeys.backToWallet.tr(),
            onBackButtonPressed: onBackButtonPressed,
          ),
          content: Expanded(
            child: DexScrollbar(
              isMobile: isMobile,
              scrollController: scrollController,
              child: SingleChildScrollView(
                controller: scrollController,
                child: _ReceiveDetailsContent(asset: asset, pubkeys: pubkeys),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReceiveDetailsContent extends StatefulWidget {
  const _ReceiveDetailsContent({required this.asset, required this.pubkeys});

  final Asset asset;
  final AssetPubkeys pubkeys;

  @override
  State<_ReceiveDetailsContent> createState() => _ReceiveDetailsContentState();
}

class _ReceiveDetailsContentState extends State<_ReceiveDetailsContent> {
  PubkeyInfo? _currentAddress;

  @override
  void initState() {
    super.initState();
    // Address initialization will be handled by ReceiveAddress widget
    // which has access to the SDK's address management system
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    final currentWallet = context.read<AuthBloc>().state.currentUser?.wallet;
    if (currentWallet?.config.hasBackup == false &&
        !widget.asset.protocol.isTestnet) {
      return const BackupNotification();
    }

    return Container(
      decoration: BoxDecoration(
        color: isMobile ? themeData.cardColor : null,
        borderRadius: BorderRadius.circular(18.0),
      ),
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 25 : 0,
        horizontal: 15,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(
            LocaleKeys.onlySendToThisAddress.tr(args: [widget.asset.id.name]),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 23),
            margin: EdgeInsets.only(top: isMobile ? 25 : 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.0),
              color: theme.mode == ThemeMode.dark
                  ? themeData.colorScheme.onSurface
                  : themeData.cardColor,
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.08),
                  offset: Offset(0, 1),
                  blurRadius: 8,
                ),
              ],
            ),
            constraints: const BoxConstraints(maxWidth: receiveWidth),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      LocaleKeys.network.tr(),
                      style: themeData.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: themeData.textTheme.labelLarge?.color,
                      ),
                    ),
                    CoinTypeTag(widget.asset.toCoin()),
                  ],
                ),
                const SizedBox(height: 30),
                ReceiveAddress(
                  asset: widget.asset,
                  selectedAddress: _currentAddress,
                  pubkeys: widget.pubkeys,
                  onChanged: _onAddressChanged,
                ),
                const SizedBox(height: 30),
                if (_currentAddress != null)
                  Column(
                    children: [
                      QRCodeAddress(currentAddress: _currentAddress!.address),
                      const SizedBox(height: 15),
                      Text(
                        LocaleKeys.scanToGetAddress.tr(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              color: themeData.textTheme.labelLarge?.color,
                            ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onAddressChanged(PubkeyInfo? address) {
    setState(() {
      _currentAddress = address;
    });
  }
}
