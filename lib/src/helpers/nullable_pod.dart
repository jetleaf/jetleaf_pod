// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'package:jetleaf_lang/lang.dart';

/// {@template nullable_pod}
/// A special marker pod instance that represents a nullable or absent pod value.
///
/// The [NullablePod] class serves as a sentinel value to distinguish between:
/// - A pod that explicitly has a `null` value
/// - A pod that doesn't exist in the registry at all
///
/// This is particularly useful in dependency injection frameworks and pod
/// management systems where you need to differentiate between "no pod found"
/// and "pod found but its value is null".
///
/// ## Key Use Cases:
/// - **Placeholder for nullable dependencies**: When a pod can legitimately be null
/// - **Optional dependency marker**: To indicate optional dependencies that weren't resolved
/// - **Configuration absence**: Represent missing configuration values explicitly
/// - **Testing**: Mock or stub scenarios where null values need special handling
///
/// ## Usage Example:
/// ```dart
/// class PodContainer {
///   final Map<String, Object?> _pods = {};
///
///   void registerPod(String name, Object? pod) {
///     _pods[name] = pod ?? NullablePod(); // Use NullablePod for explicit null
///   }
///
///   Object? getPod(String name) {
///     final pod = _pods[name];
///     if (pod is NullablePod) {
///       return null; // Convert back to actual null
///     }
///     return pod;
///   }
///
///   bool containsPod(String name) {
///     return _pods.containsKey(name);
///   }
///
///   bool isExplicitlyNull(String name) {
///     return _pods[name] is NullablePod;
///   }
/// }
///
/// void main() {
///   final container = PodContainer();
///
///   // Register different types of values
///   container.registerPod('existingPod', 'actual value');
///   container.registerPod('nullPod', null); // Stored as NullablePod
///   // 'missingPod' is not registered at all
///
///   print(container.containsPod('existingPod')); // true
///   print(container.containsPod('nullPod')); // true
///   print(container.containsPod('missingPod')); // false
///
///   print(container.isExplicitlyNull('existingPod')); // false
///   print(container.isExplicitlyNull('nullPod')); // true
///   print(container.isExplicitlyNull('missingPod')); // false
///
///   print(container.getPod('existingPod')); // 'actual value'
///   print(container.getPod('nullPod')); // null
///   print(container.getPod('missingPod')); // null
/// }
/// ```
///
/// ## Equality Semantics:
/// All instances of [NullablePod] are considered equal to each other, as they
/// all represent the same concept of "explicit null". This allows for consistent
/// comparison and usage in collections.
/// {@endtemplate}
final class NullablePod with EqualsAndHashCode {
  /// {@template nullable_pod_class}
  /// The [Class] instance representing the [NullablePod] type.
  ///
  /// This is used for reflection and type information.
  /// {@endtemplate}
  static final Class CLASS = Class<NullablePod>(null, PackageNames.POD);

  /// {@template nullable_pod_name}
  /// The name of the [NullablePod] type.
  ///
  /// This is used for reflection and type information.
  /// {@endtemplate}
  static final String NAME = '#NullablePod';

  /// {@template nullable_pod_constructor}
  /// Creates a new [NullablePod] instance.
  ///
  /// Since all [NullablePod] instances are equivalent (they all represent
  /// the same "explicit null" concept), the constructor doesn't require
  /// any parameters.
  ///
  /// ## Example:
  /// ```dart
  /// // Create nullable pod instances
  /// final nullPod1 = NullablePod();
  /// final nullPod2 = NullablePod();
  ///
  /// // All instances are equal
  /// print(nullPod1 == nullPod2); // true
  /// print(nullPod1.hashCode == nullPod2.hashCode); // true
  /// ```
  /// {@endtemplate}
  NullablePod();

  @override
  String toString() => 'NullablePod()';

  @override
  List<Object?> equalizedProperties() => ["NullablePod"];
}