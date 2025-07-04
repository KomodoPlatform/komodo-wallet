import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_wallet/bloc/trading_kind/trading_kind_bloc.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/views/dex/common/dex_text_button.dart';

class SectionSwitcher extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: theme.custom.dexFormWidth),
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          _TakerBtn(),
          const SizedBox(width: 12),
          _MakerBtn(),
        ],
      ),
    );
  }
}

class _TakerBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final TradingKindBloc bloc = context.read<TradingKindBloc>();
    final isActive = bloc.state.isTaker;
    final onTap = isActive ? null : () => bloc.setKind(TradingKind.taker);
    return DexTextButton(
      text: LocaleKeys.takerOrder.tr(),
      isActive: isActive,
      onTap: onTap,
      key: const Key('take-order-tab'),
    );
  }
}

class _MakerBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final TradingKindBloc bloc = context.read<TradingKindBloc>();
    final isActive = bloc.state.isMaker;
    final onTap = isActive ? null : () => bloc.setKind(TradingKind.maker);
    return DexTextButton(
      text: LocaleKeys.makerOrder.tr(),
      isActive: isActive,
      onTap: onTap,
      key: const Key('make-order-tab'),
    );
  }
}
