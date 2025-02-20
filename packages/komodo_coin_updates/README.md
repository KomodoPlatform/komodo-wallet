# Komodo Coin Updater

This package provides the functionality to update the coins list and configuration files for the Komodo Platform at runtime.

## Usage

To use this package, you need to add `komodo_coin_updater` to your `pubspec.yaml` file.

```yaml
dependencies:
  komodo_coin_updater: ^1.0.0
```

### Initialize the package

Then you can use the `KomodoCoinUpdater` class to initialize the package.

```dart
import 'package:komodo_coin_updater/komodo_coin_updater.dart';

void main() async {
  await KomodoCoinUpdater.ensureInitialized("path/to/komodo/coin/files");
}
```

### Provider

The coins provider is responsible for fetching the coins list and configuration files from GitHub.

```dart
import 'package:komodo_coin_updater/komodo_coin_updater.dart';

Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await KomodoCoinUpdater.ensureInitialized("path/to/komodo/coin/files");

    final provider = const CoinConfigProvider();
    final coins = await provider.getLatestCoins();
    final coinsConfigs = await provider.getLatestCoinConfigs();
}
```

### Repository

The repository is responsible for managing the coins list and configuration files, fetching from GitHub and persisting to storage.

```dart
import 'package:komodo_coin_updater/komodo_coin_updater.dart';

Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await KomodoCoinUpdater.ensureInitialized("path/to/komodo/coin/files");

    final repository = CoinConfigRepository(
        api: const CoinConfigProvider(),
        storageProvider: CoinConfigStorageProvider.withDefaults(),
    ); 
    
    // Load the coin configuration if it is saved, otherwise update it 
    if(await repository.coinConfigExists()) {
        if (await repository.isLatestCommit()) {
            await repository.loadCoinConfigs();
        } else {
            await repository.updateCoinConfig();
        }
    }
    else {
        await repository.updateCoinConfig();
    }
}
```
