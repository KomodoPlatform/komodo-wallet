import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/withdraw_form/withdraw_form_bloc.dart';
import '../helpers/analytics_helper.dart';

class WithdrawFormListeners {
  static List<BlocListener> getListeners() {
    return [
      _buildSuccessListener(),
      _buildFailureListener(),
    ];
  }

  static BlocListener<WithdrawFormBloc, WithdrawFormState> _buildSuccessListener() {
    return BlocListener<WithdrawFormBloc, WithdrawFormState>(
      listenWhen: (prev, curr) =>
          prev.step != curr.step && curr.step == WithdrawFormStep.success,
      listener: (context, state) {
        AnalyticsHelper.logSendSucceeded(context, state);
      },
    );
  }

  static BlocListener<WithdrawFormBloc, WithdrawFormState> _buildFailureListener() {
    return BlocListener<WithdrawFormBloc, WithdrawFormState>(
      listenWhen: (prev, curr) =>
          prev.step != curr.step && curr.step == WithdrawFormStep.failed,
      listener: (context, state) {
        AnalyticsHelper.logSendFailed(context, state);
      },
    );
  }
}