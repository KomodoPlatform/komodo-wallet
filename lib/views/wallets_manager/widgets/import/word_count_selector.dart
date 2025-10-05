import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

class WordCountSelector extends StatelessWidget {
  const WordCountSelector({
    required this.selectedCount,
    required this.onCountChanged,
    super.key,
  });

  final int selectedCount;
  final void Function(int count) onCountChanged;

  static const List<int> validWordCounts = [12, 18, 24];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DropdownButtonFormField<int>(
      key: const Key('word-count-selector'),
      value: selectedCount,
      decoration: InputDecoration(
        labelText: LocaleKeys.importWordCountLabel.tr(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: validWordCounts.map((count) {
        return DropdownMenuItem<int>(
          value: count,
          child: Text(
            LocaleKeys.importWordCountOption.tr(args: [count.toString()]),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onCountChanged(value);
        }
      },
      icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurface),
    );
  }
}
