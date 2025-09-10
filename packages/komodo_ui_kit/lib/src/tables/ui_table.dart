import 'package:flutter/material.dart';

class UiTable extends StatelessWidget {
  const UiTable({
    Key? key,
    required this.columns,
    required this.rows,
    this.headerColor,
    this.rowColor,
    this.padding = const EdgeInsets.all(20),
    this.cellPadding = const EdgeInsets.all(8),
    this.headerAlignment = Alignment.center,
    this.cellAlignment = Alignment.center,
    this.headingBorder,
    this.rowBorder,
  }) : super(key: key);

  final List<Widget> columns;
  final List<List<Widget>> rows;
  final Color? headerColor;
  final Color? rowColor;
  final EdgeInsets cellPadding;
  final EdgeInsets padding;
  final Alignment headerAlignment;
  final Alignment cellAlignment;
  final Border? headingBorder;
  final Border? rowBorder;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: Table(
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: headerColor,
                border: Border(
                  bottom: BorderSide(
                    // TODO(Francois): change to theme colour
                    color: Theme.of(context).colorScheme.primary,
                    width: 2.0,
                  ), // Adjust color and width as needed
                ),
              ),
              children: columns
                  .map(
                    (column) => TableCell(
                      child: Padding(
                        padding: cellPadding,
                        child: Align(alignment: headerAlignment, child: column),
                      ),
                    ),
                  )
                  .toList(),
            ),
            ...rows.map(
              (row) => TableRow(
                decoration: BoxDecoration(color: rowColor),
                children: row
                    .map(
                      (cell) => TableCell(
                        child: Padding(
                          padding: cellPadding,
                          child: Align(alignment: cellAlignment, child: cell),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
