import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/bloc/security_settings/security_settings_bloc.dart';
import 'package:web_dex/bloc/security_settings/security_settings_event.dart';
import 'package:web_dex/bloc/security_settings/security_settings_state.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/mm2/mm2_api/rpc/show_priv_key/show_priv_key_request.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/settings_menu_value.dart';
import 'package:web_dex/views/common/page_header/page_header.dart';
import 'package:web_dex/views/common/pages/page_layout.dart';
import 'package:web_dex/views/common/wallet_password_dialog/wallet_password_dialog.dart';
import 'package:web_dex/views/settings/widgets/common/settings_content_wrapper.dart';
import 'package:web_dex/views/settings/widgets/security_settings/password_update_page.dart';
import 'package:web_dex/views/settings/widgets/security_settings/security_settings_main_page.dart';
import 'package:web_dex/views/settings/widgets/security_settings/seed_settings/seed_confirm_success.dart';
import 'package:web_dex/views/settings/widgets/security_settings/seed_settings/seed_confirmation/seed_confirmation.dart';
import 'package:web_dex/views/settings/widgets/security_settings/seed_settings/seed_show.dart';

class SecuritySettingsPage extends StatefulWidget {
  // ignore: prefer_const_constructors_in_immutables
  SecuritySettingsPage({required this.onBackPressed, super.key});
  final VoidCallback onBackPressed;
  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  String _seed = '';
  final Map<Coin, String> _privKeys = {};

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SecuritySettingsBloc>(
      create: (_) => SecuritySettingsBloc(
        SecuritySettingsState.initialState(),
      ),
      child: BlocBuilder<SecuritySettingsBloc, SecuritySettingsState>(
        builder: (BuildContext context, SecuritySettingsState state) {
          final Widget content = _buildContent(state.step);
          if (isMobile) {
            return _SecuritySettingsPageMobile(
              content: content,
              onBackButtonPressed: () {
                switch (state.step) {
                  case SecuritySettingsStep.securityMain:
                    widget.onBackPressed();
                    break;
                  case SecuritySettingsStep.seedConfirm:
                    context
                        .read<SecuritySettingsBloc>()
                        .add(const ShowSeedEvent());
                    break;
                  case SecuritySettingsStep.seedShow:
                  case SecuritySettingsStep.seedSuccess:
                  case SecuritySettingsStep.passwordUpdate:
                    context
                        .read<SecuritySettingsBloc>()
                        .add(const ResetEvent());
                    break;
                }
              },
            );
          }
          return content;
        },
      ),
    );
  }

  Widget _buildContent(SecuritySettingsStep step) {
    switch (step) {
      case SecuritySettingsStep.securityMain:
        _seed = '';
        _privKeys.clear();
        return SecuritySettingsMainPage(onViewSeedPressed: onViewSeedPressed);

      case SecuritySettingsStep.seedShow:
        return SeedShow(seedPhrase: _seed, privKeys: _privKeys);

      case SecuritySettingsStep.seedConfirm:
        return SeedConfirmation(seedPhrase: _seed);

      case SecuritySettingsStep.seedSuccess:
        _seed = '';
        _privKeys.clear();
        return const SeedConfirmSuccess();

      case SecuritySettingsStep.passwordUpdate:
        _seed = '';
        _privKeys.clear();
        return const PasswordUpdatePage();
    }
  }

  Future<void> onViewSeedPressed(BuildContext context) async {
    final SecuritySettingsBloc securitySettingsBloc =
        context.read<SecuritySettingsBloc>();

    final String? pass = await walletPasswordDialog(context);
    if (pass == null) return;

    // ignore: use_build_context_synchronously
    final coinsBloc = context.read<CoinsBloc>();
    // ignore: use_build_context_synchronously
    final mm2Api = RepositoryProvider.of<Mm2Api>(context);
    // ignore: use_build_context_synchronously
    final kdfSdk = RepositoryProvider.of<KomodoDefiSdk>(context);

    final mnemonic = await kdfSdk.auth.getMnemonicPlainText(pass);
    _seed = mnemonic.plaintextMnemonic ?? '';

    _privKeys.clear();
    final parentCoins = coinsBloc.state.walletCoins.values
        .where((coin) => !coin.id.isChildAsset);
    for (final coin in parentCoins) {
      final result =
          await mm2Api.showPrivKey(ShowPrivKeyRequest(coin: coin.abbr));
      if (result != null) {
        _privKeys[coin] = result.privKey;
      }
    }

    securitySettingsBloc.add(const ShowSeedEvent());
  }
}

class _SecuritySettingsPageMobile extends StatelessWidget {
  const _SecuritySettingsPageMobile({
    required this.onBackButtonPressed,
    required this.content,
  });
  final VoidCallback onBackButtonPressed;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      header: PageHeader(
        title: SettingsMenuValue.security.title,
        backText: '',
        onBackButtonPressed: onBackButtonPressed,
      ),
      content: Flexible(
        child: SettingsContentWrapper(
          child: content,
        ),
      ),
    );
  }
}
