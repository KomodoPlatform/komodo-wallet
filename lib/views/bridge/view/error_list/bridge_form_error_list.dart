import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/bridge_form/bridge_bloc.dart';
import 'package:web_dex/bloc/bridge_form/bridge_state.dart';
import 'package:web_dex/model/dex_form_error.dart';
import 'package:web_dex/views/dex/simple/form/error_list/dex_form_error_simple.dart';
import 'package:web_dex/views/dex/simple/form/error_list/dex_form_error_with_action.dart';

class BridgeFormErrorList extends StatefulWidget {
  const BridgeFormErrorList({Key? key}) : super(key: key);

  @override
  State<BridgeFormErrorList> createState() => _BridgeFormErrorListState();
}

class _BridgeFormErrorListState extends State<BridgeFormErrorList> {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<BridgeBloc, BridgeState, DexFormError?>(
      selector: (state) => state.error,
      builder: (context, error) {
        if (error == null) return const SizedBox();

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: theme.custom.dexFormWidth),
          child: Container(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _errorBuilder(error),
            ),
          ),
        );
      },
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
