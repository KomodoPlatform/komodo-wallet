enum DisallowedFeature {
  trading;

  static DisallowedFeature parse(String value) {
    switch (value.toUpperCase()) {
      case 'TRADING':
        return DisallowedFeature.trading;
      default:
        throw ArgumentError.value(value, 'value', 'Invalid disallowed feature');
    }
  }
}
