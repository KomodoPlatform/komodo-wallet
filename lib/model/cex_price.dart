import 'package:komodo_cex_market_data/komodo_cex_market_data.dart'
    as sdk_types;

typedef CexDataProvider = sdk_types.CexDataProvider;

CexDataProvider cexDataProvider(String string) {
  return CexDataProvider.values.firstWhere(
      (e) => e.toString().split('.').last == string,
      orElse: () => CexDataProvider.unknown);
}

typedef CexPrice = sdk_types.CexPrice;
