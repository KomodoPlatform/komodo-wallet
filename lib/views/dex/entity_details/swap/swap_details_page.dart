import 'dart:convert';
import 'dart:math';

import 'package:app_theme/app_theme.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/swap.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/mm2/mm2_api/rpc/my_swap_status/my_swap_status_req.dart';
import 'package:web_dex/services/file_loader/file_loader.dart';
import 'package:web_dex/views/dex/entity_details/swap/swap_details.dart';
import 'package:web_dex/views/dex/entity_details/trading_details_header.dart';
import 'package:web_dex/views/dex/entity_details/trading_progress_status.dart';

class SwapDetailsPage extends StatefulWidget {
  const SwapDetailsPage(this.swapStatus, {Key? key}) : super(key: key);

  final Swap swapStatus;

  @override
  State<SwapDetailsPage> createState() => _SwapDetailsPageState();
}

class _SwapDetailsPageState extends State<SwapDetailsPage> {
  bool _isExporting = false;

  Future<void> _exportSwapData() async {
    setState(() => _isExporting = true);
    try {
      final mm2Api = RepositoryProvider.of<Mm2Api>(context);
      final response =
          await mm2Api.getSwapStatus(MySwapStatusReq(uuid: widget.swapStatus.uuid));
      final jsonStr = jsonEncode(response);
      await FileLoader.fromPlatform().save(
        fileName: 'swap_${widget.swapStatus.uuid}.json',
        data: jsonStr,
        type: LoadFileType.text,
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TradingDetailsHeader(title: _headerText),
        SwapProgressStatus(progress: _progress, isFailed: _isFailed),
        SwapDetails(swapStatus: widget.swapStatus, isFailed: _isFailed),
        const SizedBox(height: 20),
        UiBorderButton(
          width: 160,
          height: 32,
          borderWidth: 1,
          borderColor: theme.custom.specificButtonBorderColor,
          backgroundColor: theme.custom.specificButtonBackgroundColor,
          fontWeight: FontWeight.w500,
          text: 'Export swap data',
          icon: _isExporting
              ? const UiSpinner()
              : Icon(
                  Icons.file_download,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  size: 18,
                ),
          onPressed: _isExporting ? null : _exportSwapData,
        ),
      ],
    );
  }

  String get _headerText {
    if (_isFailed) return LocaleKeys.tradingDetailsTitleFailed.tr();
    final haveEvents = widget.swapStatus.events.isNotEmpty;
    if (haveEvents) {
      final isSuccess = widget.swapStatus.events.last.event.type ==
          widget.swapStatus.successEvents.last;
      if (isSuccess) return LocaleKeys.tradingDetailsTitleCompleted.tr();
      return LocaleKeys.tradingDetailsTitleInProgress.tr();
    }
    return LocaleKeys.tradingDetailsTitleOrderMatching.tr();
  }

  bool get _isFailed {
    return widget.swapStatus.events.firstWhereOrNull(
        (event) =>
            widget.swapStatus.errorEvents.contains(event.event.type)) !=
        null;
  }

  int get _progress {
    return min(
        100,
        (100 *
                widget.swapStatus.events.length /
                (widget.swapStatus.successEvents.length - 1))
            .ceil());
  }
}
