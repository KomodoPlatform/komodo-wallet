import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

class TableSearchField extends StatelessWidget {
  const TableSearchField({Key? key, required this.onChanged, this.height = 44})
      : super(key: key);
  final Function(String) onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final style =
        Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12);

    return SizedBox(
      height: height,
      child: TextField(
        key: const Key('search-field'),
        onChanged: onChanged,
        autofocus: isDesktop,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          hintText: LocaleKeys.searchCoin.tr(),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(height * 0.5),
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 12,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        style: style,
      ),
    );
  }
}
