import 'package:flutter/material.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_wallet/views/dex/common/front_plate.dart';
import 'package:komodo_wallet/views/dex/simple/form/tables/coins_table/coins_table_content.dart';
import 'package:komodo_wallet/views/dex/simple/form/tables/table_search_field.dart';

class CoinsTable extends StatefulWidget {
  const CoinsTable({
    required this.onSelect,
    this.maxHeight = 300,
    this.head,
    Key? key,
  }) : super(key: key);

  final Function(Coin) onSelect;
  final Widget? head;
  final double maxHeight;

  @override
  State<CoinsTable> createState() => _CoinsTableState();
}

class _CoinsTableState extends State<CoinsTable> {
  String? _searchTerm;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      child: FrontPlate(
        shadowEnabled: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.head != null) widget.head!,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TableSearchField(
                height: 30,
                onChanged: (String value) {
                  if (_searchTerm == value) return;
                  setState(() => _searchTerm = value);
                },
              ),
            ),
            const SizedBox(height: 5),
            CoinsTableContent(
              onSelect: widget.onSelect,
              searchString: _searchTerm,
              maxHeight: widget.maxHeight,
            ),
          ],
        ),
      ),
    );
  }
}
