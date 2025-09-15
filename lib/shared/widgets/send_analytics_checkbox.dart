import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/analytics/analytics_bloc.dart';
import 'package:web_dex/bloc/analytics/analytics_event.dart';
import 'package:web_dex/bloc/analytics/analytics_state.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

class SendAnalyticsCheckbox extends StatelessWidget {
  const SendAnalyticsCheckbox({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AnalyticsBloc, AnalyticsState, bool>(
      selector: (state) {
        return state.isSendDataAllowed;
      },
      builder: (context, isAllowed) {
        final AnalyticsBloc analyticsBloc = context.read<AnalyticsBloc>();
        return Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            UiSwitcher(
              key: const Key('send-analytics-switcher'),
              value: isAllowed,
              onChanged: (bool? isChecked) {
                final bool checked = isChecked ?? false;
                if (checked) {
                  analyticsBloc.add(const AnalyticsActivateEvent());
                } else {
                  analyticsBloc.add(const AnalyticsDeactivateEvent());
                }
              },
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Text(
                  LocaleKeys.sendToAnalytics.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
