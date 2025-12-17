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

import '../exceptions.dart';
import '../helpers/object.dart';
import '../helpers/utils.dart';
import 'object_factory_dependency.dart';

/// {@template dependency_object_provider}
/// **Dependency Object Provider**
///
/// Extends [ObjectFactoryDependency] and implements [ObjectProvider].
/// Designed for cases where multiple candidate pods of the same
/// type may exist. Provides advanced lookup and iteration semantics.
///
/// # Purpose
/// - Provides a stream-like view over multiple candidate pods.
/// - Supports conditional retrieval: `getIfAvailable`, `getIfUnique`.
/// - Supports consumer-based callbacks: `ifAvailable`, `ifUnique`.
/// - Implements collection-like operations: iteration, `toList()`,
///   `isEmpty`, `isNotEmpty`.
///
/// # Behavior
/// - On creation, `_buildObjects` scans the factory for all pods of the
///   given type, including those from ancestor contexts.
/// - Wraps each resolved object in an [ObjectHolder] with class metadata.
/// - Exposes them via [stream] and collection APIs.
///
/// # Example
/// ```dart
/// final provider = DependencyObjectProvider<Service>(descriptor, factory);
///
/// // Stream all matching pods
/// await for (final holder in provider.stream()) {
///   print(holder.getValue());
/// }
///
/// // Get single pod if available
/// final service = await provider.getIfAvailable();
///
/// // Execute only if unique
/// await provider.ifUnique((s) => print("Unique service: ${s.getValue()}"));
/// ```
///
/// # Error Handling
/// - [getIfAvailable] rethrows [NoUniquePodDefinitionException] but suppresses
///   [NoSuchPodDefinitionException].
/// - [getIfUnique] suppresses [NoUniquePodDefinitionException] but rethrows
///   [NoSuchPodDefinitionException].
///
/// # Notes
/// - Objects are eagerly collected in `_buildObjects`.
/// - `isEmpty` and `toList` delegate to the current stream state.
/// {@endtemplate}
@Generic(ObjectProviderDependency)
final class ObjectProviderDependency<T> extends ObjectFactoryDependency<T> implements ObjectProvider<T> {
  /// All candidate object holders for this type.
  List<ObjectHolder<T>> objects = [];

  ObjectProviderDependency(super.descriptor, super.listablePodFactory) {
    _buildObjects();
  }

  /// Builds the initial list of objects by scanning listablePodFactory pods.
  void _buildObjects() async {
    final type = descriptor.type;
    final component = descriptor.component ?? type.componentType();

    if (component != null) {
      final podsOfType = await PodUtils.podsOfTypeIncludingAncestors(
        listablePodFactory,
        component,
        includeNonSingletons: true,
        allowEagerInit: true,
      );

      for (final pod in podsOfType.entries) {
        final name = pod.key;
        final value = pod.value;
        final cls = listablePodFactory.containsDefinition(name) ? listablePodFactory.getDefinition(name).type : null;
        final converted = listablePodFactory.convertIfNecessary(name, value, component);

        if (cls != null && converted is T) {
          objects.add(ObjectHolder(
            converted,
            packageName: cls.getPackage()?.getName(),
            qualifiedName: cls.getQualifiedName(),
          ));
        }
      }
    }

    if (descriptor.lookup != null) {
      final type = await listablePodFactory.getPod(descriptor.lookup!);
      final cls = listablePodFactory.getDefinition(descriptor.lookup!).type;
      final converted = listablePodFactory.convertIfNecessary(descriptor.lookup!, type, cls);

      objects.add(ObjectHolder(
        converted,
        packageName: cls.getPackage()?.getName(),
        qualifiedName: cls.getQualifiedName(),
      ));
    }
  }

  @override
  GenericStream<ObjectHolder<T>> stream() {
    return StreamSupport.stream(objects);
  }

  @override
  Future<ObjectHolder<T>?> getIfAvailable([Supplier<ObjectHolder<T>>? supplier]) async {
    ObjectHolder<T>? result;

    try {
      result = await get();
    } on NoUniquePodDefinitionException catch (_) {
      rethrow;
    } on NoSuchPodDefinitionException catch (_) {
      result = null;
    }

    return result ?? supplier?.call();
  }

  @override
  Future<ObjectHolder<T>?> getIfUnique([Supplier<ObjectHolder<T>>? supplier]) async {
    ObjectHolder<T>? result;

    try {
      result = await get();
    } on NoUniquePodDefinitionException catch (_) {
      result = null;
    } on NoSuchPodDefinitionException catch (_) {
      rethrow;
    }

    return result ?? supplier?.call();
  }

  @override
  Future<void> ifAvailable(Consumer<ObjectHolder<T>> consumer) async {
    final dependency = await getIfAvailable();
    if (dependency != null) {
      consumer.call(dependency);
    }
  }

  @override
  Future<void> ifUnique(Consumer<ObjectHolder<T>> consumer) async {
    final dependency = await getIfUnique();
    if (dependency != null) {
      consumer.call(dependency);
    }
  }

  @override
  bool get isEmpty => toList().isEmpty;

  @override
  bool get isNotEmpty => !isEmpty;

  @override
  Iterator<T> iterator() => stream().map((e) => e.getValue()).iterator();

  @override
  List<T> toList() => stream().map((e) => e.getValue()).toList();
}