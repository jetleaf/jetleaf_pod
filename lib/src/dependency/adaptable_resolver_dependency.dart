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

import '../helpers/nullable_pod.dart';
import '../core/pod_factory.dart';

/// {@template _adaptable_resolver}
/// A private helper class to resolve collections and maps into their 
/// `Adaptable` versions (`AdaptableList`, `AdaptableSet`, `AdaptableMap`) 
/// or native Dart collections (`List`, `Set`, `Map`). 
///
/// This class is used internally during pod resolution to ensure that collections 
/// returned from dependency resolution are correctly typed and that any placeholder 
/// objects, specifically instances of `NullablePod`, are filtered out automatically. 
/// It abstracts the repetitive logic of checking the type, filtering invalid objects, 
/// and wrapping results in the appropriate adaptable container.
///
/// The `AdaptableResolverDependency` provides three static methods:
/// 1. [resolveList] – Handles lists or array-like data.
/// 2. [resolveSet] – Handles sets or unique collections.
/// 3. [resolveMap] – Handles key-value maps with string keys.
///
/// ### Key Points:
/// - Filters out `NullablePod` objects to avoid propagating placeholder objects.
/// - Supports returning either an `Adaptable` type or a plain Dart collection based on `type`.
/// - Designed for internal use; not intended for public API consumption.
/// - Can handle both single values and collections automatically.
///
/// ### Example Usage:
/// ```dart
/// final pods = await resolveMultipleCollectionPods('myPod', descriptor, autowiredPods);
///
/// // Resolve a list
/// final listResult = await AdaptableResolverDependency.resolveList(
///   AdaptableList.CLASS,
///   'myPod',
///   descriptor,
///   autowiredPods,
///   pods,
/// );
///
/// // Resolve a set
/// final setResult = await AdaptableResolverDependency.resolveSet(
///   AdaptableSet.CLASS,
///   'myPod',
///   descriptor,
///   autowiredPods,
///   pods,
/// );
///
/// // Resolve a map
/// final mapResult = await AdaptableResolverDependency.resolveMap(
///   AdaptableMap.CLASS,
///   'myPod',
///   descriptor,
///   autowiredPods,
///   pods,
/// );
/// ```
///
/// ### Behavior:
/// - If the input `pods` is null, all methods return null.
/// - Lists are converted to `List<Object>` if the type does not match `AdaptableList`.
/// - Sets are converted to `Set<Object>` if the type does not match `AdaptableSet`.
/// - Maps are converted to `Map<String, Object>` if the type does not match `AdaptableMap`.
/// - Filtering ensures that any `NullablePod` objects are removed from the final collection.
///
/// This class helps maintain consistent and type-safe handling of collections
/// during dependency injection and pod resolution in the system.
/// {@endtemplate}
final class AdaptableResolverDependency {
  /// {@macro _adaptable_resolver}
  AdaptableResolverDependency._();

  /// Resolves a list-like type (`List` or array) into an `AdaptableList` or plain `List<Object>`.
  ///
  /// Filters out any `NullablePod` objects.
  ///
  /// [type] – The target type to resolve. Determines if the result should be an `AdaptableList`.
  /// [podName] – The name of the pod being resolved; mainly for logging or internal tracking.
  /// [descriptor] – Metadata descriptor used during dependency resolution.
  /// [autowiredPods] – Optional set of already autowired pod names.
  /// [pods] – The raw data (could be a `List` or a single object) to resolve.
  ///
  /// Returns an `AdaptableList` if the type matches, a plain `List<Object>` otherwise,
  /// or null if `pods` is empty.
  static Future<Object?> resolveList(Class type, String podName, DependencyDescriptor descriptor, Set<String>? autowiredPods, Object? pods) async {
    final result = pods is List
        ? List<Object>.from(pods).where((obj) => obj is! NullablePod).toList()
        : pods != null
            ? <Object>[pods].where((obj) => obj is! NullablePod).toList()
            : null;

    if (result != null) {
      if (AdaptableList.CLASS.isAssignableFrom(type)) {
        final list = AdaptableList();
        list.addAll(result);
        return list;
      } else {
        return List<Object>.from(result);
      }
    }

    return null;
  }

  /// Resolves a set-like type (`Set`) into an `AdaptableSet` or plain `Set<Object>`.
  ///
  /// Filters out any `NullablePod` objects and ensures uniqueness.
  ///
  /// Parameters are similar to [resolveList].
  /// Returns an `AdaptableSet` if the type matches, a plain `Set<Object>` otherwise,
  /// or null if the input is empty.
  static Future<Object?> resolveSet(Class type, String podName, DependencyDescriptor descriptor, Set<String>? autowiredPods, Object? pods) async {
    final result = pods is List
        ? List<Object>.from(pods).where((obj) => obj is! NullablePod).toSet()
        : pods != null
            ? <Object>{pods}.where((obj) => obj is! NullablePod).toSet()
            : null;

    if (result != null) {
      if (AdaptableSet.CLASS.isAssignableFrom(type)) {
        final set = AdaptableSet();
        set.addAll(result);
        return set;
      } else {
        return Set<Object>.from(result);
      }
    }

    return null;
  }

  /// Resolves a map-like type (`Map<String, T>`) into an `AdaptableMap` or plain `Map<String, Object>`.
  ///
  /// Filters out any entries whose values are `NullablePod`.
  ///
  /// Parameters are similar to [resolveList].
  /// Returns an `AdaptableMap` if the type matches, a plain `Map<String, Object>` otherwise,
  /// or the original input if it is not a map.
  static Future<Object?> resolveMap(Class type, String podName, DependencyDescriptor descriptor, Set<String>? autowiredPods, Object? pods) async {
    if (pods is Map) {
      Map<String, Object> result = {};

      for (final entry in pods.entries) {
        if (entry.value is! NullablePod) {
          result[entry.key] = entry.value;
        }
      }

      if (AdaptableMap.CLASS.isAssignableFrom(type)) {
        final map = AdaptableMap();
        map.addAll(result);
        return map;
      } else {
        return result;
      }
    }

    return pods;
  }
}