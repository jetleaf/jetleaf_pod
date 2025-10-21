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

import 'package:jetleaf_convert/convert.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_logging/logging.dart';
import 'package:meta/meta.dart';

import '../definition/commons.dart';
import '../definition/pod_definition.dart';
import '../exceptions.dart';
import '../expression/default_pod_expression_resolver.dart';
import '../expression/pod_expression.dart';
import '../helpers/enums.dart';
import '../helpers/nullable_pod.dart';
import '../helpers/object.dart';
import '../helpers/utils.dart';
import '../lifecycle/disposable_lifecycle_manager.dart';
import '../lifecycle/lifecycle.dart';
import '../lifecycle/pod_processors.dart';
import '../scope/_scope.dart';
import '../scope/scope.dart';
import '../startup/application_startup.dart';
import '../startup/startup.dart';
import 'abstract_pod_provider_factory.dart';
import 'pod_factory.dart';

/// {@template abstract_pod_factory}
/// Abstract base implementation of [PodFactory] that provides core functionality
/// for pod creation, management, and lifecycle handling in the Jetleaf framework.
///
/// This class serves as the foundation for concrete pod factories, implementing
/// the core algorithm for pod retrieval, scope management, dependency resolution,
/// and lifecycle callbacks. It handles singleton caching, prototype creation,
/// circular dependency detection, and PodProvider unwrapping.
///
/// Key Features:
/// - Hierarchical pod provider support with parent-child relationships
/// - Singleton and prototype scope management
/// - Custom scope registration and handling
/// - Pod post-processing with [PodProcessor]
/// - Expression resolution for dynamic value injection
/// - Lifecycle management with destruction callbacks
/// - Circular dependency detection and prevention
///
/// Usage Example:
/// ```dart
/// class MyPodFactory extends AbstractPodFactory {
///   @override
///   PodDefinition getDefinition(String name) {
///     // Implementation to return pod definition by name
///   }
///
///   @override
///   FutureOr<Object> doCreate(String name, RootPodDefinition definition, List<ArgumentValue>? args) {
///     // Implementation to create pod instance
///   }
/// }
///
/// final factory = MyPodFactory();
/// final pod = await factory.getPod<MyService>('myService');
/// ```
///
/// See also:
/// - [PodFactory] for the main interface
/// - [ConfigurablePodFactory] for configuration methods
/// - [PodScope] for scope implementations
/// {@endtemplate}
abstract class AbstractPodFactory extends AbstractPodProviderFactory
    implements ConfigurablePodFactory {
  /// Constant used to denote the startup step for pod instantiation in the abstract pod provider.
  static const String STARTUP_STEP_INSTANTIATE_POD = 'jetleaf*pod*instantiate';

  /// Logger instance for tracking pod factory operations, errors, and diagnostic information.
  final Log _logger = LogFactory.getLog(AbstractPodFactory);

  /// Parent pod factory for hierarchical pod lookup and dependency resolution.
  PodFactory? _parentPodFactory;

  /// Service for converting configuration values and dependency types during pod creation.
  late ConversionService _conversionService;

  /// Registry of processors that intercept pod instantiation for custom logic execution.
  ///
  /// These processors are invoked before and after pod instantiation, allowing for
  /// custom initialization, dependency injection modifications, or instantiation
  /// short-circuiting.
  final Set<PodInstantiationProcessor> _instantiationPodProcessors = {};

  /// Registry of processors that handle pod destruction lifecycle events.
  ///
  /// These processors are invoked before pod destruction, enabling custom cleanup
  /// logic, resource release, or finalization operations.
  final Set<PodDestructionProcessor> _destructionPodProcessors = {};

  /// Registry of processors that handle pod initialization lifecycle events.
  ///
  /// These processors are invoked during the pod initialization process, allowing for
  /// custom initialization logic, validation, or enhancement of pod instances.
  final Set<PodInitializationProcessor> _initializationPodProcessors = {};

  /// Registry of processors that handle smart pod instantiation.
  ///
  /// These processors can modify or enhance the instantiation process, allowing for
  /// advanced instantiation scenarios, such as conditional instantiation or
  /// parameterized pod creation.
  final Set<PodSmartInstantiationProcessor> _smartInstantiationPodProcessors = {};

  /// General registry of all pod-aware processors for comprehensive lifecycle management.
  ///
  /// This includes processors that handle various pod lifecycle events beyond
  /// just instantiation and destruction.
  final Set<PodProcessor> _podProcessors = {};

  /// Resolver for evaluating dynamic expressions in pod definitions and configuration.
  PodExpressionResolver? _expressionResolver;

  /// Controls whether pod metadata should be cached for performance optimization.
  ///
  /// When enabled, pod definitions and related metadata are cached to avoid
  /// repeated computation during pod lookup and creation.
  bool _cacheMetadata = true;

  /// Class reference for managing disposable pod lifecycles and resource cleanup.
  Class<DisposableLifecycleManager> _DISPOSABLE_CLASS = Class<DisposableLifecycleManager>(null, PackageNames.CORE);

  /// Thread-local storage for tracking prototype pods currently being created.
  ///
  /// Used to detect and prevent circular dependencies during prototype pod
  /// instantiation by maintaining creation context per thread.
  final LocalThread<Object> _prototypesCurrentlyInCreation = LocalThread<Object>();

  /// Map of registered pod scopes available for pod lifecycle management.
  ///
  /// Contains both built-in scopes (singleton, prototype) and any custom
  /// scopes registered via [registerScope].
  final Map<String, PodScope> _scopes = {};

  /// Cache of merged pod definitions for efficient pod definition resolution.
  ///
  /// Stores the result of merging parent and child pod definitions to avoid
  /// repeated merging operations during pod creation.
  final Map<String, RootPodDefinition> _mergedPodDefinitions = {};

  /// Set tracking which pods have been created at least once for lifecycle management.
  ///
  /// Used to optimize repeated pod access and manage initialization state
  /// for singleton pods.
  final Set<String> _alreadyCreated = {};

  /// Component for coordinating pod instantiation during application startup sequence.
  late ApplicationStartup _applicationStartup;

  /// {@macro abstract_pod_factory}
  /// Creates a new abstract pod factory with optional parent factory for hierarchical resolution.
  ///
  /// Parameters:
  /// - [parent]: Optional parent pod factory for hierarchical pod lookup
  ///
  /// Initializes default scopes, expression resolver, conversion service, and application startup.
  /// Registers built-in singleton and prototype scopes automatically.
  AbstractPodFactory([PodFactory? parent]) {
    _parentPodFactory = parent;

    // Register default scopes
    _scopes[ScopeType.SINGLETON.name.toLowerCase()] = SingletonScope();
    _scopes[ScopeType.PROTOTYPE.name.toLowerCase()] = PrototypeScope();
    _prototypesCurrentlyInCreation.set(<String>{});
    _applicationStartup = DefaultApplicationStartup();
    _expressionResolver = DefaultPodExpressionResolver();
    _conversionService = DefaultConversionService();
  }

  // ----------------------------------------------------------------------------------------------------
  // INHERITED METHODS
  // ----------------------------------------------------------------------------------------------------

  @override
  void setParentFactory(PodFactory? parent) {
    if (this == parent) {
      throw IllegalStateException("Cannot set parent pod provider to self");
    }

    if (_parentPodFactory != null && _parentPodFactory != parent) {
      throw IllegalStateException(
        'Parent provider already set and not equal to new parent',
      );
    }

    _parentPodFactory = parent;
  }

  @override
  PodFactory? getParentFactory() => _parentPodFactory;

  @override
  void setCachePodMetadata(bool cacheMetadata) {
    _cacheMetadata = cacheMetadata;
  }

  @override
  bool isCachePodMetadata() => _cacheMetadata;

  @override
  void setConversionService(ConversionService conversionService) {
    _conversionService = conversionService;
  }

  @override
  ConversionService getConversionService() => _conversionService;

  @override
  void registerScope(String scopeName, PodScope scope) {
    if (ScopeType.SINGLETON.name.equalsIgnoreCase(scopeName) || ScopeType.PROTOTYPE.name.equalsIgnoreCase(scopeName)) {
      throw IllegalArgumentException("Cannot replace existing scopes 'singleton' and 'prototype'");
    }

    PodScope? previous = _scopes.get(scopeName.toLowerCase());
    if (previous != null && previous != scope) {
      if (logger.getIsDebugEnabled()) {
        logger.debug("Replacing scope '$scopeName' from [$previous] to [$scope]");
      }
    } else if (logger.getIsTraceEnabled()) {
      logger.trace("Registering scope '$scopeName' with implementation [$scope]");
    }

    _scopes[scopeName.toLowerCase()] = scope;
  }

  @override
  List<String> getRegisteredScopeNames() => _scopes.keys.toList();

  @override
  PodScope? getRegisteredScope(String scopeName) => _scopes[scopeName.toLowerCase()];

  @override
  void setApplicationStartup(ApplicationStartup applicationStartup) {
    _applicationStartup = applicationStartup;
  }

  @override
  ApplicationStartup getApplicationStartup() => _applicationStartup;

  @override
  void copyConfigurationFrom(ConfigurablePodFactory other) {
    setCachePodMetadata(other.isCachePodMetadata());
    setConversionService(other.getConversionService());
    setPodExpressionResolver(other.getPodExpressionResolver());

    if (other is AbstractPodFactory) {
      _applicationStartup = other._applicationStartup;
      _DISPOSABLE_CLASS = other._DISPOSABLE_CLASS;
      _parentPodFactory = other._parentPodFactory;
      _scopes.addAll(other._scopes);
      _instantiationPodProcessors.addAll(other._instantiationPodProcessors);
      _destructionPodProcessors.addAll(other._destructionPodProcessors);
      _podProcessors.addAll(other._podProcessors);
      _initializationPodProcessors.addAll(other._initializationPodProcessors);
      _smartInstantiationPodProcessors.addAll(other._smartInstantiationPodProcessors);
    } else {
      final scopeNames = other.getRegisteredScopeNames();
      for (String scopeName in scopeNames) {
        registerScope(scopeName, other.getRegisteredScope(scopeName)!);
      }
    }
  }

  @override
  void addPodProcessor(PodProcessor processor) {
    if (logger.getIsTraceEnabled()) {
      logger.trace("Adding pod aware processor ${processor.runtimeType} to ${runtimeType}");
    }

    _removePodProcessor(processor);
    _addPodProcessor(processor);
  }

  @override
  List<PodProcessor> getPodProcessors() => _podProcessors.toList();

  /// Adds a pod-aware processor to the factory with thread-safe synchronization.
  ///
  /// This method registers a processor and categorizes it based on its specific
  /// interfaces to enable optimized invocation during different pod lifecycle phases.
  /// Processors are automatically categorized into:
  ///
  /// - **PodDestructionProcessor**: For pod destruction lifecycle events
  /// - **PodInstantiationProcessor**: For pod instantiation lifecycle events
  /// - **General PodProcessor**: For all pod lifecycle events
  ///
  /// **Thread Safety:**
  /// The operation is synchronized on the processor instance to prevent
  /// concurrent modification issues during processor registration.
  ///
  /// **Parameters:**
  /// - `processor`: The pod-aware processor to add
  ///
  /// **Example:**
  /// ```dart
  /// factory._addPodProcessor(MyCustomProcessor());
  /// // Processor is now registered and categorized for appropriate lifecycle events
  /// ```
  void _addPodProcessor(PodProcessor processor) {
    return synchronized(processor, () {
      if (processor is PodDestructionProcessor) {
        _destructionPodProcessors.add(processor);
      }

      if (processor is PodInstantiationProcessor) {
        _instantiationPodProcessors.add(processor);

        if (processor is PodSmartInstantiationProcessor) {
          _smartInstantiationPodProcessors.add(processor);
        }
      }

      if (processor is PodInitializationProcessor) {
        _initializationPodProcessors.add(processor);
      }

      _podProcessors.add(processor);
    });
  }

  /// Removes a pod-aware processor from the factory with thread-safe synchronization.
  ///
  /// This method unregisters a processor and removes it from all relevant
  /// processor categories. It ensures the processor will no longer receive
  /// notifications for pod lifecycle events.
  ///
  /// **Thread Safety:**
  /// The operation is synchronized on the processor instance to prevent
  /// concurrent modification issues during processor removal.
  ///
  /// **Parameters:**
  /// - `processor`: The pod-aware processor to remove
  ///
  /// **Example:**
  /// ```dart
  /// factory._removePodProcessor(oldProcessor);
  /// // Processor is now unregistered from all lifecycle events
  /// ```
  void _removePodProcessor(PodProcessor processor) {
    return synchronized(processor, () {
      _podProcessors.remove(processor);

      if (processor is PodDestructionProcessor) {
        _destructionPodProcessors.remove(processor);
      }

      if (processor is PodInstantiationProcessor) {
        _instantiationPodProcessors.remove(processor);

        if (processor is PodSmartInstantiationProcessor) {
          _smartInstantiationPodProcessors.remove(processor);
        }
      }

      if (processor is PodInitializationProcessor) {
        _initializationPodProcessors.remove(processor);
      }
    });
  }

  /// Returns a copy of all registered destruction-aware pod processors.
  ///
  /// This method provides safe access to the destruction-aware processors
  /// list by returning a defensive copy to prevent external modification.
  ///
  /// **Returns:**
  /// - A list of [PodDestructionProcessor] instances
  ///
  /// **Example:**
  /// ```dart
  /// final processors = factory.getPodDestructionProcessors();
  /// for (final processor in processors) {
  ///   await processor.postProcessBeforeDestruction(pod, podName);
  /// }
  /// ```
  @protected
  List<PodDestructionProcessor> getPodDestructionProcessors() => _destructionPodProcessors.toList();

  /// Returns a copy of all registered instantiation-aware pod processors.
  ///
  /// This method provides safe access to the instantiation-aware processors
  /// list by returning a defensive copy to prevent external modification.
  ///
  /// **Returns:**
  /// - A list of [PodInstantiationProcessor] instances
  ///
  /// **Example:**
  /// ```dart
  /// final processors = factory.getPodInstantiationProcessors();
  /// for (final processor in processors) {
  ///   final result = processor.postProcessBeforeInstantiation(podClass, podName);
  ///   if (result != null) return result; // Short-circuit instantiation
  /// }
  /// ```
  @protected
  List<PodInstantiationProcessor> getPodInstantiationProcessors() => _instantiationPodProcessors.toList();

  /// Returns a copy of all registered initialization-aware pod processors.
  ///
  /// This method provides safe access to the initialization-aware processors
  /// list by returning a defensive copy to prevent external modification.
  ///
  /// **Returns:**
  /// - A list of [PodInitializationProcessor] instances
  ///
  /// **Example:**
  /// ```dart
  /// final processors = factory.getPodInitializationProcessors();
  /// for (final processor in processors) {
  ///   await processor.postProcessBeforeInitialization(pod, podName);
  /// }
  /// ```
  @protected
  List<PodInitializationProcessor> getPodInitializationProcessors() => _initializationPodProcessors.toList();

  /// Returns a copy of all registered smart instantiation-aware pod processors.
  ///
  /// This method provides safe access to the smart instantiation-aware processors
  /// list by returning a defensive copy to prevent external modification.
  ///
  /// **Returns:**
  /// - A list of [PodSmartInstantiationProcessor] instances
  ///
  /// **Example:**
  /// ```dart
  /// final processors = factory.getPodSmartInstantiationProcessors();
  /// for (final processor in processors) {
  ///   await processor.postProcessBeforeSmartInstantiation(podClass, podName);
  /// }
  /// ```
  @protected
  List<PodSmartInstantiationProcessor> getPodSmartInstantiationProcessors() => _smartInstantiationPodProcessors.toList();

  /// {@template abstract_pod_factory_has_instantiation_pod_post_processors}
  /// Returns true if there are any instantiation pod post-processors registered.
  ///
  /// This method checks if the pod processor cache contains any post-processors
  /// that are intended to be applied during pod instantiation.
  ///
  /// Returns true if there are any instantiation post-processors, false otherwise.
  /// {@endtemplate}
  @protected
  bool hasPodInstantiationProcessors() => _instantiationPodProcessors.isNotEmpty;

  /// {@template abstract_pod_factory_has_destruction_pod_post_processors}
  /// Returns true if there are any destruction pod post-processors registered.
  ///
  /// This method checks if the pod processor cache contains any post-processors
  /// that are intended to be applied during pod destruction.
  ///
  /// Returns true if there are any destruction post-processors, false otherwise.
  /// {@endtemplate}
  @protected
  bool hasPodDestructionProcessors() => _destructionPodProcessors.isNotEmpty;

  /// {@template abstract_pod_factory_has_smart_instantiation_pod_post_processors}
  /// Returns true if there are any smart instantiation pod post-processors registered.
  ///
  /// This method checks if the pod processor cache contains any post-processors
  /// that are intended to be applied during pod smart instantiation.
  ///
  /// Returns true if there are any smart instantiation post-processors, false otherwise.
  /// {@endtemplate}
  @protected
  bool hasPodSmartInstantiationProcessors() => _smartInstantiationPodProcessors.isNotEmpty;

  /// {@template abstract_pod_factory_has_initialization_pod_post_processors}
  /// Returns true if there are any initialization pod post-processors registered.
  ///
  /// This method checks if the pod processor cache contains any post-processors
  /// that are intended to be applied during pod initialization.
  ///
  /// Returns true if there are any initialization post-processors, false otherwise.
  /// {@endtemplate}
  @protected
  bool hasPodInitializationProcessors() => _initializationPodProcessors.isNotEmpty;

  /// {@template abstract_pod_factory_has_pod_post_processors}
  /// Returns true if there are any pod post-processors registered.
  ///
  /// This method checks if the pod processor cache contains any post-processors
  /// that are intended to be applied during pod lifecycle management.
  ///
  /// Returns true if there are any pod post-processors, false otherwise.
  /// {@endtemplate}
  @protected
  bool hasPodProcessors() => hasPodDestructionProcessors() || hasPodInstantiationProcessors() || _podProcessors.isNotEmpty;

  @override
  int getPodProcessorCount() => getPodProcessors().length;

  @override
  List<String> getAliases(String name) {
    String transformed = transformedPodName(name);
    List<String> aliases = [];

    bool hasFactoryPrefix = (name.isNotEmpty && name.first() == PodUtils.POD_PROVIDER_PREFIX);
    String fullname = transformed;

    if (hasFactoryPrefix) {
      fullname = podProviderName(transformed);
    }

    if (fullname.notEquals(name)) {
      aliases.add(fullname);
    }

    final retrievedAliases = super.getAliases(transformed);
    String prefix = hasFactoryPrefix ? PodUtils.POD_PROVIDER_PREFIX : "";
    for (String retrievedAlias in retrievedAliases) {
      String alias = prefix + retrievedAlias;
      if (!alias.equals(name)) {
        aliases.add(alias);
      }
    }

    if (!containsSingleton(transformed) && !containsDefinition(transformed)) {
      final parent = getParentFactory();
      if (parent != null) {
        aliases.addAll(parent.getAliases(fullname));
      }
    }

    return aliases;
  }

  @override
  bool isActuallyInCreation(String name) =>
      isCurrentlyCreatingSingleton(name) || isCurrentlyCreatingPrototype(name);

  @override
  Future<bool> containsLocalPod(String name) async {
    final transformed = transformedPodName(name);
    final matches = containsSingleton(transformed) || containsDefinition(transformed);
    final isFactory = !PodUtils.isFactoryDereference(name) || await isPodProvider(transformed);

    return matches && isFactory;
  }

  @override
  Future<bool> isPodProvider(String name, [RootPodDefinition? rpd]) async {
    if (rpd != null) {
      return rpd.isPodProvider || rpd.type.isAssignableFrom(POD_PROVIDER_CLASS);
    }

    String transformed = transformedPodName(name);
    if (containsDefinition(name)) {
      final def = getDefinition(name);
      return def.isPodProvider || def.type.isAssignableFrom(POD_PROVIDER_CLASS);
    }

    if (containsSingleton(name)) {
      final instance = await getSingleton(transformed, allowEarlyReference: false);
      return instance is PodProvider;
    }

    // No singleton instance found -> check pod definition.
    final parent = getParentFactory();
    if (!containsDefinition(transformed) && parent is ConfigurablePodFactory) {
      // No pod definition found in this provider -> delegate to parent.
      return parent.isPodProvider(transformed);
    }

    return await isPodProvider(transformed, getLocalMergedPodDefinition(transformed));
  }

  @override
  RootPodDefinition getMergedPodDefinition(String name) {
    final transformed = transformedPodName(name);

    // Efficiently check whether pod definition exists in this provider.
    final parent = getParentFactory();
    if (parent is ConfigurablePodFactory && !containsDefinition(transformed)) {
      return parent.getMergedPodDefinition(transformed);
    }

    return synchronized(_mergedPodDefinitions, () {
      if (!containsDefinition(transformed)) {
        throw NoSuchPodDefinitionException.byName(transformed);
      }

      final podDefinition = getDefinition(transformed);
      final definition = RootPodDefinition.from(podDefinition);

      if (isCachePodMetadata() || isPodEligibleForMetadataCaching(transformed)) {
        cacheMergedPodDefinition(definition, transformed);
      }

      definition.setIsStale(false);

      return definition;
    });
  }

  @override
  Future<void> destroyPod(String name, Object pod) async => _destroy(name, pod, getLocalMergedPodDefinition(name));

  void _destroy(String name, Object pod, RootPodDefinition root) async {
    await DisposableLifecycleManager(pod, name, root, getPodDestructionProcessors()).onDestroy();
  }

  @override
  void destroyScopedPod(String name) {
    RootPodDefinition root = getLocalMergedPodDefinition(name);
    if (root.scope.isSingleton || root.scope.isPrototype) {
      throw new IllegalArgumentException("Pod name '$name' does not correspond to an object in a mutable scope");
    }

    String scopeName = root.scope.type;
    PodScope? scope = _scopes.get(scopeName);
    if (scope == null) {
      throw new IllegalStateException("No Scope SPI registered for scope name '$scopeName'");
    }

    Object? pod = scope.remove(name);
    if (pod != null) {
      _destroy(name, pod, root);
    }
  }

  @override
  Future<bool> containsPod(String name) async {
    final transformed = transformedPodName(name);

    if (containsSingleton(transformed) || containsDefinition(transformed)) {
      return !PodUtils.isFactoryDereference(name) || await isPodProvider(transformed);
    }

    final parent = getParentFactory();
    return parent?.containsPod(PodUtils.originalName(name)) ?? false;
  }

  @override
  Future<bool> isTypeMatch(String name, Class typeToMatch, [bool allowPodProviderInit = false]) async {
    final transformed = transformedPodName(name);
    final isFactoryDereference = PodUtils.isFactoryDereference(name);

    // 1) check local singleton cache first (fast path)
    final cachedHolder = await getSingletonCache(transformed, false);
    if (cachedHolder != null && cachedHolder.getType()?.getType() != NullablePod.CLASS.getType()) {
      final instance = cachedHolder.getValue();

      // 1.a) Instance is a PodProvider (lazy provider)
      if (instance is PodProvider) {
        // If caller asked for factory dereference (& name used factory deref), we should not treat provider as target instance.
        if (isFactoryDereference) {
          return false;
        }

        // If provider directly supports the target type, success.
        if (instance.supportsType(typeToMatch)) {
          return true;
        }

        // Try to determine what the provider would produce (may initialize provider depending on flag).
        final providedClass = await getPodProviderType(instance, allowPodProviderInit);
        if (providedClass == null) {
          // Can't determine the provided type => no match.
          return false;
        }

        // If target type is assignable from the provider's produced type => match.
        if (typeToMatch.isAssignableFrom(providedClass)) {
          return true;
        }

        // If target has generics, consult local merged definition for componentType heuristics.
        if (typeToMatch.hasGenerics() && containsDefinition(transformed)) {
          final merged = getLocalMergedPodDefinition(transformed);
          final Class targetClass = merged.type;

          // If merged type itself is a PodProvider subclass, inspect component type
          if (POD_PROVIDER_CLASS.isAssignableFrom(targetClass)) {
            // Avoid confusing provider types: if requested type is not a provider itself
            // but could match the provider's component type, return that result.
            if (!POD_PROVIDER_CLASS.isAssignableFrom(typeToMatch) && !typeToMatch.isAssignableFrom(targetClass)) {
              final comp = targetClass.componentType();
              return comp != null && typeToMatch.isAssignableFrom(comp);
            }
          } else {
            // Otherwise compare typeToMatch with the merged targetClass
            return typeToMatch.isAssignableFrom(targetClass);
          }
        }

        // No match from provider path
        return false;
      }

      // 1.b) Instance is not a provider
      if (isFactoryDereference) {
        // Caller explicitly asked for factory reference (e.g. "&podName") but the cached instance is the pod itself,
        // so the factory reference semantics don't match.
        return false;
      }

      // Direct instance check
      if (typeToMatch.isInstance(instance)) {
        return true;
      }

      // If target type has generics, consult local merged definition metadata as fallback
      if (typeToMatch.hasGenerics() && containsDefinition(transformed)) {
        final definition = getLocalMergedPodDefinition(transformed);
        final Class targetType = definition.type;

        if (!targetType.isInstance(instance)) {
          final Class? componentToMatch = typeToMatch.componentType();
          if (componentToMatch != null && !componentToMatch.isInstance(instance)) {
            return false;
          }
          if (typeToMatch.isAssignableFrom(targetType)) {
            return true;
          }
        }
        return typeToMatch.isAssignableFrom(targetType);
      }

      // No match against cached instance
      return false;
    } // end cachedHolder != null

    // 2) No cached instance -> check local definition metadata (if any)
    if (containsDefinition(transformed)) {
      final def = getLocalMergedPodDefinition(transformed);
      final Class declaredType = def.type;

      // If caller asked for factory deref, we only match if declaredType is PodProvider (or subclass)
      if (isFactoryDereference) {
        return POD_PROVIDER_CLASS.isAssignableFrom(declaredType);
      }

      // Direct assignability from declared type is a match
      if (typeToMatch.isAssignableFrom(declaredType)) {
        return true;
      }

      // If typeToMatch has generics, try matching component/generic types of declaredType
      if (typeToMatch.hasGenerics()) {
        final Class? declaredComponent = declaredType.componentType();
        final Class? wantedComponent = typeToMatch.componentType();
        if (wantedComponent != null && declaredComponent != null) {
          if (wantedComponent.isAssignableFrom(declaredComponent)) {
            return true;
          }
        }
      }

      // If declaredType is a PodProvider, check the provider's produced type (without instantiating provider unless allowed)
      if (POD_PROVIDER_CLASS.isAssignableFrom(declaredType)) {
        // If we can determine produced type from the definition metadata, prefer that.
        final Class? declaredProvided = def.type;
        if (declaredProvided != null) {
          return typeToMatch.isAssignableFrom(declaredProvided);
        }

        // If no metadata available and we are allowed to init provider, try instantiating provider to inspect
        if (allowPodProviderInit) {
          try {
            final providerInstance = await getPod(transformed, []);
            if (providerInstance is PodProvider) {
              final produced = await getPodProviderType(providerInstance, true);
              if (produced != null && typeToMatch.isAssignableFrom(produced)) {
                return true;
              }
            }
          } catch (_) {
            // ignore; fall through to parent check
          }
        }
      }

      // Not matched by local definition
    }

    // 3) Nothing local matched -> delegate to parent factory (if any)
    final parent = getParentFactory();
    if (parent != null) {
      try {
        // Assume parent exposes the same isTypeMatch API and is async
        return await parent.isTypeMatch(name, typeToMatch, allowPodProviderInit);
      } catch (_) {
        // swallow and return false for robust fallback semantics
        return false;
      }
    }

    // 4) No parent and no match -> false
    return false;
  }

  @override
  Future<bool> isSingleton(String name) async {
    final transformed = transformedPodName(name);

    final singleton = await super.getSingleton(transformed, allowEarlyReference: false);
    if (singleton != null) {
      if (singleton is PodProvider) {
        return PodUtils.isFactoryDereference(name) || singleton.isSingleton();
      } else {
        return !PodUtils.isFactoryDereference(name);
      }
    }

    // No singleton instance found -> check pod definition.
    final parent = getParentFactory();
    if (parent != null && !containsDefinition(transformed)) {
      // No pod definition found in this provider -> delegate to parent.
      return parent.isSingleton(PodUtils.originalName(name));
    }

    final merged = getLocalMergedPodDefinition(transformed);

    // In case of PodProvider, return singleton status of created object if not a dereference.
    if (merged.scope.isSingleton) {
      if (await isPodProvider(transformed, merged)) {
        if (PodUtils.isFactoryDereference(name)) {
          return true;
        }

        final res = await getPod(podProviderName(transformed));
        if (res is PodProvider) {
          return res.isSingleton();
        }

        return false;
      } else {
        return !PodUtils.isFactoryDereference(name);
      }
    } else {
      return false;
    }
  }

  @override
  Future<bool> isPrototype(String name) async {
    final transformed = transformedPodName(name);

    final parent = getParentFactory();
    if (parent != null && !containsDefinition(transformed)) {
      // No pod definition found in this provider -> delegate to parent.
      return parent.isPrototype(PodUtils.originalName(name));
    }

    final merged = getLocalMergedPodDefinition(transformed);
    if (merged.scope.isPrototype) {
      // In case of PodProvider, return singleton status of created object if not a dereference.
      return (!PodUtils.isFactoryDereference(name) || await isPodProvider(transformed, merged));
    }

    // Singleton or scoped - not a prototype.
    // However, PodProvider may still produce a prototype object...
    if (PodUtils.isFactoryDereference(name)) {
      return false;
    }

    if (await isPodProvider(transformed, merged)) {
      final pp = await getPod(podProviderName(transformed));
      if (pp is PodProvider) {
        return pp.isPrototype() || !pp.isSingleton();
      }

      return false;
    } else {
      return false;
    }
  }

  @override
  Future<Object> getNamedObject(String name, [List<ArgumentValue>? args]) async {
    return await doGet(name, null, args);
  }

  @override
  Future<Object> getObject(Class<Object> type, [List<ArgumentValue>? args]) async {
    final definition = getDefinitionByClass(type);
    return await doGet(definition.name, type, args);
  }

  @override
  Future<T> get<T>(Class<T> type, [List<ArgumentValue>? args]) async {
    final definition = getDefinitionByClass(type);
    final classType = Class.fromQualifiedName<Object>(definition.type.getQualifiedName());
    return await doGet(definition.name, classType, args) as T;
  }

  @override
  Future<T> getPod<T>(String name, [List<ArgumentValue>? args, Class<T>? type]) async {
    final classType = type != null ? Class.fromQualifiedName<Object>(type.getQualifiedName()) : null;
    return await doGet(name, classType, args) as T;
  }

  @override
  void setPodExpressionResolver(PodExpressionResolver? valueResolver) {
    _expressionResolver = valueResolver;
  }

  @override
  PodExpressionResolver? getPodExpressionResolver() => _expressionResolver;

  // -----------------------------------------------------------------------------------------------------
  // PROTECTED METHODS
  // -----------------------------------------------------------------------------------------------------

  /// {@template abstract_pod_factory_reset_pod_processor_cache}
  /// Resets the pod processor cache, clearing all cached post-processors.
  ///
  /// This method is used to invalidate the cache when pod post-processors
  /// are modified or when the pod factory is reconfigured.
  ///
  /// {@endtemplate}
  @protected
  void resetPodProcessorCache() {
    return synchronized(_podProcessors, () {
      _podProcessors.clear();
      _instantiationPodProcessors.clear();
      _destructionPodProcessors.clear();
    });
  }

  @protected
  Future<Class?> getPodProviderType(PodProvider provider, bool allowPodProviderInit) async {
    final cls = provider.getClass();

    if (cls != null) {
      return cls;
    }

    if (allowPodProviderInit) {
      final result = await provider.get();
      return result?.getType();
    }

    return null;
  }

  /// {@template abstract_pod_factory_evaluate_expression}
  /// Evaluates a pod expression using the configured expression resolver.
  ///
  /// This method is used to resolve dynamic values defined in pod expressions
  /// during pod creation and configuration.
  ///
  /// Usage Example:
  /// ```dart
  /// final expression = PodExpression('${environment.variable}');
  /// final result = evaluateExpression(expression, podDefinition);
  /// ```
  ///
  /// [value] the pod expression to evaluate
  /// [podDefinition] the pod definition context for evaluation
  /// Returns an [ObjectHolder] with the evaluated value, or `null` if no resolver is configured
  /// {@endtemplate}
  @protected
  FutureOr<ObjectHolder<Object>?> evaluateExpression(Object? value, PodDefinition? podDefinition) {
    if (_expressionResolver == null) {
      return null;
    }

    PodScope? scope = null;
    if (podDefinition != null) {
      String scopeName = podDefinition.scope.type;
      scope = getRegisteredScope(scopeName);
    }

    return _expressionResolver!.evaluate(value, PodExpressionContext(this, scope));
  }

  /// {@template abstract_pod_factory_transformed_pod_name}
  /// Transforms a pod name by removing any prefix and suffix.
  ///
  /// This method is used to normalize pod names by removing any prefix or suffix
  /// that may be added during pod registration or configuration.
  ///
  /// Usage Example:
  /// ```dart
  /// final transformed = transformedPodName('myPod');
  /// ```
  ///
  /// [name] the pod name to transform
  /// Returns the transformed pod name
  /// {@endtemplate}
  @protected
  String transformedPodName(String name) => targetName(PodUtils.transformedName(name));

  /// {@template abstract_pod_factory_original_pod_name}
  /// Returns the original pod name by removing any prefix and suffix.
  ///
  /// This method is used to retrieve the original pod name from a transformed name
  /// by removing any prefix or suffix that may have been added during pod registration
  /// or configuration.
  ///
  /// Usage Example:
  /// ```dart
  /// final original = originalPodName('myPod');
  /// ```
  ///
  /// [name] the transformed pod name
  /// Returns the original pod name
  /// {@endtemplate}
  @protected
  String originalPodName(String name) {
    String transformed = transformedPodName(name);
    if (name.isNotEmpty && name.startsWith(PodUtils.POD_PROVIDER_PREFIX)) {
      transformed = podProviderName(transformed);
    }

    return transformed;
  }

  /// Gets the name of a pod with the appended pod provider prefix.
  @protected
  String podProviderName(String name) => "${PodUtils.POD_PROVIDER_PREFIX}$name";

  /// {@template abstract_pod_factory_is_currently_creating_prototype}
  /// Checks if a prototype pod is currently being created.
  ///
  /// This method is used for circular dependency detection during prototype creation.
  ///
  /// [name] the name of the pod to check
  /// Returns `true` if the pod is currently being created, `false` otherwise
  /// {@endtemplate}
  @protected
  bool isCurrentlyCreatingPrototype(String name) {
    Object? val = _prototypesCurrentlyInCreation.get();
    return (val != null && (val.equals(name) || (val is Set && val.contains(name))));
  }

  /// {@template abstract_pod_factory_before_prototype_creation}
  /// Marks a prototype pod as being created to detect circular dependencies.
  ///
  /// This method should be called before starting the creation of a prototype pod.
  ///
  /// [name] the name of the pod being created
  /// {@endtemplate}
  @protected
  void beforePrototypeCreation(String name) {
    Object? val = _prototypesCurrentlyInCreation.get();

    if (val == null) {
      _prototypesCurrentlyInCreation.set(name);
    } else if (val is String) {
      Set<String> podNameSet = HashSet<String>();

      podNameSet.add(val);
      podNameSet.add(name);
      _prototypesCurrentlyInCreation.set(podNameSet);
    } else {
      Set<String> podNameSet = val as Set<String>;
      podNameSet.add(name);
    }
  }

  /// {@template abstract_pod_factory_after_prototype_creation}
  /// Removes a prototype pod from the creation tracking after creation completes.
  ///
  /// This method should be called after the creation of a prototype pod completes,
  /// whether successfully or with an error.
  ///
  /// [name] the name of the pod that was created
  /// {@endtemplate}
  @protected
  void afterPrototypeCreation(String name) {
    Object? val = _prototypesCurrentlyInCreation.get();
    if (val is String) {
      _prototypesCurrentlyInCreation.remove();
    } else if (val is Set<String>) {
      val.remove(name);
      if (val.isEmpty) {
        _prototypesCurrentlyInCreation.remove();
      }
    }
  }

  /// {@template abstract_pod_factory_has_started_creating_pod}
  /// Checks if a pod has already been created.
  ///
  /// This method is used to track whether a pod has already been created
  /// to prevent duplicate creation and circular dependencies.
  ///
  /// Returns `true` if the pod has already been created, `false` otherwise
  /// {@endtemplate}
  @protected
  bool hasStartedCreatingPod() => !_alreadyCreated.isEmpty;

  /// {@template abstract_pod_factory_cache_merged_pod_definition}
  /// Caches a merged pod definition for a given pod name.
  ///
  /// This method is used to cache a merged pod definition for a given pod name
  /// to prevent duplicate merging and improve performance.
  ///
  /// [root] the root pod definition to cache
  /// [name] the name of the pod to cache
  /// {@endtemplate}
  @protected
  void cacheMergedPodDefinition(RootPodDefinition root, String name) {
    _mergedPodDefinitions[name] = RootPodDefinition.from(root);
  }

  /// {@template abstract_pod_factory_get_local_merged_pod_definition}
  /// Returns the locally cached merged pod definition if available and not stale.
  ///
  /// This method provides efficient access to cached pod definitions while
  /// ensuring stale definitions are re-merged when necessary.
  ///
  /// [name] the name of the pod to get the definition for
  /// Returns the cached [RootPodDefinition] or fetches a fresh one if needed
  /// {@endtemplate}
  @protected
  RootPodDefinition getLocalMergedPodDefinition(String name) {
    // Quick check on the map first, with minimal locking.
    final root = _mergedPodDefinitions[name];
    if (root != null && !root.getIsStale()) {
      return root;
    }

    return getMergedPodDefinition(name);
  }

  /// {@template abstract_pod_factory_check_merged_pod_definition}
  /// Checks the merged pod definition for a given pod name.
  ///
  /// This method is used to validate the merged pod definition for a given pod name
  /// to ensure it is not abstract and to prevent duplicate merging.
  ///
  /// [root] the root pod definition to check
  /// [name] the name of the pod to check
  /// [args] any additional arguments to pass to the check
  /// {@endtemplate}
  @protected
  void checkMergedPodDefinition(RootPodDefinition root, String name, Object? args) {
    if (root.isAbstractAndNoFactory()) {
      throw PodIsAbstractException("Merged pod definition is non-instantiable for $name", name: name);
    }
  }

  /// {@template abstract_pod_factory_clear_merged_pod_definition}
  /// Clears the merged pod definition for a given pod name.
  ///
  /// This method is used to clear the merged pod definition for a given pod name
  /// to prevent stale definitions from being used.
  ///
  /// [name] the name of the pod to clear the definition for
  /// {@endtemplate}
  @protected
  void clearMergedPodDefinition(String name) {
    final definition = _mergedPodDefinitions[name];
    if (definition != null) {
      definition.setIsStale(true);
    }
  }

  /// {@template abstract_pod_factory_mark_pod_as_created}
  /// Marks a pod as having been created at least once.
  ///
  /// This method updates internal tracking to indicate that a pod has been
  /// instantiated, which affects metadata caching eligibility.
  ///
  /// [name] the name of the pod that was created
  /// {@endtemplate}
  @protected
  void markPodAsCreated(String name) {
    if (!_alreadyCreated.contains(name)) {
      return synchronized(_mergedPodDefinitions, () {
        if (!isPodEligibleForMetadataCaching(name)) {
          // Let the pod definition get re-merged now that we're actually creating
          // the pod... just in case some of its metadata changed in the meantime.
          clearMergedPodDefinition(name);
        }
        _alreadyCreated.add(name);
      });
    }
  }

  /// {@template abstract_pod_factory_is_pod_eligible_for_metadata_caching}
  /// Checks if a pod is eligible for metadata caching.
  ///
  /// This method determines whether a pod has been created at least once,
  /// which affects metadata caching eligibility.
  ///
  /// [name] the name of the pod to check
  /// Returns `true` if the pod is eligible for metadata caching, `false` otherwise
  /// {@endtemplate}
  @protected
  bool isPodEligibleForMetadataCaching(String name) => _alreadyCreated.contains(name);

  /// {@template abstract_pod_factory_cleanup_after_pod_creation_failure}
  /// Cleans up after a pod creation failure.
  ///
  /// This method removes the pod from the already created set and ensures
  /// that any merged pod definitions are cleared.
  ///
  /// [name] the name of the pod that failed to create
  /// {@endtemplate}
  @protected
  void cleanupAfterPodCreationFailure(String name) {
    return synchronized((_mergedPodDefinitions), () {
      _alreadyCreated.remove(name);
    });
  }

  /// {@template abstract_pod_factory_remove_singleton_if_created}
  /// Removes a singleton pod if it has been created.
  ///
  /// This method checks if a singleton pod has been created and removes it
  /// from the singleton cache if it has.
  ///
  /// [name] the name of the singleton pod to remove
  /// Returns `true` if the singleton pod was removed, `false` otherwise
  /// {@endtemplate}
  @protected
  bool removeSingletonIfCreated(String name) {
    if (!_alreadyCreated.contains(name)) {
      removeSingleton(name);
      return true;
    } else {
      return false;
    }
  }

  /// {@template abstract_pod_factory_requires_destruction}
  /// Checks if a pod requires destruction.
  ///
  /// This method determines whether a pod requires destruction based on its type
  /// and the presence of destruction pod post-processors.
  ///
  /// [pod] the pod to check
  /// [root] the root pod definition to check
  /// Returns `true` if the pod requires destruction, `false` otherwise
  /// {@endtemplate}
  @protected
  Future<bool> requiresDestruction(Object pod, RootPodDefinition root) async {
    bool notNullable = root.type != NullablePod;
    bool hasProcessors = hasPodDestructionProcessors() && await DisposableLifecycleManager.hasApplicableProcessors(pod, root, _destructionPodProcessors);

    return notNullable && (DisposableLifecycleManager.hasDestroyMethod(pod, root) || hasProcessors);
  }

  /// {@template abstract_pod_factory_register_disposable_handler}
  /// Registers a disposable handler for a pod that requires destruction callbacks.
  ///
  /// This method sets up the appropriate destruction callback based on the pod's scope.
  /// For singleton pods, it registers a disposable pod. For scoped pods, it registers
  /// with the scope's destruction callback mechanism.
  ///
  /// [name] the name of the pod
  /// [pod] the pod instance
  /// [root] the pod definition containing scope information
  /// {@endtemplate}
  @protected
  Future<void> registerDisposableHandler(String name, DisposablePod pod, RootPodDefinition root) async {
    if (!root.scope.isPrototype && await requiresDestruction(pod, root)) {
      final handler = DisposableLifecycleManager(pod, name, root, _destructionPodProcessors.toList());

      if (root.scope.isSingleton) {
        // Register a DisposablePod implementation that performs all destruction
        // work for the given pod: DestructionAwarePodPostProcessors,
        // DisposablePod interface, custom destroy method.
        registerDisposablePod(name, pod, root.type.getQualifiedName());
      } else {
        // A pod with a custom scope...
        final scope = _scopes.get(root.scope.type);
        if (scope == null) {
          throw new IllegalStateException("No Scope registered for scope name '${root.scope.type}'");
        }

        scope.registerDestructionCallback(name, handler);
      }
    }
  }

  /// {@template abstract_pod_factory_do_get}
  /// Main template method for pod retrieval that implements the core resolution algorithm.
  ///
  /// This method is the heart of the pod factory system, handling:
  /// 1. Pod name transformation and alias resolution
  /// 2. Singleton cache lookup
  /// 3. Parent factory delegation for hierarchical lookups
  /// 4. Dependency resolution and circular dependency detection
  /// 5. Scope-based pod creation (singleton, prototype, custom scopes)
  /// 6. PodProvider unwrapping and instance creation
  ///
  /// Usage Example:
  /// ```dart
  /// final pod = await doGet('myService', Class.forObject(MyService), null);
  /// ```
  ///
  /// [name] the name of the pod to retrieve
  /// [type] the expected type of the pod (optional)
  /// [args] constructor arguments for the pod (optional)
  /// Returns the retrieved pod instance
  ///
  /// Throws [PodCurrentlyInCreationException] for circular dependencies
  /// Throws [PodCreationException] for pod creation failures
  /// {@endtemplate}
  @protected
  Future<Object> doGet(String name, Class<Object>? type, List<ArgumentValue>? args, [bool prototypeInSingleton = false]) async {
    Object instance;

    final transformed = transformedPodName(name);
    ObjectHolder<Object>? cache = await getSingletonCache(transformed); // Check singleton cache first
    Object? shared = cache?.getValue();

    if (shared != null && args == null && cache != null) {
      if (_logger.getIsTraceEnabled()) {
        if (isCurrentlyCreatingSingleton(transformed)) {
          _logger.trace("Returning eagerly cached instance of singleton pod '$transformed' that is not fully initialized yet - a consequence of a circular reference");
        } else {
          _logger.trace("Returning cached instance of singleton pod '$transformed'");
        }
      }

      instance = await doGetObject(shared, type, name, transformed, null);
    } else {
      // Fail if we're already creating this pod instance: We're assumably within a circular reference.
      if (isCurrentlyCreatingPrototype(transformed)) {
        throw PodCurrentlyInCreationException(name: transformed);
      }

      // Check if pod definition exists in this provider.
      PodFactory? parent = getParentFactory();

      if (parent != null && !containsDefinition(transformed)) {
        String lookup = PodUtils.originalName(name); // Not found -> check parent.

        if (parent is AbstractPodFactory) {
          return await parent.doGet(lookup, type, args);
        } else if (args != null) {
          // Delegation to parent with explicit args.
          if (type == null) {
            return await parent.getPod(lookup, args);
          } else {
            return await parent.get(type, args);
          }
        } else {
          // No args -> delegate to standard getPod method.
          if (type != null) {
            return await parent.get(type);
          }
          return await parent.getPod(lookup);
        }
      } else {
        markPodAsCreated(transformed);

        StartupStep createStep = _applicationStartup.start(STARTUP_STEP_INSTANTIATE_POD).tag("name", value: name);

        try {
          if (type != null) {
            createStep.tag("podType", value: type.toString());
          }

          final merged = getLocalMergedPodDefinition(transformed);
          type ??= Class.fromQualifiedName<Object>(merged.type.getQualifiedName());

          checkMergedPodDefinition(merged, transformed, args);

          // Guarantee initialization of pods that the current pod depends on.
          List<DependencyDesign> dependsOn = merged.dependsOn;
          if (dependsOn.isNotEmpty) {
            for (DependencyDesign dep in dependsOn) {
              final depName = dep.name;
              final depType = dep.type;

              String? dependency;
              if (depType != null) {
                dependency = getDefinitionByClass(depType).name;
              } else if (depName != null) {
                dependency = depName;
              }

              if (dependency == null) {
                continue;
              }

              if (isDependent(transformed, dependency)) {
                throw PodCreationException.withResource(
                  merged.description,
                  transformed,
                  "Circular depends-on relationship between '$transformed' and '$dep'",
                );
              }

              registerDependentPod(dependency, transformed);
              try {
                await doGet(dependency, null, null, dep.prototypeInSingleton);
              } on NoSuchPodDefinitionException catch (ex) {
                throw PodCreationException.withResource(
                  merged.description,
                  transformed,
                  "$transformed depends on missing pod $dep",
                  cause: ex,
                );
              } on PodCreationException catch (ex) {
                throw PodCreationException.withResource(
                  merged.description,
                  transformed,
                  "Failed to initialize dependency '${(ex.getPodName() ?? "")}' of ${type.getSimpleName()} pod '$transformed'",
                  cause: ex,
                );
              }
            }
          }

          // If a pod instance is already available, return it.
          if (merged.instance != null) {
            if (type.isInstance(merged.instance)) {
              return convertIfNecessary(name, merged.instance!, type);
            } else if (merged.type.isInstance(merged.instance)) {
              return convertIfNecessary(name, merged.instance!, merged.type);
            }
          }

          // Create pod instance
          if (merged.scope.isSingleton && !prototypeInSingleton) {
            final create = () async {
              try {
                return ObjectHolder(
                  await doCreate(transformed, merged, args),
                  packageName: type?.getPackage()?.getName(),
                  qualifiedName: type?.getQualifiedName(),
                );
              } on PodException catch (_) {
                // Explicitly remove instance from singleton cache: It might have been put there
                // eagerly by the creation process, to allow for circular reference resolution.
                // Also remove any pods that received a temporary reference to the pod.
                destroySingleton(transformed);
                rethrow;
              }
            };

            final creator = SimpleObjectFactory<Object>(([args]) async => create());
            shared = await getSingleton(transformed, factory: creator);

            if (shared == null) {
              throw PodCreationException.withResource(
                merged.description,
                transformed,
                "Failed to create singleton pod '$transformed'",
              );
            }

            instance = await doGetObject(shared, type, name, transformed, merged);
          } else if (merged.scope.isPrototype || prototypeInSingleton) {
            // It's a prototype -> create a new instance.
            Object prototype;
            try {
              beforePrototypeCreation(transformed);
              prototype = await doCreate(transformed, merged, args);
            } finally {
              afterPrototypeCreation(transformed);
            }

            instance = await doGetObject(prototype, type, name, transformed, merged);
          } else {
            final scopeName = merged.scope.type;

            if (scopeName.isEmpty) {
              throw IllegalStateException("No scope name defined for pod '$transformed'");
            } else {
              final scope = _scopes[scopeName];
              if (scope == null) {
                throw PodException('No Scope registered for scope name: $scopeName');
              } else {
                try {
                  final create = () async {
                    beforePrototypeCreation(transformed);

                    try {
                      return ObjectHolder(
                        await doCreate(transformed, merged, args),
                        packageName: type?.getPackage()?.getName(),
                        qualifiedName: type?.getQualifiedName(),
                      );
                    } finally {
                      afterPrototypeCreation(transformed);
                    }
                  };

                  final result = await scope.get(transformed, SimpleObjectFactory(([args]) async => create()));
                  shared = result.getValue();

                  instance = await doGetObject(result.getValue(), type, name, transformed, merged);
                } on IllegalStateException catch (ex) {
                  throw ScopeNotActiveException(transformed, scopeName, ex);
                }
              }
            }
          }
        } on PodException catch (ex) {
          createStep.tag("exception", value: ex.getClass().toString());
          createStep.tag("message", value: ex.getMessage());
          cleanupAfterPodCreationFailure(transformed);
          rethrow;
        } finally {
          createStep.end();
          if (!isCachePodMetadata()) {
            clearMergedPodDefinition(transformed);
          }
        }
      }
    }

    return convertIfNecessary(name, instance, type);
  }

  /// {@template abstract_pod_factory_internal_do_get}
  /// Internal method to handle PodProvider unwrapping and instance retrieval.
  ///
  /// This method processes the retrieved pod instance, handling PodProvider
  /// unwrapping and ensuring the correct instance is returned based on the
  /// request type (provider pod vs produced pod).
  ///
  /// [instance] the pod instance retrieved from cache or creation
  /// [type] the expected type of the pod
  /// [name] the original pod name
  /// [transformed] the transformed pod name
  /// [definition] the pod definition (optional)
  /// Returns the final pod instance to return
  ///
  /// Throws [PodIsNotAProviderException] if a provider pod is expected but not found
  /// {@endtemplate}
  @protected
  Future<Object> doGetObject(Object instance, Class? type, String name, String transformed, PodDefinition? definition) async {
    Object object;
    if (instance is Future) {
      object = await instance;
    } else {
      object = instance;
    }

    // If name starts with &, return the provider pod itself
    if (PodUtils.isFactoryDereference(name)) {
      if (object is NullablePod) {
        throw PodCreationException.withResource(
          definition?.description,
          transformed,
          "Failed to create singleton pod '$transformed'. The pod is null.",
        );
      } else if (object is! PodProvider) {
        throw PodIsNotAProviderException(transformed, type ?? object.getClass());
      } else if (definition != null) {
        definition.isPodProvider = true;
      }

      return object;
    }

    // If not a provider pod, return as-is
    if (object is! PodProvider) {
      return object;
    } else {
      // Handle PodProvider
      if (definition != null) {
        definition.isPodProvider = true;
      }

      Object? po;
      if (definition == null) {
        final nullable = await getNullableProviderObject(transformed);
        if (nullable != null) {
          po = nullable.getValue();
        }
      }

      if (po == null) {
        if (definition == null && await containsDefinition(transformed)) {
          definition = await getLocalMergedPodDefinition(transformed);
        }

        if (definition != null) {
          definition.isPodProvider = true;
        }

        bool synthetic = definition != null && definition.design.isInfrastructure;
        final provider = await getProviderObject(object, type, transformed, !synthetic);
        po = provider.getValue();
      }

      return po;
    }
  }

  /// {@template abstract_pod_factory_convert}
  /// Converts a pod instance to the required type if necessary.
  ///
  /// This method checks if the pod instance matches the required type and
  /// attempts to convert it using the conversion service if not.
  ///
  /// [name] the name of the pod
  /// [pod] the pod instance to convert
  /// [type] the required type
  /// [source] the source type of the pod instance
  /// Returns the converted pod instance
  ///
  /// Throws [PodNotOfRequiredTypeException] if conversion fails
  /// {@endtemplate}
  T convertIfNecessary<T>(String name, Object pod, [Class? type, Class? source]) {
    // Check if required type matches the type of the actual pod instance.
    Class? sourceType = source;
    if (source == null || !source.isInstance(pod)) {
      try {
        final cls = pod.getClass();
        if (cls.isInstance(pod)) {
          sourceType = cls;
        }
      } catch (ex) {}
    }

    if (type != null && !type.isInstance(pod)) {
      try {
        final convertedPod = _conversionService.convertTo(pod, type, sourceType);
        if (convertedPod == null) {
          throw PodNotOfRequiredTypeException(
            name: name,
            requiredType: type,
            actualType: pod.getClass(),
          );
        }

        return convertedPod as T;
      } on TypeError catch (ex) {
        if (_logger.getIsTraceEnabled()) {
          _logger.trace("Failed to convert pod '$name' to required type '${type.getSimpleName()}'", error: ex);
        }

        throw PodNotOfRequiredTypeException(name: name, requiredType: pod.getClass(), actualType: type);
      }
    }

    return pod as T;
  }

  // -----------------------------------------------------------------------------------------------------
  // PUBLIC METHODS
  // -----------------------------------------------------------------------------------------------------

  /// {@template abstract_pod_factory_is_name_in_use}
  /// Checks if a pod name is already in use in this factory.
  ///
  /// This method checks if the name is used as an alias, contains a local pod,
  /// or has dependent pods registered.
  ///
  /// Usage Example:
  /// ```dart
  /// final factory = getPodFactory();
  /// if (await factory.isNameInUse('newPod')) {
  ///   print('Pod name is already in use');
  /// } else {
  ///   print('Pod name is available');
  /// }
  /// ```
  ///
  /// [name] the pod name to check
  /// Returns `true` if the name is in use, `false` otherwise
  /// {@endtemplate}
  Future<bool> isNameInUse(String name) async {
    return isAlias(name) || await containsLocalPod(name) || hasDependentPod(name);
  }

  /// {@template abstract_pod_factory_clear_metadata_cache}
  /// Clears the metadata cache for pods that are not eligible for caching.
  ///
  /// This method marks pod definitions as stale if they haven't been created yet,
  /// forcing them to be re-merged on next access.
  ///
  /// Usage Example:
  /// ```dart
  /// final factory = getPodFactory();
  /// factory.clearMetadataCache(); // Force refresh of pod definitions
  /// ```
  /// {@endtemplate}
  void clearMetadataCache() {
    _mergedPodDefinitions.forEach((name, bd) {
      if (!isPodEligibleForMetadataCaching(name)) {
        bd.setIsStale(true);
      }
    });
  }

  /// {@template abstract_pod_factory_get_definition}
  /// Return the registered PodDefinition for the specified pod, allowing access
  /// to its property values and constructor argument value (which can be
  /// modified during pod factory post-processing).
  ///
  /// A returned PodDefinition object should not be a copy but the original
  /// definition object as registered in the factory. This means that it should
  /// be castable to a more specific implementation type, if necessary.
  ///
  /// NOTE: This method does not consider ancestor factories.
  /// It is only meant for accessing local pod definitions of the factory.
  ///
  /// [podName] the name of the pod
  /// Returns the registered PodDefinition
  ///
  /// Throws [PodNotFoundException] if there is no pod with the given name
  /// defined in this factory
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

  /// Check if pod definition exists locally.
  ///
  /// Subclasses should implement this method to provide the actual pod
  /// definition existence check logic.
  ///
  /// Usage Example:
  /// ```dart
  /// final provider = getPodFactory();
  /// if (provider.containsDefinition("myPod")) {
  ///   print("Pod 'myPod' exists");
  /// } else {
  ///   print("Pod 'myPod' does not exist");
  /// }
  /// ```
  bool containsDefinition(String name);

  /// {@template abstract_pod_factory_do_create}
  /// Abstract method for creating pod instances that must be implemented by subclasses.
  ///
  /// This method is responsible for the actual pod instantiation logic, including:
  /// - Resolving the pod class
  /// - Invoking constructors or provider methods
  /// - Populating properties and dependencies
  /// - Applying post-processors
  /// - Handling initialization callbacks
  ///
  /// Usage Example:
  /// ```dart
  /// class MyPodFactory extends AbstractPodFactory {
  ///   @override
  ///   FutureOr<Object> doCreate(String name, RootPodDefinition definition, List<ArgumentValue>? args) {
  ///     // Implementation to create the pod instance
  ///     final constructor = definition.constructor;
  ///     final instance = constructor.invoke(args ?? []);
  ///
  ///     // Apply property population
  ///     definition.properties.forEach((property) {
  ///       property.applyTo(instance);
  ///     });
  ///
  ///     return instance;
  ///   }
  /// }
  /// ```
  ///
  /// [name] the name of the pod to create
  /// [definition] the pod definition containing creation instructions
  /// [args] optional constructor arguments
  /// Returns the created pod instance
  ///
  /// Throws [PodCreationException] if pod creation fails
  /// {@endtemplate}
  FutureOr<Object> doCreate(String name, RootPodDefinition definition, List<ArgumentValue>? args);
}