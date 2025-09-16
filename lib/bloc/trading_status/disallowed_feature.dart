enum DisallowedFeature {
  trading;

  static DisallowedFeature? fromString(String value) {
    switch (value.toUpperCase()) {
      case 'TRADING':
        return DisallowedFeature.trading;
      default:
        return null;
    }
  }
}

