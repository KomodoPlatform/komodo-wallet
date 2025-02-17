part of 'trezor_init_bloc.dart';

abstract class TrezorInitEvent {
  const TrezorInitEvent();
}

class TrezorInitUpdateAuthMode extends TrezorInitEvent {
  const TrezorInitUpdateAuthMode(this.kdfUser);
  final KdfUser? kdfUser;
}

class TrezorInit extends TrezorInitEvent {
  const TrezorInit();
}

class TrezorInitReset extends TrezorInitEvent {
  const TrezorInitReset();
}

class TrezorInitSubscribeStatus extends TrezorInitEvent {
  const TrezorInitSubscribeStatus();
}

class TrezorInitUpdateStatus extends TrezorInitEvent {
  const TrezorInitUpdateStatus();
}

class TrezorInitSuccess extends TrezorInitEvent {
  const TrezorInitSuccess(this.status);

  final InitTrezorStatusData status;
}

class TrezorInitSendPin extends TrezorInitEvent {
  const TrezorInitSendPin(this.pin);
  final String pin;
}

class TrezorInitSendPassphrase extends TrezorInitEvent {
  const TrezorInitSendPassphrase(this.passphrase);
  final String passphrase;
}
