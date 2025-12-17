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

import 'dart:async';

import 'package:jetleaf_lang/lang.dart';

import '../core/default_listable_pod_factory.dart';
import '../core/pod_factory.dart';
import '../exceptions.dart';
import '../helpers/object.dart';

/// {@template dependency_object_factory}
/// **Dependency Object Factory**
///
/// A specialized [ObjectFactory] that resolves and produces objects
/// based on a [DependencyDescriptor]. It integrates with the
/// [DefaultListablePodFactory] to perform resolution.
///
/// # Purpose
/// - Bridges the gap between abstract dependency descriptors and actual
///   pod instances.
/// - Provides an [ObjectHolder] wrapper with additional metadata such as
///   package and qualified class names.
/// - Throws explicit exceptions when dependencies cannot be found.
///
/// # Behavior
/// - Inspects the descriptor’s `type` to determine its `componentType()`.
/// - Delegates resolution to [DefaultListablePodFactory.doResolveDependency].
/// - Wraps the result in an [ObjectHolder].
///
/// # Example
/// ```dart
/// final descriptor = DependencyDescriptor(Database, "dbProperty", "mainDb");
/// final factory = DefaultListablePodFactory();
/// final objectFactory = DependencyObjectFactory<Database>(descriptor, factory);
///
/// final dbHolder = await objectFactory.get();
/// print(dbHolder.getValue()); // Database instance
/// ```
///
/// # Error Handling
/// - Throws [PodDefinitionStoreException] if no pod of the given type is defined.
/// - Ensures precise error messages with pod name and type information.
/// {@endtemplate}
@Generic(ObjectFactoryDependency)
class ObjectFactoryDependency<T> extends ObjectFactory<T> {
  /// The dependency metadata describing what is being resolved.
  final DependencyDescriptor descriptor;

  /// The backing pod factory used to resolve dependencies.
  final DefaultListablePodFactory listablePodFactory;

  /// {@macro dependency_object_factory}
  ObjectFactoryDependency(this.descriptor, this.listablePodFactory);

  @override
  FutureOr<ObjectHolder<T>> get([List<ArgumentValue>? args]) async {
    final type = descriptor.type;
    final component = descriptor.component ?? type.componentType();

    if (component != null) {
      final result = await listablePodFactory.doResolveDependency(
        DependencyDescriptor(
          source: component,
          podName: descriptor.propertyName,
          propertyName: descriptor.podName,
          type: component,
          args: args,
          lookup: descriptor.lookup
        ),
      );

      if (result != null) {
        final converted = listablePodFactory.convertIfNecessary(component.getName(), result, component);
        return ObjectHolder(
          converted,
          packageName: component.getPackage()?.getName(),
          qualifiedName: component.getQualifiedName(),
        );
      } else {
        throw PodDefinitionStoreException(
          name: component.getName(),
          resourceDescription: null,
          msg: "No pod of type '${component.getName()}' is defined",
        );
      }
    }

    throw PodDefinitionStoreException(name: descriptor.podName, resourceDescription: null, msg: "Pod of type '$T' is not defined");
  }
}