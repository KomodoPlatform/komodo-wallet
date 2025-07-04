import 'package:easy_localization/easy_localization.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';

enum WithdrawFormStep {
  fill,
  confirm,
  success,
  failed;

  static WithdrawFormStep initial() => WithdrawFormStep.fill;

  String get title {
    switch (this) {
      case WithdrawFormStep.fill:
        return LocaleKeys.enterDataToSend.tr();
      case WithdrawFormStep.confirm:
        return LocaleKeys.confirmSending.tr();
      case WithdrawFormStep.success:
        return LocaleKeys.transactionComplete.tr();
      case WithdrawFormStep.failed:
        return LocaleKeys.transactionDenied.tr();
    }
  }
}
