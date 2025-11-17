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

import 'default_listable_pod_factory.dart';

/// {@template factory_aware_order_source_provider}
/// An [OrderSourceProvider] implementation that is aware of the container’s
/// [DefaultListablePodFactory].
///
/// This provider bridges between **pod definitions** and the **ordering system**
/// used by dependency resolution, sorting, and prioritization (e.g. in
/// autowiring or lifecycle processing).
///
/// # Behavior
/// - Maintains a map of object → pod name ([podNames]).
/// — When asked for the order of a given [obj], it resolves the pod definition
///   from the factory.
/// - If the pod’s design metadata specifies an `order`, wraps it in a
///   [_SimplyOrdered] and returns it.
/// - If no mapping or order is found, returns `null`.
///
/// # Use Cases
/// - Allows container-managed objects to participate in ordered resolution.
/// - Supports ordered-like semantics by tying the order back to pod metadata rather than the raw object itself.
///
/// # Parameters
/// - [factory]: The backing [DefaultListablePodFactory] for definition lookups.
/// - [podNames]: A mapping of object instances to their logical pod names.
///
/// # Notes
/// - Only provides order information for pods that are known in [podNames].
/// - This is typically wired into the container’s dependency comparator logic.
/// {@endtemplate}
final class FactoryAwareOrderSourceProvider implements OrderSourceProvider {
  /// The factory to use for definition lookups.
  final DefaultListablePodFactory factory;
  
  /// The mapping of object instances to their logical pod names.
  final Map<Object, String> podNames;

  /// {@macro factory_aware_order_source_provider}
  FactoryAwareOrderSourceProvider(this.factory, this.podNames);
  
  @override
  Object? getOrderSource(Object obj) {
    final name = podNames[obj];
    if (name != null) {
      final sources = <Object?>[];
      final definition = factory.getMergedPodDefinition(name);

      final order = definition.design.order;
      if (order != null) {
        sources.add(_SimplyOrdered(order));
      } else {
        final factoryMethod = definition.factoryMethod.getFactoryMethod();
        if (factoryMethod != null) {
          sources.add(factoryMethod);
        } else {
          final cls = definition.type;
          if (cls != obj.getClass()) {
            sources.add(cls);
          }
        }
      }
      
      return sources;
    }

    return null;
  }
}

/// {@template simply_ordered}
/// A lightweight implementation of [Ordered] that wraps a fixed `order` value.
///
/// # Behavior
/// - Returns the given [order] integer directly from [getOrder].
/// - Useful as a simple adapter when only an explicit order is provided
///   (e.g. from pod metadata or design annotations).
///
/// # Example
/// ```dart
/// final ordered = SimplyOrdered(10);
/// print(ordered.getOrder()); // 10
/// ```
///
/// # Notes
/// - Lower order values generally indicate higher priority in resolution.
/// - Often used in conjunction with [_FactoryAwareOrderSourceProvider].
/// {@endtemplate}
final class _SimplyOrdered implements Ordered {
  /// {@template simply_ordered.order}
  /// The order value.
  /// 
  /// Lower values indicate higher priority in dependency resolution ordering.
  /// {@endtemplate}
  final int order;

  /// {@macro simply_ordered}
  _SimplyOrdered(this.order);

  @override
  int getOrder() => order;
}