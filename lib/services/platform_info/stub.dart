import 'package:web_dex/services/platform_info/platform_info.dart';

PlatformInfo createPlatformInfo() => StubPlatformInfo();

class StubPlatformInfo extends PlatformInfo with MemoizedPlatformInfoMixin {
  @override
  String computeOsLanguage() => 'en-US';

  @override
  String computePlatform() => 'Unknown Platform';

  @override
  String? computeScreenSize() => '800:600';

  @override
  Future<PlatformType> computePlatformType() async {
    return PlatformType.unknown;
  }
}
