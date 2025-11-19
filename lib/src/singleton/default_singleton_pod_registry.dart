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
import 'package:jetleaf_logging/logging.dart';
import 'package:meta/meta.dart';

import '../alias/simple_alias_registry.dart';
import '../lifecycle/lifecycle.dart';
import '../exceptions.dart';
import '../helpers/object.dart';
import '../helpers/utils.dart';
import 'singleton_pod_registry.dart';

/// {@template default_singleton_pod_registry}
/// Default implementation of the [SingletonPodRegistry] interface.
///
/// This class provides a comprehensive implementation for managing singleton
/// pod instances with support for:
/// - Singleton caching and lifecycle management
/// - Early singleton references for circular dependency resolution
/// - Singleton factory registration and lazy initialization
/// - Dependency tracking and destruction ordering
/// - Thread-safe singleton operations
/// - Exception handling and suppression
///
/// Key features:
/// - Three-level singleton caching (fully initialized, early, factory)
/// - Circular dependency detection and resolution
/// - Proper destruction order based on dependencies
/// - Container lifecycle management
/// - Comprehensive dependency tracking
///
/// Example usage:
/// ```dart
/// final registry = DefaultSingletonPodRegistry();
///
/// // Register a singleton instance
/// registry.registerSingleton('userService', UserService());
///
/// // Retrieve a singleton
/// final userService = registry.getSingleton('userService');
///
/// // Destroy all singletons during shutdown
/// registry.destroySingletons();
/// ```
/// {@endtemplate}
class DefaultSingletonPodRegistry extends SimpleAliasRegistry implements SingletonPodRegistry {
  /// {@template default_singleton_pod_registry_singleton_objects}
  /// Cache of fully initialized singleton objects: pod name to pod instance.
  ///
  /// This map contains singletons that have been completely initialized
  /// and are ready for use. These are the primary instances returned
  /// by [getSingleton].
  /// {@endtemplate}
  final Map<String, ObjectHolder<Object>> _singletons = {};
  
  /// {@template default_singleton_pod_registry_singleton_factories}
  /// Cache of singleton factories: pod name to ObjectFactory.
  ///
  /// This map contains factory functions that can create singleton instances
  /// when needed. Used for lazy initialization and circular dependency resolution.
  /// {@endtemplate}
  final Map<String, ObjectFactory<Object>> _singletonFactories = {};

  /// {@template default_singleton_pod_registry_singleton_callbacks}
  /// Map of singleton callbacks: pod name to Consumer.
  ///
  /// This map contains callbacks that are executed when a singleton is initialized.
  /// {@endtemplate}
  final Map<String, Consumer<Object>> singletonCallbacks = {};
  
  /// {@template default_singleton_pod_registry_early_singleton_objects}
  /// Cache of early singleton objects: pod name to pod instance.
  ///
  /// This map contains singleton instances that are still being initialized
  /// but are made available early to resolve circular dependencies.
  /// {@endtemplate}
  final Map<String, ObjectHolder<Object>> _earlySingletons = {};
  
  /// {@template default_singleton_pod_registry_registered_singletons}
  /// Set of registered singletons, containing the pod names in registration order.
  ///
  /// This set tracks all singleton names that have been registered, regardless
  /// of their current state (fully initialized, early, or factory).
  /// {@endtemplate}
  final Set<String> _registeredSingletons = <String>{};
  
  /// {@template default_singleton_pod_registry_singletons_currently_in_creation}
  /// Names of pods that are currently in creation.
  ///
  /// This set tracks pods that are actively being initialized to detect
  /// and handle circular dependencies.
  /// {@endtemplate}
  final Set<String> _singletonsCurrentlyInCreation = {};
  
  /// {@template default_singleton_pod_registry_in_creation_check_exclusions}
  /// Names of pods currently excluded from in creation checks.
  ///
  /// This set contains pods that should be excluded from circular dependency
  /// detection, typically for special singleton types.
  /// {@endtemplate}
  final Set<String> _currentlyExcludedPodsForCreationChecks = {};
  
  /// {@template default_singleton_pod_registry_suppressed_exceptions}
  /// Collection of suppressed Exceptions, available for associating related causes.
  ///
  /// This collection stores exceptions that occur during singleton creation
  /// but are suppressed to provide better error reporting.
  /// {@endtemplate}
  final LocalThread<Set<Exception>> _suppressedExceptions = LocalThread<Set<Exception>>();
  
