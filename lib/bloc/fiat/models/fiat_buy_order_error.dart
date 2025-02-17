import 'package:equatable/equatable.dart';
import 'package:web_dex/shared/utils/utils.dart';

class FiatBuyOrderError extends Equatable {
  const FiatBuyOrderError({
    required this.code,
    required this.status,
    required this.title,
  });

  factory FiatBuyOrderError.fromJson(Map<String, dynamic> json) {
    return FiatBuyOrderError(
      code: assertInt(json['code']) ?? 0,
      status: assertInt(json['status']) ?? 0,
      title: json['title'] as String? ?? '',
    );
  }

  const FiatBuyOrderError.none() : this(code: 0, status: 0, title: '');

  bool get isNone => this == const FiatBuyOrderError.none();

  final int code;
  final int status;
  final String title;

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'status': status,
      'title': title,
    };
  }

  @override
  List<Object> get props => [code, status, title];
}
