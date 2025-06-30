import 'package:app_theme/app_theme.dart';
import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/nft_withdraw/nft_withdraw_bloc.dart';
import 'package:web_dex/bloc/withdraw_form/withdraw_form_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/model/nft.dart';

class NftWithdrawForm extends StatelessWidget {
  const NftWithdrawForm({
    super.key,
    required this.state,
  });

  final NftWithdrawFillState state;

  @override
  Widget build(BuildContext context) {
    final sendError = state.sendError;
    final addressError = state.addressError;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.nft.contractType == NftContractType.erc1155)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                  flex: 7,
                  child: _AddressField(
                    address: state.address,
                    textInputAction: TextInputAction.next,
                    error: addressError,
                  )),
              Flexible(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: _AmountField(
                    amount: state.amount,
                    error: state.amountError,
                    isEnabled:
                        state.nft.contractType == NftContractType.erc1155,
                  ),
                ),
              ),
            ],
          )
        else
          _AddressField(
            address: state.address,
            error: addressError,
            textInputAction: TextInputAction.done,
          ),
        if (addressError is MixedCaseAddressError)
          Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: _MixedAddressError(
                error: addressError,
              )),
        if (sendError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 40),
              child: SingleChildScrollView(
                child: SelectableText(
                  sendError.message,
                  style: Theme.of(context).inputDecorationTheme.errorStyle,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AddressField extends StatefulWidget {
  const _AddressField({
    required this.address,
    required this.textInputAction,
    required this.error,
  });
  final String address;
  final TextInputAction textInputAction;
  final BaseError? error;

  @override
  State<_AddressField> createState() => __AddressFieldState();
}

class __AddressFieldState extends State<_AddressField> {
  final TextEditingController _addressController = TextEditingController();
  TextSelection _previousTextSelection =
      const TextSelection.collapsed(offset: 0);
  @override
  Widget build(BuildContext context) {
    InputBorder? errorBorder;
    TextStyle? errorStyle;
    final error = widget.error;

    if (error != null) {
      final theme = Theme.of(context);

      errorBorder = theme.inputDecorationTheme.errorBorder;
      errorStyle = theme.inputDecorationTheme.errorStyle;
    }
    _addressController
      ..text = widget.address
      ..selection = _previousTextSelection;

    return UiTextFormField(
      controller: _addressController,
      autocorrect: false,
      autofocus: true,
      textInputAction: widget.textInputAction,
      enableInteractiveSelection: true,
      onChanged: (_) {
        _previousTextSelection = _addressController.selection;
        context
            .read<NftWithdrawBloc>()
            .add(NftWithdrawAddressChanged(_addressController.text));
      },
      validationMode: InputValidationMode.aggressive,
      inputFormatters: [LengthLimitingTextInputFormatter(256)],
      hintText: LocaleKeys.recipientAddress.tr(),
      hintTextStyle: errorStyle,
      labelStyle: errorStyle,
      errorStyle: errorStyle,
      style: errorStyle,
      enabledBorder: errorBorder,
      focusedBorder: errorBorder,
      validator: (_) => error is MixedCaseAddressError ? null : error?.message,
      errorMaxLines: 2,
    );
  }
}

class _AmountField extends StatefulWidget {
  const _AmountField({
    required this.amount,
    required this.error,
    required this.isEnabled,
  });
  final int? amount;
  final bool isEnabled;
  final BaseError? error;

  @override
  State<_AmountField> createState() => __AmountFieldState();
}

class __AmountFieldState extends State<_AmountField> {
  final TextEditingController _amountController = TextEditingController();
  TextSelection _previousTextSelection =
      const TextSelection.collapsed(offset: 0);

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.isEnabled;
    final int? amount = widget.amount;
    final error = widget.error;

    InputBorder? errorBorder;
    TextStyle? errorStyle;

    if (error != null) {
      final theme = Theme.of(context);

      errorBorder = theme.inputDecorationTheme.errorBorder;
      errorStyle = theme.inputDecorationTheme.errorStyle;
    }
    _amountController
      ..text = amount?.toString() ?? ''
      ..selection = _previousTextSelection;

    return UiTextFormField(
      enabled: isEnabled,
      controller: _amountController,
      validationMode: InputValidationMode.aggressive,
      onChanged: (_) {
        _previousTextSelection = _amountController.selection;

        context.read<NftWithdrawBloc>().add(
            NftWithdrawAmountChanged(int.tryParse(_amountController.text)));
      },
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^[0-9]+$'))],
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      hintText: LocaleKeys.amount.tr(),
      hintTextStyle: errorStyle,
      labelStyle: errorStyle,
      errorStyle: errorStyle,
      style: errorStyle,
      enabledBorder: errorBorder,
      focusedBorder: errorBorder,
      validator: (_) => widget.error?.message,
    );
  }
}

class _MixedAddressError extends StatelessWidget {
  const _MixedAddressError({required this.error});
  final MixedCaseAddressError error;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).extension<TextThemeExtension>()!;
    final colorScheme = Theme.of(context).extension<ColorSchemeExtension>()!;
    return Row(
      children: [
        Flexible(
          child: SelectableText(
            error.message,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 6.0),
          child: UiPrimaryButton(
            text: LocaleKeys.convert.tr(),
            width: 80,
            height: 30,
            textStyle: textTheme.bodyXSBold.copyWith(color: colorScheme.surf),
            onPressed: () => context
                .read<NftWithdrawBloc>()
                .add(const NftWithdrawConvertAddress()),
          ),
        ),
      ],
    );
  }
}
