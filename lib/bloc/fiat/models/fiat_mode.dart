enum FiatMode {
  onramp,
  offramp;

  const FiatMode();

  factory FiatMode.fromTabIndex(int tabIndex) {
    if (tabIndex == 0) {
      return onramp;
    } else if (tabIndex == 1) {
      return offramp;
    } else {
      throw Exception('Unknown FiatMode');
    }
  }

  int get tabIndex {
    switch (this) {
      case onramp:
        return 0;
      case offramp:
        return 1;
    }
  }
}
