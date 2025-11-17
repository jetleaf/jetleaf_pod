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

import '../core/default_listable_pod_factory.dart';
import '../core/pod_factory.dart';

/// {@template dependency_optional}
/// A private helper class within the Jetleaf framework that represents
/// an optional dependency resolver.
///
/// This class acts as a wrapper around a [DefaultListablePodFactory]
/// and provides the ability to resolve dependencies that may or may not
/// be available at runtime.  
///
/// The primary use case is when a dependency should not be required,
/// but can still be requested dynamically from the dependency container.  
///
/// This class always returns results wrapped inside an [Optional] to
/// explicitly represent the presence or absence of a resolved value.
///
/// Key points:
/// - Wraps dependency resolution logic with null-safety semantics.
/// - Does not throw errors when a dependency is unavailable.
/// - Plays a role in supporting optional bindings in the Jetleaf DI system.
///
/// {@endtemplate}
final class OptionalDependency {
  /// {@template dependency_optional.factory}
  /// The underlying factory responsible for creating and resolving pods
  /// (dependency instances).
  ///
  /// It is used internally by [OptionalDependency] to perform actual
  /// resolution calls to the Jetleaf container.
  ///
  /// This field is final and cannot be reassigned after initialization.
  /// {@endtemplate}
  final DefaultListablePodFactory factory;

  /// {@macro dependency_optional}
  ///
  /// Creates a new [OptionalDependency] tied to a specific
  /// [DefaultListablePodFactory].
  ///
  /// - [factory]: The pod factory that will handle resolution.
  OptionalDependency(this.factory);

  /// {@template dependency_optional.resolve}
  /// Attempts to resolve an optional dependency described by [descriptor].
  ///
  /// This method will:
  /// 1. Determine the component type from the [descriptor].
  /// 2. If no component type is found, return an empty [Optional].
  /// 3. Otherwise, request the dependency from the [factory].
  /// 4. Wrap the result inside an [Optional] to indicate presence or absence.
  ///
  /// ### Example
  /// ```dart
  /// final optional = OptionalDependency(factory);
  /// final result = await optional.resolve(
  ///   DependencyDescriptor(MyService, 'myPod', 'myProperty', MyService)
  /// );
  /// if (result.isPresent) {
  ///   print('Dependency found: ${result.get()}');
  /// } else {
  ///   print('Dependency not available.');
  /// }
  /// ```
  ///
  /// - Returns: An [Optional] containing the resolved dependency if present,
  ///   or an empty [Optional] otherwise.
  /// {@endtemplate}
  Future<Optional<Object>> resolve(DependencyDescriptor descriptor) async {
    final component = descriptor.component ?? descriptor.type.componentType();
    if (component == null) {
      return Optional.ofNullable(null);
    }

    final lookup = descriptor.lookup;
    if (lookup != null) {
      final result = await factory.getPod(lookup);
      final converted = factory.convertIfNecessary(lookup, result, component);
      return Optional.ofNullable(converted);
    }

    final result = await factory.resolveDependency(
      DependencyDescriptor(
        source: component,
        podName: descriptor.podName,
        propertyName: descriptor.propertyName,
        type: component,
        lookup: descriptor.lookup
      ),
    );
  
    return Optional.ofNullable(result);
  }
}