import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/model/wallet.dart';

class WalletDeleting extends StatefulWidget {
  const WalletDeleting({
    super.key,
    required this.wallet,
    required this.close,
  });
  final Wallet wallet;
  final VoidCallback close;

  @override
  State<WalletDeleting> createState() => _WalletDeletingState();
}

class _WalletDeletingState extends State<WalletDeleting> {
  // final bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Padding(
          padding: const EdgeInsets.only(top: 18.0),
          child: Text(
            LocaleKeys.deleteWalletTitle.tr(args: [widget.wallet.name]),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            LocaleKeys.deleteWalletInfo.tr(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 25.0),
          child: _buildButtons(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(0),
          icon: Icon(
            Icons.chevron_left,
            color: theme.custom.headerIconColor,
          ),
          splashRadius: 15,
          iconSize: 18,
          onPressed: widget.close,
        ),
        Text(
          LocaleKeys.back.tr(),
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Flexible(
          child: UiBorderButton(
            text: LocaleKeys.cancel.tr(),
            onPressed: widget.close,
            height: 40,
            width: 150,
            borderWidth: 2,
            borderColor: theme.custom.specificButtonBorderColor,
          ),
        ),
        // TODO!: uncomment once re-implemented
        // const SizedBox(width: 8.0),
        // Flexible(
        //   child: UiPrimaryButton(
        //     text: LocaleKeys.delete.tr(),
        //     onPressed: _isDeleting ? null : _deleteWallet,
        //     prefix: _isDeleting ? const UiSpinner() : null,
        //     height: 40,
        //     width: 150,
        //   ),
        // )
      ],
    );
  }

  // TODO!: uncomment once re-implemented
  // Future<void> _deleteWallet() async {
  //   setState(() {
  //     _isDeleting = true;
  //   });
  //   final walletsRepository = RepositoryProvider.of<WalletsRepository>(context);
  //   await walletsRepository.deleteWallet(widget.wallet);
  //   setState(() {
  //     _isDeleting = false;
  //   });
  //   widget.close();
  // }
}