  /// {@template default_singleton_pod_registry_singletons_currently_in_destruction}
  /// Flag that indicates whether we're currently within destroySingletons.
  ///
  /// This flag prevents new singleton creation during destruction phase.
  /// {@endtemplate}
  bool _singletonsCurrentlyInDestruction = false;
  
  /// {@template default_singleton_pod_registry_disposable_pods}
  /// Disposable pod instances: pod name to disposable instance.
  ///
  /// This map tracks pods that implement [DisposablePod] and need
  /// cleanup during destruction.
  /// {@endtemplate}
  final Map<String, ObjectHolder<Object>> _disposablePods = {};
  
  /// {@template default_singleton_pod_registry_contained_pod_map}
  /// Map between containing pod names: pod name to Set of pod names that the pod contains.
  ///
  /// This map tracks containment relationships for proper destruction ordering.
  /// {@endtemplate}
  final Map<String, Set<String>> _containedPods = {};
  
  /// {@template default_singleton_pod_registry_dependent_pod_map}
  /// Map between dependent pod names: pod name to Set of dependent pod names.
  ///
  /// This map tracks which pods depend on other pods for destruction ordering.
  /// {@endtemplate}
  final Map<String, Set<String>> _dependentPods = {};
  
  /// {@template default_singleton_pod_registry_dependencies_for_pod_map}
  /// Map between depending pod names: pod name to Set of pod names for the pod's dependencies.
  ///
  /// This map tracks the dependencies of each pod for destruction ordering.
  /// {@endtemplate}
  final Map<String, Set<String>> _dependenciesForPods = {};

  /// {@template default_singleton_pod_registry_singleton_types}
  /// Map between singleton names: pod name to Class of the singleton.
  ///
  /// This map tracks the types of each singleton for proper initialization.
  /// {@endtemplate}
  final Map<String, Class> _singletonTypes = {};

  /// {@template default_singleton_pod_registry_logger}
  /// Logger for this class.
  /// {@endtemplate}
  final Log _logger = LogFactory.getLog(DefaultSingletonPodRegistry);

  /// {@macro default_singleton_pod_registry}
  DefaultSingletonPodRegistry() {
    _suppressedExceptions.set(<Exception>{});
  }

  @override
  Future<void> registerSingleton(String name, Class type, {ObjectHolder<Object>? object, ObjectFactory<Object>? factory}) async {
    return synchronized(_singletons, () async {
      final oldObject = _singletons[name];
      if (oldObject != null) {
        final objValue = object?.getValue() ?? await factory?.get();
        throw PodException("Could not register object [$objValue] under pod name '$name': there is already object [${oldObject.getValue()}] bound");
      }

      _singletonTypes[name] = type;

      await addSingleton(name, object: object, factory: factory);
    });
  }
  
  /// {@template default_singleton_pod_registry_add_singleton}
  /// Add the given singleton object to the singleton cache of this factory.
  ///
  /// This method registers a fully initialized singleton instance and
  /// cleans up any intermediate state (factories, early references).
  ///
  /// [name]: The name of the pod to register
  /// [qualifiedName]: The fully qualified name of the pod to register
  /// [singleton]: The fully initialized singleton instance
  ///
  /// Example:
  /// ```dart
  /// final userService = UserService();
  /// // Perform dependency injection and initialization
  /// injectDependencies(userService);
  /// initializePod(userService);
  ///
  /// registry.addSingleton('userService', userService);
  /// ```
  /// {@endtemplate}
  /// 
  /// {@template default_singleton_pod_registry_add_singleton_factory}
  /// Add the given singleton factory for building the specified singleton if necessary.
  ///
  /// This method registers a factory function that can create the singleton
  /// instance when needed. Useful for lazy initialization and circular
  /// dependency resolution.
  ///
  /// [name]: The name of the pod to register a factory for
  /// [singletonFactory]: The factory function that creates the singleton instance
  ///
  /// Example:
  /// ```dart
  /// registry.addSingletonFactory('dataSource', () {
  ///   final dataSource = DataSource();
  ///   dataSource.initialize();
  ///   return dataSource;
  /// });
  /// ```
  /// {@endtemplate}
  @protected
  Future<void> addSingleton(String name, {ObjectHolder<Object>? object, ObjectFactory<Object>? factory}) async {
    if(object == null && factory == null) {
      throw IllegalArgumentException("At least one of object or factory must be provided");
    }

    if(object != null) {
      return synchronized(_singletons, () {
        _singletons[name] = object;
        _singletonFactories.remove(name);
        _earlySingletons.remove(name);
        _registeredSingletons.add(name);

        final obj = object.getValue();

        final callback = singletonCallbacks[name];
        if(callback != null) {
          callback(obj);
        }

        if(obj is DisposablePod && !_disposablePods.containsKey(name)) {
          _disposablePods[name] = object;
        }

        final type = object.getType();
        if (type != null) {
          _singletonTypes[name] = type;
        }
      });
    } else if(factory != null) {
      return synchronized(_singletons, () async {
        _singletonFactories[name] = factory;
        _earlySingletons.remove(name);
        _registeredSingletons.add(name);
      });
    }
  }

