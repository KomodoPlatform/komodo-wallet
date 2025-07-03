import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/analytics/analytics_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/analytics/events/transaction_events.dart';
import 'package:web_dex/bloc/withdraw_form/withdraw_form_bloc.dart';
import 'package:web_dex/model/wallet.dart';

class AnalyticsHelper {
  static void logSendSucceeded(BuildContext context, WithdrawFormState state) {
    final walletType = _getWalletType(context);
    
    context.read<AnalyticsBloc>().logEvent(
      SendSucceededEventData(
        assetSymbol: state.asset.id.id,
        network: state.asset.id.subClass.name,
        amount: double.tryParse(state.amount) ?? 0.0,
        walletType: walletType,
      ),
    );
  }

  static void logSendFailed(BuildContext context, WithdrawFormState state) {
    final walletType = _getWalletType(context);
    final reason = state.transactionError?.message ?? 'unknown';
    
    context.read<AnalyticsBloc>().logEvent(
      SendFailedEventData(
        assetSymbol: state.asset.id.id,
        network: state.asset.protocol.subClass.name,
        failReason: reason,
        walletType: walletType,
      ),
    );
  }

  static void logSendInitiated(BuildContext context, WithdrawFormState state) {
    final walletType = _getWalletType(context);
    
    context.read<AnalyticsBloc>().logEvent(
      SendInitiatedEventData(
        assetSymbol: state.asset.id.id,
        network: state.asset.protocol.subClass.name,
        amount: double.tryParse(state.amount) ?? 0.0,
        walletType: walletType,
      ),
    );
  }

  static String _getWalletType(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    return authBloc.state.currentUser?.wallet.config.type.name ?? '';
  }
}