import 'dart:convert';

import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/mm2/mm2_api/rpc/my_recent_swaps/my_recent_swaps_request.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

class ShowSwapData extends StatefulWidget {
  const ShowSwapData({Key? key}) : super(key: key);

  @override
  State<ShowSwapData> createState() => _ShowSwapDataState();
}

class _ShowSwapDataState extends State<ShowSwapData> {
  final TextEditingController _controller = TextEditingController();
  bool _showData = false;
  bool _inProgress = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSwitcherButton(),
        if (_showData) ...{const SizedBox(height: 20), _buildData()},
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSwitcherButton() {
    return UiBorderButton(
      width: 160,
      height: 32,
      borderWidth: 1,
      borderColor: theme.custom.specificButtonBorderColor,
      backgroundColor: theme.custom.specificButtonBackgroundColor,
      fontWeight: FontWeight.w500,
      text: LocaleKeys.showSwapData.tr(),
      suffix: Icon(
        _showData ? Icons.arrow_drop_up : Icons.arrow_drop_down,
        size: 14,
      ),
      onPressed: _inProgress
          ? null
          : () {
              if (_showData) {
                setState(() => _showData = false);
              } else {
                _getSwapData();
              }
            },
    );
  }

  Widget _buildData() {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Flexible(
          child: TextField(
            controller: _controller,
            maxLines: 10,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          child: IconButton(
            onPressed: () => copyToClipBoard(context, _controller.text),
            icon: const Icon(Icons.copy),
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Future<void> _getSwapData() async {
    setState(() => _inProgress = true);

    try {
      final mm2Api = RepositoryProvider.of<Mm2Api>(context);
      final response = await mm2Api.getRawSwapData(MyRecentSwapsRequest());
      final Map<String, dynamic> data = jsonDecode(response);
      _controller.text = jsonEncode(data['result']['swaps']).toString();
    } catch (e) {
      _controller.text = e.toString();
    }

    setState(() {
      _showData = true;
      _inProgress = false;
    });
  }
}
