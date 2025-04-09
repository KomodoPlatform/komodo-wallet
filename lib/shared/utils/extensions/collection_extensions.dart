import 'dart:collection';

/// Extension to make Lists unmodifiable.
extension UnmodifiableListExtension<E> on Iterable<E> {
  /// Returns an unmodifiable view of this iterable.
  ///
  /// NB! This references the original iterable, so if the original iterable is
  /// modified, the unmodifiable view will reflect those changes.
  ///
  /// This is useful for preventing modifications to the list while still
  /// allowing read access.
  ///
  /// This won't protect against modifications to the elements of the iterable
  /// if they are mutable.
  Iterable<E> unmodifiable() => UnmodifiableListView<E>(this);
}

/// Extension to make Maps unmodifiable.
///
/// NB! This references the original map, so if the original map is
/// modified, the unmodifiable view will reflect those changes.
///
/// This is useful for preventing modifications to the map while still
/// allowing read access.
///
/// This won't protect against modifications to the elements of the map
/// if they are mutable.
extension UnmodifiableMapExtension<K, V> on Map<K, V> {
  /// Returns an unmodifiable view of this map.
  ///
  /// This is useful for preventing modifications to the map while still
  /// allowing read access.
  ///
  /// This won't protect against modifications to the elements of the map
  /// if they are mutable.
  Map<K, V> unmodifiable() => UnmodifiableMapView<K, V>(this);
}
