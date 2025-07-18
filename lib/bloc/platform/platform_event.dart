import 'package:equatable/equatable.dart';

abstract class PlatformEvent extends Equatable {
  const PlatformEvent();

  @override
  List<Object?> get props => [];
}

class PlatformInitRequested extends PlatformEvent {
  const PlatformInitRequested();
}
