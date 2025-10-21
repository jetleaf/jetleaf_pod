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

import 'pod_definition.dart';

/// {@template pod_definition_registry}
/// Interface for registries that hold [PodDefinition] instances.
///
/// This abstraction represents the core contract for managing the registration,
/// lookup, and removal of pod definitions in a dependency injection container
/// or application context.
///
/// Framework components or configuration processors can interact with this interface
/// to introspect or programmatically register pods without requiring concrete
/// knowledge of the underlying implementation.
///
/// ### Example
/// ```dart
/// class MyRegistry implements PodDefinitionRegistry {
///   final Map<String, PodDefinition> _definitions = {};
///
///   @override
///   void registerDefinition(String name, PodDefinition podDefinition) {
///     _definitions[name] = podDefinition;
///   }
///
///   @override
///   void removeDefinition(String name) {
///     _definitions.remove(name);
///   }
///
///   @override
///   PodDefinition getDefinition(String name) {
///     return _definitions[name]!;
///   }
///
///   @override
///   bool containsDefinition(String name) => _definitions.containsKey(name);
///
///   @override
///   List<String> getDefinitionNames() => _definitions.keys.toList();
///
///   @override
///   int getDefinitionCount() => _definitions.length;
///
///   @override
///   bool isNameInUse(String name) => _definitions.containsKey(name);
/// }
/// ```
/// {@endtemplate}
abstract interface class PodDefinitionRegistry implements ListablePodDefinitionRegistry {
  /// {@template pod_definition_registry_register}
  /// Register a new [pod] under the given [name].
  ///
  /// This method adds a pod to the registry with the specified name.
  /// The pod name must be unique within the registry and follow
  /// the naming conventions established by the implementation.
  ///
  /// [name]: The name to register the pod under. Must be unique
  ///             and non-empty. Follows typical pod naming patterns.
  /// [pod]: The pod object to register. The type [T] depends on the
  ///         registry implementation (PodDefinition, Object, etc.)
  ///
  /// Throws:
  /// - [IllegalArgumentException] if name is null, empty, or invalid
  ///
  /// Example:
  /// ```dart
  /// // Register a pod definition
  /// final podDef = GenericPodDefinition.forClass(UserService);
  /// registry.registerDefinition('userService', podDef);
  /// ```
  /// {@endtemplate}
  Future<void> registerDefinition(String name, PodDefinition pod);

  /// {@template pod_definition_registry_remove}
  /// Remove the pod associated with [name].
  ///
  /// This method removes a pod from the registry, making the name
  /// available for reuse (depending on implementation constraints).
  ///
  /// [name]: The name of the pod to remove
  ///
  /// Throws:
  /// - [NoSuchPodDefinitionException] if no pod exists with the given name
  ///
  /// Example:
  /// ```dart
  /// if (registry.containsDefinition('oldService')) {
  ///   registry.removeDefinition('oldService');
  ///   print('Removed oldService from registry');
  /// }
  /// ```
  /// {@endtemplate}
  Future<void> removeDefinition(String name);

  /// {@template pod_definition_registry_get}
  /// Retrieve the pod registered under [name].
  ///
  /// This method returns the pod associated with the given name.
  /// The exact behavior and returned type depend on the registry
  /// implementation and the generic type [T].
  ///
  /// [name]: The name of the pod to retrieve
  /// Returns the pod object of type [T] associated with the name
  ///
  /// Throws:
  /// - [NoSuchPodDefinitionException] if no pod exists with the given name
  ///
  /// Example:
  /// ```dart
  /// // Get a pod definition
  /// final podDef = definitionRegistry.getDefinition('userService');
  /// print('Pod class: ${podDef.getPodClassName()}');
  /// ```
  /// {@endtemplate}
  PodDefinition getDefinition(String name);

  /// {@template abstract_pod_factory_get_definition_by_class}
  /// Returns the pod definition for the specified class type.
  ///
  /// This method looks up the pod definition by class rather than by name.
  ///
  /// Usage Example:
  /// ```dart
  /// final factory = getPodFactory();
  /// final definition = factory.getDefinitionByClass(Class.forObject(MyService));
  /// ```
  ///
  /// [type] the class type to look up
  /// Returns the [PodDefinition] for the specified class
  ///
  /// Throws [PodNotFoundException] if no pod is defined for the class
  /// {@endtemplate}
  PodDefinition getDefinitionByClass(Class type);

