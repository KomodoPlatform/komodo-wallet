import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

extension WidgetTesterFindExtension on CommonFinders {
  Finder byKeyName(String key) {
    return find.byKey(Key(key));
  }
}
