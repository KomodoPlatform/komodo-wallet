import 'package:komodo_wallet/mm2/mm2_api/rpc/base.dart';

class TextError implements BaseError {
  TextError({required this.error});
  static TextError empty() {
    return TextError(error: '');
  }

  static TextError? fromString(String? text) {
    if (text == null) return null;

    return TextError(error: text);
  }

  static const String type = 'TextError';
  final String error;

  @override
  String get message => error;
}
