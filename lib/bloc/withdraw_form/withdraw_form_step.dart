import 'package:web_dex/localization/app_localizations.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

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
