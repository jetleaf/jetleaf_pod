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

import '../helpers/enums.dart';
import '../helpers/object.dart';
import 'scope.dart';

// --------------------------------------------------------------------------------------------------------
// SingletonScope
// --------------------------------------------------------------------------------------------------------

/// {@template singleton_scope}
/// A **singleton-scoped pod container** that ensures only **one instance**
/// of a pod is created and reused across the entire application.
///
/// This scope is useful when you want objects to be shared globally, 
/// much like how dependency injection frameworks provide singleton lifetimes.
///
/// ### How it works:
/// - When you request a pod by name using [get], it will either:
///   - Return the already existing instance if it was created before.
///   - Create a new instance via the provided [ObjectFactory] and store it
///     for future reuse.
/// - Pods are stored in a private [_instances] map keyed by their names.
/// - You can register destruction callbacks with 
///   [registerDestructionCallback] to clean up resources when a pod is removed.
/// - Removing a pod using [remove] will first run its destruction callbacks.
///
/// ### Example usage:
/// ```dart
/// void main() {
///   final scope = SingletonPodScope();
///
///   final userFactory = ObjectFactory<User>(() => User('Alice'));
///
///   // The first call creates and stores the instance.
///   final user1 = scope.get<User>('user', userFactory);
///
///   // The second call returns the same instance (singleton behavior).
///   final user2 = scope.get<User>('user', userFactory);
///
///   print(identical(user1, user2)); // true
///
///   // Register cleanup logic for when the pod is removed.
///   scope.registerDestructionCallback('user', Runnable(() {
///     print('User pod destroyed!');
///   }));
///
///   // Removing triggers the destruction callback.
///   scope.remove('user');
/// }
/// ```
///
/// {@endtemplate}
class SingletonScope extends PodScope {
  /// Stores singleton instances of pods, keyed by their names.
  /// 
  /// [name]: The name of the pod.
  final Map<String, ObjectHolder<Object>> _instances = {};

  /// Stores lists of destruction callbacks for pods, keyed by their names.
  /// 
  /// [name]: The name of the pod.
  final Map<String, List<Runnable>> _destructionCallbacks = {};

  /// {@macro singleton_scope}
  SingletonScope();

  @override
  Future<ObjectHolder<Object>> get(String name, ObjectFactory<Object> factory) async {
    // Creates the pod if it doesn't exist, otherwise returns existing instance.
    if(_instances.containsKey(name)) {
      return _instances[name]!;
    }
    
    return _instances[name] = await factory.get();
  }

  @override
  ObjectHolder<Object>? remove(String name) {
    final value = _instances.remove(name);
    if(value != null) {
      _runDestructionCallbacks(name);
    }

    return value;
  }

  @override
  void registerDestructionCallback(String name, Runnable callback) {
    // Add a cleanup callback to be triggered when the pod is removed.
    _destructionCallbacks.putIfAbsent(name, () => []).add(callback);
  }

  @override
  String? getConversationId() => ScopeType.SINGLETON.name;

  /// {@template pod_scope_get_all_scoped_pods}
  /// Return a map of all scoped pods in the current scope.
  ///
  /// This method returns a map of all scoped pods in the current scope,
  /// where the keys are pod names and the values are the corresponding pod instances.
  ///
  /// Returns a map of scoped pods, where the keys are pod names and the values are the corresponding pod instances
  ///
  /// Example:
  /// ```dart
  /// final scopedPods = scope.getAllScopedPods();
  /// for (final entry in scopedPods.entries) {
  ///   final podName = entry.key;
  ///   final podInstance = entry.value;
  ///   print('Pod name: $podName, Pod instance: $podInstance');
  /// }
  /// ```
  /// {@endtemplate}
  Map<String, ObjectHolder<Object>> getAllScopedPods() => Map.unmodifiable(_instances);

  /// Runs all destruction callbacks for the pod with the given [name].
  /// After execution, the callbacks are removed from memory.
  /// 
  /// [name]: The name of the pod for which to run destruction callbacks.
  void _runDestructionCallbacks(String name) {
    if (_destructionCallbacks.containsKey(name)) {
      for (final callback in _destructionCallbacks[name]!) {
        callback.run();
      }
      _destructionCallbacks.remove(name);
    }
  }
}

// --------------------------------------------------------------------------------------------------------
// PrototypeScope
// --------------------------------------------------------------------------------------------------------

/// {@template prototype_scope}
/// A [PodScope] implementation that creates a new instance of a pod
/// every time it is requested (prototype scope pattern).
/// 
/// Unlike singleton scopes that maintain a single instance, this scope
/// ensures that each call to [get] returns a fresh instance created by
/// the provided [ObjectFactory]. This is useful for stateless objects
/// or objects that should not be shared across different parts of an application.
/// 
/// ## Usage Example:
/// ```dart
/// final scope = PrototypePodScope();
/// final factory = ObjectFactory<MyService>(() => MyService());
/// 
/// // Each call returns a new instance
/// final instance1 = scope.get('myService', factory);
/// final instance2 = scope.get('myService', factory);
/// 
/// print(identical(instance1, instance2)); // false - different instances
/// ```
/// 
/// ## When to Use:
/// - For stateless services that don't need to maintain state
/// - When you need fresh instances for each request
/// - For objects that are expensive to create but used infrequently
/// {@endtemplate}
class PrototypeScope extends PodScope {
  /// {@macro prototype_scope}
  PrototypeScope();

  @override
  Future<ObjectHolder<Object>> get(String name, ObjectFactory<Object> factory) async {
    return await factory.get();
  }

  @override
  String? getConversationId() => ScopeType.PROTOTYPE.name;
}