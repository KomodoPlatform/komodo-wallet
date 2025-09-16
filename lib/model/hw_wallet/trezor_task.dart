class TrezorTask {
  TrezorTask({
    required this.taskId,
    required this.type,
  });

  final int taskId;
  final TrezorTaskType type;
}

enum TrezorTaskType {
  initTrezor,
  enableUtxo,
  withdraw,
  accountBalance;

  String get name {
    switch (this) {
      case TrezorTaskType.initTrezor:
        return 'init_trezor';
      case TrezorTaskType.enableUtxo:
        return 'enable_utxo';
      case TrezorTaskType.withdraw:
        return 'withdraw';
      case TrezorTaskType.accountBalance:
        return 'account_balance';
    }
  }
}