  @override
  void addSingletonCallback(String name, Class type, Consumer<Object> callback) {
    singletonCallbacks[name] = callback;
    _singletonTypes[name] = type;
  }
  
  @override
  Future<Object?> getSingleton(String name, {bool allowEarlyReference = true, ObjectFactory<Object>? factory}) async {
    final instance = await doGetSingleton(name, allowEarlyReference: allowEarlyReference, factory: factory);
    return instance?.value;
  }

  /// {@template default_singleton_pod_registry_do_get_singleton}
  /// Get the singleton instance for the given name.
  /// 
  /// This method is used to retrieve the singleton instance for the given name.
  /// 
  /// [name]: The name of the singleton to retrieve
  /// [allowEarlyReference]: Whether to allow early references to the singleton
  /// [factory]: The factory to use to create the singleton if necessary
  /// 
  /// Example:
  /// ```dart
  /// final userService = registry.doGetSingleton('userService');
  /// ```
  /// {@endtemplate}
  @protected
  Future<TypedInstance?> doGetSingleton(String name, {bool allowEarlyReference = true, ObjectFactory<Object>? factory}) async {
    if(factory != null) {
      return synchronized(_singletons, () async {
        // 1️⃣ Check if already created
        ObjectHolder<Object>? singleton = _singletons[name];

        Object? result = singleton?.getValue();
        Class? resultType = singleton?.getType();

        if (result == null) {
          // 2️⃣ Prevent creation during destruction phase
          if (_singletonsCurrentlyInDestruction) {
            throw PodCreationNotAllowedException(
              name: name,
              'Singleton pod creation not allowed while singletons of this factory are in destruction (Do not request a pod from a PodFactory in a destroy method implementation!)'
            );
          }

          if (_logger.getIsTraceEnabled()) {
            _logger.trace("Creating shared instance of pod $name");
          }

          // 3️⃣ Mark as in creation
          try {
            beforeSingletonCreation(name);
          } on PodCurrentlyInCreationException catch (_) {
            _singletonFactories[name] = factory;
            final cached = await getSingletonCache(name, allowEarlyReference);

            if (cached != null) {
              final resultType = cached.getType();

              if (resultType != null) {
                _singletonTypes[name] = resultType;
              }

              return TypedInstance(cached.getValue(), resultType);
            }

            beforeSingletonCreation(name);
          }

          bool newSingleton = false;
          bool recordSuppressedExceptions = (_suppressedExceptions.get()?.isEmpty ?? true);
          if (recordSuppressedExceptions) {
            _suppressedExceptions.get()?.clear();
          }

          try {
            singleton = await factory.get();
            result = singleton.getValue();
            resultType = singleton.getType();

            newSingleton = true;
          } on IllegalStateException catch (_) {
            // If factory indicates the state changed and the singleton implicitly appeared,
            // prefer the cache instance if present; otherwise rethrow.
            singleton = _singletons[name];
            if (singleton == null) {
              rethrow;
            }

            result = singleton.getValue();
            resultType = singleton.getType();
          } catch (e) {
            if (recordSuppressedExceptions) {
              for (final ex in _suppressedExceptions.get()!) {
                onSuppressedException(ex);
              }
            }
            rethrow;
          } finally {
            if (recordSuppressedExceptions) {
              _suppressedExceptions.get()?.clear();
            }
            afterSingletonCreation(name);
          }

          // If we created the singleton, register it (tolerate implicit duplicate)
          if (newSingleton) {
            try {
              addSingleton(name, object: singleton);
            } on IllegalStateException catch (_) {
              // Another concurrent path may have registered the same pod.
              // Accept the existing instance if it's identical; otherwise rethrow.
              final existing = _singletons[name];
              if (result != existing?.getValue()) {
                rethrow;
              }
            }
          }
        }

        if (resultType != null) {
          _singletonTypes[name] = resultType;
        }

        return TypedInstance(result, resultType);
      });
    } else {
      final singleton = await getSingletonCache(name, allowEarlyReference);

      if (singleton != null) {
        return TypedInstance(singleton.getValue(), singleton.getType());
      } else {
        return null;
      }
    }
  }

