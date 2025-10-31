import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/router/state/routing_state.dart';
import 'package:web_dex/model/main_menu_value.dart';

class BridgeNothingFound extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 30, 0, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
              Text(
                LocaleKeys.bridgeNoCrossNetworkRoutes.tr(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          UiSimpleButton(
            onPressed: () {
              routingState.selectedMenu = MainMenuValue.dex;
              routingState.dexState.orderType = 'maker';
            },
            child: Text(
              LocaleKeys.makerOrder.tr(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
