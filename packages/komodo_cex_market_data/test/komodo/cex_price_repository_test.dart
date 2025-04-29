import 'package:komodo_cex_market_data/src/komodo/prices/komodo_price_provider.dart';
import 'package:komodo_cex_market_data/src/komodo/prices/komodo_price_repository.dart';
import 'package:test/test.dart';

void main() {
  late KomodoPriceRepository cexPriceRepository;
  setUp(() {
    cexPriceRepository =
        KomodoPriceRepository(cexPriceProvider: KomodoPriceProvider());
  });

  group('getPrices', () {
    test('should return Komodo fiat rates list', () async {
      // Arrange

      // Act
      final result = await cexPriceRepository.getKomodoPrices();

      // Assert
      expect(result.length, greaterThan(0));
      expect(result.keys, contains('KMD'));
    });
  });
}
