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
import 'package:meta/meta.dart';

import '../definition/pod_definition.dart';
import '../definition/pod_definition_registry.dart';
import '../definition/simple_pod_definition_registry.dart';
import '../dependency/adaptable_resolver_dependency.dart';
import '../dependency/object_factory_dependency.dart';
import '../dependency/object_provider_dependency.dart';
import '../dependency/optional_dependency.dart';
import '../helpers/nullable_pod.dart';
import '../exceptions.dart';
import '../helpers/object.dart';
import '../helpers/utils.dart';
import '../lifecycle/lifecycle.dart';
import 'abstract_autowire_pod_factory.dart';
import 'factory_aware_order_source_provider.dart';
import 'pod_factory.dart';

/// {@template default_listable_pod_factory}
/// Default implementation of [ConfigurableListablePodFactory] that provides
/// comprehensive pod management capabilities in the Jetleaf framework.
/// 
/// This class extends [AbstractAutowirePodFactory] and implements advanced features
/// including pod definition registry, dependency resolution, annotation-based
/// pod discovery, and configuration management.
/// 
/// Key Features:
/// - Complete pod definition lifecycle management (register, remove, query)
/// - Annotation-based pod discovery and filtering
/// - Advanced dependency resolution with autowire candidate checking
/// - Singleton pre-instantiation for eager initialization
/// - Configuration freezing to prevent runtime modifications
/// - Hierarchical pod factory support with parent delegation
/// 
/// Usage Example:
/// ```dart
/// final factory = DefaultListablePodFactory();
/// 
/// // Register pod definitions
/// await factory.registerDefinition('userService', UserServiceDefinition());
/// 
/// // Get all pods of a specific type
/// final services = await factory.getPodsOf<UserService>(Class.forObject(UserService));
/// 
/// // Find pods with specific annotations
/// final annotatedPods = await factory.getPodsWithAnnotation<RestController>(Class.forObject(RestController));
/// 
/// // Pre-instantiate singletons for faster startup
/// await factory.preInstantiateSingletons();
/// ```
/// 
/// See also:
/// - [AbstractAutowirePodFactory] for the base autowire functionality
/// - [ConfigurableListablePodFactory] for the interface contract
/// - [PodDefinitionRegistry] for pod definition management
/// {@endtemplate}
class DefaultListablePodFactory extends AbstractAutowirePodFactory implements ConfigurableListablePodFactory {
  /// {@template default_listable_pod_factory.pod_definition_registry}
  /// Thread-local storage for pod definition registry.
  /// 
  /// Manages all pod definitions in a thread-safe manner, providing isolation
  /// between different execution contexts while sharing the same factory instance.
  /// 
  /// See also:
  /// - [SimplePodDefinitionRegistry] for the default implementation
  /// - [PodDefinitionRegistry] for the interface contract
  /// {@endtemplate}
  final LocalThread<SimplePodDefinitionRegistry> _podDefinitionRegistry = LocalThread<SimplePodDefinitionRegistry>();
  
  /// {@template default_listable_pod_factory.configuration_frozen}
  /// Flag indicating whether factory configuration is frozen.
  /// 
  /// When `true`, prevents modifications to pod definitions and factory
  /// configuration to ensure runtime stability. Once frozen, attempts to
  /// register new definitions or modify existing ones will throw exceptions.
  /// 
  /// Default: `false` (configuration is mutable)
  /// {@endtemplate}
  bool _configurationFrozen = false;
  
  /// {@template default_listable_pod_factory.resolvable_dependencies}
  /// Registry of resolvable dependencies by type.
  /// 
  /// Maps dependency types to their pre-resolved values, allowing for
  /// custom dependency injection of values that aren't managed as pods.
  /// 
  /// Example:
  /// ```dart
  /// factory.registerResolvableDependency(Class<String>(), "default-value");
  /// ```
  /// {@endtemplate}
  final Map<Class, Object?> _resolvableDependencies = {};

  /// {@template default_listable_pod_factory.ignored_dependency_types}
  /// Set of dependency types that should be ignored during autowiring.
  /// 
  /// Dependencies of these types will not be considered as autowire candidates,
  /// effectively excluding them from dependency resolution process.
  /// 
  /// See also:
  /// - [registerIgnoredDependency] for adding types to this set
  /// {@endtemplate}
  final Set<Class> _ignoredDependencyTypes = {};

  /// {@template default_listable_pod_factory.merged_pod_definition_holders}
  /// Cache of merged pod definition holders for performance optimization.
  /// 
  /// Stores computed pod definition metadata after merging parent definitions,
  /// annotations, and configuration to avoid repeated computation during
  /// dependency resolution and pod instantiation.
  /// 
  /// Key: Pod name
  /// Value: Tuple containing name, definition, and aliases
  /// {@endtemplate}
  final Map<String, PodDefinitionHolder> _mergedPodDefinitionHolders = {};

  /// {@template default_listable_pod_factory.singleton_and_non_singleton_pod_names}
  /// Map of all pod names (singleton and non-singleton) by dependency type.
  /// 
  /// Used for fast lookup of all pods that can satisfy a given dependency type,
  /// regardless of their scope. This includes both singleton and prototype scoped pods.
  /// 
  /// Key: Dependency type [Class]
  /// Value: List of pod names that implement or extend the type
  /// {@endtemplate}
  final Map<Class, List<String>> _singletonAndNonSingletonPodNames = {};

  /// {@template default_listable_pod_factory.singleton_pod_names}
  /// Map of singleton-only pod names by dependency type.
  /// 
  /// Used for fast lookup of singleton pods that can satisfy a given dependency type.
  /// This excludes prototype-scoped pods and is used when only singletons are required.
  /// 
  /// Key: Dependency type [Class]
  /// Value: List of singleton pod names that implement or extend the type
  /// {@endtemplate}
  final Map<Class, List<String>> _singletonPodNames = {};

  /// {@template default_listable_pod_factory.dependency_comparator}
  /// Comparator used for ordering dependencies during resolution.
  /// 
  /// When multiple dependencies satisfy a requirement, this comparator
  /// determines the order in which they are considered. Can be used to
  /// implement custom dependency prioritization logic.
  /// 
  /// See also:
  /// - [setDependencyComparator] for setting a custom comparator
  /// - [getDependencyComparator] for retrieving the current comparator
  /// {@endtemplate}
  Comparator<Object>? _dependencyComparator;

  /// {@template default_listable_pod_factory.frozen_pod_definition_names}
  /// Immutable list of pod definition names when configuration is frozen.
  /// 
  /// When configuration is frozen, this list provides a snapshot of all
  /// registered pod definition names to prevent modifications while
  /// allowing efficient read operations.
  /// 
  /// See also:
  /// - [freezeConfiguration] for freezing the factory
  /// {@endtemplate}
  List<String> _frozenPodDefinitionNames = [];
  
  /// {@macro default_listable_pod_factory}
  /// 
  /// Creates a new [DefaultListablePodFactory] with an optional parent factory.
  /// 
  /// The parent factory allows for hierarchical dependency resolution where
  /// pods not found in this factory can be delegated to the parent.
  /// 
  /// [parentFactory] Optional parent pod factory for hierarchical resolution
  DefaultListablePodFactory([super.parentFactory]) {
    _podDefinitionRegistry.set(SimplePodDefinitionRegistry());
  }

  // ----------------------------------------------------------------------------------------------------
  // PUBLIC METHODS
  // ----------------------------------------------------------------------------------------------------

  /// {@template default_listable_pod_factory.set_dependency_comparator}
  /// Sets the dependency comparator used by this factory.
  /// 
  /// The comparator is used to determine the order of dependency resolution
  /// when multiple candidates are available. This affects autowiring behavior
  /// and collection injection ordering.
  /// 
  /// [comparator] the dependency comparator to set
  /// 
  /// Example:
  /// ```dart
  /// factory.setDependencyComparator((a, b) => a.priority.compareTo(b.priority));
  /// ```
  /// {@endtemplate}
  void setDependencyComparator(Comparator<Object> comparator) {
    _dependencyComparator = comparator;
  }

