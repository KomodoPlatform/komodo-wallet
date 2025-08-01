import 'dart:convert';

extension StringExtension on String {
  /// Converts the string to sentence case.
  ///
  /// The first letter is capitalized and the rest are lowercased.
  /// Example: "hello world" becomes "Hello world".
  String toCapitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }

  bool isJson() {
    try {
      jsonDecode(this);
      return true;
    } catch (e) {
      return false;
    }
  }
}
