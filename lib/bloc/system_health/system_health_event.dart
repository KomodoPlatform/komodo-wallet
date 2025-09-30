part of 'system_health_bloc.dart';

abstract class SystemHealthEvent {}

/// Event to request a system health check (past tense, as per conventions)
class SystemHealthCheckRequested extends SystemHealthEvent {}

/// Event to start the periodic check timer
class SystemHealthPeriodicCheckStarted extends SystemHealthEvent {}

/// Event to cancel the periodic check timer
class SystemHealthPeriodicCheckCancelled extends SystemHealthEvent {}
