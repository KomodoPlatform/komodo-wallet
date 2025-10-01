import 'package:flutter/material.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/views/dex/common/front_plate.dart';
import 'package:web_dex/views/dex/simple/form/tables/coins_table/coins_table_content.dart';
import 'package:web_dex/views/dex/simple/form/tables/table_search_field.dart';

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
  late final Debouncer _searchDebouncer;

  @override
  void initState() {
    super.initState();
    _searchDebouncer = Debouncer(duration: const Duration(milliseconds: 200));
  }

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
                  final nextValue = value;
                  _searchDebouncer.run(() {
                    if (!mounted) return;
                    if (_searchTerm == nextValue) return;
                    setState(() => _searchTerm = nextValue);
                  });
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

  @override
  void dispose() {
    _searchDebouncer.dispose();
    super.dispose();
  }
}
