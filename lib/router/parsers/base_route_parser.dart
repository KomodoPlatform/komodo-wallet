import 'package:komodo_wallet/router/routes.dart';

abstract class BaseRouteParser {
  AppRoutePath getRoutePath(Uri uri);
}
