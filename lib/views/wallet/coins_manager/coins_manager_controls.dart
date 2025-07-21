import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/coins_manager/coins_manager_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/views/custom_token_import/custom_token_import_button.dart';
import 'package:web_dex/views/wallet/coins_manager/coins_manager_filters_dropdown.dart';
import 'package:web_dex/views/wallet/coins_manager/coins_manager_select_all_button.dart';

class CoinsManagerFilters extends StatelessWidget {
  const CoinsManagerFilters({Key? key, required this.isMobile})
      : super(key: key);
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchField(context),
          const SizedBox(height: 8),
          const CustomTokenImportButton(),
          Padding(
            padding: const EdgeInsets.only(top: 14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 20.0),
                  child: CoinsManagerSelectAllButton(),
                ),
                const Spacer(),
                CoinsManagerFiltersDropdown(),
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 240),
              height: 45,
              child: _buildSearchField(context),
            ),
            const SizedBox(width: 20),
            Container(
              constraints: const BoxConstraints(maxWidth: 240),
              height: 45,
              child: const CustomTokenImportButton(),
            ),
            const Spacer(),
            CoinsManagerFiltersDropdown(),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return UiTextFormField(
      key: const Key('coins-manager-search-field'),
      fillColor: isMobile
          ? theme.custom.coinsManagerTheme.searchFieldMobileBackgroundColor
          : null,
      autocorrect: false,
      autofocus: true,
      textInputAction: TextInputAction.none,
      enableInteractiveSelection: true,
      prefixIcon: const Icon(Icons.search, size: 18),
      inputFormatters: [LengthLimitingTextInputFormatter(40)],
      hintText: LocaleKeys.searchAssets.tr(),
      hintTextStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      onChanged: (String? text) => context
          .read<CoinsManagerBloc>()
          .add(CoinsManagerSearchUpdate(text: text ?? '')),
    );
  }
}
