import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/bloc/coins_manager/coins_manager_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/router/state/wallet_state.dart';
import 'package:web_dex/views/common/page_header/page_header.dart';
import 'package:web_dex/views/common/pages/page_layout.dart';
import 'package:web_dex/views/wallet/coins_manager/coins_manager_list_wrapper.dart';

class CoinsManagerPage extends StatelessWidget {
  const CoinsManagerPage({
    Key? key,
    required this.action,
    required this.closePage,
  }) : super(key: key);

  final CoinsManagerAction action;
  final void Function() closePage;

  @override
  Widget build(BuildContext context) {
    assert(
      action == CoinsManagerAction.add || action == CoinsManagerAction.remove,
    );

    final title = action == CoinsManagerAction.add
        ? LocaleKeys.addAssets.tr()
        : LocaleKeys.removeAssets.tr();

    return PageLayout(
      header: PageHeader(
        title: title,
        backText: LocaleKeys.backToWallet.tr(),
        onBackButtonPressed: closePage,
      ),
      content: Flexible(
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: BlocBuilder<AuthBloc, AuthBlocState>(
            builder: (context, state) {
              if (!state.isSignedIn) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(0, 100, 0, 100),
                    child: UiSpinner(),
                  ),
                );
              }
              return const CoinsManagerListWrapper();
            },
          ),
        ),
      ),
    );
  }
}
