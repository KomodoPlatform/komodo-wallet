import 'package:web_dex/bloc/auth_bloc/auth_repository.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/wallets_bloc/wallets_repo.dart';
import 'package:web_dex/blocs/coins_bloc.dart';
import 'package:web_dex/blocs/current_wallet_bloc.dart';
import 'package:web_dex/blocs/dropdown_dismiss_bloc.dart';
import 'package:web_dex/blocs/maker_form_bloc.dart';
import 'package:web_dex/blocs/orderbook_bloc.dart';
import 'package:web_dex/blocs/trading_entities_bloc.dart';
import 'package:web_dex/blocs/wallets_bloc.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/services/cex_service/cex_service.dart';
import 'package:web_dex/services/file_loader/file_loader.dart';
import 'package:web_dex/shared/utils/encryption_tool.dart';

// todo(yurii): recommended bloc arch refactoring order:

/// [AlphaVersionWarningService] can be converted to Bloc
/// and [AlphaVersionWarningService.isShown] might be stored in [StoredSettings]

// 1)
CexService cexService = CexService();
// 2)
TradingEntitiesBloc tradingEntitiesBloc = TradingEntitiesBloc();
// 3)
WalletsBloc walletsBloc = WalletsBloc(
  walletsRepo: walletsRepo,
  encryptionTool: EncryptionTool(),
);
// 4)
CurrentWalletBloc currentWalletBloc = CurrentWalletBloc(
  fileLoader: FileLoader.fromPlatform(),
  authRepo: authRepo,
  walletsRepo: walletsRepo,
  encryptionTool: EncryptionTool(),
);

/// Returns a global singleton instance of [CurrentWalletBloc].
///
/// NB! Even though the class is called [CoinsBloc], it is not a Bloc.
CoinsBloc coinsBloc = CoinsBloc(
  api: mm2Api,
  currentWalletBloc: currentWalletBloc,
  authRepo: authRepo,
  coinsRepo: coinsRepo,
);

/// Returns the same instance of [CoinsBloc] as [coinsBloc]. The purpose of this
/// is to identify which methods of [CoinsBloc] need to be refacored into a
/// the existing [CoinsRepository] or a new repository.
///
/// NB! Even though the class is called [CoinsBloc], it is not a Bloc.
CoinsBloc get coinsBlocRepository => coinsBloc;

MakerFormBloc makerFormBloc = MakerFormBloc(api: mm2Api);
OrderbookBloc orderbookBloc = OrderbookBloc(api: mm2Api);

DropdownDismissBloc globalCancelBloc = DropdownDismissBloc();
