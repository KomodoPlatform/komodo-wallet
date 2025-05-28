import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/trading_kind/trading_kind_bloc.dart';
import 'package:web_dex/views/dex/simple/form/maker/maker_form_layout.dart';
import 'package:web_dex/views/dex/simple/form/taker/taker_form.dart';

/// Unified swap form that combines maker and taker workflows.
///
/// The widget displays a switcher allowing users to toggle
/// between "Swap Now" (taker) and "Create Order" (maker) modes.
/// The initial mode is derived from [TradingKindBloc].
class UnifiedSwapForm extends StatefulWidget {
  const UnifiedSwapForm({super.key});

  @override
  State<UnifiedSwapForm> createState() => _UnifiedSwapFormState();
}

class _UnifiedSwapFormState extends State<UnifiedSwapForm> {
  late bool _isTaker;

  @override
  void initState() {
    super.initState();
    final kind = context.read<TradingKindBloc>().state.kind;
    _isTaker = kind == TradingKind.taker;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_isTaker ? 'Swap Now' : 'Create Order'),
            const SizedBox(width: 8),
            UiSwitcher(
              value: _isTaker,
              onChanged: (val) => setState(() => _isTaker = val),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Use IndexedStack to keep state of inner forms
        IndexedStack(
          index: _isTaker ? 0 : 1,
          children: const [TakerForm(), MakerFormLayout()],
        ),
      ],
    );
  }
}
