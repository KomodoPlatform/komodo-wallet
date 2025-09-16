import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/bridge_form/bridge_bloc.dart';
import 'package:web_dex/bloc/bridge_form/bridge_event.dart';
import 'package:web_dex/bloc/bridge_form/bridge_state.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/utils/extensions/string_extensions.dart';
import 'package:web_dex/views/bridge/pick_item.dart';

const double bridgeTickerSelectWidthCollapsed = 162;
const double bridgeTickerSelectWidthExpanded = 300;

class BridgeTickerSelector extends StatelessWidget {
  const BridgeTickerSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BridgeBloc, BridgeState>(
      buildWhen: (prev, cur) {
        return prev.showTickerDropdown != cur.showTickerDropdown ||
            prev.selectedTicker != cur.selectedTicker;
      },
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              width: 1,
              color: state.showTickerDropdown
                  ? theme.custom.noColor
                  : theme.currentGlobal.colorScheme.primary,
            ),
          ),
          child: SizedBox(
            height: 42,
            width: state.showTickerDropdown
                ? bridgeTickerSelectWidthExpanded
                : bridgeTickerSelectWidthCollapsed,
            child: _SelectedTickerTile(
              title: LocaleKeys.token.tr().toCapitalize(),
              ticker: state.selectedTicker,
              onTap: () => _toggleTickerDropdown(context),
              expanded: state.showTickerDropdown,
            ),
          ),
        );
      },
    );
  }

  void _toggleTickerDropdown(BuildContext context) {
    final BridgeBloc bridgeBloc = context.read<BridgeBloc>();
    final bridgeState = bridgeBloc.state;

    bridgeBloc.add(BridgeShowTickerDropdown(!bridgeState.showTickerDropdown));
  }
}

class _SelectedTickerTile extends StatelessWidget {
  const _SelectedTickerTile({
    Key? key,
    required this.ticker,
    required this.onTap,
    required this.title,
    required this.expanded,
  }) : super(key: key);

  final String? ticker;
  final String title;
  final Function() onTap;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return ticker == null
        ? PickItem(
            title: title,
            onTap: onTap,
          )
        : Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              hoverColor: theme.custom.noColor,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(7, 7, 5, 7),
                child: Row(
                  children: [
                    Container(
                      height: 30,
                      width: 30,
                      alignment: const Alignment(0, 0),
                      decoration: BoxDecoration(
                          color: themeData.cardColor,
                          borderRadius: BorderRadius.circular(15)),
                      child: AssetIcon.ofTicker(
                        ticker!,
                        size: 26,
                      ),
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    Expanded(
                      child: AutoScrollText(
                        text: ticker!,
                        style: themeData.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                    ),
                    Icon(expanded ? Icons.expand_less : Icons.expand_more,
                        color: Theme.of(context).textTheme.bodyMedium?.color)
                  ],
                ),
              ),
            ),
          );
  }
}
