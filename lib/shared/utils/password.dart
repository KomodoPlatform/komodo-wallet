import 'package:komodo_defi_types/komodo_defi_type_utils.dart';

/// Generates a password that meets the KDF password policy requirements using
/// the device's secure random number generator.
String generatePassword() => SecurityUtils.generatePasswordSecure(16);

/// unit tests: [testValidateRPCPassword]
bool validateRPCPassword(String src) =>
    SecurityUtils.checkPasswordRequirements(src).isValid;
