import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

const double _hiddenSearchFieldWidth = 285;
const double _normalSearchFieldWidth = 285;

class WalletManagerSearchField extends StatefulWidget {
  const WalletManagerSearchField({required this.onChange});
  final Function(String) onChange;

  @override
  State<WalletManagerSearchField> createState() =>
      _WalletManagerSearchFieldState();
}

class _WalletManagerSearchFieldState extends State<WalletManagerSearchField> {
  double _searchFieldWidth = _normalSearchFieldWidth;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    _searchController.addListener(_onChange);
    _focusNode.addListener(_onFocusChange);
    if (isMobile) {
      _changeSearchFieldWidth(false);
    }
    super.initState();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onChange);
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      constraints: BoxConstraints.tightFor(
        width: _searchFieldWidth,
        height: isMobile ? _hiddenSearchFieldWidth : 40,
      ),
      child: TextFormField(
        key: const Key('wallet-page-search-field'),
        controller: _searchController,
        focusNode: _focusNode,
        autocorrect: false,
        textInputAction: TextInputAction.none,
        enableInteractiveSelection: true,
        inputFormatters: [LengthLimitingTextInputFormatter(40)],
        decoration: InputDecoration(
          filled: true,
          // fillColor: theme.colorScheme.surfaceContainer,
          // hintText: LocaleKeys.searchAssets.tr(),
          hintText: LocaleKeys.search.tr(),
          // hintStyle: theme.textTheme.bodyMedium?.copyWith(
          //   color: theme.colorScheme.onSurfaceVariant,
          // ),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            // color: theme.colorScheme.onSurfaceVariant,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          //   enabledBorder: OutlineInputBorder(
          //     borderRadius: BorderRadius.circular(12),
          //     borderSide: BorderSide.none,
          //   ),
          //   focusedBorder: OutlineInputBorder(
          //     borderRadius: BorderRadius.circular(12),
          //     borderSide: BorderSide.none,
          //   ),
          // ),
          // style: theme.textTheme.bodyMedium?.copyWith(
          //   color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  void _onFocusChange() {
    if (!isMobile) return;
    _changeSearchFieldWidth(_focusNode.hasFocus);
  }

  void _changeSearchFieldWidth(bool hasFocus) {
    if (hasFocus) {
      setState(() => _searchFieldWidth = _normalSearchFieldWidth);
    } else if (_searchController.text.isEmpty) {
      setState(() => _searchFieldWidth = _hiddenSearchFieldWidth);
    }
  }

  void _onChange() {
    widget.onChange(_searchController.text.trim());
  }
}
