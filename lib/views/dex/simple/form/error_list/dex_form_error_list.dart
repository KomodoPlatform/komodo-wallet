import 'package:flutter/material.dart';
import 'package:web_dex/model/dex_form_error.dart';
import 'package:web_dex/views/dex/simple/form/error_list/dex_form_error_simple.dart';
import 'package:web_dex/views/dex/simple/form/error_list/dex_form_error_with_action.dart';

class DexFormErrorList extends StatefulWidget {
  const DexFormErrorList({required this.errors, Key? key}) : super(key: key);

  final List<DexFormError> errors;

  @override
  State<DexFormErrorList> createState() => _DexFormErrorListState();
}

class _DexFormErrorListState extends State<DexFormErrorList> {
  @override
  Widget build(BuildContext context) {
    final List<DexFormError> errorList = widget.errors;
    if (errorList.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      child: Column(
        children: errorList
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _errorBuilder(e),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _errorBuilder(DexFormError error) {
    switch (error.type) {
      case DexFormErrorType.simple:
        return DexFormErrorSimple(error: error);
      case DexFormErrorType.largerMaxSellVolume:
        return _buildLargerMaxSellVolumeError(error);
      case DexFormErrorType.largerMaxBuyVolume:
        return _buildLargerMaxBuyVolumeError(error);
      case DexFormErrorType.lessMinVolume:
        return _buildLessMinVolumeError(error);
    }
  }

  Widget _buildLargerMaxSellVolumeError(DexFormError error) {
    assert(error.type == DexFormErrorType.largerMaxSellVolume);
    assert(error.action != null);

    return DexFormErrorWithAction(error: error, action: error.action!);
  }

  Widget _buildLargerMaxBuyVolumeError(DexFormError error) {
    assert(error.type == DexFormErrorType.largerMaxBuyVolume);

    return DexFormErrorWithAction(error: error, action: error.action!);
  }

  Widget _buildLessMinVolumeError(DexFormError error) {
    assert(error.type == DexFormErrorType.lessMinVolume);
    assert(error.action != null);

    return DexFormErrorWithAction(error: error, action: error.action!);
  }
}
