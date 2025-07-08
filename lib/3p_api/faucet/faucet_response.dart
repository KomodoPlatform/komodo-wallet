import 'package:web_dex/localization/app_localizations.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/utils/extensions/string_extensions.dart';

enum FaucetStatus {
  success,
  denied,
  error,
  loading;

  static FaucetStatus byNameOrError(String name) {
    final isContains = FaucetStatus.values.map((e) => e.name).contains(name);
    if (isContains) {
      return FaucetStatus.values.byName(name);
    }
    return FaucetStatus.error;
  }

  String get title => name.toCapitalize();
}

class FaucetResponse {
  FaucetResponse({
    required this.status,
    required this.address,
    required this.message,
    required this.coin,
  });

  factory FaucetResponse.fromJson(Map<String, dynamic> json) {
    final result = json["result"];
    final status = FaucetStatus.byNameOrError(json["status"]);

    if (result != null && result is Map<String, dynamic>) {
      return FaucetResponse(
        status: status,
        message: result["message"] ?? '',
        address: result["address"] ?? '',
        coin: result["coin"] ?? '',
      );
    } else {
      return FaucetResponse.error(LocaleKeys.faucetUnknownErrorMessage.tr());
    }
  }

  factory FaucetResponse.error(String errorMessage) {
    return FaucetResponse(
      status: FaucetStatus.error,
      message: errorMessage,
      address: '',
      coin: '',
    );
  }

  final FaucetStatus status;
  final String message;
  final String coin;
  final String address;
}
