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
import 'package:meta/meta.dart';

import '../definition/commons.dart';
import '../definition/pod_definition.dart';
import '../exceptions.dart';
import '../helpers/enums.dart';
import '../helpers/object.dart';
import '../instantiation/simple_executable_strategy.dart';
import '../lifecycle/disposable_lifecycle_manager.dart';
import '../lifecycle/init_methods_manager.dart';
import '../lifecycle/lifecycle.dart';
import '../instantiation/executable_strategy.dart';
import 'abstract_pod_factory.dart';
import 'pod_factory.dart';

/// {@template abstractAutowirePodFactory}
/// Abstract base class for pod factories that support autowiring capabilities.
///
/// This class provides the foundation for dependency injection with autowiring,
/// including circular reference handling, definition overriding, and dependency
/// exclusion. It manages the complex lifecycle of pod creation with thread-local
/// context tracking and initialization method management.
///
/// **Key Features:**
/// - Circular reference detection and handling
/// - Definition overriding control
/// - Dependency type and interface exclusion
/// - Thread-safe pod creation tracking
/// - Initialization method management
/// - Constructor resolution strategies
///
/// **Example:**
/// ```dart
/// class MyAutowirePodFactory extends AbstractAutowirePodFactory {
///   @override
///   void configure() {
///     // Configure autowiring behavior
///     setAllowCircularReferences(false);
///     setAllowDefinitionOverriding(true);
///
///     // Ignore specific dependency types
///     ignoreDependencyType(Class<Logger>(null, PackageNames.CORE));
///     ignoreDependencyInterface(Class<Serializable>(null, PackageNames.CORE));
///
///     // Configure initialization methods
///     getInitMethodsManager().setInitMethodName('initialize');
///     getInitMethodsManager().setDestroyMethodName('dispose');
///   }
///
///   @override
///   Object createPod(PodDefinition definition) {
///     // Custom pod creation logic with autowiring
///     return super.createPod(definition);
///   }
/// }
///
/// // Usage
/// final factory = MyAutowirePodFactory();
/// factory.configure();
///
/// final pod = factory.createPod(podDefinition);
/// ```
/// {@endtemplate}
abstract class AbstractAutowirePodFactory extends AbstractPodFactory implements AutowirePodFactory {
  /// {@macro allowCircularReferences}
  /// Controls whether circular references are allowed during autowiring.
  ///
  /// When true, the factory will attempt to resolve circular dependencies
  /// using proxies or other mechanisms. When false, circular dependencies
  /// will result in exceptions.
  bool _allowCircularReferences = true;

  /// {@macro allowDefinitionOverriding}
  /// Controls whether pod definition overriding is allowed.
  ///
  /// When true, multiple definitions for the same pod name can be registered
  /// with the last one taking precedence. When false, duplicate definitions
  /// will result in exceptions.
  bool _allowDefinitionOverriding = true;

  /// {@macro allowRawInjectionDespiteWrapping}
  /// Controls whether raw injection is allowed despite wrapping.
  ///
  /// When true, dependencies can be injected directly even when the target
  /// is wrapped in proxies or decorators. When false, only wrapped instances
  /// are injected.
  bool _allowRawInjection = false;

  /// {@macro ignoredDependencyTypes}
  /// Set of dependency types to ignore during autowiring.
  ///
  /// Types in this set will not be considered for autowiring and will
  /// need to be explicitly provided or will result in missing dependency errors.
  final Set<Class> _ignoredDependencyTypes = HashSet();

  /// {@macro ignoredDependencyInterfaces}
  /// Set of dependency interfaces to ignore during autowiring.
  ///
  /// Interfaces in this set will not be considered for autowiring, useful
  /// for excluding framework interfaces or optional dependencies.
  final Set<Class> _ignoredDependencyInterfaces = HashSet();

  /// {@macro currentlyCreatedPod}
  /// Thread-local storage for tracking the currently created pod name.
  ///
  /// This is used for cycle detection and context-aware dependency resolution
  /// during the pod creation process.
  final LocalThread<String> _currentlyCreatedPod = LocalThread();

  /// {@macro initMethodsManager}
  /// Manager for pod initialization and destruction methods.
  ///
  /// Handles the invocation of init-methods and destroy-methods as defined
  /// in pod definitions or annotations.
  late InitMethodsManager _initMethodsManager;

  /// {@macro executableStrategy}
  /// Strategy for constructor and method resolution.
  ///
  /// Determines how constructors and factory methods are selected and invoked
  /// during pod instantiation.
  late ExecutableStrategy _executableStrategy;

  final List<CreatedPodHolder> _createdPods = [];

  /// {@macro abstract_autowire_pod_factory}
  ///
  /// Creates a new autowire-capable pod factory with optional parent factory.
  ///
  /// Example:
  /// ```dart
  /// // Create with parent factory for hierarchical dependency resolution
  /// final parentFactory = DefaultPodFactory();
  /// final autowireFactory = MyAutowirePodFactory(parentFactory);
  /// ```
  ///
  /// @param parentFactory The parent pod factory for hierarchical resolution
  AbstractAutowirePodFactory([super.parentFactory]) {
    _currentlyCreatedPod.set("");
    _initMethodsManager = InitMethodsManager();
    _executableStrategy = SimpleExecutableStrategy(this);
    _createdPods.clear();
  }

  // -----------------------------------------------------------------------------------------------------
  // OVERRIDDEN METHODS
  // -----------------------------------------------------------------------------------------------------

  @override
  void setAllowCircularReferences(bool value) {
    _allowCircularReferences = value;
  }

  @override
  void setAllowDefinitionOverriding(bool value) {
    _allowDefinitionOverriding = value;
  }

  @override
  void setAllowRawInjection(bool value) {
    _allowRawInjection = value;
  }

  @override
  bool getAllowCircularReferences() => _allowCircularReferences;

  @override
  bool getAllowDefinitionOverriding() => _allowDefinitionOverriding;

  @override
  bool getAllowRawInjection() =>
      _allowRawInjection;

