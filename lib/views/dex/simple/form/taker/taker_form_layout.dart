import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:komodo_wallet/bloc/taker_form/taker_bloc.dart';
import 'package:komodo_wallet/bloc/taker_form/taker_state.dart';
import 'package:komodo_wallet/common/screen.dart';
import 'package:komodo_wallet/views/dex/simple/confirm/taker_order_confirmation.dart';
import 'package:komodo_wallet/views/dex/simple/form/tables/coins_table/taker_sell_coins_table.dart';
import 'package:komodo_wallet/views/dex/simple/form/tables/orders_table/taker_orders_table.dart';
import 'package:komodo_wallet/views/dex/simple/form/taker/taker_form_content.dart';
import 'package:komodo_wallet/views/dex/simple/form/taker/taker_order_book.dart';

class TakerFormLayout extends StatelessWidget {
  const TakerFormLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TakerBloc, TakerState, TakerStep>(
      selector: (state) => state.step,
      builder: (context, step) {
        return step == TakerStep.confirm
            ? const TakerOrderConfirmation()
            : isMobile
                ? const _TakerFormMobileLayout()
                : _TakerFormDesktopLayout();
      },
    );
  }
}

class _TakerFormDesktopLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // We want to place form in the middle of the screen,
        // and orderbook, when shown, should be on the right side
        // (leaving the form in the middle)
        const Expanded(flex: 3, child: SizedBox.shrink()),
        Flexible(
          flex: 6,
          child: DexScrollbar(
            scrollController: scrollController,
            isMobile: isMobile,
            child: SingleChildScrollView(
              key: const Key('taker-form-layout-scroll'),
              controller: scrollController,
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(maxWidth: theme.custom.dexFormWidth),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const TakerFormContent(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 52, 16, 0),
                      child: TakerSellCoinsTable(),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 167, 16, 0),
                      child: TakerOrdersTable(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: SingleChildScrollView(
                controller: ScrollController(), child: const TakerOrderbook()),
          ),
        )
      ],
    );
  }
}

class _TakerFormMobileLayout extends StatelessWidget {
  const _TakerFormMobileLayout();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: ScrollController(),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: theme.custom.dexFormWidth),
        child: Stack(
          children: [
            const Column(
              children: [
                TakerFormContent(),
                SizedBox(height: 22),
                TakerOrderbook(),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 52, 16, 0),
              child: TakerSellCoinsTable(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 167, 16, 0),
              child: TakerOrdersTable(),
            ),
          ],
        ),
      ),
    );
  }
}