  /// {@template pod_definition_registry_is_name_in_use}
  /// Returns `true` if [name] is currently in use in this registry.
  ///
  /// This method checks if a pod name is already registered, which is
  /// useful for validating new pod registrations and preventing name
  /// conflicts.
  ///
  /// [name]: The pod name to check for availability
  /// Returns true if the name is already registered, false if available
  ///
  /// Example:
  /// ```dart
  /// final proposedName = 'newService';
  /// if (registry.isNameInUse(proposedName)) {
  ///   throw PodException('Pod name "$proposedName" is already registered');
  /// } else {
  ///   registry.registerDefinition(proposedName, newServicePod);
  /// }
  /// ```
  /// {@endtemplate}
  Future<bool> isNameInUse(String name);
}

/// {@template listable_pod_definition_registry}
/// Interface for registries that provides additional functionality for listing and enumeration.
/// 
/// This interface adds methods for retrieving all pod definitions and their names, which is useful for
/// framework components that need to process all pods of a certain type or
/// annotation.
/// 
/// ## Key Features
/// - Getting all pod names
/// - Checking if a pod exists
/// - Getting the count of all pods
/// 
/// ## Usage Example
/// 
/// ```dart
/// // Create a listable pod definition registry
/// ListablePodDefinitionRegistry registry = MyListablePodDefinitionRegistry();
/// 
/// // Check if a pod name is in use
/// if (registry.isNameInUse('userService')) {
///   print('userService is registered');
/// } else {
///   print('userService is not available');
/// }
/// 
/// // Get all pod names
/// List<String> allPods = registry.getDefinitionNames();
/// print('Total pods: ${allPods.length}');
/// 
/// // Get all pod definitions
/// List<PodDefinition> allDefinitions = registry.getDefinitions();
/// print('Total pod definitions: ${allDefinitions.length}');
/// 
/// // Get the count of all pods
/// int count = registry.getDefinitionCount();
/// print('Total pods registered: $count');
/// ```
/// 
/// {@endtemplate}
abstract interface class ListablePodDefinitionRegistry {
  /// {@template pod_definition_registry_contains}
  /// Returns `true` if this registry contains a pod with the given [name].
  ///
  /// This method provides a lightweight way to check for pod existence
  /// without the overhead of retrieving the actual pod object.
  ///
  /// [name]: The name of the pod to check for
  /// Returns true if a pod with the given name exists in the registry,
  ///         false otherwise
  ///
  /// Example:
  /// ```dart
  /// if (registry.containsDefinition('userService')) {
  ///   print('userService is registered');
  /// } else {
  ///   print('userService is not available');
  /// }
  /// ```
  /// {@endtemplate}
  bool containsDefinition(String name);

  /// {@template pod_definition_registry_get_names}
  /// Returns a list of all pod names currently registered.
  ///
  /// This method provides access to all pod names in the registry,
  /// which is useful for debugging, administration, and programmatic
  /// registry inspection.
  ///
  /// Returns an unmodifiable list of all pod names in the registry.
  /// The list may be empty but will never be null. The order of names
  /// is implementation-dependent.
  ///
  /// Example:
  /// ```dart
  /// final allNames = registry.getDefinitionNames();
  /// print('Registered pods: ${allNames.join(', ')}');
  /// // Output: Registered pods: userService, productService, configService
  ///
  /// for (final name in allNames) {
  ///   final pod = registry.getDefinition(name);
  ///   // Process each pod
  /// }
  /// ```
  /// {@endtemplate}
  List<String> getDefinitionNames();

  /// {@template pod_definition_registry_get_count}
  /// Returns the total number of pods registered.
  ///
  /// This method provides a count of all pods currently registered,
  /// which is useful for monitoring, capacity planning, and testing.
  ///
  /// Returns the total number of pods in the registry.
  /// Returns 0 if the registry is empty.
  ///
  /// Example:
  /// ```dart
  /// final count = registry.getDefinitionCount();
  /// print('Total pods registered: $count');
  ///
  /// if (count == 0) {
  ///   print('Registry is empty - initializing default pods...');
  ///   initializeDefaultPods(registry);
  /// }
  /// ```
  /// {@endtemplate}
  int getNumberOfPodDefinitions();
}