  @override
  void copyConfigurationFrom(ConfigurablePodFactory other) {
    super.copyConfigurationFrom(other);
    if (other is AbstractAutowirePodFactory) {
      _allowCircularReferences = other._allowCircularReferences;
      _allowDefinitionOverriding = other._allowDefinitionOverriding;
      _ignoredDependencyTypes.addAll(other._ignoredDependencyTypes);
      _ignoredDependencyInterfaces.addAll(other._ignoredDependencyInterfaces);
      _initMethodsManager = other._initMethodsManager;
    }
  }

  @override
  Future<T> createPod<T>(T instance, Class type) async {
    if (!type.isInstance(instance)) {
      throw PodCreationException("Instance type does not match pod class type");
    }

    final definition = RootPodDefinition(type: type)
      ..scope = ScopeDesign.type(ScopeType.PROTOTYPE.name);

    return await doCreate(type.getName(), definition, null) as T;
  }

  @override
  FutureOr<Object> doCreate(String name, RootPodDefinition definition, List<ArgumentValue>? args) async {
    // Check circular reference protection
    String currentPodName = _currentlyCreatedPod.get() ?? "";
    if (currentPodName.isNotEmpty && !_allowCircularReferences) {
      throw PodCreationException.withResource(
        definition.description,
        name,
        "Circular dependency detected: currently creating '$currentPodName'",
      );
    }

    final created = _createdPods.find((c) => c.$1.equals(name) && c.$2 == definition);
    if (created != null) {
      return created.$3;
    }

    try {
      _currentlyCreatedPod.set(name);

      // Give PodInstantiationProcessors a chance to return a proxy instead of the target pod instance
      Object? pod = await applyBeforeInstantiationProcessing(name, definition);
      if (pod != null) {
        return pod;
      }

      final instance = await create(name, definition, args);
      if (logger.getIsTraceEnabled()) {
        logger.trace("Finished creating instance of pod $name");
      }

      if (definition.scope.isSingleton) {
        _createdPods.add((name, definition, instance));
      }

      return instance;
    } finally {
      _currentlyCreatedPod.remove();
    }
  }

  @override
  Future<Object> autowire(Class podClass, int autowireMode, bool checkDependency) async {
    RootPodDefinition root = RootPodDefinition(type: podClass)
      ..scope = ScopeDesign.type(ScopeType.PROTOTYPE.name)
      ..autowireCandidate = AutowireCandidateDescriptor(autowireCandidate: true, autowireMode: AutowireMode.fromValue(autowireMode));

    if (autowireMode == AutowireMode.BY_TYPE.value) {
      return await instantiateUsingConstructor(podClass.getName(), root, null, null);
    } else {
      Object instance = await instantiateUsingConstructor(podClass.getName(), root, null, null);
      await populate(podClass.getName(), root, (instance, podClass));

      return instance;
    }
  }

  @override
  Future<void> autowirePod(Object existing, Class type, {int? autowireMode, bool? checkDependency}) async {
    // Use non-singleton pod definition, to avoid registering pod as dependent pod.
    RootPodDefinition root = RootPodDefinition(type: type)
      ..scope = ScopeDesign.type(ScopeType.PROTOTYPE.name)
      ..instance = existing;

    // Set autowire mode if provided
    if (autowireMode != null) {
      root.autowireCandidate = AutowireCandidateDescriptor(autowireCandidate: true, autowireMode: AutowireMode.fromValue(autowireMode));
    }

    // Set dependency check if provided
    if (checkDependency != null) {
      root.dependencyCheck = checkDependency 
        ? type.getFields().all((f) => !f.isNullable()) 
          ? DependencyCheck.ALL : DependencyCheck.OBJECTS
        : DependencyCheck.NONE;
    }

    await populate(root.type.getName(), root, (existing, type));
  }

  @override
  Future<void> applyPodPropertyValues(Object existing, String name) async {
    RootPodDefinition root = getMergedPodDefinition(name);
    Class podClass = root.type;
    PodHolder ph = (existing, podClass);

    MutablePropertyValues pvs = MutablePropertyValues.from(root.propertyValues);
    applyPropertyValues(name, root, ph, pvs);
  }

  @override
  Future<void> initializePod(Object existing, Class type, String name) async {
    initializeExistingPod(existing, type, name);
  }

  @override
  Future<void> destroyExistingPod(Object existing, Class type, String name) async {
    try {
      if (DisposableLifecycleManager.hasDestroyMethod(existing, getMergedPodDefinition(name))) {
        // Apply destruction post-processors
        for (final processor in getPodDestructionProcessors()) {
          processor.processBeforeDestruction(existing, type, name);
        }
      }
    } catch (e) {
      if (logger.getIsWarnEnabled()) {
        logger.warn("Destruction of pod failed: $e");
      }
    }
  }

  @override
  Future<Object> configurePod(Object existing, String name) async {
    RootPodDefinition root = getMergedPodDefinition(name);
    Class podClass = root.type;
    PodHolder ph = (existing, podClass);

    // Apply property population
    await populate(name, root, ph);

    return initializeExistingPod(existing, podClass, name);
  }

  @override
  Future<Object?> resolveDependency(DependencyDescriptor descriptor, [Set<String>? autowiredPods]) async {
    // 1. Determine dependency type
    Class type = descriptor.type;

    // 2. Check if dependency type should be ignored
    if (_ignoredDependencyTypes.contains(type) || _ignoredDependencyInterfaces.any( (ignored) => type.isAssignableFrom(ignored))) {
      return null;
    }

    // 3. Handle other types
    return await doResolveDependency(descriptor, autowiredPods);
  }

  @override
  Future<ObjectHolder<Object>> postProcessObjectFromPodProvider(ObjectHolder<Object> object, String name) async {
    try {
      Object processedValue = object.getValue();

      // Apply PodExpression evaluation if available
      if (containsDefinition(name)) {
        final definition = getDefinition(name);
        if (definition is AbstractPodDefinition) {
          final expression = definition.getPodExpression();
          if (expression != null) {
            try {
              final result = await evaluateExpression(expression, definition);
              if (result != null) {
                processedValue = result.getValue();
                if (logger.getIsTraceEnabled()) {
                  logger.trace("Applied PodExpression post-processing for pod '$name'");
                }
              }
            } catch (e) {
              if (logger.getIsWarnEnabled()) {
                logger.warn("Failed to evaluate PodExpression for pod '$name': $e");
              }
            }
          }
        }
      }

      // Apply additional post-processing logic
      processedValue = applyCustomPostProcessing(processedValue, name);

      return ObjectHolder<Object>(
        processedValue,
        packageName: object.getPackageName(),
        qualifiedName: object.getQualifiedName(),
      );
    } catch (e) {
      if (logger.getIsWarnEnabled()) {
        logger.warn("Error in post-processing object from PodProvider for '$name': $e");
      }
      return object; // Return original on error
    }
  }

