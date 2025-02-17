import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/blocs/current_wallet_bloc.dart';
import 'package:web_dex/common/app_assets.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/views/common/wallet_password_dialog/wallet_password_dialog.dart';

class PlateSeedBackup extends StatelessWidget {
  const PlateSeedBackup({required this.onViewSeedPressed});
  final Function(BuildContext context) onViewSeedPressed;

  @override
  Widget build(BuildContext context) {
    return isMobile
        ? _MobileBody(onViewSeedPressed: onViewSeedPressed)
        : _DesktopBody(onViewSeedPressed: onViewSeedPressed);
  }
}

class _MobileBody extends StatelessWidget {
  const _MobileBody({required this.onViewSeedPressed});

  final Function(BuildContext context) onViewSeedPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(18.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          const _AtomicIcon(),
          const SizedBox(height: 28),
          const _SaveAndRememberTitle(),
          const SizedBox(height: 12),
          const _SaveAndRememberBody(),
          const SizedBox(height: 8),
          _SaveAndRememberButtons(onViewSeedPressed: onViewSeedPressed),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _DesktopBody extends StatelessWidget {
  const _DesktopBody({required this.onViewSeedPressed});

  final Function(BuildContext context) onViewSeedPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(18.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _AtomicIcon(),
              const SizedBox(width: 22.5),
              const Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 12),
                    _SaveAndRememberTitle(),
                    SizedBox(height: 12),
                    _SaveAndRememberBody(),
                    SizedBox(height: 12),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _SaveAndRememberButtons(onViewSeedPressed: onViewSeedPressed),
            ],
          ),
        ],
      ),
    );
  }
}

class _AtomicIcon extends StatelessWidget {
  const _AtomicIcon();

  @override
  Widget build(BuildContext context) {
    final currentWallet = context.read<AuthBloc>().state.currentUser?.wallet;
    final hasBackup = currentWallet?.config.hasBackup ?? false;
    return DexSvgImage(
      path: hasBackup ? Assets.seedBackedUp : Assets.seedNotBackedUp,
      size: 50,
    );
  }
}

class _SaveAndRememberTitle extends StatelessWidget {
  const _SaveAndRememberTitle();

  @override
  Widget build(BuildContext context) {
    final currentWallet = context.read<AuthBloc>().state.currentUser?.wallet;
    final hasBackup = currentWallet?.config.hasBackup ?? false;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (!hasBackup)
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: theme.custom.decreaseColor,
              borderRadius: BorderRadius.circular(7 / 2),
            ),
          ),
        if (!hasBackup)
          const SizedBox(
            width: 7,
          ),
        Text(
          LocaleKeys.saveAndRemember.tr(),
          style: TextStyle(
            fontSize: isMobile ? 15 : 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SaveAndRememberBody extends StatelessWidget {
  const _SaveAndRememberBody();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 100),
      child: Text(
        LocaleKeys.seedAccessSpan1.tr(),
        style: TextStyle(
          fontSize: isMobile ? 13 : 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SaveAndRememberButtons extends StatelessWidget {
  const _SaveAndRememberButtons({required this.onViewSeedPressed});

  final Function(BuildContext context) onViewSeedPressed;

  @override
  Widget build(BuildContext context) {
    final currentWallet = context.read<AuthBloc>().state.currentUser?.wallet;
    final currentWalletBloc = context.read<CurrentWalletBloc>();
    final hasBackup = currentWallet?.config.hasBackup == true;
    final text = hasBackup
        ? LocaleKeys.viewSeedPhrase.tr()
        : LocaleKeys.backupSeedPhrase.tr();
    final width = isMobile ? double.infinity : 187.0;
    final height = isMobile ? 52.0 : 40.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        UiPrimaryButton(
          onPressed: () => onViewSeedPressed(context),
          width: width,
          height: height,
          text: text,
          textStyle: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: theme.custom.defaultGradientButtonTextColor,
          ),
        ),
        const SizedBox(height: 2),
        UiUnderlineTextButton(
          onPressed: () async {
            final String? password = await walletPasswordDialog(context);
            if (password == null) return;

            currentWalletBloc.downloadCurrentWallet(password);
          },
          width: isMobile ? double.infinity : 187,
          height: isMobile ? 52 : 40,
          text: LocaleKeys.seedPhraseSettingControlsDownloadSeed.tr(),
          textFontSize: 14,
        )
      ],
    );
  }
}