  @protected
  Future<ObjectHolder<Object>?> getSingletonCache(String name, [bool allowEarlyReference = true]) async {
    // 1. Check fully created singletons first (fast path)
    final singleton = _singletons[name];
    if (singleton != null) {
      return singleton;
    }

    // 2. Check for early references (only if pod is in creation)
    if (isCurrentlyCreatingSingleton(name)) {
      return synchronized(_singletons, () async {
        var obj = _earlySingletons[name];

        if (obj == null && allowEarlyReference) {
          obj ??= _singletons[name];
          obj ??= _earlySingletons[name];

          if (obj == null) {
            final factory = _singletonFactories[name];
            if (factory != null) {
              obj = await factory.get();

              if (_singletonFactories.remove(name) != null) {
                _earlySingletons[name] = obj;
              } else {
                obj = _singletons[name];
              }
            }
          }
        }

        return obj;
      });
    }

    return null;
  }
  
  /// {@template default_singleton_pod_registry_before_singleton_creation}
  /// Callback before singleton creation.
  ///
  /// This method performs pre-creation checks and state management,
  /// including circular dependency detection.
  ///
  /// [name]: The name of the pod about to be created
  ///
  /// Throws [PodCurrentlyInCreationException] if circular dependency is detected
  /// {@endtemplate}
  @protected
  void beforeSingletonCreation(String name) {
    if (!_currentlyExcludedPodsForCreationChecks.contains(name) && !_singletonsCurrentlyInCreation.add(name)) {
      throw PodCurrentlyInCreationException(name: name, msg: 'Singleton pod $name is currently in creation');
    }
  }
  
  /// {@template default_singleton_pod_registry_after_singleton_creation}
  /// Callback after singleton creation.
  ///
  /// This method performs post-creation cleanup and state management.
  ///
  /// [name]: The name of the pod that was created
  ///
  /// Throws [PodException] if state inconsistency is detected
  /// {@endtemplate}
  @protected
  void afterSingletonCreation(String name) {
    if (!_currentlyExcludedPodsForCreationChecks.contains(name) && !_singletonsCurrentlyInCreation.remove(name)) {
      throw PodException("Singleton $name isn't currently in creation");
    }
  }

  /// {@template default_singleton_pod_registry_is_actually_in_creation}
  /// Check whether the specified singleton pod is actually in creation.
  ///
  /// [name]: The name of the pod to check
  /// Returns true if the pod is actually in creation, false otherwise
  ///
  /// Example:
  /// ```dart
  /// if (registry.isActuallyInCreation('userService')) {
  ///   print('UserService is actually in creation - possible circular dependency');
  /// }
  /// ```
  /// {@endtemplate}
  @protected
  bool isActuallyInCreation(String name) => isCurrentlyCreatingSingleton(name);

  /// {@template default_singleton_pod_registry_is_singleton_currently_in_creation}
  /// Check whether the specified singleton pod is currently in creation.
  ///
  /// [name]: The name of the pod to check
  /// Returns true if the pod is currently being created, false otherwise
  ///
  /// Example:
  /// ```dart
  /// if (registry.isSingletonCurrentlyInCreation('userService')) {
  ///   print('UserService is being created - possible circular dependency');
  /// }
  /// ```
  /// {@endtemplate}
  @protected
  bool isCurrentlyCreatingSingleton(String name) => _singletonsCurrentlyInCreation.contains(name);

