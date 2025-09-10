import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

class WalletManagerSearchField extends StatefulWidget {
  const WalletManagerSearchField({required this.onChange});
  final Function(String) onChange;

  @override
  State<WalletManagerSearchField> createState() =>
      _WalletManagerSearchFieldState();
}

class _WalletManagerSearchFieldState extends State<WalletManagerSearchField> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    _searchController.addListener(_onChange);
    super.initState();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const Key('wallet-page-search-field'),
      controller: _searchController,
      focusNode: _focusNode,
      autocorrect: false,
      textInputAction: TextInputAction.none,
      enableInteractiveSelection: true,
      inputFormatters: [LengthLimitingTextInputFormatter(40)],
      decoration: InputDecoration(
        filled: true,
        hintText: LocaleKeys.search.tr(),
        prefixIcon: Icon(Icons.search, size: 20),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _onChange() {
    widget.onChange(_searchController.text.trim());
  }
}