  @override
  Future<Object> doGetObject(Object instance, Class? type, String name, String transformed, PodDefinition? definition) {
    final currently = _currentlyCreatedPod.get();
    if (currently != null) {
      registerDependentPod(name, currently);
    }

    return super.doGetObject(instance, type, name, transformed, definition);
  }

  @override
  void removeSingleton(String name) {
    super.removeSingleton(name);
    podProviderInstanceCache.remove(name);
  }

  @override
  void clearSingletonCache() {
    super.clearSingletonCache();
    podProviderInstanceCache.clear();
  }

  // -----------------------------------------------------------------------------------------------------
  // PUBLIC METHODS
  // -----------------------------------------------------------------------------------------------------

  /// {@macro ignore_dependency_type}
  ///
  /// Ignores the specified dependency type during autowiring.
  ///
  /// This is useful for excluding certain types from automatic dependency
  /// resolution, such as framework types or types that should be manually wired.
  ///
  /// Example:
  /// ```dart
  /// factory.ignoreDependencyType(Logger); // Ignore Logger dependencies
  /// ```
  ///
  /// @param type The class type to ignore during dependency resolution
  void ignoreDependencyType(Class type) {
    _ignoredDependencyTypes.add(type);
  }

  /// {@macro ignore_dependency_interface}
  ///
  /// Ignores the specified dependency interface and all its implementations
  /// during autowiring.
  ///
  /// Example:
  /// ```dart
  /// factory.ignoreDependencyInterface(Serializable); // Ignore all serializable types
  /// ```
  ///
  /// @param type The interface type to ignore during dependency resolution
  void ignoreDependencyInterface(Class type) {
    _ignoredDependencyInterfaces.add(type);
  }

  /// {@macro executable_strategy}
  ///
  /// Returns the executable strategy used by this factory.
  ///
  /// @return The executable strategy
  ExecutableStrategy getExecutableStrategy() => _executableStrategy;

  /// {@macro set_executable_strategy}
  ///
  /// Sets the executable strategy used by this factory.
  ///
  /// @param executableStrategy The executable strategy to set
  void setExecutableStrategy(ExecutableStrategy executableStrategy) {
    _executableStrategy = executableStrategy;
  }

  // -----------------------------------------------------------------------------------------------------
  // PROTECTED METHODS
  // -----------------------------------------------------------------------------------------------------

  /// {@macro is_type_ignored}
  ///
  /// Checks if the specified type is ignored during dependency resolution.
  ///
  /// @param type The type to check
  /// @return true if the type is ignored, false otherwise
  @protected
  bool isTypeIgnored(Class type) => _ignoredDependencyTypes.contains(type);

  /// {@macro is_interface_ignored}
  ///
  /// Checks if the specified interface is ignored during dependency resolution.
  ///
  /// @param type The interface type to check
  /// @return true if the interface is ignored, false otherwise
  @protected
  bool isInterfaceIgnored(Class type) => _ignoredDependencyInterfaces.contains(type);

  /// {@macro convert_value_if_necessary}
  ///
  /// Converts a value to the target type if necessary using the conversion service.
  ///
  /// This method is used during property population to ensure values are
  /// of the correct type for the target field or parameter.
  ///
  /// @param value The value to convert
  /// @param target The target type
  /// @param source The source type (optional)
  /// @return The converted value, or the original value if no conversion needed
  @protected
  Object? convertValueIfNecessary(Object? value, Class target, Class? source) {
    if (value == null) {
      return null;
    }

    if (target.isInstance(value)) {
      return value;
    }

    // Use conversion service if available
    ConversionService? conversionService = getConversionService();
    if (conversionService.canConvert(source, target)) {
      return conversionService.convertTo(value, target, source);
    }

    return value;
  }

  /// {@macro resolve_before_instantiation}
  ///
  /// Gives PodInstantiationProcessors a chance to return a proxy instead
  /// of the target pod instance before instantiation.
  ///
  /// @param podName The name of the pod being created
  /// @param root The pod definition
  /// @return A proxy object if any processor returns one, null otherwise
  @protected
  Future<Object?> resolveBeforeInstantiation(String podName, PodDefinition root) async {
    Object? pod;

    if (root.hasBeforeInstantiationResolved) {
      return pod;
    }

    if (!root.design.isInfrastructure && hasPodInstantiationProcessors()) {
      pod = await applyBeforeInstantiationProcessing(podName, root);
      if (pod != null) {
        pod = await applyAfterInitializationProcessing(pod, podName, root.type);
      }
    }

    root.hasBeforeInstantiationResolved = pod != null;

    return pod;
  }

  /// {@macro apply_before_instantiation_processing}
  ///
  /// Applies post-processing to a pod instance before its initialization.
  ///
  /// This method is used to apply post-processing to a pod instance before
  /// its initialization. It is called by [create] and [getObject] methods.
  ///
  /// @param podName The name of the pod being created
  /// @param root The pod definition
  /// @return The processed pod instance
  @protected
  Future<Object?> applyBeforeInstantiationProcessing(String podName, PodDefinition root) async {
    Object? pod;

    if (!root.design.isInfrastructure && hasPodInstantiationProcessors()) {
      for (final processor in getPodInstantiationProcessors()) {
        pod = await processor.processBeforeInstantiation(root.type, podName);
        if (pod != null) {
          return pod;
        }
      }
    }

    return pod;
  }

  /// {@macro apply_after_instantiation_processing}
  ///
  /// Applies post-processing to a pod instance after its instantiation.
  ///
  /// This method is used to apply post-processing to a pod instance after
  /// its instantiation. It is called by [create] and [getObject] methods.
  ///
  /// @param existing The existing pod instance
  /// @param podName The name of the pod being created
  /// @param type The pod class
  /// @return The processed pod instance
  @protected
  Future<void> applyAfterInstantiationProcessing(Object existing, String podName, Class type) async {
    Object pod = existing;

    if (hasPodInstantiationProcessors()) {
      for (final processor in getPodInstantiationProcessors()) {
        final proceed = await processor.processAfterInstantiation(pod, type, podName);
        if (proceed) {
          continue;
        }
      }
    }
  }

