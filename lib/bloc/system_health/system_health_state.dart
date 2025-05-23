part of 'system_health_bloc.dart';

abstract class SystemHealthState {}

class SystemHealthInitial extends SystemHealthState {}

class SystemHealthLoadInProgress extends SystemHealthState {}

class SystemHealthLoadSuccess extends SystemHealthState {
  SystemHealthLoadSuccess(this.isValid);

  final bool isValid;
}

class SystemHealthLoadFailure extends SystemHealthState {}
