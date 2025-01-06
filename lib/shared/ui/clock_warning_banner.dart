import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/system_health/system_health_bloc.dart';
import 'package:web_dex/bloc/system_health/system_health_state.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:easy_localization/easy_localization.dart';

class ClockWarningBanner extends StatelessWidget {
  const ClockWarningBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SystemHealthBloc, SystemHealthState>(
      builder: (context, systemHealthState) {
        if (systemHealthState is SystemHealthLoadSuccess &&
            !systemHealthState.isValid &&
            !kIsWalletOnly) {
          return _buildWarningBanner();
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              LocaleKeys.systemTimeWarning.tr(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