  /// {@macro determine_property_values_from_pod_aware_processors}
  ///
  /// Determines the property values for a pod instance from pod-aware processors.
  ///
  /// This method is used to determine the property values for a pod instance
  /// from pod-aware processors. It is called by [create] and [getObject] methods.
  ///
  /// @param pvs The property values to determine
  /// @param type The pod class
  /// @param pod The pod instance
  /// @param podName The name of the pod being created
  /// @return The determined property values
  @protected
  Future<PropertyValues?> applyPropertyValuesProcessing(PropertyValues pvs, Class type, Object pod, String podName) async {
    if (hasPodInstantiationProcessors()) {
      for (final iap in getPodInstantiationProcessors()) {
        final usage = await iap.processPropertyValues(pvs, pod, type, podName);
        if (usage == null) {
          continue;
        }

        pvs = usage;
      }
    }

    return pvs;
  }

  /// {@macro populate_values}
  ///
  /// Populates the values of a pod instance from pod-aware processors.
  ///
  /// This method is used to populate the values of a pod instance from
  /// pod-aware processors. It is called by [create] and [getObject] methods.
  ///
  /// @param pod The pod instance
  /// @param type The pod class
  /// @param podName The name of the pod being created
  @protected
  Future<void> applyPopulateValueProcessing(Object pod, Class type, String podName) async {
    if (hasPodInstantiationProcessors()) {
      for (final iap in getPodInstantiationProcessors()) {
        await iap.populateValues(pod, type, podName);
      }
    }
  }

  @protected
  Future<List<Constructor>?> determineConstructorsFromPodProcessors(Class podClass, String podName) async {
    if (hasPodSmartInstantiationProcessors()) {
      for (final iap in getPodSmartInstantiationProcessors()) {
        final cs = await iap.determineCandidateConstructors(podClass, podName);
        if (cs != null) {
          return cs;
        }
      }
    }

    return null;
  }

  /// {@macro apply_determine_candidate_arguments}
  ///
  /// Determines the candidate arguments for a pod instance.
  ///
  /// This method is used to determine the candidate arguments for a pod instance.
  /// It is called by [create] and [getObject] methods.
  ///
  /// @param podName The name of the pod being created
  /// @param executable The executable to determine the candidate arguments for
  /// @param parameters The parameters of the executable
  /// @return The candidate arguments
  @protected
  Future<List<ArgumentValue>?> determineCandidateArguments(String podName, Executable executable, List<Parameter> parameters) async {
    if (hasPodSmartInstantiationProcessors()) {
      for (final iap in getPodSmartInstantiationProcessors()) {
        final args = await iap.determineCandidateArguments(podName, executable, parameters);
        if (args != null) {
          return args;
        }
      }
    }

    return null;
  }

  /// {@macro apply_before_initialization_processing}
  ///
  /// Applies post-processing to a pod instance after its initialization.
  ///
  /// This method is used to apply post-processing to a pod instance after
  /// its initialization. It is called by [create] and [getObject] methods.
  ///
  /// @param podName The name of the pod being created
  /// @param type The pod class
  /// @return The processed pod instance
  @protected
  Future<Object> applyBeforeInitializationProcessing(Object existing, String podName, Class type) async {
    Object pod = existing;

    if (hasPodInitializationProcessors()) {
      for (final processor in getPodInitializationProcessors()) {
        final shouldProcess = await processor.shouldProcessBeforeInitialization(pod, type, podName);

        if (containsDefinition(podName) && !shouldProcess) {
          final definition = getDefinition(podName);
          if (definition.design.isInfrastructure) {
            return pod;
          }
        }

        if (shouldProcess) {
          final processed = await processor.processBeforeInitialization(pod, type, podName,);
          if (processed == null) {
            continue;
          }

          pod = processed;
        }
      }
    }

    return pod;
  }

  /// {@macro apply_after_initialization_processing}
  ///
  /// Applies post-processing to a pod instance after its initialization.
  ///
  /// This method is used to apply post-processing to a pod instance after
  /// its initialization. It is called by [create] and [getObject] methods.
  ///
  /// @param podName The name of the pod being created
  /// @param type The pod class
  /// @return The processed pod instance
  @protected
  Future<Object> applyAfterInitializationProcessing(Object existing, String podName, Class type) async {
    Object pod = existing;

    if (containsDefinition(podName)) {
      final definition = getDefinition(podName);
      if (definition.design.isInfrastructure) {
        return pod;
      }
    }

    if (hasPodInitializationProcessors()) {
      for (final pp in getPodInitializationProcessors()) {
        final processed = await pp.processAfterInitialization(pod, type, podName);
        if (processed == null) {
          continue;
        }

        pod = processed;
      }
    }

    return pod;
  }