  /// {@template default_singleton_pod_registry_set_currently_in_creation}
  /// Set the specified singleton pod as currently in creation.
  ///
  /// [name]: The name of the pod to set as currently in creation
  /// [inCreation]: Whether the pod is currently in creation
  ///
  /// Example:
  /// ```dart
  /// registry.setCurrentlyInCreation('userService', true);
  /// ```
  /// {@endtemplate}
  void setCurrentlyInCreation(String name, bool inCreation) {
		if (!inCreation) {
			_currentlyExcludedPodsForCreationChecks.add(name);
		} else {
			_currentlyExcludedPodsForCreationChecks.remove(name);
		}
	}

  /// {@template default_singleton_pod_registry_is_currently_in_creation}
  /// Check whether the specified singleton pod is currently in creation.
  ///
  /// [name]: The name of the pod to check
  /// Returns true if the pod is currently being created, false otherwise
  ///
  /// Example:
  /// ```dart
  /// if (registry.isCurrentlyInCreation('userService')) {
  ///   print('UserService is being created - possible circular dependency');
  /// }
  /// ```
  /// {@endtemplate}
  bool isCurrentlyInCreation(String name) => !_currentlyExcludedPodsForCreationChecks.contains(name) && isActuallyInCreation(name);
  
  @override
  bool containsSingleton(String name) => _singletons.containsKey(name) || _singletonFactories.containsKey(name);
  
  @override
  List<String> getSingletonNames() => synchronized(_singletons, () => List.from(_registeredSingletons));
  
  @override
  int getSingletonCount() => synchronized(_singletons, () => _registeredSingletons.length);
  
  /// {@template default_singleton_pod_registry_destroy_singleton}
  /// Destroy the given pod. Delegates to destroyPod if a corresponding disposable pod instance is found.
  ///
  /// This method handles the complete destruction lifecycle including:
  /// - Removal from singleton caches
  /// - Dependency cleanup
  /// - Disposable pod destruction
  /// - Contained pod destruction
  ///
  /// [name]: The name of the pod to destroy
  ///
  /// Example:
  /// ```dart
  /// registry.destroySingleton('userService');
  /// ```
  /// {@endtemplate}
  @protected
  Future<void> destroySingleton(String name) async {
    // Destroy the corresponding DisposablePod instance
    var pod = _disposablePods[name];
    synchronized(_disposablePods, () => pod = _disposablePods.remove(name));
    
    if(pod != null) {
      await destroyPod(name, pod!.getValue());
    }

    // Remove a registered singleton of the given name, if any
    removeSingleton(name);
  }
  
  @override
  void removeSingleton(String name) {
    return synchronized(_singletons, () {
      _singletons.remove(name);
      _singletonFactories.remove(name);
      _singletonTypes.remove(name);
      _earlySingletons.remove(name);
      _disposablePods.remove(name);
      _registeredSingletons.remove(name);
    });
  }

  /// {@template default_singleton_pod_registry_destroy_singletons}
  /// Destroy all singleton pods in this registry.
  ///
  /// This method performs complete registry shutdown by:
  /// - Destroying all singletons in reverse registration order
  /// - Cleaning up all internal state
  /// - Handling proper destruction order based on dependencies
  ///
  /// Example:
  /// ```dart
  /// // During application shutdown
  /// registry.destroySingletons();
  /// ```
  /// {@endtemplate}
  Future<void> destroySingletons() async {
    synchronized(_singletons, () => _singletonsCurrentlyInDestruction = true);
    
    final names = List<String>.from(_disposablePods.keys);
    for (int i = names.length - 1; i >= 0; i--) {
      await destroySingleton(names[i]);
    }
    
    _containedPods.clear();
    _dependentPods.clear();
    _dependenciesForPods.clear();
    
    clearSingletonCache();

    return synchronized(_singletons, () => _singletonsCurrentlyInDestruction = true);
  }
  
