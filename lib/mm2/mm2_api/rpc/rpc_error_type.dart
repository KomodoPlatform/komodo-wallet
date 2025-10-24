enum RpcErrorType {
  alreadyStarted,
  alreadyStopped,
  alreadyStopping,
  cannotStartFromStopping,
  invalidRequest;

  @override
  String toString() {
    switch (this) {
      case RpcErrorType.alreadyStarted:
        return 'AlreadyStarted';
      case RpcErrorType.alreadyStopped:
        return 'AlreadyStopped';
      case RpcErrorType.alreadyStopping:
        return 'AlreadyStopping';
      case RpcErrorType.cannotStartFromStopping:
        return 'CannotStartFromStopping';
      case RpcErrorType.invalidRequest:
        return 'InvalidRequest';
    }
  }

  static RpcErrorType? fromString(String value) {
    switch (value) {
      case 'AlreadyStarted':
        return RpcErrorType.alreadyStarted;
      case 'AlreadyStopped':
        return RpcErrorType.alreadyStopped;
      case 'AlreadyStopping':
        return RpcErrorType.alreadyStopping;
      case 'CannotStartFromStopping':
        return RpcErrorType.cannotStartFromStopping;
      case 'InvalidRequest':
        return RpcErrorType.invalidRequest;
      default:
        return null;
    }
  }
}
