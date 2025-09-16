part of 'market_maker_bot_bloc.dart';

/// Represents the state of the market maker bot.
final class MarketMakerBotState extends Equatable {
  /// Whether the bot is starting, stopping, running or stopped.
  final MarketMakerBotStatus status;

  /// The error message if the bot failed to start or stop.
  /// TODO: change to enum error type.
  final String? errorMessage;

  const MarketMakerBotState({required this.status, this.errorMessage});

  /// The initial state of the bot. Defaults [status] to stopped
  /// and [errorMessage] to null.
  const MarketMakerBotState.initial()
      : this(status: MarketMakerBotStatus.stopped);

  /// The bot is starting. Defaults [status] to starting
  /// and [errorMessage] to null.
  const MarketMakerBotState.starting()
      : this(status: MarketMakerBotStatus.starting);

  /// The bot is stopping. Defaults [status] to stopping
  /// and [errorMessage] to null.
  const MarketMakerBotState.stopping()
      : this(status: MarketMakerBotStatus.stopping);

  /// The bot is running. Defaults [status] to running
  /// and [errorMessage] to null.
  const MarketMakerBotState.running()
      : this(status: MarketMakerBotStatus.running);

  /// The bot is stopped. Defaults [status] to stopped
  /// and [errorMessage] to null.
  const MarketMakerBotState.stopped()
      : this(status: MarketMakerBotStatus.stopped);

  bool get isRunning => status == MarketMakerBotStatus.running;
  bool get isUpdating =>
      status == MarketMakerBotStatus.starting ||
      status == MarketMakerBotStatus.stopping;

  MarketMakerBotState copyWith({
    MarketMakerBotStatus? status,
    String? error,
  }) {
    return MarketMakerBotState(
      status: status ?? this.status,
      errorMessage: error,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
