import 'dart:math';

int decimalPlacesForSignificantFigures(
  double number,
  int significantFigures,
) {
  if (number == 0) {
    // For zero, the number of decimal places is simply the number of significant figures minus 1
    return significantFigures - 1;
  }

  // Calculate the order of magnitude of the number
  int orderOfMagnitude = log((number.abs()) / ln10).floor();

  // Calculate the number of decimal places required
  int decimalPlaces = significantFigures - 1 - orderOfMagnitude;

  // Ensure we don't return a negative number of decimal places
  return decimalPlaces > 0 ? decimalPlaces : 0;
}
