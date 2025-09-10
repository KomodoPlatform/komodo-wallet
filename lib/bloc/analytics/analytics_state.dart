import 'package:equatable/equatable.dart';
import 'package:web_dex/model/settings/analytics_settings.dart';

class AnalyticsState extends Equatable {
  const AnalyticsState({required this.isSendDataAllowed});
  static AnalyticsState initial() =>
      const AnalyticsState(isSendDataAllowed: false);

  static AnalyticsState fromSettings(AnalyticsSettings settings) =>
      AnalyticsState(isSendDataAllowed: settings.isSendAllowed);

  AnalyticsState copyWith({bool? isSendDataAllowed}) {
    return AnalyticsState(
      isSendDataAllowed: isSendDataAllowed ?? this.isSendDataAllowed,
    );
  }

  final bool isSendDataAllowed;

  @override
  List<Object?> get props => [isSendDataAllowed];
}