  /// {@macro create_pod_instance}
  ///
  /// Creates a pod instance with the given name and definition.
  ///
  /// This method handles the complete pod creation lifecycle including
  /// instantiation, population, and initialization.
  ///
  /// @param podName The name of the pod to create
  /// @param root The pod definition
  /// @param args Optional constructor arguments
  /// @return The created pod instance
  @protected
  Future<Object> create(String podName, RootPodDefinition root, List<ArgumentValue>? args) async {
    // Instantiate the pod
    PodHolder? podHolder;

    if (root.scope.isSingleton) {
      final obj = podProviderInstanceCache.remove(podName);
      final cls = obj?.getType();

      if (obj != null && cls != null) {
        podHolder = (obj.getValue(), cls);
      }
    }

    podHolder ??= await createInstance(podName, root, args);

    final earlySingletonExposure = root.scope.isSingleton && getAllowCircularReferences() && isCurrentlyCreatingSingleton(podName);

    Object pod = podHolder.$1;
    Class podClass = podHolder.$2;

    if (earlySingletonExposure) {
      if (logger.getIsTraceEnabled()) {
        logger.trace('Eagerly caching pod $podName to allow potential circular references resolution');
      }

      Future<ObjectHolder<Object>> create() async {
        return await getEarlyPodReference(
          podName,
          root,
          ObjectHolder(
            pod,
            packageName: podClass.getPackage()?.getName(),
            qualifiedName: podClass.getQualifiedName(),
          ),
        );
      }

      addSingleton(podName, factory: SimpleObjectFactory(([args]) async => create()));
    }

    Object exposed = pod;

    try {
      // Populate the pod instance
      await populate(podName, root, podHolder);

      // Initialize the pod
      exposed = await initializeExistingPod(exposed, podHolder.$2, podName);
    } catch (e) {
      if (e is PodCreationException && e.getPodName().equals(podName)) {
        rethrow;
      }

      final message = e is Throwable ? e.getMessage() : e.toString();
      final cause = e is Throwable ? e : RuntimeException(e.toString());

      throw PodCreationException.withResource(root.description, podName, message, cause: cause);
    }

    if (earlySingletonExposure) {
      final earlyReference = await getSingleton(podName, allowEarlyReference: false);
      if (earlyReference != null) {
        if (exposed == pod) {
          exposed = earlyReference;
        } else if (!_allowRawInjection && hasDependentPod(podName)) {
          final dependents = getDependentPods(podName);
          final actualDependents = Set.from(dependents);

          for (String dependent in dependents) {
            if (!removeSingletonIfCreated(dependent)) {
              actualDependents.remove(dependent);
            }
          }

          if (actualDependents.isNotEmpty) {
            throw PodCurrentlyInCreationException(
              name: podName,
              msg:
                "Pod $podName has been injected into other pods ${actualDependents.join(', ')} "
                "in its raw (uninitialized) form as part of a circular reference. This means that "
                "mentioned pods do not use the final (fully initialized) form of $podName. "
                "This is often the result of over-zealous circular reference prevention. "
                "Consider using 'getPodsForType' with the 'allowEagerInit' flag turned off.",
            );
          }
        }
      }
    }

    // Register pod as disposable (if it is a disposable)
    if (exposed is DisposablePod) {
      try {
        registerDisposableHandler(podName, exposed, root);
      } on PodDefinitionValidationException catch (e) {
        throw PodCreationException.withResource(
          root.description,
          podName,
          "Invalid disposable pod",
          cause: e,
        );
      }
    }

    return exposed;
  }

  /// {@macro create_instance}
  ///
  /// Creates a pod instance using the appropriate strategy (factory method,
  /// constructor, or default instantiation).
  ///
  /// @param podName The name of the pod
  /// @param root The pod definition
  /// @param args Optional arguments for creation
  /// @return A PodHolder containing the instance and its class
  @protected
  Future<PodHolder> createInstance(String podName, RootPodDefinition root, List<ArgumentValue>? args) async {
    Class podClass = root.type;

    // Obtain from provided instance
    if (root.instance != null) {
      Object instance = await instantiateFromSupplier(root.instance!);
      return (instance, instance.getClass());
    }

    // Obtain from factory method
    if (root.factoryMethod.methodName.isNotEmpty) {
      final instance = await instantiateUsingFactoryMethod(podName, root, args);
      if (instance is Future) {
        Object result = await instance;
        return (result, result.getClass());
      }

      return (instance, instance.getClass());
    }

    // Obtain from constructor arguments
    final cs = await determineConstructorsFromPodProcessors(podClass, podName);
    final instance = await instantiateUsingConstructor(podName, root, cs, args);
    return (instance, instance.getClass());
  }

  @protected
  Future<Object> instantiateFromSupplier(Object supplier) async {
    if (supplier is Supplier) {
      return supplier.get();
    }

    if (supplier is ThrowingSupplier) {
      return supplier.get();
    }

    if (supplier is Provider) {
      return supplier.get();
    }

    return supplier;
  }

  /// {@macro instantiate_using_factory_method}
  ///
  /// Instantiates a pod using a factory method defined in the pod definition.
  ///
  /// @param podName The name of the pod
  /// @param root The pod definition containing factory method information
  /// @param args Optional arguments for the factory method
  /// @return The instance created by the factory method
  @protected
  Future<Object> instantiateUsingFactoryMethod(String podName, RootPodDefinition root, List<ArgumentValue>? args) async {
    Object factoryInstance = await getPod(root.factoryMethod.podName, args);

    final result = await _executableStrategy.determineFactoryMethod(root, podName, args);
    final method = result.executable as Method;

    try {
      if (method.isStatic()) {
        throw PodIsAbstractException(
          "Factory method '${method.getName()}' in pod '${root.factoryMethod.podName}' is static and cannot be invoked",
          name: podName,
        );
      }

      if (logger.getIsTraceEnabled()) {
        logger.trace(
          "Instantiating pod '$podName' using factory method '${method.getName()}' "
          "from pod '${root.factoryMethod.podName}' "
          "with args: named=${result.namedArgs}, positional=${result.positionalArgs}",
        );
      }

      return method.invoke(factoryInstance, result.namedArgs, result.positionalArgs);
    } on PodException catch (e, st) {
      if (logger.getIsTraceEnabled()) {
        logger.trace(
          "Pod instantiation failed for '$podName' via factory method '${method.getName()}': $e",
          error: e,
          stacktrace: st,
        );
      }

      rethrow;
    } catch (e, st) {
      if (logger.getIsTraceEnabled()) {
        logger.trace(
          "Unexpected error while instantiating pod '$podName' via factory method '${method.getName()}': $e\n$st",
          error: e,
          stacktrace: st,
        );
      }

      rethrow;
    }
  }

