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

import '../helpers/object.dart';

/// {@template singleton_pod_registry}
/// Interface for registries that hold singleton pod instances.
///
/// This interface defines the contract for managing singleton pods within
/// the JetLeaf framework. Singleton pods are objects that are instantiated
/// once and shared throughout the application context.
///
/// Key responsibilities:
/// - Registering singleton instances by name
/// - Retrieving singleton instances by name
/// - Checking for singleton existence
/// - Providing singleton metadata and statistics
/// - Thread-safe singleton management
///
/// Implementations of this interface are responsible for the complete
/// lifecycle management of singleton pods, including:
/// - Early singleton instantiation during context startup
/// - Singleton caching and reuse
/// - Dependency injection for singleton pods
/// - Proper cleanup during context shutdown
///
/// Example usage:
/// ```dart
/// class MySingletonRegistry implements SingletonPodRegistry {
///   final Map<String, Object> _singletons = {};
///   final Object _mutex = Object();
///
///   @override
///   void register(String name, String qualifiedName, Object singletonObject) {
///     _singletons[name] = singletonObject;
///   }
///
///   @override
///   Object? get(String name) => _singletons[name];
///
///   // ... other interface implementations
/// }
///
/// final registry = MySingletonRegistry();
/// registry.register('userService', 'package:example/example.dart.UserService', UserService());
/// final service = registry.get('userService');
/// ```
/// {@endtemplate}
abstract class SingletonPodRegistry {
  /// {@template singleton_pod_registry_register}
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
  /// - [PodException] if a pod with the same name already exists
  /// - [UnsupportedOperationException] if the registry is read-only
  ///
  /// Example:
  /// ```dart
  /// // Register a singleton instance
  /// final instance = UserService();
  /// singletonRegistry.registerSingleton(
  ///   'userService',
  ///   object: ObjectHolder<UserService>(instance, packageName: "jetleaf")
  /// );
  /// 
  /// // Register a singleton factory
  /// singletonRegistry.registerSingleton(
  ///   'userService',
  ///   factory: ObjectFactory<UserService>(() => ObjectHolder<UserService>(UserService(), packageName: "jetleaf"))
  /// );
  /// ```
  /// {@endtemplate}
  Future<void> registerSingleton(String name, Class type, {ObjectHolder<Object>? object, ObjectFactory<Object>? factory});

  /// {@template singleton_pod_registry_add_singleton_callback}
  /// Add a callback to be executed when the singleton associated with [name] is initialized.
  ///
  /// This method allows registering callbacks that will be executed when a singleton is initialized.
  /// The callback will receive the singleton instance as its parameter.
  ///
  /// [name]: The name of the singleton to register the callback for
  /// [callback]: The callback to execute when the singleton is initialized
  ///
  /// Throws:
  /// - [IllegalArgumentException] if name is null or empty
  /// - [PodNotFoundException] if no singleton exists with the given name
  ///
  /// Example:
  /// ```dart
  /// singletonRegistry.addSingletonCallback('userService', (userService) {
  ///   print('UserService initialized: $userService');
  /// });
  /// ```
  /// {@endtemplate}
  void addSingletonCallback(String name, Class type, Consumer<Object> callback);

  /// {@template singleton_pod_registry_remove}
  /// Remove the pod associated with [name].
  ///
  /// This method removes a pod from the registry, making the name
  /// available for reuse (depending on implementation constraints).
  ///
  /// [name]: The name of the pod to remove
  ///
  /// Throws:
  /// - [IllegalArgumentException] if name is null or empty
  /// - [PodNotFoundException] if no pod exists with the given name
  /// - [UnsupportedOperationException] if the registry doesn't support removal
  ///
  /// Example:
  /// ```dart
  /// if (registry.containsSingleton('oldService')) {
  ///   registry.removeSingleton('oldService');
  ///   print('Removed oldService from registry');
  /// }
  /// ```
  /// {@endtemplate}
  void removeSingleton(String name);

  /// {@template singleton_pod_registry_get}
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
  /// - [IllegalArgumentException] if name is null or empty
  /// - [PodNotFoundException] if no pod exists with the given name
  ///
  /// Example:
  /// ```dart
  /// // Get a singleton instance
  /// final instance = singletonRegistry.getSingleton('userService');
  /// instance.processRequest();
  /// ```
  /// {@endtemplate}
  Future<Object?> getSingleton(String name, {bool allowEarlyReference = true, ObjectFactory<Object>? factory});

  /// {@template singleton_pod_registry_contains}
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
  /// if (registry.containsSingleton('userService')) {
  ///   print('userService is registered');
  /// } else {
  ///   print('userService is not available');
  /// }
  /// ```
  /// {@endtemplate}
  bool containsSingleton(String name);

  /// {@template singleton_pod_registry_get_names}
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
  /// final allNames = registry.getSingletonNames();
  /// print('Registered pods: ${allNames.join(', ')}');
  /// // Output: Registered pods: userService, productService, configService
  ///
  /// for (final name in allNames) {
  ///   final pod = registry.getSingleton(name);
  ///   // Process each pod
  /// }
  /// ```
  /// {@endtemplate}
  List<String> getSingletonNames();

  /// {@template singleton_pod_registry_get_count}
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
  /// final count = registry.getCount();
  /// print('Total pods registered: $count');
  ///
  /// if (count == 0) {
  ///   print('Registry is empty - initializing default pods...');
  ///   initializeDefaultPods(registry);
  /// }
  /// ```
  /// {@endtemplate}
  int getSingletonCount();

  /// {@template singleton_pod_registry_clear_cache}
  /// Clears all cached singleton pods.
  /// 
  /// This method is useful for resetting the singleton registry without
  /// affecting other pod registries or configurations. Typically used during
  /// application shutdown or reconfiguration.
  /// 
  /// ## Example:
  /// ```dart
  /// final registry = MySingletonPodRegistry();
  /// 
  /// // Populate cache with multiple singletons
  /// registry.registerSingleton('userService', UserService());
  /// registry.registerSingleton('productService', ProductService());
  /// 
  /// print(registry.getSingletonCount()); // 2
  /// 
  /// // Clear all cached singletons
  /// registry.clearSingletonCache();
  /// 
  /// // Cache is now empty
  /// print(registry.getSingletonCount()); // 0
  /// ```
  /// {@endtemplate}
  void clearSingletonCache();
}