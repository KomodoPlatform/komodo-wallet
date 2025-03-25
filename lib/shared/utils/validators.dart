import 'package:easy_localization/easy_localization.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

String? validateConfirmPassword(String password, String confirmPassword) {
  if (confirmPassword.isEmpty) {
    return LocaleKeys.walletCreationConfirmPasswordEmptyError.tr();
  } else if (password != confirmPassword) {
    return LocaleKeys.walletCreationConfirmPasswordError.tr();
  }
  return null;
}

/// unit test: [testValidatePassword]
String? validatePassword(String password, String errorText) {
  final RegExp exp =
      RegExp(r'^(?:(?=.*[a-z])(?=.*[A-Z])(?=.*[^a-zA-Z0-9\s])).{12,}$');
  return password.isEmpty || !password.contains(exp) ? errorText : null;
}