  /// {@template default_listable_pod_factory.get_dependency_comparator}
  /// Returns the dependency comparator used by this factory.
  /// 
  /// The comparator is used to determine the order of dependency resolution.
  /// 
  /// Returns the [Comparator<Object>] instance, or `null` if no comparator is set
  /// 
  /// Example:
  /// ```dart
  /// final comparator = factory.getDependencyComparator();
  /// ```
  /// {@endtemplate}
  Comparator<Object>? getDependencyComparator() => _dependencyComparator;

  /// {@template default_listable_pod_factory.freeze_configuration}
  /// Freezes the factory configuration to prevent runtime modifications.
  /// 
  /// When frozen, the factory prevents modifications to pod definitions
  /// and configuration, ensuring runtime stability. This is typically called
  /// after all pods are registered and before the application starts processing
  /// requests.
  /// 
  /// Once frozen, attempts to register new definitions will throw
  /// [PodDefinitionStoreException].
  /// 
  /// Usage Example:
  /// ```dart
  /// final factory = DefaultListablePodFactory();
  /// // Register all definitions...
  /// await factory.registerDefinition('serviceA', ServiceADefinition());
  /// await factory.registerDefinition('serviceB', ServiceBDefinition());
  /// 
  /// factory.freezeConfiguration(); // Prevent further modifications
  /// 
  /// // This will now throw an exception:
  /// // await factory.registerDefinition('serviceC', ServiceCDefinition());
  /// ```
  /// {@endtemplate}
  void freezeConfiguration() {
    _configurationFrozen = true;
    _frozenPodDefinitionNames = List.unmodifiable(getPodRegistry().getDefinitionNames());
    clearMetadataCache();
  }

  // ------------------------------------------------------------------------------------------------
  // OVERRIDDEN METHODS
  // ------------------------------------------------------------------------------------------------

  @override
  void copyConfigurationFrom(ConfigurablePodFactory other) {
    super.copyConfigurationFrom(other);

    if (other is DefaultListablePodFactory) {
      _resolvableDependencies.addAll(other._resolvableDependencies);
      _ignoredDependencyTypes.addAll(other._ignoredDependencyTypes);
      _dependencyComparator = other._dependencyComparator;
    }
  }

  @override
  String getPackageName() => PackageNames.POD;

  @override
  Future<void> addSingleton(String name, {ObjectHolder<Object>? object, ObjectFactory<Object>? factory}) async {
    super.addSingleton(name, object: object, factory: factory);

    final filter = ((Class cls) => cls != Class<Object>() && cls.isInstance(object?.getValue()));
    _singletonAndNonSingletonPodNames.keys.toList().removeWhere(filter);
    _singletonPodNames.keys.toList().removeWhere(filter);
  }

  @override
  Future<Set<A>> findAllAnnotationsOnPod<A>(String podName, Class<A> type) async {
    final result = <A>{};
    
    try {
      if (containsDefinition(podName)) {
        final podDef = getDefinition(podName);
        final podClass = podDef.type;
        
        if (podClass.hasDirectAnnotation<A>()) {
          final annotation = podClass.getDirectAnnotation<A>();
          if (annotation != null) {
            result.add(annotation);
          }
        } else if (podDef.hasAnnotation<A>()) {
          final annotation = podDef.getAnnotation<A>();
          if (annotation != null) {
            result.add(annotation);
          }
        }
      }
    } catch (e) {
      if(logger.getIsTraceEnabled()) {
        logger.trace("Could not find annotations on pod '$podName': $e");
      }
    }
    
    return result;
  }

  @override
  Future<A?> findAnnotationOnPod<A>(String podName, Class<A> type) async {
    try {
      if (containsDefinition(podName)) {
        final podDef = getDefinition(podName);
        final podClass = podDef.type;
        
        if (podClass.hasDirectAnnotation<A>()) {
          return podClass.getDirectAnnotation<A>();
        } else if (podDef.hasAnnotation<A>()) {
          return podDef.getAnnotation<A>();
        }
      }
    } catch (e) {
      if(logger.getIsTraceEnabled()) {
        logger.trace("Could not find annotation on pod '$podName': $e");
      }
    }
    
    return null;
  }

  @override
  bool containsDefinition(String podName) => getPodRegistry().containsDefinition(podName);

  @override
  PodDefinition getDefinition(String podName) {
    try {
      return getPodRegistry().getDefinition(podName);
    } on NoSuchPodDefinitionException catch (_) {
      if(logger.getIsWarnEnabled()) {
        logger.warn("No pod named '$podName' is defined");
      }
      
      throw PodDefinitionStoreException(
        name: podName,
        resourceDescription: null,
        msg: "No pod named '$podName' is defined"
      );
    }
  }

  @override
  PodDefinition getDefinitionByClass(Class type) {
    try {
      return getPodRegistry().getDefinitionByClass(type);
    } on NoSuchPodDefinitionException catch (_) {
      if(logger.getIsWarnEnabled()) {
        logger.warn("No pod of type '${type.getQualifiedName()}' is defined");
      }
      
      throw PodDefinitionStoreException(
        name: type.getName(),
        resourceDescription: null,
        msg: "No pod of type '${type.getQualifiedName()}' is defined"
      );
    }
  }

  @override
  List<String> getDefinitionNames() {
    if (_configurationFrozen) {
      return _frozenPodDefinitionNames;
    }
    
    return getPodRegistry().getDefinitionNames();
  }

  @override
  int getNumberOfPodDefinitions() {
    if (_configurationFrozen) {
      return _frozenPodDefinitionNames.length;
    }
    
    return getPodRegistry().getNumberOfPodDefinitions();
  }

  @override
  Future<Class> getPodClass(String name) async {
    Class? type;

    if (containsDefinition(name)) {
      final podDef = getDefinition(name);

      if (podDef is AbstractPodDefinition) {
        if (podDef.getPodExpression() != null) {
          final podClass = await _resolvePodClass(podDef);
          if(podClass != null) {
            type = podClass;
          }
        }
      }
      
      type ??= podDef.type;
    }

    if (type == null && containsSingleton(name)) {
      type = getSingletonClass(name);
    }

    final parent = getParentFactory();
    if (parent != null && type == null) {
      return await parent.getPodClass(name);
    }

    if (type == null) {
      throw PodDefinitionStoreException(
        name: name,
        resourceDescription: null,
        msg: "No pod named '$name' is defined"
      );
    }

    return type;
  }

  @override
  Future<List<String>> getPodNames(Class type, {bool includeNonSingletons = false, bool allowEagerInit = false}) async {
    final result = <String>[];
    final cache = includeNonSingletons ? _singletonAndNonSingletonPodNames : _singletonPodNames;
    final resolvedNames = cache[type];
    
    if(resolvedNames != null && _configurationFrozen) {
      return resolvedNames;
    }
    
    // Check definition registry
    try {
      final names = getDefinitionNames();
      for (String name in names) {
        if (isAlias(name)) {
          continue;
        }

        final definition = getDefinition(name);
        final cls = definition.type;
        final notLazy = definition.lifecycle.isLazy != null ? !definition.lifecycle.isLazy! : false;

        if (!definition.isAbstractAndNoFactory() && (allowEagerInit || notLazy || !await _requiresEagerInit(name))) {
          final isPp = await isPodProvider(name);
          final allowPpInit = allowEagerInit || containsSingleton(name);
          final isS = await isSingleton(name);

          if (cls == type || cls.isSubclassOf(type) || type.isAssignableFrom(cls) || type.isInstance(cls)) {
            if (!isPp) {
              if (includeNonSingletons || isS) {
                if (allowPpInit) {
                  await get(type);
                }
                
                result.add(name);
              }
            } else {
              name = podProviderName(name);
              if (includeNonSingletons || isS) {
                if (allowPpInit) {
                  await get(type);
                }
                
                result.add(name);
              }
            }
          }
        }
      }
    } on PodDefinitionStoreException catch (e) {
      if (allowEagerInit) {
        rethrow;
      }

      if (logger.getIsTraceEnabled()) {
        logger.trace("Could not get pod names for type '$type'. $e");
      }

      onSuppressedException(e);
    }
    
    cache.add(type, result);
    
    return result;
  }

