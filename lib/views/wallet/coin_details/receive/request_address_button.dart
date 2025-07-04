import 'dart:async';

import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:komodo_wallet/bloc/coins_bloc/coins_repo.dart';
import 'package:komodo_wallet/dispatchers/popup_dispatcher.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/mm2/mm2_api/rpc/trezor/get_new_address/get_new_address_response.dart';
import 'package:komodo_wallet/router/state/routing_state.dart';
import 'package:komodo_wallet/shared/ui/ui_simple_border_button.dart';
import 'package:komodo_wallet/views/wallet/coin_details/receive/trezor_new_address_confirmation.dart';

class RequestAddressButton extends StatefulWidget {
  const RequestAddressButton(
    this.asset, {
    required this.onSuccess,
    super.key,
  });

  final Asset asset;
  final void Function(PubkeyInfo) onSuccess;

  @override
  State<RequestAddressButton> createState() => _RequestAddressButtonState();
}

class _RequestAddressButtonState extends State<RequestAddressButton> {
  String? _message;
  bool _inProgress = false;
  PopupDispatcher? _confirmAddressDispatcher;

  @override
  void dispose() {
    final coinsRepository = RepositoryProvider.of<CoinsRepo>(context);
    _message = null;
    _inProgress = false;
    _confirmAddressDispatcher?.close();
    _confirmAddressDispatcher = null;
    coinsRepository.trezor.unsubscribeFromNewAddressStatus();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMessage(),
        const SizedBox(height: 10),
        _buildButton(),
      ],
    );
  }

  Widget _buildMessage() {
    final message = _message;
    if (message == null) return const SizedBox.shrink();

    return Text(
      message,
      style: theme.currentGlobal.textTheme.bodySmall,
    );
  }

  Widget _buildButton() {
    return Row(
      children: [
        UiSimpleBorderButton(
          onPressed: _inProgress ? null : _getAddress,
          child: SizedBox(
            height: 24,
            child: Row(
              children: [
                if (_inProgress)
                  const UiSpinner(width: 10, height: 10, strokeWidth: 1)
                else
                  const Icon(Icons.add, size: 16),
                const SizedBox(width: 6),
                Text(LocaleKeys.freshAddress.tr()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _getAddress() async {
    final coinsRepository = RepositoryProvider.of<CoinsRepo>(context);
    setState(() {
      _inProgress = true;
      _message = null;
    });

    final taskId = await coinsRepository.trezor.initNewAddress(widget.asset);
    if (taskId == null) return;
    routingState.isBrowserNavigationBlocked = true;
    coinsRepository.trezor
        .subscribeOnNewAddressStatus(taskId, widget.asset, _onStatusUpdate);
  }

  void _onStatusUpdate(GetNewAddressResponse initNewAddressStatus) {
    final String? error = initNewAddressStatus.error;
    if (error != null) {
      _onError(error);
      return;
    }

    final GetNewAddressStatus? status = initNewAddressStatus.result?.status;
    final GetNewAddressResultDetails? details =
        initNewAddressStatus.result?.details;

    switch (status) {
      case GetNewAddressStatus.inProgress:
        if (details is GetNewAddressResultConfirmAddressDetails) {
          _onConfirmAddressStatus(details);
        }
        return;
      case GetNewAddressStatus.ok:
        if (details is GetNewAddressResultOkDetails) {
          _onOkStatus(details);
        }
        return;
      case GetNewAddressStatus.unknown:
      case null:
        return;
    }
  }

  void _onConfirmAddressStatus(
      GetNewAddressResultConfirmAddressDetails details) {
    _confirmAddressDispatcher ??= PopupDispatcher(
      width: 360,
      barrierDismissible: false,
      popupContent:
          TrezorNewAddressConfirmation(address: details.expectedAddress),
    );
    if (!_confirmAddressDispatcher!.isShown) {
      _confirmAddressDispatcher?.show();
    }
  }

  void _onOkStatus(GetNewAddressResultOkDetails details) {
    final coinsRepository = RepositoryProvider.of<CoinsRepo>(context);
    coinsRepository.trezor.unsubscribeFromNewAddressStatus();
    _confirmAddressDispatcher?.close();
    _confirmAddressDispatcher = null;
    routingState.isBrowserNavigationBlocked = false;

    widget.onSuccess(details.newAddress.toPubkeyInfo());
    setState(() {
      _inProgress = false;
      _message = null;
    });
  }

  void _onError(String error) {
    routingState.isBrowserNavigationBlocked = false;
    setState(() {
      _inProgress = false;
      _message = error;
    });
  }
}