  /// {@template default_singleton_pod_registry_destroy_pod}
  /// Destroy the given pod.
  ///
  /// This method performs the actual pod destruction including:
  /// - Dependency destruction
  /// - Disposable pod cleanup
  /// - Contained pod destruction
  /// - Dependency map cleanup
  ///
  /// [name]: The name of the pod being destroyed
  /// [pod]: The pod instance to destroy (may be null)
  ///
  /// Example:
  /// ```dart
  /// final pod = registry.getSingleton('userService');
  /// registry.destroyPod('userService', pod);
  /// ```
  /// {@endtemplate}
  @protected
  Future<void> destroyPod(String name, Object pod) async  {
    await destroyDependentPods(name);
    
    // Actually destroy the pod now
    try {
      if (pod is DisposablePod) {
        await pod.onDestroy();
      }

      if (pod is Closeable) {
        await pod.close();
      }

      if (pod is StreamSubscription) {
        await pod.cancel();
      }
    } on Exception catch (e) {
      onSuppressedException(e);
    }
    
    // Trigger destruction of contained pods
    Set<String>? containedPods;
    synchronized(_containedPods, () => containedPods = _containedPods.remove(name));

    print("Contained - $containedPods - $name");
    if (containedPods != null) {
      for (final containedPodName in containedPods!) {
        await destroySingleton(containedPodName);
      }
    }
    
    // Remove destroyed pod from other pods' dependencies
    synchronized(_dependentPods, () {
      for (final dependentName in _dependentPods.keys.toList()) {
        final dependents = _dependentPods[dependentName];
        dependents?.remove(name);
        if (dependents?.isEmpty == true) {
          _dependentPods.remove(dependentName);
        }
      }
    });
    
    // Remove destroyed pod's own dependencies from the registry
    _dependenciesForPods.remove(name);
  }
  
  /// {@template default_singleton_pod_registry_destroy_dependent_pods}
  /// Destroy all pods that depend on the specified pod.
  ///
  /// This method ensures proper destruction order by first destroying
  /// dependent pods before destroying the pod they depend on.
  ///
  /// [name]: The name of the pod whose dependents should be destroyed
  ///
  /// Example:
  /// ```dart
  /// // Before destroying UserService, destroy all pods that depend on it
  /// registry.destroyDependentPods('userService');
  /// ```
  /// {@endtemplate}
  @protected
  Future<void> destroyDependentPods(String name) async {
    Set<String>? dependents;

    synchronized(_dependentPods, () => dependents = _dependentPods.remove(name));

    if (dependents != null) {
      for (final dependentName in dependents!) {
        await destroySingleton(dependentName);
      }
    }
  }

  /// {@template default_singleton_pod_registry_register_disposable_pod}
  /// Register a disposable pod for the given pod name.
  ///
  /// This method is used to register a pod that implements the [DisposablePod]
  /// interface, allowing it to be destroyed when the registry is destroyed.
  ///
  /// [name]: The name of the pod to register
  /// [pod]: The pod to register
  ///
  /// Example:
  /// ```dart
  /// final userService = UserService();
  /// // Perform dependency injection and initialization
  /// injectDependencies(userService);
  /// initializePod(userService);
  ///
  /// registry.registerDisposablePod('userService', userService);
  /// ```
  /// {@endtemplate}
  @protected
  void registerDisposablePod(String name, DisposablePod pod, [String? qualifiedName]) {
		return synchronized(_disposablePods, () {
      _disposablePods.put(name, ObjectHolder<Object>(pod, packageName: pod.getPackageName(), qualifiedName: qualifiedName));
    });
	}
  
  /// {@template default_singleton_pod_registry_clear_singleton_cache}
  /// Clear all cached singleton instances in this registry.
  ///
  /// This method resets the registry to its initial state by clearing
  /// all singleton caches and resetting internal state flags.
  ///
  /// Example:
  /// ```dart
  /// // After destruction or for testing
  /// registry.clearSingletonCache();
  /// ```
  /// {@endtemplate}
  @override
  void clearSingletonCache() {
    return synchronized(_singletons, () {
      _singletons.clear();
      _singletonFactories.clear();
      _earlySingletons.clear();
      _registeredSingletons.clear();
      _singletonsCurrentlyInDestruction = false;
    });
  }
  
