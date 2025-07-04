import 'package:uuid/uuid.dart';
import 'package:komodo_wallet/model/text_error.dart';
import 'package:komodo_wallet/views/dex/simple/form/error_list/dex_form_error_with_action.dart';

class DexFormError implements TextError {
  DexFormError({
    required this.error,
    this.type = DexFormErrorType.simple,
    this.isWarning = false,
    this.action,
  }) : id = const Uuid().v4();

  final DexFormErrorType type;
  final bool isWarning;
  final String id;
  final DexFormErrorAction? action;

  @override
  final String error;

  @override
  String get message => error;
}

enum DexFormErrorType {
  simple,
  largerMaxSellVolume,
  largerMaxBuyVolume,
  lessMinVolume,
}
