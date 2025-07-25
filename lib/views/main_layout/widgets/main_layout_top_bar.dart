import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/coins_bloc/asset_coin_extension.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/release_options.dart';
import 'package:web_dex/shared/utils/extensions/sdk_extensions.dart';
import 'package:web_dex/shared/utils/formatters.dart';
import 'package:web_dex/views/common/header/actions/account_switcher.dart';

class MainLayoutTopBar extends StatelessWidget {
  const MainLayoutTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: AppBar(
        toolbarHeight: appBarHeight,
        automaticallyImplyLeading: false,
        elevation: 0,
        leading: BlocBuilder<CoinsBloc, CoinsState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ActionTextButton(
                text: LocaleKeys.balance.tr(),
                secondaryText:
                    '\$${formatAmt(_getTotalBalance(state.walletCoins.values, context))}',
                onTap: null,
              ),
            );
          },
        ),
        leadingWidth: 200,
        actions: _getHeaderActions(context),
        titleSpacing: 0,
      ),
    );
  }

  double _getTotalBalance(Iterable<Coin> coins, BuildContext context) {
    double total = coins.fold(
        0, (prev, coin) => prev + (coin.usdBalance(context.sdk) ?? 0));

    if (total > 0.01) {
      return total;
    }

    return total != 0 ? 0.01 : 0;
  }

  List<Widget> _getHeaderActions(BuildContext context) {
    final languageCodes = localeList.map((e) => e.languageCode).toList();
    final langCode2flags = {
      for (var loc in languageCodes)
        loc: SvgPicture.asset(
          '$assetsPath/flags/$loc.svg',
        ),
    };

    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          if (showLanguageSwitcher) ...[
            LanguageSwitcher(
              currentLocale: context.locale.toString(),
              languageCodes: languageCodes,
              flags: langCode2flags,
            ),
            const SizedBox(width: 16),
          ],
          SizedBox(
            height: 40,
            child: const AccountSwitcher(),
          ),
        ]),
      )
    ];
  }
}
