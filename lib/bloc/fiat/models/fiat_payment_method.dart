import 'package:equatable/equatable.dart';
import 'package:decimal/decimal.dart';
import 'package:web_dex/bloc/fiat/models/fiat_price_info.dart';
import 'package:web_dex/bloc/fiat/models/fiat_transaction_fee.dart';
import 'package:web_dex/bloc/fiat/models/fiat_transaction_limit.dart';
import 'package:web_dex/shared/utils/utils.dart';

class FiatPaymentMethod extends Equatable {
  const FiatPaymentMethod({
    required this.providerId,
    required this.id,
    required this.name,
    required this.priceInfo,
    required this.relativePercent,
    required this.providerIconAssetPath,
    required this.transactionLimits,
    required this.transactionFees,
  });

  static final none = FiatPaymentMethod(
    providerId: 'none',
    id: '',
    name: '',
    priceInfo: FiatPriceInfo.zero,
    relativePercent: Decimal.zero,
    providerIconAssetPath: '',
    transactionLimits: const [],
    transactionFees: const [],
  );

  factory FiatPaymentMethod.fromJson(Map<String, dynamic> json) {
    final limitsJson = json['transaction_limits'] as List<dynamic>? ?? [];
    final List<FiatTransactionLimit> limits = limitsJson
        .map(
          (e) =>
              FiatTransactionLimit.fromJson(e as Map<String, dynamic>? ?? {}),
        )
        .toList();

    final feesJson = json['transaction_fees'] as List<dynamic>? ?? [];
    final List<FiatTransactionFee> fees = feesJson
        .map(
          (e) => FiatTransactionFee.fromJson(e as Map<String, dynamic>? ?? {}),
        )
        .toList();

    return FiatPaymentMethod(
      providerId: json['provider_id'] as String? ?? '',
      id: assertString(json['id']) ?? '',
      name: json['name'] as String? ?? '',
      priceInfo: FiatPriceInfo.fromJson(
        json['price_info'] as Map<String, dynamic>? ?? {},
      ),
      relativePercent:
          Decimal.parse(json['relative_percent'] as String? ?? '0'),
      providerIconAssetPath: json['provider_icon_asset_path'] as String? ?? '',
      transactionLimits: limits,
      transactionFees: fees,
    );
  }

  final String providerId;
  final String id;
  final String name;
  final FiatPriceInfo priceInfo;
  final Decimal relativePercent;
  final String providerIconAssetPath;
  final List<FiatTransactionLimit> transactionLimits;
  final List<FiatTransactionFee> transactionFees;

  bool get isNone => providerId == 'none';

  FiatPaymentMethod copyWith({
    String? providerId,
    String? id,
    String? name,
    FiatPriceInfo? priceInfo,
    Decimal? relativePercent,
    String? providerIconAssetPath,
    List<FiatTransactionLimit>? transactionLimits,
    List<FiatTransactionFee>? transactionFees,
  }) {
    return FiatPaymentMethod(
      providerId: providerId ?? this.providerId,
      id: id ?? this.id,
      name: name ?? this.name,
      priceInfo: priceInfo ?? this.priceInfo,
      relativePercent: relativePercent ?? this.relativePercent,
      providerIconAssetPath:
          providerIconAssetPath ?? this.providerIconAssetPath,
      transactionLimits: transactionLimits ?? this.transactionLimits,
      transactionFees: transactionFees ?? this.transactionFees,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider_id': providerId,
      'id': id,
      'name': name,
      'price_info': priceInfo.toJson(),
      'relative_percent': relativePercent.toString(),
      'provider_icon_asset_path': providerIconAssetPath,
      'transaction_limits': transactionLimits.map((e) => e.toJson()).toList(),
      'transaction_fees': transactionFees.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        providerId,
        id,
        name,
        priceInfo,
        relativePercent,
        providerIconAssetPath,
        transactionLimits,
        transactionFees,
      ];
}

List<FiatPaymentMethod> defaultFiatPaymentMethods = [
  // Ramp API keys unavailable for the time being
  // TODO(takenagain): re-enable when API keys are available
  // FiatPaymentMethod(
  //   id: 'CARD_PAYMENT',
  //   name: 'Card Payment',
  //   providerId: 'Ramp',
  //   priceInfo: FiatPriceInfo.zero,
  //   relativePercent: Decimal.zero,
  //   providerIconAssetPath: 'assets/fiat/providers/ramp_icon.svg',
  //   transactionLimits: const [],
  //   transactionFees: const [],
  // ),
  // FiatPaymentMethod(
  //   id: 'APPLE_PAY',
  //   name: 'Apple Pay',
  //   providerId: 'Ramp',
  //   priceInfo: FiatPriceInfo.zero,
  //   relativePercent: Decimal.parse('-0.04126038522159592'),
  //   providerIconAssetPath: 'assets/fiat/providers/ramp_icon.svg',
  //   transactionLimits: const [],
  //   transactionFees: const [],
  // ),
  FiatPaymentMethod(
    id: '7554',
    name: 'Visa/Mastercard',
    providerId: 'Banxa',
    priceInfo: FiatPriceInfo.zero,
    relativePercent: Decimal.parse('-0.017942476775854282'),
    providerIconAssetPath: 'assets/fiat/providers/banxa_icon.svg',
    transactionLimits: const [],
    transactionFees: const [],
  ),
];