  @override
  Future<List<String>> getPodNamesForAnnotation<A>(Class<A> type) async {
    final result = <String>[];
    
    // Check definition registry
    final names = getDefinitionNames();
    for (final name in names) {
      final definition = getDefinition(name);
      
      if (definition.hasAnnotation<A>()) {
        result.add(name);
      } else if (definition.type.hasDirectAnnotation<A>()) {
        result.add(name);
      } else if (definition.type.getAllDirectAnnotations().any((a) => a.getClass() == type)) {
        result.add(name);
      }
    }

    // Check parent factory
    final parent = getParentFactory();
    if (parent != null && parent is ListablePodFactory) {
      result.addAll(await parent.getPodNamesForAnnotation<A>(type));
    }
    
    return result;
  }

  @override
  Iterator<String> getPodNamesIterator() {
    final allNames = <String>{};
    
    // Add pod definition names first
    allNames.addAll(getDefinitionNames());
    
    // Add manually registered singleton names
    final singletonNames = getSingletonNames();
    for (final name in singletonNames) {
      if (!allNames.contains(name)) {
        allNames.add(name);
      }
    }
    
    return allNames.iterator;
  }

  @override
  void clearMetadataCache() {
    super.clearMetadataCache();

    getDefinitionNames().forEach((name) => clearMergedPodDefinition(name));
    _mergedPodDefinitionHolders.clear();
  }

  @override
  Future<Map<String, T>> getPodsOf<T>(Class<T> type, {bool includeNonSingletons = false, bool allowEagerInit = false}) async {
    final result = <String, T>{};
    final podNames = await getPodNames(type, includeNonSingletons: includeNonSingletons, allowEagerInit: allowEagerInit);

    for (final name in podNames) {
      try {
        final pod = await getPod<T>(name);
        if (pod is! NullablePod) {
          result[name] = pod;
        }
      } on PodNotOfRequiredTypeException catch (_) {
        // ignore
      } on PodCreationException catch (e) {
        if (e is PodCurrentlyInCreationException) {
					String exPodName = (e as PodCurrentlyInCreationException).name;
					if (isCurrentlyInCreation(exPodName)) {
						if (logger.getIsTraceEnabled()) {
							logger.trace("Ignoring match to currently created Pod '$exPodName': ${e.getMessage()}");
						}

						onSuppressedException(e);
						// Ignore: indicates a circular reference when autowiring constructors.
						// We want to find matches other than the currently created pod itself.
						continue;
					}
				}
				
        rethrow;
      }
    }
    
    return result;
  }

  @override
  Future<Map<String, Object>> getPodsWithAnnotation<A>(Class<A> type) async {
    final result = <String, Object>{};
    final podNames = await getPodNamesForAnnotation<A>(type);
    
    for (final name in podNames) {
      final pod = await getPod(name);
      if (pod is! NullablePod) {
        result[name] = pod;
      }
    }
    
    return result;
  }

  @override
  Future<ObjectProvider<T>> getProvider<T>(Class<T> type, {String? podName, bool allowEagerInit = false}) async {
    final objects = <ObjectHolder<T>>[];
    final result = await getPodsOf<T>(type, includeNonSingletons: true, allowEagerInit: allowEagerInit);
    if (result.isNotEmpty) {
      for (final value in result.values) {
        objects.add(ObjectHolder<T>(value, qualifiedName: type.getQualifiedName(), packageName: type.getPackage()?.getName()));
      }
    }

    String name;
    if (podName != null) {
      name = podName;
    } else {
      try {
        final podClass = getDefinitionByClass(type);
        name = podClass.name;
      } catch (e) {
        name = type.getName();
      }
    }
    
    return DefaultObjectProvider(name, this, objects);
  }

