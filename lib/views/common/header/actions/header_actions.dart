import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:komodo_wallet/app_config/app_config.dart';
import 'package:komodo_wallet/bloc/coins_bloc/asset_coin_extension.dart';
import 'package:komodo_wallet/bloc/coins_bloc/coins_bloc.dart';
import 'package:komodo_wallet/common/screen.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_wallet/release_options.dart';
import 'package:komodo_wallet/shared/utils/formatters.dart';
import 'package:komodo_wallet/shared/utils/utils.dart';
import 'package:komodo_wallet/views/common/header/actions/account_switcher.dart';

const EdgeInsets headerActionsPadding = EdgeInsets.fromLTRB(38, 18, 0, 0);
final _languageCodes = localeList.map((e) => e.languageCode).toList();
final _langCode2flags = {
  for (var loc in _languageCodes)
    loc: SvgPicture.asset(
      '$assetsPath/flags/$loc.svg',
    ),
};
List<Widget>? getHeaderActions(BuildContext context) {
  return <Widget>[
    if (showLanguageSwitcher)
      Padding(
        padding: headerActionsPadding,
        child: LanguageSwitcher(
          currentLocale: context.locale.toString(),
          languageCodes: _languageCodes,
          flags: _langCode2flags,
        ),
      ),
    Padding(
      padding: headerActionsPadding,
      child: BlocBuilder<CoinsBloc, CoinsState>(
        builder: (context, state) {
          return ActionTextButton(
            text: LocaleKeys.balance.tr(),
            secondaryText:
                '\$${formatAmt(_getTotalBalance(state.walletCoins.values, context))}',
            onTap: null,
          );
        },
      ),
    ),
    const Padding(
      padding: headerActionsPadding,
      child: AccountSwitcher(),
    ),
    if (!isWideScreen) const SizedBox(width: mainLayoutPadding),
  ];
}

double _getTotalBalance(Iterable<Coin> coins, BuildContext context) {
  double total =
      coins.fold(0, (prev, coin) => prev + (coin.usdBalance(context.sdk) ?? 0));

  if (total > 0.01) {
    return total;
  }

  return total != 0 ? 0.01 : 0;
}
