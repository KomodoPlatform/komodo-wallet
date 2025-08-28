part of 'version_info_bloc.dart';

abstract class VersionInfoEvent {
  const VersionInfoEvent();
}

class LoadVersionInfo extends VersionInfoEvent {
  const LoadVersionInfo();
}

class StartPeriodicPolling extends VersionInfoEvent {
  const StartPeriodicPolling();
}

class StopPeriodicPolling extends VersionInfoEvent {
  const StopPeriodicPolling();
}