  @override
  bool isAutowireCandidate(String podName, DependencyDescriptor descriptor) {
    // Check if dependency type is ignored
    if (isTypeIgnored(descriptor.type)) {
      return false;
    }
    
    // Check if dependency interface is ignored
    if (isInterfaceIgnored(descriptor.type)) {
      return false;
    }

    final name = transformedPodName(podName);
    
    try {
      if (containsDefinition(name)) {
        return _isAutowireCandidate(podName, getLocalMergedPodDefinition(podName), descriptor);
      } else if (containsSingleton(name)) {
        final singletonClass = getSingletonClass(name);
        if (singletonClass == null) {
          return false;
        }

        return _isAutowireCandidate(podName, RootPodDefinition(type: singletonClass), descriptor);
      }
      
      // Check parent factory if available
      final parent = getParentFactory();
      if (parent != null && parent is ConfigurableListablePodFactory) {
        return parent.isAutowireCandidate(podName, descriptor);
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> containsType(Class requestedType, [bool allowPodProviderInit = false]) async {
    // 1) Fast path: check all cached singletons
    final singletonNames = getSingletonNames(); // Iterable<String>
    for (final name in singletonNames) {
      final holder = await getSingletonCache(name, false);
      if (holder == null) continue;
      final holderType = holder.getType()?.getType();
      if (holderType == NullablePod.CLASS.getType()) continue; // ignored placeholder

      final instance = holder.getValue();

      // 1.a) If instance is a PodProvider
      if (instance is PodProvider) {
        // If provider itself would satisfy requestedType (e.g. requestedType is PodProvider or compatible)
        if (instance.supportsType(requestedType)) {
          return true;
        }

        // Try to determine what the provider produces (may instantiate provider if allowed)
        final produced = await getPodProviderType(instance, allowPodProviderInit);
        if (produced != null && requestedType.isAssignableFrom(produced)) {
          return true;
        }

        // If requestedType has generics, consult local definition metadata (if available)
        if (requestedType.hasGenerics() && containsDefinition(name)) {
          final merged = getLocalMergedPodDefinition(name);
          final Class declared = merged.type;
          if (POD_PROVIDER_CLASS.isAssignableFrom(declared)) {
            // If requested type is not a provider, try matching component type
            if (!POD_PROVIDER_CLASS.isAssignableFrom(requestedType) && !requestedType.isAssignableFrom(declared)) {
              final comp = declared.componentType();
              if (comp != null && requestedType.isAssignableFrom(comp)) {
                return true;
              }
            }
          } else {
            if (requestedType.isAssignableFrom(declared)) return true;
          }
        }

        // Not matched by this provider instance
        continue;
      }

      // 1.b) If instance is not a provider
      if (requestedType.isInstance(instance)) {
        return true;
      }

      // For generics, consult the local definition if exists
      if (requestedType.hasGenerics() && containsDefinition(name)) {
        final def = getLocalMergedPodDefinition(name);
        final Class declared = def.type;
        if (!declared.isInstance(instance)) {
          final Class? comp = requestedType.componentType();
          if (comp != null && !comp.isInstance(instance)) {
            // instance doesn't match component type -> continue searching
            continue;
          }
          if (requestedType.isAssignableFrom(declared)) return true;
        } else {
          if (requestedType.isAssignableFrom(declared)) return true;
        }
      }
    } // end singletons loop

    // 2) Check local PodDefinitions (declarations) even if not instantiated yet
    final localNames = getDefinitionNames();
    for (final name in localNames) {
      final def = getLocalMergedPodDefinition(name);

      // 2.a) Declared type directly matches
      final Class declaredType = def.type;
      if (requestedType.isAssignableFrom(declaredType)) {
        return true;
      }

      // 2.b) If declared type is a PodProvider, check provided type metadata first
      if (POD_PROVIDER_CLASS.isAssignableFrom(declaredType)) {
        // If the definition exposes providedType metadata, prefer that
        final Class providedFromDef = def.type; // optional metadata; null if unknown
        if (requestedType.isAssignableFrom(providedFromDef)) {
          return true;
        }

        // If allowed, instantiate provider to inspect produced type
        if (allowPodProviderInit) {
          try {
            final providerInstance = await getPod(name, []);
            if (providerInstance is PodProvider) {
              final Class? produced = await getPodProviderType(providerInstance, true);
              if (produced != null && requestedType.isAssignableFrom(produced)) {
                return true;
              }
            }
          } catch (_) {
            // ignore provider instantiation failures and continue scanning others
          }
        }

        // For generics, check component type on declared provider
        if (requestedType.hasGenerics()) {
          final Class? declaredComp = declaredType.componentType();
          final Class? wantedComp = requestedType.componentType();
          if (declaredComp != null && wantedComp != null && wantedComp.isAssignableFrom(declaredComp)) {
            return true;
          }
        }

        // continue checking other definitions
        continue;
      }

      // 2.c) Generics: check component/generic compatibility between requestedType and declaredType
      if (requestedType.hasGenerics()) {
        final Class? declaredComp = declaredType.componentType();
        final Class? wantedComp = requestedType.componentType();
        if (declaredComp != null && wantedComp != null && wantedComp.isAssignableFrom(declaredComp)) {
          return true;
        }
      }
    } // end local definitions loop

    // 3) Delegate to parent factory if present
    final parent = getParentFactory();
    if (parent != null) {
      try {
        return await parent.containsType(requestedType, allowPodProviderInit);
      } catch (_) {
        // If parent lookup errors, treat as no match (robust fallback)
        return false;
      }
    }

    // 4) Nothing matched
    return false;
  }

  @override
  Future<void> preInstantiateSingletons() async {
    if (logger.getIsDebugEnabled()) {
      logger.debug("Starting pre-instantiation of singleton pods in $runtimeType.");
    }

    final podNames = List<String>.from(getDefinitionNames());
    final pods = <String, Object>{};

    // Instantiate processors first
    for (final name in podNames) {
      final entry = await instantiateSingletonPod(name);
      if (entry != null) {
        final value = entry.value;
        pods[entry.key] = value;
      }
    }

    // Call on ready when singletons are initialized
    for (final name in podNames) {
      final instance = await getSingleton(name);

      if (instance is SmartInitializingSingleton) {
        if (logger.getIsTraceEnabled()) {
          logger.trace("Invoking onSingletonReady() for '$name'");
        }
        
        await instance.onSingletonReady();
        
        if (logger.getIsTraceEnabled()) {
          logger.trace("Successfully invoked onSingletonReady() for '$name'");
        }
      }
    }
  }

  /// Attempts to pre-instantiate a singleton pod and returns its resolved instance.
  ///
  /// This method is used during container startup or refresh phases to eagerly
  /// create all non-lazy singleton pods. It performs several validation checks
  /// before instantiation and safely skips pods that should not or cannot be
  /// created at this time.
  ///
  /// ### Behavior Overview
  ///
  /// The method proceeds through the following steps:
  ///
  /// 1. **Lookup merged pod definition**  
  ///    Retrieves the effective pod definition for [podName]. If the definition
  ///    is missing, a warning is logged and `null` is returned.
  ///
  /// 2. **Eligibility checks**  
  ///    The pod is skipped if:
  ///    - It is *abstract* and has no factory method (`isAbstractAndNoFactory()`), or  
  ///    - It is not defined as a *singleton* (`!def.scope.isSingleton`)
  ///
  ///    These cases indicate the pod cannot or should not be instantiated
  ///    directly.
  ///
  /// 3. **Lazy singletons**  
  ///    If the pod's lifecycle is marked as `lazy`, it will not be created
  ///    eagerly and is simply skipped.
  ///
  /// 4. **Provider pods**  
  ///    If the pod is a provider, its *real* target pod name is resolved before
  ///    invoking [getPod].
  ///
  /// 5. **Instantiation & error handling**  
  ///    Attempts to create (or retrieve) the pod instance through [getPod].  
  ///    - If the pod is already in creation (`PodCurrentlyInCreationException`),
  ///      instantiation is skipped to avoid circular-creation conflicts.
  ///    - Any other failure is logged and rethrown.
  ///
  /// ### Return Value
  /// - Returns a [MapEntry] of the original [podName] and its instantiated
  ///   singleton instance on success.
  /// - Returns `null` if the pod is skipped or cannot be instantiated.
  ///
  /// ### Logging
  /// - **TRACE** logs are emitted for all skip conditions.
  /// - **WARN** logs are emitted when:
  ///   - The definition is missing
  ///   - Instantiation of an eligible singleton fails
  ///
  /// ### Example
  /// ```dart
  /// final entry = await instantiateSingletonPod("userService");
  /// if (entry != null) {
  ///   print("Pre-instantiated: ${entry.key} -> ${entry.value}");
  /// }
  /// ```
  ///
  /// ### Throws
  /// - Re-throws any exception from [getPod] other than
  ///   [PodCurrentlyInCreationException].
  ///
  /// ### See also
  /// - [getPod]
  /// - [isPodProvider]
  /// - [podProviderName]
  /// - [getLocalMergedPodDefinition]
  Future<MapEntry<String, Object>?> instantiateSingletonPod(String podName) async {
    try {
      final def = getLocalMergedPodDefinition(podName);

      // Must be singleton and instantiable
      if (def.isAbstractAndNoFactory() || !def.scope.isSingleton) {
        if (logger.getIsTraceEnabled()) {
          logger.trace(
            "Skipping pod '$podName': definition is not a singleton, "
            "it's abstract with no factory or has non-singleton scope."
          );
        }
        return null;
      }

      // Lazy singletons are skipped
      final isLazy = def.lifecycle.isLazy == true;
      if (isLazy) {
        if (logger.getIsTraceEnabled()) {
          logger.trace("Pod '$podName' is marked as lazy. Skipping pre-instantiation.");
        }
        return null;
      }

      // Provider pod?
      final bool provider = await isPodProvider(podName);
      final String realName = provider ? podProviderName(podName) : podName;

      try {
        final Object instance = await getPod(realName);
        return MapEntry(podName, instance);
      } on PodCurrentlyInCreationException catch (_) {
        if (logger.getIsTraceEnabled()) {
          logger.trace("Pod '$podName' is currently being created elsewhere. Skipping.");
        }

        return null;
      } catch (e) {
        if (logger.getIsWarnEnabled()) {
          logger.warn("Failed to pre-instantiate singleton '$podName'", error: e);
        }

        rethrow;
      }
    } on NoSuchPodDefinitionException catch (_) {
      if (logger.getIsWarnEnabled()) {
        logger.warn("No definition found for '$podName' while pre-instantiating singletons");
      }

      return null;
    }
  }

  @override
  Future<void> registerDefinition(String podName, PodDefinition podDefinition) async {
    if (_configurationFrozen) {
      throw PodDefinitionStoreException(
        name: podName,
        resourceDescription: podDefinition.description,
        msg: "Cannot register pod definition '$podName': factory is frozen"
      );
    }

    PodUtils.validateName(podName);

    PodDefinition? existingDefinition;
    if (containsDefinition(podName)) {
      existingDefinition = getDefinition(podName);

      if (!getAllowDefinitionOverriding()) {
        throw PodDefinitionOverrideException(podName);
      }

      _logDefinitionOverriding(podName, podDefinition, existingDefinition);

      if (podDefinition.name.isEmpty) {
        podDefinition.name = podName;
      }

      getPodRegistry().registerDefinition(podName, podDefinition);
    } else {
      if (isAlias(podName)) {
        String aliasedName = targetName(podName);

        if (!getAllowDefinitionOverriding()) {
          if (containsDefinition(aliasedName)) {
            throw PodDefinitionOverrideException(podName);
          } else {
            throw PodDefinitionStoreException(
              name: podName,
              resourceDescription: podDefinition.description,
              msg: "Cannot register pod definition for pod '$podName' when another pod is bound to the alias '$aliasedName'"
            );
          }
        } else {
          if (logger.getIsInfoEnabled()) {
            logger.info("Removing alias '$podName' for pod '$aliasedName' due to the registration of a new pod definition [$podDefinition] for pod '$podName'");
          }

          removeAlias(podName);
        }
      }

      if(logger.getIsTraceEnabled()) {
        logger.trace("Pod definition '$podName' does not exist. Attempting registration");
      }

      if (podDefinition.name.isEmpty) {
        podDefinition.name = podName;
      }
      
      getPodRegistry().registerDefinition(podName, podDefinition);
      _frozenPodDefinitionNames = [];
    }

    if (existingDefinition != null || containsSingleton(podName)) {
      resetDefinition(podName);
    }
  }

  @override
  void registerIgnoredDependency(Class type) {
    _ignoredDependencyTypes.add(type);

    if (type.isInterface()) {
      ignoreDependencyInterface(type);
    } else {
      ignoreDependencyType(type);
    }
  }

  @override
  void registerResolvableDependency(Class type, [Object? autowiredValue]) {
    _resolvableDependencies[type] = autowiredValue;
  }

  @override
  Future<void> removeDefinition(String podName) async {
    if (_configurationFrozen) {
      throw PodDefinitionStoreException(
        name: podName,
        msg: "Cannot remove pod definition '$podName': factory is frozen"
      );
    }

    if (containsDefinition(podName)) {
      await getPodRegistry().removeDefinition(podName);
      resetDefinition(podName);
    }

    final parent = getParentFactory();
    if (parent != null && parent is DefaultListablePodFactory && parent.containsDefinition(podName)) {
      await parent.removeDefinition(podName);
    }
  }

  @override
  Future<Object?> doResolveDependency(DependencyDescriptor descriptor, [Set<String>? autowiredPods]) async {
    // 1. Get type
    final type = descriptor.type;
    final podName = descriptor.podName;
    final lookup = descriptor.lookup;

    // 🔹 Special handling for ObjectFactory / ObjectProvider / (dart's class with the factory design)
    if (Class<ObjectFactory>(null, PackageNames.POD).isAssignableFrom(type) && !Class<ObjectProvider>(null, PackageNames.POD).isAssignableFrom(type)) {
      return ObjectFactoryDependency<Object>(descriptor, this);
    }
    
    if (Class<ObjectProvider>(null, PackageNames.POD).isAssignableFrom(type)) {
      return ObjectProviderDependency<Object>(descriptor, this);
    }

    // 3. Handle Optional<T>
    if (Class<Optional>(null, PackageNames.LANG).isAssignableFrom(type)) {
      return await OptionalDependency(this).resolve(descriptor);
    }

    if (lookup != null && lookup.isNotEmpty) {
      String dependencyName = targetName(lookup);

      if (await isTypeMatch(dependencyName, type) && isAutowireCandidate(dependencyName, descriptor) && !selfReferenced(podName, dependencyName)) {
        if (autowiredPods != null) {
          autowiredPods.add(dependencyName);
        }

        final result = await _get(dependencyName, type);
        return verifyInstance(result, type, dependencyName, descriptor);
      }
    }

    // Handle Stream<T>
    if (Class<Stream>(null, PackageNames.DART).isAssignableFrom(type)) {
      final result = await resolveMultipleCollectionPods(podName, descriptor, autowiredPods);
      if (result is List) {
        return Stream<Object>.fromIterable(List<Object>.from(result)).where((obj) => obj is! NullablePod);
      }

      return result != null ? Stream<Object>.value(result).where((obj) => obj is! NullablePod) : null;
    }
    
    // Handle GenericStream<T>
    if (Class<GenericStream>(null, PackageNames.LANG).isAssignableFrom(type)) {
      Object? result = await resolveMultipleCollectionPods(podName, descriptor, autowiredPods);
      if (result is List) {
        return GenericStream<Object>.of(List<Object>.from(result)).filter((obj) => obj is! NullablePod);
      }

      return result != null ? GenericStream<Object>.ofSingle(result).filter((obj) => obj is! NullablePod) : null;
    }
    
    // Handle Set<T>
    if (Class<Set>(null, PackageNames.DART).isAssignableFrom(type)) {
      final pods = await resolveMultipleCollectionPods(podName, descriptor, autowiredPods);
      return AdaptableResolverDependency.resolveSet(type, podName, descriptor, autowiredPods, pods);
    }
    
    // Handle List<T> or arrays
    if (type.isArray() || Class<List>(null, PackageNames.DART).isAssignableFrom(type)) {
      final pods = await resolveMultipleCollectionPods(podName, descriptor, autowiredPods);
      return AdaptableResolverDependency.resolveList(type, podName, descriptor, autowiredPods, pods);
    }
    
    // Handle Map<String, T>
    if (type.isKeyValuePaired() || Class<Map>(null, PackageNames.DART).isAssignableFrom(type)) {
      final pods = await resolveMultipleMappedPods(podName, descriptor, autowiredPods);
      return AdaptableResolverDependency.resolveMap(type, podName, descriptor, autowiredPods, pods);
    }

    Map<String, Object> candidates = await findAutowireCandidates(podName, descriptor);
    if (candidates.isEmpty) {
      return notifyDependencyNotFound(podName, descriptor);
    }

    String? autowiredName;
		Object? instanceCandidate;

    if (candidates.length > 1) {
      autowiredName = determineAutowireCandidate(candidates, descriptor);

      if (autowiredName == null) {
        if (isRequired(descriptor)) {
          return notifyMultipleCandidatesFound(type, candidates);
        } else {
          return null;
        }
      }
  
      instanceCandidate = candidates[autowiredName];
    } else {
      instanceCandidate = candidates.values.first;
      autowiredName = candidates.keys.first;
    }

    if (autowiredPods != null) {
      autowiredPods.add(autowiredName);
    }

    if (instanceCandidate != null) {
      final instance = convertIfNecessary(podName, instanceCandidate, type);
      return verifyInstance(instance, type, podName, descriptor);
    }

    return null;
  }

  // -----------------------------------------------------------------------------------------------
  // PROTECTED METHODS
  // -----------------------------------------------------------------------------------------------

  /// {@template default_listable_pod_factory.get_pod_registry}
  /// Returns the pod definition registry used by this factory.
  /// 
  /// The registry manages all pod definitions and provides methods for
  /// registration, removal, and querying of pod definitions.
  /// 
  /// Returns the [PodDefinitionRegistry] instance
  /// 
  /// Example:
  /// ```dart
  /// final registry = factory.getPodRegistry();
  /// final names = registry.getDefinitionNames();
  /// ```
  /// {@endtemplate}
  @protected
  PodDefinitionRegistry getPodRegistry() => _podDefinitionRegistry.get()!;

  /// {@template default_listable_pod_factory.reset_definition}
  /// Resets the cached state for a specific pod definition.
  /// 
  /// This method clears both the merged definition cache and any singleton
  /// instances associated with the pod, forcing fresh resolution on next access.
  /// 
  /// Use this method when pod definitions change at runtime or when
  /// troubleshooting dependency resolution issues.
  /// 
  /// [podName] the name of the pod to reset
  /// 
  /// Example:
  /// ```dart
  /// factory.resetDefinition('userService');
  /// ```
  /// {@endtemplate}
  @protected
  void resetDefinition(String podName) {
    clearMergedPodDefinition(podName);
    destroySingleton(podName);
  }

  /// {@template default_listable_pod_factory.verify_instance}
  /// Verifies that a resolved instance matches the expected type and requirements.
  /// 
  /// This method performs type checking and nullability validation on
  /// resolved dependency instances to ensure they meet the dependency
  /// requirements.
  /// 
  /// [instance] the resolved instance to verify
  /// [type] the expected type of the dependency
  /// [name] the name of the pod being verified
  /// [descriptor] the dependency descriptor
  /// 
  /// Returns the verified instance
  /// 
  /// Throws:
  /// - [NoSuchPodDefinitionException] if instance is NullablePod and dependency is required
  /// - [PodNotOfRequiredTypeException] if instance type doesn't match expected type
  /// {@endtemplate}
  @protected
  Object? verifyInstance(Object instance, Class type, String name, DependencyDescriptor descriptor) {
    if (instance is NullablePod) {
      if (isRequired(descriptor)) {
        throw NoSuchPodDefinitionException.byTypeWithMessage(
          type,
          "No pod definition found for required type '${type.getQualifiedName()}'. "
          "Ensure that a pod of this type is registered in the factory or provided by configuration."
        );
      }

      return null;
    }

    if (!type.isInstance(instance)) {
      throw PodNotOfRequiredTypeException(name: name, requiredType: type, actualType: instance.getClass());
    }

    return instance;
  }

  /// {@template default_listable_pod_factory.notify_dependency_not_found}
  /// Notifies that a required dependency was not found.
  /// 
  /// This method creates and throws an appropriate exception when a
  /// required dependency cannot be resolved.
  /// 
  /// [podName] the name of the pod that required the dependency
  /// [descriptor] the dependency descriptor that couldn't be resolved
  /// 
  /// Throws:
  /// - [NoSuchPodDefinitionException] with detailed error message
  /// {@endtemplate}
  @protected
  Object notifyDependencyNotFound(String podName, DependencyDescriptor descriptor) {
    final typeName = descriptor.type.getQualifiedName().substring(descriptor.type.getQualifiedName().lastIndexOf(".") + 1);
    
    throw NoSuchPodDefinitionException.byTypeWithMessage(
      descriptor.type,
      "No pod definition found for required type '$typeName' (qualified name: '${descriptor.type.getQualifiedName()}'). "
      "Ensure that a pod of this type is registered in the factory or provided by configuration."
    );
  }

  /// {@template default_listable_pod_factory.notify_multiple_candidates_found}
  /// Notifies that multiple candidates were found for a required dependency.
  /// 
  /// This method creates and throws an appropriate exception when multiple
  /// pods satisfy a dependency requirement and autowiring cannot determine
  /// which one to use.
  /// 
  /// [requiredType] the type of dependency that has multiple candidates
  /// [candidates] the map of candidate pod names to instances
  /// 
  /// Throws:
  /// - [NoUniquePodDefinitionException] with detailed error message
  /// {@endtemplate}
  @protected
  String notifyMultipleCandidatesFound(Class requiredType, Map<String, Object> candidates) {
    final typeName = requiredType.getQualifiedName().substring(requiredType.getQualifiedName().lastIndexOf(".") + 1);
    
    throw NoUniquePodDefinitionException.byTypeWithNamesAndMessage(
      requiredType,
      candidates.keys.toList(),
      "Multiple pod definitions found for required type '$typeName' (qualified name: '${requiredType.getQualifiedName()}'). "
      "Candidates: ${candidates.keys.join(', ')}. "
      "Consider marking one as @Primary, using @Qualifier to disambiguate, or narrowing the injection point."
    );
  }

  /// {@template default_listable_pod_factory.resolve_multiple_mapped_pods}
  /// Resolves multiple pods as a mapped collection.
  /// 
  /// This method handles dependency resolution for Map<String, T> dependencies
  /// by finding all pods of the value type and mapping them by pod name.
  /// 
  /// [podName] the name of the pod requiring the dependency
  /// [descriptor] the dependency descriptor for the map
  /// [autowiredPods] optional set to track autowired pods
  /// 
  /// Returns a [Map] of pod names to pod instances, or `null` if no pods found
  /// {@endtemplate}
  @protected
  Future<Object?> resolveMultipleMappedPods(String? podName, DependencyDescriptor descriptor, Set<String>? autowiredPods) async {
    Class cls = descriptor.type;
    Class? keyType = descriptor.key ?? cls.keyType();
    Class? valueType = descriptor.component ?? cls.componentType();
    
    if (keyType != Class<String>()) {
      return null;
    }

    if (valueType == null) {
      return null;
    }

    final matchingPods = await findAutowireCandidates(podName, DependencyDescriptor(
      source: valueType,
      podName: descriptor.podName,
      propertyName: descriptor.propertyName,
      type: valueType,
      lookup: descriptor.lookup,
      isEager: descriptor.isEager,
      isRequired: descriptor.isRequired
    ));
    if (matchingPods.isEmpty) {
      return null;
    }
    
    final result = <String, Object>{};

    if (autowiredPods != null) {
      autowiredPods.addAll(matchingPods.keys);
    }
    
    for (final entry in matchingPods.entries) {
      final key = entry.key;
      final pod = entry.value;
      result[key] = convertIfNecessary(podName ?? entry.key, pod, valueType);
    }
    
    return result;
  }

  /// {@template default_listable_pod_factory.resolve_multiple_collection_pods}
  /// Resolves multiple pods as a collection.
  /// 
  /// This method handles dependency resolution for collection types like
  /// List<T>, Set<T>, Stream<T> by finding all pods of the element type
  /// and collecting them into the appropriate collection type.
  /// 
  /// [podName] the name of the pod requiring the dependency
  /// [descriptor] the dependency descriptor for the collection
  /// [autowiredPods] optional set to track autowired pods
  /// 
  /// Returns a collection of pod instances, or `null` if no pods found
  /// {@endtemplate}
  @protected
  Future<Object?> resolveMultipleCollectionPods(String? podName, DependencyDescriptor descriptor, Set<String>? autowiredPods) async {
    Class cls = descriptor.type;
    Class? valueType = descriptor.component ?? cls.componentType();

    if (valueType == null) {
      return null;
    }

    final matchingPods = await findAutowireCandidates(podName, DependencyDescriptor(
      source: valueType,
      podName: descriptor.podName,
      propertyName: descriptor.propertyName,
      type: valueType,
      lookup: descriptor.lookup,
      isEager: descriptor.isEager,
      isRequired: descriptor.isRequired
    ));

    if (matchingPods.isEmpty) {
      return null;
    }
    
    final result = <Object>[];

    if (autowiredPods != null) {
      autowiredPods.addAll(matchingPods.keys);
    }
    
    for (final entry in matchingPods.entries) {
      final pod = entry.value;
      result.add(convertIfNecessary(podName ?? entry.key, pod, valueType));
    }

    result.sort(_getDependencyComparator(matchingPods)?.compare);
    
    return result;
  }

  /// {@template default_listable_pod_factory.find_autowire_candidates}
  /// Finds all autowire candidates for a dependency.
  /// 
  /// This method searches for all pods that match the dependency type
  /// and are valid autowire candidates according to the dependency descriptor.
  /// 
  /// [podName] the name of the pod requiring the dependency
  /// [descriptor] the dependency descriptor
  /// 
  /// Returns a [Map] of candidate pod names to instances
  /// {@endtemplate}
  @protected
  Future<Map<String, Object>> findAutowireCandidates(String? podName, DependencyDescriptor descriptor) async {
    final candidates = <String, Object>{};
    final type = descriptor.type;
    
    final podsOfType = await PodUtils.podsOfTypeIncludingAncestors(this, type, includeNonSingletons: true, allowEagerInit: true);
    
    for (final entry in podsOfType.entries) {
      final candidate = entry.key;
      final pod = entry.value;
      // Check if pod is an autowire candidate
      if (isAutowireCandidate(candidate, descriptor) && !selfReferenced(podName, candidate)) {
        if (containsSingleton(candidate)) {
          // Early reference handling
          final earlyRef = await getSingletonCache(candidate);
          final value = earlyRef?.getValue();

          if (value != null) {
            candidates[candidate] = value;
          } else {
            // Might throw exception instead of this...
            candidates[candidate] = pod;
          }
        } else {
          candidates[candidate] = pod;
        }
      }
    }
    
    return candidates;
  }

  /// {@template default_listable_pod_factory.determine_autowire_candidate}
  /// Determines the best autowire candidate from multiple options.
  /// 
  /// This method applies various strategies to select the most appropriate
  /// candidate when multiple pods satisfy a dependency requirement:
  /// 1. Primary candidate
  /// 2. Name matching
  /// 3. Highest priority candidate
  /// 4. Resolvable dependency
  /// 
  /// [candidates] the map of candidate pod names to instances
  /// [descriptor] the dependency descriptor
  /// 
  /// Returns the selected candidate name, or `null` if no candidate can be determined
  /// {@endtemplate}
  @protected
  String? determineAutowireCandidate(Map<String, Object> candidates, DependencyDescriptor descriptor) {
    String? candidate = determinePrimaryCandidate(candidates.keys.toList());
    if (candidate != null) {
      return candidate;
    }

    candidate = candidates.keys.find((c) => matchesName(c, descriptor.podName));
    if (candidate != null) {
      return candidate;
    }

    candidate = candidates.keys.find((c) => matchesName(c, descriptor.propertyName));
    if (candidate != null) {
      return candidate;
    }

    candidate = determineHighestPriorityCandidate(candidates, descriptor.type);
    if (candidate != null) {
      return candidate;
    }

    candidate = candidates.entries.find((e) => _resolvableDependencies.containsValue(e.value))?.key;
    if (candidate != null) {
      return candidate;
    }

    return null;
  }

  /// {@template default_listable_pod_factory.is_primary_candidate}
  /// Checks if a pod is marked as a primary candidate.
  /// 
  /// Primary candidates are preferred when multiple pods satisfy a dependency.
  /// 
  /// [podName] the name of the pod to check
  /// 
  /// Returns `true` if the pod is a primary candidate, `false` otherwise
  /// {@endtemplate}
  @protected
  bool isPrimaryCandidate(String podName) {
    final name = transformedPodName(podName);

    if (containsDefinition(name)) {
      return getLocalMergedPodDefinition(name).design.isPrimary;
    }

    final parent = getParentFactory();
    if (parent != null && parent is DefaultListablePodFactory) {
      return parent.isPrimaryCandidate(name);
    }

    return false;
  }

  /// {@template default_listable_pod_factory.determine_primary_candidate}
  /// Determines the primary candidate from a list of candidate names.
  /// 
  /// This method searches through the candidates and returns the first
  /// one that is marked as primary.
  /// 
  /// [candidates] the list of candidate pod names
  /// 
  /// Returns the primary candidate name, or `null` if no primary candidate exists
  /// {@endtemplate}
  @protected
  String? determinePrimaryCandidate(List<String> candidates) {
    for (final candidate in candidates) {
      if (isPrimaryCandidate(candidate)) {
        return candidate;
      }
    }

    return null;
  }
  
  /// {@template default_listable_pod_factory.determine_highest_priority_candidate}
  /// Determines the highest priority candidate from multiple options.
  /// 
  /// This method evaluates the priority of each candidate and selects
  /// the one with the highest priority (lowest numerical value). If
  /// multiple candidates have the same highest priority, it indicates
  /// a conflict.
  /// 
  /// [candidates] the map of candidate pod names to instances
  /// [requiredType] the type of dependency being resolved
  /// 
  /// Returns the highest priority candidate name, or throws an exception if conflict exists
  /// {@endtemplate}
  @protected
  String? determineHighestPriorityCandidate(Map<String, Object> candidates, Class requiredType) {
    String? highestPrioritizedName;
		int? highestPriority;
		bool highestPriorityConflictDetected = false;
    
    for (final entry in candidates.entries) {
			String candidate = entry.key;
			Object instance = entry.value;

			int? candidatePriority = getPriority(instance);
      if (candidatePriority != null) {
        if (highestPriority != null) {
          if (candidatePriority.equals(highestPriority)) {
            highestPriorityConflictDetected = true;
          } else if (candidatePriority < highestPriority) {
            highestPrioritizedName = candidate;
            highestPriority = candidatePriority;
            highestPriorityConflictDetected = false;
          }
        } else {
          highestPrioritizedName = candidate;
          highestPriority = candidatePriority;
        }
      }
		}
    
    if (highestPriorityConflictDetected) {
			return notifyMultipleCandidatesFound(requiredType, candidates);
		}

		return highestPrioritizedName;
  }

  /// {@template default_listable_pod_factory.get_priority}
  /// Gets the priority of an instance for dependency resolution.
  /// 
  /// This method extracts the priority value from an instance using
  /// the dependency comparator if it's an [OrderComparator].
  /// 
  /// [instance] the instance to get priority for
  /// 
  /// Returns the priority value, or `null` if no priority can be determined
  /// {@endtemplate}
  @protected
  int? getPriority(Object instance) {
		final comparator = getDependencyComparator();
    if (comparator is OrderComparator) {
      return comparator.getPriority(instance);
    }

    return null;
	}

  /// {@template default_listable_pod_factory.matches_name}
  /// Checks if a pod name matches a candidate name.
  /// 
  /// This method checks if the pod name directly matches the candidate name
  /// or if any of the pod's aliases match the candidate name.
  /// 
  /// [podName] the pod name to check
  /// [candidateName] the candidate name to match against
  /// 
  /// Returns `true` if the names match, `false` otherwise
  /// {@endtemplate}
  @protected
  bool matchesName(String podName, [String? candidateName]) {
    return candidateName != null && (candidateName.equals(podName) || getAliases(podName).any((a) => a.equals(candidateName)));
  }

  /// {@template default_listable_pod_factory.self_referenced}
  /// Checks if a candidate pod is a self-reference.
  /// 
  /// This method detects circular references where a pod depends on itself,
  /// either directly or through factory method relationships.
  /// 
  /// [podName] the name of the pod requiring the dependency
  /// [candidateName] the name of the candidate pod
  /// 
  /// Returns `true` if the candidate is a self-reference, `false` otherwise
  /// {@endtemplate}
  @protected
  bool selfReferenced([String? podName, String? candidateName]) {
    return podName != null && candidateName != null &&
      (podName.equals(candidateName) || (containsDefinition(podName) && podName.equals(getLocalMergedPodDefinition(candidateName).factoryMethod.podName)));
  }

  /// {@template default_listable_pod_factory.is_required}
  /// Checks if a dependency is required.
  /// 
  /// This method determines whether a dependency must be resolved or if
  /// it can be omitted. Optional dependencies and nullable types are
  /// not required.
  /// 
  /// [descriptor] the dependency descriptor to check
  /// 
  /// Returns `true` if the dependency is required, `false` otherwise
  /// {@endtemplate}
  @protected
  bool isRequired(DependencyDescriptor descriptor) {
    // Check if dependency is required (not Optional, not nullable)
    return !Class<Optional>(null, PackageNames.LANG).isAssignableFrom(descriptor.type) || descriptor.isRequired;
  }

  // -----------------------------------------------------------------------------------------------
  // PRIVATE METHODS
  // -----------------------------------------------------------------------------------------------

  /// {@template default_listable_pod_factory.resolve_pod_class}
  /// Resolves the pod class from a pod expression.
  /// 
  /// This internal method evaluates pod expressions that define classes
  /// dynamically and converts the evaluation result to a [Class] instance.
  /// 
  /// [podDef] the pod definition containing the expression
  /// 
  /// Returns the resolved [Class] or `null` if resolution fails
  /// 
  /// See also:
  /// - [AbstractPodDefinition.getPodExpression] for expression format
  /// {@endtemplate}
  Future<Class?> _resolvePodClass(AbstractPodDefinition podDef) async {
		final expression = podDef.getPodExpression();
		final evaluated = await evaluateExpression(expression, podDef);

    if(evaluated != null) {
      if (evaluated.getValue() is Class) {
        return evaluated.getValue() as Class;
      } else if(evaluated.getQualifiedName() != null && evaluated.getQualifiedName()!.isNotEmpty) {
        return Class.fromQualifiedName(evaluated.getQualifiedName()!);
      } else if(evaluated.getPackageName() != null && evaluated.getPackageName()!.isNotEmpty) {
        return evaluated.getValue().getClass(null, evaluated.getPackageName()!);
      }
    }

    return null;
	}

  /// {@template default_listable_pod_factory.requires_eager_init}
  /// Checks if a pod requires eager initialization.
  /// 
  /// This method determines whether a pod should be initialized eagerly
  /// based on its scope and singleton status. It returns true if the pod
  /// is a provider and not a singleton.
  /// 
  /// [name] The name of the pod to check
  /// 
  /// Returns a [Future] that completes with `true` if the pod requires eager initialization
  /// {@endtemplate}
  Future<bool> _requiresEagerInit(String name) async => await isPodProvider(name) && !containsSingleton(name);

  /// {@template default_listable_pod_factory._is_autowire_candidate}
  /// Internal method to check autowire candidate status for a pod definition.
  /// 
  /// This method performs the actual autowire candidate checking logic
  /// by examining the pod definition's autowire candidate settings and
  /// abstract status.
  /// 
  /// [name] the pod name
  /// [rpd] the root pod definition
  /// [descriptor] the dependency descriptor
  /// 
  /// Returns `true` if the pod is an autowire candidate, `false` otherwise
  /// {@endtemplate}
  bool _isAutowireCandidate(String name, RootPodDefinition rpd, DependencyDescriptor descriptor) {
    final podName = transformedPodName(name);
    final pdh = _mergedPodDefinitionHolders.computeIfAbsent(podName, (key) => (podName, rpd, getAliases(podName)));
    final def = pdh.$2;

    // Check if pod is abstract
    if (def.isAbstractAndNoFactory()) {
      return false;
    }
    
    return pdh.$2.autowireCandidate.autowireCandidate;
  }

  /// {@template default_listable_pod_factory._log_definition_overriding}
  /// Internal method to log pod definition overriding events.
  /// 
  /// This method provides detailed logging when pod definitions are
  /// overridden, including information about the existing and new definitions
  /// and their roles in the application hierarchy.
  /// 
  /// [podName] the name of the pod being overridden
  /// [newD] the new pod definition
  /// [existing] the existing pod definition being replaced
  /// {@endtemplate}
  void _logDefinitionOverriding(String podName, PodDefinition newD, PodDefinition existing) {
    final explicitlyOverride = getAllowDefinitionOverriding();

    if (existing.design.role.value < newD.design.role.value) {
      // Example: ROLE_APPLICATION overridden by ROLE_SUPPORT or ROLE_INFRASTRUCTURE
      if (logger.getIsInfoEnabled()) {
        logger.info(
          "Pod definition override detected for '$podName': "
          "user-defined pod [$existing] replaced with framework pod [$newD]"
        );
      }
    } else if (newD != existing) {
      if (explicitlyOverride || logger.getIsInfoEnabled()) {
        logger.info(
          "Pod definition override detected for '$podName': "
          "existing definition [$existing] replaced with new definition [$newD]"
        );
      } else {
        if (logger.getIsTraceEnabled()) {
          logger.trace("Pod definition for '$podName' overridden: [$existing] → [$newD]");
        }
      }
    } else {
      if (explicitlyOverride || logger.getIsInfoEnabled()) {
        logger.info("Pod definition override detected for '$podName': equivalent definitions replaced (no effective change)");
      } else {
        if (logger.getIsTraceEnabled()) {
          logger.trace("Pod definition for '$podName' replaced with an equivalent definition (no changes)");
        }
      }
    }
  }

  /// {@template default_listable_pod_factory._get}
  /// Internal method to get a pod by name with type safety.
  /// 
  /// This method attempts to get a pod with the specified type, falling back
  /// to getting the pod without type checking if a type mismatch occurs.
  /// 
  /// [name] the name of the pod to get
  /// [type] the expected type of the pod
  /// 
  /// Returns the pod instance
  /// 
  /// Throws:
  /// - [PodNotOfRequiredTypeException] if type doesn't match and fallback fails
  /// {@endtemplate}
  Future<Object> _get(String name, Class type) async {
    try {
      final result = await getPod(name, null, type);
      return result;
    } on PodNotOfRequiredTypeException catch (_) {
      return await getPod(name);
    }
  }

  /// {@template default_listable_pod_factory._get_dependency_comparator}
  /// Gets the dependency comparator with source provider if available.
  /// 
  /// This internal method returns the dependency comparator, enhanced with
  /// a source provider if it's an [OrderComparator].
  /// 
  /// [pods] the map of pods for which to create a source provider
  /// 
  /// Returns the dependency comparator, or `null` if not set
  /// {@endtemplate}
  Comparator<Object>? _getDependencyComparator(Map<String, Object> pods) {
    Comparator<Object>? comparator = getDependencyComparator();
    if (comparator is OrderComparator) {
      return comparator.withSource(_getAwareSourceProvider(pods));
    }

    return _dependencyComparator;
  }

  /// {@template default_listable_pod_factory._get_aware_source_provider}
  /// Creates an order source provider aware of the factory and pods.
  /// 
  /// This internal method creates an [FactoryAwareOrderSourceProvider]
  /// that can provide order information for the specified pods.
  /// 
  /// [pods] the map of pods to create the source provider for
  /// 
  /// Returns an [OrderSourceProvider] instance
  /// {@endtemplate}
  OrderSourceProvider _getAwareSourceProvider(Map<String, Object> pods) {
    final setOfPods = <Object, String>{};
    for (final entry in pods.entries) {
      setOfPods[entry.value] = entry.key;
    }

    return FactoryAwareOrderSourceProvider(this, setOfPods);
  }

  // Future<Object?> _resolve(Class requiredType, List<ArgumentValue>? args, bool returnNonUniqueAsNull) async {
  //   final parent = getParentFactory();
  //   if (parent is DefaultListablePodFactory) {
  //     return await parent._resolve(requiredType, args, returnNonUniqueAsNull);
  //   }

  //   if (parent != null) {
  //     final provider = await parent.getProvider(requiredType);
  //     if (args != null) {
  //       final result = await provider.get(args);
  //       return result.getValue();
  //     }

  //     final result = returnNonUniqueAsNull ? await provider.getIfUnique() : await provider.getIfAvailable();
  //     return result?.getValue();
  //   }
    
  //   return null;
  // }
}

/// {@template pod_definition_holder}
/// Type definition for a pod definition holder tuple.
/// 
/// This typedef represents a tuple containing:
/// - [String] name: The name of the pod
/// - [PodDefinition] definition: The pod definition
/// - [List<String>] aliases: List of aliases for the pod
/// 
/// Used internally for caching merged pod definitions with their metadata.
/// {@endtemplate}
typedef PodDefinitionHolder = (String name, PodDefinition definition, List<String> aliases);