  /// {@macro instantiate_using_constructor}
  ///
  /// Instantiates a pod using constructor injection.
  ///
  /// This method selects the appropriate constructor and resolves all
  /// constructor arguments through dependency injection.
  ///
  /// @param podName The name of the pod
  /// @param root The pod definition
  /// @param chosenConstructors Optional specific constructors to use
  /// @param explicitArgs Optional explicit arguments
  /// @return The autowired instance
  @protected
  Future<Object> instantiateUsingConstructor(String podName, RootPodDefinition root, List<Constructor>? chosenConstructors, List<ArgumentValue>? explicitArgs) async {
    final result = await _executableStrategy.determineConstructor(root, podName, chosenConstructors, explicitArgs);
    final constructor = result.executable as Constructor;

    try {
      if (logger.getIsTraceEnabled()) {
        logger.trace(
          "Instantiating pod '$podName' using constructor '${constructor.getName()}' "
          "with args: named=${result.namedArgs}, positional=${result.positionalArgs}",
        );
      }

      return constructor.newInstance(result.namedArgs, result.positionalArgs);
    } on PodException catch (e, st) {
      if (logger.getIsTraceEnabled()) {
        logger.trace(
          "Pod instantiation failed for '$podName' via constructor '${constructor.getName()}': $e",
          error: e,
          stacktrace: st,
        );
      }

      rethrow;
    } catch (e, st) {
      if (logger.getIsTraceEnabled()) {
        logger.trace(
          "Unexpected error while instantiating pod '$podName' via constructor '${constructor.getName()}': $e\n$st",
          error: e,
          stacktrace: st,
        );
      }

      rethrow;
    }
  }

  @protected
  Future<ObjectHolder<Object>> getEarlyPodReference(String podName, RootPodDefinition rpd, ObjectHolder<Object> pod) async {
    ObjectHolder<Object> object = pod;

    if (!rpd.design.isInfrastructure && hasPodSmartInstantiationProcessors()) {
      for (final iap in getPodSmartInstantiationProcessors()) {
        object = await iap.getEarlyPodReference(object, rpd.type, podName);
      }
    }

    return object;
  }

  /// {@macro populate_pod}
  ///
  /// Populates a pod instance with property values and dependencies.
  ///
  /// This method handles autowiring by name or type, applies property values,
  /// and performs dependency checking.
  ///
  /// @param podName The name of the pod
  /// @param root The pod definition
  /// @param ph The pod holder containing instance and class
  @protected
  Future<void> populate(String podName, RootPodDefinition root, PodHolder ph) async {
    if (ph.$2.isRecord()) {
      if (root.hasPropertyValues()) {
        throw PodCreationException.withResource(
          root.description,
          podName,
          "Cannot apply property values to a record",
        );
      } else {
        // Skip property population phase for records since they are immutable.
        return;
      }
    }

    // Give any InstantiationAwarePodPostProcessors the opportunity to modify the
    // state of the pod before properties are set. This can be used, for example,
    // to support styles of field injection.
    await applyAfterInstantiationProcessing(ph.$1, podName, ph.$2);
    await applyPopulateValueProcessing(ph.$1, ph.$2, podName);

    MutablePropertyValues pvs = root.propertyValues;
    int autowire = root.autowireCandidate.autowireMode.value;
    if (autowire == AutowireMode.BY_NAME.value) {
      await autowireByName(podName, root, ph, pvs);
    } else if (autowire == AutowireMode.BY_TYPE.value) {
      await autowireByType(podName, root, ph, pvs);
    }

    final data = await applyPropertyValuesProcessing(pvs, ph.$2, ph.$1, podName);
    if (data != null) {
      pvs = MutablePropertyValues.from(data);
    }

    bool needsDepCheck = root.dependencyCheck != DependencyCheck.NONE;
    if (needsDepCheck) {
      checkDependencies(podName, root, ph, pvs);
    }

    if (pvs.isNotEmpty) {
      applyPropertyValues(podName, root, ph, pvs);
    }
  }

  /// {@macro autowire_by_name}
  ///
  /// Performs autowiring by name for the pod instance.
  ///
  /// This method looks for pods in the factory that match property names
  /// and injects them into the corresponding fields or setters.
  ///
  /// @param podName The name of the pod being wired
  /// @param root The pod definition
  /// @param ph The pod holder
  /// @param pvs The property values to populate
  @protected
  Future<void> autowireByName(String podName, RootPodDefinition root, PodHolder ph, MutablePropertyValues pvs) async {
    Map<String, Class> nonSatisfiedProperties = getUnsatisfiedNonSimpleProperties(root, ph);
    for (final entry in nonSatisfiedProperties.entries) {
      String propertyName = entry.key;
      Class type = entry.value;

      if (await containsPod(propertyName)) {
        Object pod = await getPod(propertyName);
        pvs.add(
          propertyName,
          pod,
          qualifiedName: type.getQualifiedName(),
          packageName: type.getPackage()?.getName(),
        );
        registerDependentPod(propertyName, podName);

        if (logger.getIsTraceEnabled()) {
          logger.trace("Added autowiring by name from pod name '$podName' via property '$propertyName' to pod named '$propertyName'");
        }
      } else {
        if (logger.getIsTraceEnabled()) {
          logger.trace("Could not autowire by name from pod name '$podName' via property '$propertyName' to pod named '$propertyName'");
        }
      }
    }
  }

  /// {@macro get_unsatisfied_non_simple_properties}
  ///
  /// Gets a map of property names to their types that are not satisfied
  /// by existing property values and are not simple types.
  ///
  /// @param root The pod definition
  /// @param ph The pod holder
  /// @return Map of property names to their class types
  @protected
  Map<String, Class> getUnsatisfiedNonSimpleProperties(PodDefinition root, PodHolder ph) {
    Map<String, Class> result = {};
    PropertyValues pvs = root.propertyValues;
    final fields = ph.$2.getFields();

    for (final field in fields) {
      String fieldName = field.getName();
      final clazz = field.getReturnClass();

      if (!pvs.containsProperty(fieldName)) {
        // Skip simple properties (primitives, strings, etc.)
        if (clazz.isPrimitive()) {
          continue;
        }

        if (field.isNullable()) {
          // Skip nullable fields
          continue;
        }

        try {
          final currentValue = field.getValue(ph.$1);
          if (currentValue != null) {
            continue;
          }
        } catch (_) {}

        result[fieldName] = clazz;
      } else {
        // Skip if already has property value
      }
    }

    return result;
  }

