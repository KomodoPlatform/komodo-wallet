import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
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
    Key? key,
    required this.coin,
    required this.onBackButtonPressed,
  }) : super(key: key);

  final Coin coin;
  final VoidCallback onBackButtonPressed;

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();
    return BlocBuilder<AuthBloc, AuthBlocState>(
      builder: (context, state) {
        return PageLayout(
          header: PageHeader(
            title: LocaleKeys.receive.tr(),
            widgetTitle: coin.mode == CoinMode.segwit
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
                child: _ReceiveDetailsContent(coin: coin),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReceiveDetailsContent extends StatefulWidget {
  const _ReceiveDetailsContent({required this.coin});

  final Coin coin;

  @override
  State<_ReceiveDetailsContent> createState() => _ReceiveDetailsContentState();
}

class _ReceiveDetailsContentState extends State<_ReceiveDetailsContent> {
  String? _currentAddress;
  @override
  void initState() {
    _currentAddress = widget.coin.defaultAddress;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    final currentWallet = context.read<AuthBloc>().state.currentUser?.wallet;
    if (currentWallet?.config.hasBackup == false && !widget.coin.isTestCoin) {
      return const BackupNotification();
    }

    final currentAddress = _currentAddress;

    return Container(
      decoration: BoxDecoration(
          color: isMobile ? themeData.cardColor : null,
          borderRadius: BorderRadius.circular(18.0)),
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 25 : 0,
        horizontal: 15,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(
            LocaleKeys.sendToAddress
                .tr(args: [Coin.normalizeAbbr(widget.coin.abbr)]),
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
                ]),
            constraints: const BoxConstraints(maxWidth: receiveWidth),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(LocaleKeys.network.tr(),
                        style: themeData.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: themeData.textTheme.labelLarge?.color,
                        )),
                    CoinTypeTag(widget.coin),
                  ],
                ),
                const SizedBox(height: 30),
                ReceiveAddress(
                  coin: widget.coin,
                  selectedAddress: _currentAddress,
                  onChanged: _onAddressChanged,
                ),
                const SizedBox(height: 30),
                if (currentAddress != null)
                  Column(
                    children: [
                      QRCodeAddress(currentAddress: currentAddress),
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

  void _onAddressChanged(String address) {
    setState(() {
      _currentAddress = address;
    });
  }
}
