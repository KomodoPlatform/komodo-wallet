import 'dart:convert';

extension StringExtension on String {
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