  /// {@macro autowire_by_type}
  ///
  /// Performs autowiring by type for the pod instance.
  ///
  /// This method resolves dependencies based on their types and injects
  /// them into the corresponding fields or setters.
  ///
  /// @param podName The name of the pod being wired
  /// @param root The pod definition
  /// @param ph The pod holder
  /// @param pvs The property values to populate
  @protected
  Future<void> autowireByType(String podName, RootPodDefinition root, PodHolder ph, MutablePropertyValues pvs) async {
    final nonSatisfiedProperties = getUnsatisfiedNonSimpleProperties(root, ph);
    final autowiredPods = <String>{};

    for (final entry in nonSatisfiedProperties.entries) {
      String propertyName = entry.key;
      Class type = entry.value;
      bool isEager = ph.$1 is PriorityOrdered;

      // Skip Object type
      if (type.getType() == Object) {
        continue;
      }

      try {
        final methods = ph.$2.getMethods();

        Method? method = methods.firstWhereOrNull((m) => m.getName().equalsIgnoreCase('set$propertyName'));
        method ??= methods.firstWhereOrNull((m) => m.getName().equalsIgnoreCase(propertyName) && m.isSetter());

        if (method != null) {
          Class type = method.getReturnClass();
          final autowiredValue = await resolveDependency(
            DependencyDescriptor(
              source: method,
              podName: podName,
              propertyName: propertyName,
              type: type,
              args: null,
              component: type.componentType(),
              key: type.keyType(),
              isEager: isEager,
            ),
            autowiredPods,
          );
          if (autowiredValue != null) {
            pvs.add(
              propertyName,
              autowiredValue,
              qualifiedName: type.getQualifiedName(),
              packageName: type.getPackage()?.getName(),
            );

            if (logger.getIsTraceEnabled()) {
              logger.trace("Autowiring by type from method '$method' for pod name '$propertyName' to pod named '$podName'");
            }
          }

          for (final name in autowiredPods) {
            registerDependentPod(name, podName);

            if (logger.getIsTraceEnabled()) {
              logger.trace("Autowiring by type from method '$method' for pod name '$name' via property '$propertyName' to pod named '$podName'");
            }
          }

          autowiredPods.clear();
        } else {
          // Fallback to cached fields for field injection and performance
          final fields = ph.$2.getFields();
          final field = fields.firstWhereOrNull((f) => f.getName().equalsIgnoreCase(propertyName) && !f.getReturnClass().isPrimitive());
          
          if (field != null) {
            Class type = field.getReturnClass();
            final autowiredValue = await resolveDependency(
              DependencyDescriptor(
                source: field,
                podName: podName,
                propertyName: propertyName,
                type: type,
                args: null,
                component: type.componentType(),
                key: type.keyType(),
                isEager: isEager,
                isRequired: !field.isNullable(),
              ),
              autowiredPods,
            );

            if (autowiredValue != null) {
              pvs.add(
                propertyName,
                autowiredValue,
                qualifiedName: type.getQualifiedName(),
                packageName: type.getPackage()?.getName(),
              );

              if (logger.getIsTraceEnabled()) {
                logger.trace("Autowiring by type from pod name '$propertyName' to pod named '$podName'");
              }
            }
          }

          for (final name in autowiredPods) {
            registerDependentPod(name, podName);

            if (logger.getIsTraceEnabled()) {
              logger.trace("Autowiring by type from method '$method' for pod name '$name' via property '$propertyName' to pod named '$podName'");
            }
          }

          autowiredPods.clear();
        }
      } catch (e) {
        if (logger.getIsTraceEnabled()) {
          logger.trace("Failed to autowire property '$propertyName' by type: $e");
        }

        throw UnsatisfiedDependencyException.withResource(
          root.description,
          podName,
          "Unsatisfied dependency of type '${type.getQualifiedName()}' for property '$propertyName'",
          cause: e is Throwable ? e : RuntimeException(e.toString()),
        );
      }
    }
  }

  /// {@macro check_dependencies}
  ///
  /// Checks if all dependencies are satisfied for the pod instance.
  ///
  /// Throws an exception if required dependencies are missing.
  ///
  /// @param podName The name of the pod
  /// @param root The pod definition
  /// @param ph The pod holder
  /// @param pvs The property values
  @protected
  void checkDependencies(String podName, RootPodDefinition root, PodHolder ph, MutablePropertyValues pvs) {
    int dependencyCheck = root.dependencyCheck.value;
    final unsatisfiedProperties = getUnsatisfiedNonSimpleProperties(root, ph);

    for (final property in unsatisfiedProperties.entries) {
      if (!pvs.containsProperty(property.key)) {
        final returnClass = ph.$2.getField(property.key)?.getReturnClass();
        final isSimple = returnClass?.isPrimitive() ?? false;

        if (!isSimple && (dependencyCheck == DependencyCheck.ALL.value || dependencyCheck == DependencyCheck.OBJECTS.value)) {
          throw PodCreationException.withResource(
            root.description,
            podName,
            "Unsatisfied dependency of type '${returnClass?.getName()}' for property '${property.key}'",
          );
        }
      }
    }
  }

  /// {@macro apply_property_values}
  ///
  /// Applies property values to the pod instance.
  ///
  /// This method converts values to the appropriate types and sets them
  /// on the pod instance using reflection.
  ///
  /// @param podName The name of the pod
  /// @param root The pod definition
  /// @param ph The pod holder
  /// @param pvs The property values to apply
  @protected
  void applyPropertyValues(String podName, RootPodDefinition root, PodHolder ph, MutablePropertyValues pvs) {
    if (pvs.isEmpty) {
      return;
    }

    try {
      List<PropertyValue> resolvedValues = [];

      for (PropertyValue pv in pvs.getPropertyValues()) {
        final resolvedValue = pv.getValue();

        PropertyValue resolvedPv = pv;
        if (pv.isConverted()) {
          resolvedPv.setConvertedValue(resolvedValue);
        }
        resolvedValues.add(resolvedPv);
      }

      // Apply resolved property values to the pod instance
      for (PropertyValue pv in resolvedValues) {
        try {
          setPropertyValue(ph, pv);
        } on PodCreationException catch (e) {
          if (logger.getIsTraceEnabled()) {
            logger.trace("Failed to set property '${pv.getName()}' on pod '$podName' while creating pod: $e");
          }

          rethrow;
        } catch (e) {
          if (logger.getIsTraceEnabled()) {
            logger.trace("Failed to set property '${pv.getName()}' on pod '$podName': $e");
          }

          throw PodCreationException.withResource(
            root.description,
            podName,
            "Failed to set property '${pv.getName()}': $e",
            cause: e is Throwable ? e : RuntimeException(e.toString()),
          );
        }
      }
    } on PodCreationException catch (_) {
      rethrow;
    } catch (e) {
      throw PodCreationException.withResource(
        root.description,
        podName,
        "Error setting property values: $e",
        cause: e is Throwable ? e : RuntimeException(e.toString()),
      );
    }
  }