  /// {@template default_singleton_pod_registry_register_contained_pod}
  /// Register a containment relationship between two pods.
  ///
  /// This method tracks which pods contain other pods for proper
  /// destruction ordering (contained pods are destroyed first).
  ///
  /// [child]: The name of the pod that is contained
  /// [parent]: The name of the pod that does the containing
  ///
  /// Example:
  /// ```dart
  /// // Register that UserService contains a UserRepository
  /// registry.registerContainedPod('userRepository', 'userService');
  /// ```
  /// {@endtemplate}
  @protected
  void registerContainedPod(String child, String parent) {
    synchronized(_containedPods, () {
      final containedPods = _containedPods.putIfAbsent(parent, () => <String>{});
      containedPods.add(child);

      _containedPods[parent] = containedPods;
    });
  }
  
  /// {@template default_singleton_pod_registry_register_dependent_pod}
  /// Register a dependent pod for the given pod.
  ///
  /// This method tracks dependency relationships for proper destruction
  /// ordering (dependents are destroyed before their dependencies).
  ///
  /// [name]: The name of the pod that is depended upon
  /// [dependentName]: The name of the pod that has the dependency
  ///
  /// Example:
  /// ```dart
  /// // Register that OrderService depends on UserService
  /// registry.registerDependentPod('userService', 'orderService');
  /// ```
  /// {@endtemplate}
  @protected
  void registerDependentPod(String name, String dependentName) {
    final canonicalName = PodUtils.transformedName(name);
    
    synchronized(_dependentPods, () {
      final dependents = _dependentPods.putIfAbsent(canonicalName, () => <String>{});
      if (!dependents.add(dependentName)) {
        return;
      }
    });
    
    synchronized(_dependenciesForPods, () {
      final dependenciesForPod = _dependenciesForPods.putIfAbsent(dependentName, () => <String>{});
      dependenciesForPod.add(canonicalName);
    });
  }
  
  /// {@template default_singleton_pod_registry_is_dependent}
  /// Determine whether the specified dependent pod has been registered as
  /// dependent on the given pod or on any of its transitive dependencies.
  ///
  /// This method checks for both direct and transitive dependencies.
  ///
  /// [name]: The name of the pod to check for dependency
  /// [dependentName]: The name of the potentially dependent pod
  /// Returns true if there is a dependency relationship, false otherwise
  ///
  /// Example:
  /// ```dart
  /// if (registry.isDependent('userService', 'orderService')) {
  ///   print('OrderService depends on UserService');
  /// }
  /// ```
  /// {@endtemplate}
  @protected
  bool isDependent(String name, String dependentName) {
    return synchronized(_dependentPods, () {
      return _isDependent(name, dependentName, null);
    });
  }
  
  bool _isDependent(String name, String dependentName, Set<String>? visited) {
    if (visited != null && visited.contains(name)) {
      return false;
    }

    final canonicalName = PodUtils.transformedName(name);
    final dependents = _dependentPods[canonicalName];
    if (dependents == null) {
      return false;
    }

    if (dependents.contains(dependentName)) {
      return true;
    }

    for (final dep in dependents) {
      visited ??= <String>{};
      visited.add(name);
      if (_isDependent(dep, dependentName, visited)) {
        return true;
      }
    }

    return false;
  }
  
  /// {@template default_singleton_pod_registry_has_dependent_pod}
  /// Determine whether a dependent pod has been registered for the given name.
  ///
  /// [name]: The name of the pod to check
  /// Returns true if any pods depend on this pod, false otherwise
  ///
  /// Example:
  /// ```dart
  /// if (registry.hasDependentPod('userService')) {
  ///   print('Some pods depend on UserService');
  /// }
  /// ```
  /// {@endtemplate}
  @protected
  bool hasDependentPod(String name) => _dependentPods.containsKey(name);
  
  /// {@template default_singleton_pod_registry_get_dependent_pods}
  /// Return the names of all pods which depend on the specified pod, if any.
  ///
  /// [name]: The name of the pod to get dependents for
  /// Returns a list of pod names that depend on the specified pod
  ///
  /// Example:
  /// ```dart
  /// final dependents = registry.getDependentPods('userService');
  /// print('Pods that depend on UserService: $dependents');
  /// ```
  /// {@endtemplate}
  @protected
  List<String> getDependentPods(String name) {
    final dependents = _dependentPods[name];

    if (dependents == null) {
      return [];
    }

    return synchronized(_dependentPods, () => List.from(dependents));
  }
  
