import 'package:flutter/material.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/model/coin.dart';

class BridgeTickersListItem extends StatelessWidget {
  const BridgeTickersListItem({
    Key? key,
    required this.coin,
    required this.onSelect,
  }) : super(key: key);

  final Coin coin;
  final Function onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      child: InkWell(
        key: Key('bridge-coin-table-item-${coin.abbr}'),
        onTap: () => onSelect(),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      height: 30,
                      width: 30,
                      alignment: const Alignment(0, 0),
                      decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(15)),
                      child: AssetIcon.ofTicker(
                        coin.abbr,
                        size: 26,
                      ),
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    Expanded(
                      child: AutoScrollText(
                        text: coin.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