  /// {@macro set_property_value}
  ///
  /// Sets a property value on the pod instance using reflection.
  ///
  /// This method handles type conversion and field assignment.
  ///
  /// @param ph The pod holder containing instance and class
  /// @param pv The property value to set
  @protected
  void setPropertyValue(PodHolder ph, PropertyValue pv) {
    final field = ph.$2.getField(pv.getName());
    if (field != null && field.isWritable()) {
      final source = pv.getQualifiedName() != null ? Class.fromQualifiedName(pv.getQualifiedName()!) : pv.getValue()?.getClass(null, pv.getPackageName());

      if (source != null) {
        final value = convertValueIfNecessary(pv.getValue(), field.getReturnClass(), source);
        field.setValue(ph.$1, value);
      } else {
        throw PodException("No source found for property '${pv.getName()}' in class '${ph.$2.getName()}'");
      }
    }
  }

  /// {@macro initialize_existing_pod}
  ///
  /// Initializes an existing pod instance by applying post-processors
  /// and calling initialization methods.
  ///
  /// @param existing The pod instance to initialize
  /// @param podClass The class of the pod
  /// @param podName The name of the pod
  /// @return The initialized pod instance
  @protected
  Future<Object> initializeExistingPod(Object existing, Class podClass, String podName) async {
    Object wrappedPod = existing;

    // Apply before-initialization post-processors
    wrappedPod = await applyBeforeInitializationProcessing(existing, podName, podClass);

    // Call initialization methods
    final root = containsDefinition(podName) ? getDefinition(podName) : null;

    try {
      await _initMethodsManager.invokeInitMethods(podName, wrappedPod, root);
    } catch (e) {
      final message = e is Throwable ? e.getMessage() : e.toString();
      final exception = e is Throwable ? e : RuntimeException(e.toString());

      throw PodCreationException.withResource(root?.description, podName, message, cause: exception);
    }

    // Apply after-initialization post-processors
    wrappedPod = await applyAfterInitializationProcessing(wrappedPod, podName, podClass);

    return wrappedPod;
  }

  /// {@macro do_resolve_dependency}
  ///
  /// Abstract method that must be implemented by subclasses to resolve
  /// dependencies according to the specific factory implementation.
  ///
  /// Example implementation:
  /// ```dart
  /// @override
  /// Future<Object?> doResolveDependency(DependencyDescriptor descriptor) async {
  ///   // Check local registry first
  ///   if (containsPod(descriptor.name)) {
  ///     return getPod(descriptor.name);
  ///   }
  ///
  ///   // Fall back to parent factory
  ///   return await parentFactory?.resolveDependency(descriptor);
  /// }
  /// ```
  ///
  /// @param descriptor The dependency descriptor containing resolution information
  /// @return The resolved dependency object, or null if not resolvable
  @protected
  Future<Object?> doResolveDependency(DependencyDescriptor descriptor, [Set<String>? autowiredPods]);

  /// {@macro apply_custom_post_processing}
  ///
  /// Applies custom post-processing logic to an object from a PodProvider.
  ///
  /// Subclasses can override this method to add custom post-processing
  /// logic without modifying the main post-processing flow.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Object applyCustomPostProcessing(Object object, String name) {
  ///   // Add custom validation or transformation
  ///   if (object is Validatable) {
  ///     object.validate();
  ///   }
  ///   return object;
  /// }
  /// ```
  ///
  /// @param object The object to process
  /// @param name The name of the pod
  /// @return The processed object
  @protected
  Object applyCustomPostProcessing(Object object, String name) {
    if (containsDefinition(name)) {
      return applyAfterInitializationProcessing(object, name, getDefinition(name).type);
    }

    return applyAfterInitializationProcessing(object, name, object.getClass());
  }
}

/// {@template pod_holder}
/// A tuple representing a pod and its class.
///
/// This type is used to store the pod instance and its class in the
/// [AbstractAutowireCapablePodFactory] class.
///
/// Example usage:
/// ```dart
/// PodHolder holder = (myPodInstance, MyPodClass);
/// Object pod = holder.$1; // The pod instance
/// Class podClass = holder.$2; // The pod class
/// ```
/// {@endtemplate}
typedef PodHolder = (Object pod, Class podClass);

/// The holder for created pods
typedef CreatedPodHolder = (String name, PodDefinition definition, Object pod);

/// {@template allowCircularReferences}
/// Circular reference allowance configuration.
///
/// This template documents the circular reference handling setting
/// that controls whether circular dependencies are permitted.
/// {@endtemplate}

/// {@template allowDefinitionOverriding}
/// Definition overriding allowance configuration.
///
/// This template documents the definition overriding setting
/// that controls whether duplicate pod definitions are allowed.
/// {@endtemplate}

/// {@template allowRawInjectionDespiteWrapping}
/// Raw injection allowance configuration.
///
/// This template documents the raw injection setting that controls
/// whether dependencies can bypass wrapping mechanisms.
/// {@endtemplate}

/// {@template ignoredDependencyTypes}
/// Dependency type exclusion set.
///
/// This template documents the set of dependency types that are
/// excluded from autowiring consideration.
/// {@endtemplate}

/// {@template ignoredDependencyInterfaces}
/// Dependency interface exclusion set.
///
/// This template documents the set of dependency interfaces that are
/// excluded from autowiring consideration.
/// {@endtemplate}

/// {@template currentlyCreatedPod}
/// Current pod creation context tracking.
///
/// This template documents the thread-local context tracking
/// used for cycle detection and contextual dependency resolution.
/// {@endtemplate}

/// {@template initMethodsManager}
/// Initialization method lifecycle management.
///
/// This template documents the initialization and destruction
/// method management component.
/// {@endtemplate}

/// {@template executableStrategy}
/// Executable resolution strategy.
///
/// This template documents the strategy for constructor and
/// method resolution during pod instantiation.
/// {@endtemplate}

/// {@template autowirePodFactoryLogger}
/// Autowiring factory logging component.
///
/// This template documents the logger used for autowiring
/// operations and diagnostic information.
/// {@endtemplate}