  /// {@template default_singleton_pod_registry_get_dependencies_for_pod}
  /// Return the names of all pods that the specified pod depends on, if any.
  ///
  /// [name]: The name of the pod to get dependencies for
  /// Returns a list of pod names that the specified pod depends on
  ///
  /// Example:
  /// ```dart
  /// final dependencies = registry.getDependenciesForPod('orderService');
  /// print('OrderService depends on: $dependencies');
  /// ```
  /// {@endtemplate}
  @protected
  List<String> getDependenciesForPod(String name) {
    final dependenciesForPod = _dependenciesForPods[name];

    if (dependenciesForPod == null) {
      return [];
    }

    return synchronized(_dependenciesForPods, () => List.from(dependenciesForPod));
  }
  
  /// {@template default_singleton_pod_registry_on_suppressed_exception}
  /// Handle a suppressed exception.
  ///
  /// This method logs a warning message if the logger is enabled.
  ///
  /// [ex]: The exception to handle
  ///
  /// Example:
  /// ```dart
  /// registry.onSuppressedException(Exception('Suppressed exception'));
  /// ```
  /// {@endtemplate}
  @protected
  void onSuppressedException(Exception ex) {
    if(_logger.getIsWarnEnabled()) {
      _logger.add(LogLevel.WARN, 'Suppressed exception: $ex');
    }
  }

  /// {@template default_singleton_pod_registry_get_singleton_class}
  /// Return the class of the specified singleton pod, if any.
  ///
  /// [name]: The name of the singleton pod to get the class for
  /// Returns the class of the specified singleton pod, or null if not found
  ///
  /// Example:
  /// ```dart
  /// final singletonClass = registry.getSingletonClass('userService');
  /// print('Singleton class: $singletonClass');
  /// ```
  /// {@endtemplate}
  @protected
  Class? getSingletonClass(String name) => _singletonTypes[name];
}

/// {@template typed_instance}
/// A strongly typed object wrapper that couples a runtime [value]
/// with its reflective [Class] type within the Jetleaf type system.
///
/// The [TypedInstance] class is used to represent objects that have
/// explicit reflective type metadata attached — useful for dependency
/// resolution, reflection, and runtime type-safe operations.
///
/// Unlike a raw object reference, a [TypedInstance] preserves both the
/// **instance value** and its **declared Jetleaf class metadata**, allowing
/// the framework to perform advanced introspection and autowiring.
///
/// ### Example
/// ```dart
/// // Suppose `DatabaseService` is a Jetleaf-managed class.
/// final db = DatabaseService();
/// final type = Class.of(DatabaseService);
///
/// final typed = TypedInstance(db, type);
///
/// print(typed.instance); // The actual service object
/// print(typed.type.name); // "DatabaseService"
/// ```
/// {@endtemplate}
final class TypedInstance {
  /// {@template typed_instance.instance_field}
  /// The underlying object reference represented by this typed instance.
  ///
  /// Jetleaf components typically use this value during autowiring or
  /// when invoking reflective executables such as constructors or
  /// factory methods.
  ///
  /// Example:
  /// ```dart
  /// print(typedInstance.instance); // -> DatabaseService()
  /// ```
  /// {@endtemplate}
  final Object value;

  /// {@template typed_instance.type_field}
  /// The reflective [Class] metadata describing the runtime type of [value].
  ///
  /// This type information allows Jetleaf to perform reflective lookups,
  /// dependency matching, and type-based caching.
  ///
  /// Example:
  /// ```dart
  /// print(typedInstance.type.getQualifiedName()); // "package:example/test.dart.DatabaseService"
  /// ```
  /// {@endtemplate}
  final Class? type;

  /// {@template typed_instance.constructor}
  /// Creates a new [TypedInstance] that binds a concrete [value] to
  /// its reflective [type].
  ///
  /// This is primarily used internally by Jetleaf’s dependency factory
  /// or reflective utilities to track runtime objects with their
  /// associated metadata.
  ///
  /// Example:
  /// ```dart
  /// final typed = TypedInstance(service, Class.of(service.runtimeType));
  /// ```
  /// {@endtemplate}
  TypedInstance(this.value, this.type);
}