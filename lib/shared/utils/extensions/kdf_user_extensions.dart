import 'package:komodo_defi_types/komodo_defi_types.dart' show KdfUser;
import 'package:web_dex/model/wallet.dart';

extension KdfUserAnalyticsExtension on KdfUser {
  /// Returns a normalized wallet type string for analytics/logging.
  String get type => wallet.config.type.name;
}
