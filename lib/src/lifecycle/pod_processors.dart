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

/// {@template PodProcessor}
/// Abstract interface for processors that handle or manipulate pods in the JetLeaf framework.
/// 
/// This interface serves as the foundation for all pod processors in the JetLeaf ecosystem.
/// Pod processors are components that can intercept, transform, or enhance pods during
/// various lifecycle phases. They enable cross-cutting concerns and advanced container
/// features without requiring modifications to the pod implementations themselves.
/// 
/// ## Processor Hierarchy
/// 
/// JetLeaf provides several specialized processor interfaces that extend this base:
/// - [PodInitializationProcessor]: For pod initialization lifecycle hooks
/// - [PodInstantiationProcessor]: For pod instantiation and property population
/// - [PodSmartInstantiationProcessor]: For advanced instantiation scenarios
/// - [PodDestructionProcessor]: For pod destruction and cleanup lifecycle
/// 
/// ## Integration Points
/// 
/// Processors are integrated with the JetLeaf container through:
/// - Automatic detection during application context refresh
/// - Ordered execution based on priority annotations
/// - Conditional application based on pod characteristics
/// - Proper error handling and lifecycle management
/// 
/// Example custom processor:
/// ```dart
/// @Pod
/// class CustomPodProcessor implements PodProcessor {
///   // Base processor - can be used for generic pod processing
/// }
/// ```
/// 
/// ## Best Practices
/// 
/// - Implement the most specific processor interface for your use case
/// - Use proper error handling in processor methods
/// - Consider performance implications of processor logic
/// - Document processor behavior and intended usage
/// - Test processors with various pod types and scenarios
/// {@endtemplate}
abstract interface class PodProcessor {}

/// {@template PodInitializationProcessor}
/// Processor that provides hooks into the pod initialization lifecycle phases.
/// 
/// This processor allows interception and transformation of pods during their
/// initialization process, both before and after initialization callbacks are invoked.
/// It enables cross-cutting concerns like validation, enhancement, or wrapping
/// of pods without modifying the pod implementations.
/// 
/// ## Initialization Phases
/// 
/// The pod initialization process follows this sequence:
/// 1. Property population and dependency injection
/// 2. `processBeforeInitialization()` calls on all processors
/// 3. `@PostConstruct` method invocations
/// 4. Initialization-aware interface callbacks
/// 5. `processAfterInitialization()` calls on all processors
/// 6. Pod is marked as fully initialized
/// 
/// ## Use Cases
/// 
/// - **Validation**: Verify pod state before initialization completes
/// - **Enhancement**: Add functionality through wrapping or decoration
/// - **Monitoring**: Track initialization metrics and timing
/// - **Security**: Apply security constraints or checks
/// - **Configuration**: Apply runtime configuration based on pod characteristics
/// 
/// Example:
/// ```dart
/// @Pod
/// class ValidationProcessor implements PodInitializationProcessor {
///   @override
///   Future<Object?> processBeforeInitialization(Object pod, Class podClass, String name) async {
///     if (pod is Validatable) {
///       await pod.validate();
///     }
///     return pod; // Return original or wrapped instance
///   }
/// 
///   @override
///   Future<bool> shouldProcessBeforeInitialization(Object pod, Class podClass, String name) async {
///     return pod is Validatable; // Only process validatable pods
///   }
/// }
/// ```
/// {@endtemplate}
abstract class PodInitializationProcessor implements PodProcessor {
  /// {@template processBeforeInitialization}
  /// Processes the pod before any initialization callbacks are invoked.
  /// 
  /// This method is called after property population but before any `@PostConstruct`
  /// methods or initialization-aware interface callbacks. The pod is fully constructed
  /// with dependencies injected but not yet initialized.
  /// 
  /// ## Transformation Semantics
  /// 
  /// The method can:
  /// - Return the original pod instance (no transformation)
  /// - Return a wrapped/decorated instance (enhancement)
  /// - Return `null` to suppress further processing (advanced use cases)
  /// - Throw an exception to prevent pod initialization
  /// 
  /// ## Parameters
  /// 
  /// @param pod The pod instance to process
  /// @param podClass The class metadata of the pod
  /// @param name The name of the pod in the container
  /// @return The pod instance to use (original, wrapped, or null)
  /// 
  /// Example:
  /// ```dart
  /// @override
  /// Future<Object?> processBeforeInitialization(Object pod, Class podClass, String name) async {
  ///   if (podClass.hasAnnotation<Measured>()) {
  ///     return PerformanceMonitor.wrap(pod, name);
  ///   }
  ///   return pod;
  /// }
  /// ```
  /// {@endtemplate}
  Future<Object?> processBeforeInitialization(Object pod, Class podClass, String name) async => null;

  /// {@template processAfterInitialization}
  /// Processes the pod after all initialization callbacks have completed.
  /// 
  /// This method is called after all `@PostConstruct` methods and initialization-aware
  /// interface callbacks have been invoked. The pod is fully initialized and ready for use.
  /// 
  /// ## Use Cases
  /// 
  /// - Final validation of initialized state
  /// - Registration with external systems
  /// - Starting background tasks or schedulers
  /// - Cache warming or preloading
  /// 
  /// ## Parameters
  /// 
  /// @param pod The fully initialized pod instance
  /// @param podClass The class metadata of the pod
  /// @param name The name of the pod in the container
  /// @return The pod instance to use (original, wrapped, or null)
  /// 
  /// Example:
  /// ```dart
  /// @override
  /// Future<Object?> processAfterInitialization(Object pod, Class podClass, String name) async {
  ///   if (pod is ScheduledTask) {
  ///     await pod.startScheduler();
  ///   }
  ///   return pod;
  /// }
  /// ```
  /// {@endtemplate}
  Future<Object?> processAfterInitialization(Object pod, Class podClass, String name) async => null;

  /// {@template shouldProcessBeforeInitialization}
  /// Determines whether this processor should be applied to the given pod.
  /// 
  /// This method allows for conditional processing based on pod characteristics,
  /// reducing unnecessary overhead for pods that don't require processing.
  /// 
  /// ## Evaluation Timing
  /// 
  /// This method is called before `processBeforeInitialization()` to determine
  /// if the processor should be invoked for a particular pod instance.
  /// 
  /// ## Parameters
  /// 
  /// @param pod The pod instance to evaluate
  /// @param podClass The class metadata of the pod
  /// @param name The name of the pod in the container
  /// @return `true` if the processor should be applied, `false` otherwise
  /// 
  /// Example:
  /// ```dart
  /// @override
  /// Future<bool> shouldProcessBeforeInitialization(Object pod, Class podClass, String name) async {
  ///   // Only process pods annotated with @Audited
  ///   return podClass.hasAnnotation<Audited>();
  /// }
  /// ```
  /// {@endtemplate}
  Future<bool> shouldProcessBeforeInitialization(Object pod, Class podClass, String name) async => false;
}

// ---------------------------------------------------------------------------------------------------------
// PodInstantiationProcessor
// ---------------------------------------------------------------------------------------------------------

/// {@template PodInstantiationProcessor}
/// Processor that provides hooks into the pod instantiation and property population lifecycle.
/// 
/// This processor enables advanced control over how pods are instantiated and how their
/// properties are populated. It supports scenarios like custom instantiation logic,
/// property value transformation, and dependency resolution customization.
/// 
/// ## Instantiation Phases
/// 
/// The pod instantiation process follows this sequence:
/// 1. `processBeforeInstantiation()` - Opportunity to suppress default instantiation
/// 2. Pod instance creation (unless suppressed)
/// 3. `processAfterInstantiation()` - Custom field injection before property population
/// 4. `processPropertyValues()` - Property value transformation
/// 5. Property population
/// 6. `populateValues()` - Additional value population
/// 
/// ## Advanced Scenarios
/// 
/// - **Custom Instantiation**: Provide alternative instance creation mechanisms
/// - **Field Injection**: Perform injection not supported by standard property population
/// - **Property Transformation**: Modify or enhance property values before application
/// - **Conditional Population**: Skip property population based on custom logic
/// 
/// Example:
/// ```dart
/// @Pod
/// class CustomInstantiationProcessor implements PodInstantiationProcessor {
///   @override
///   Future<Object?> processBeforeInstantiation(Class podClass, String name) async {
///     // Provide custom instance for specific pods
///     if (name == 'specialPod') {
///       return SpecialImplementation();
///     }
///     return null; // Proceed with default instantiation
///   }
/// }
/// ```
/// {@endtemplate}
abstract class PodInstantiationProcessor extends PodProcessor {
  /// {@template processBeforeInstantiation}
  /// Intercepts pod instantiation before the default instantiation process begins.
  /// 
  /// This method can completely bypass the default instantiation mechanism by
  /// returning a pod instance. If a non-null value is returned, the container
  /// will use that instance instead of creating one through normal means.
  /// 
  /// ## Use Cases
  /// 
  /// - Providing mock instances in test environments
  /// - Implementing custom instance creation logic
  /// - Integrating with third-party instance management systems
  /// - Implementing sophisticated pooling or caching strategies
  /// 
  /// ## Parameters
  /// 
  /// @param podClass The class of the pod to be instantiated
  /// @param name The name of the pod in the container
  /// @return A pod instance to use instead of default instantiation, or `null` to proceed normally
  /// 
  /// Example:
  /// ```dart
  /// @override
  /// Future<Object?> processBeforeInstantiation(Class podClass, String name) async {
  ///   if (podClass == Class<ExpensiveService>()) {
  ///     // Return cached instance instead of creating new one
  ///     return _cache.getOrCreate(name, () => ExpensiveService());
  ///   }
  ///   return null; // Use default instantiation
  /// }
  /// ```
  /// {@endtemplate}
  Future<Object?> processBeforeInstantiation(Class podClass, String name) async => null;

  /// {@template processAfterInstantiation}
  /// Processes the pod immediately after instantiation but before property population.
  /// 
  /// This is the ideal point for performing custom field injection or other
  /// initialization that must occur before standard property population.
  /// 
  /// ## Control Flow
  /// 
  /// Returning `false` from this method will skip all subsequent property
  /// population, including `processPropertyValues()` and standard property setting.
  /// 
  /// ## Parameters
  /// 
  /// @param pod The newly instantiated pod instance
  /// @param podClass The class metadata of the pod
  /// @param name The name of the pod in the container
  /// @return `true` to proceed with property population, `false` to skip it
  /// 
  /// Example:
  /// ```dart
  /// @override
  /// Future<bool> processAfterInstantiation(Object pod, Class podClass, String name) async {
  ///   if (pod is ManuallyConfigured) {
  ///     // Pod handles its own configuration
  ///     await pod.manualSetup();
  ///     return false; // Skip automatic property population
  ///   }
  ///   return true; // Proceed with property population
  /// }
  /// ```
  /// {@endtemplate}
  Future<bool> processAfterInstantiation(Object pod, Class podClass, String name) async => true;

  /// {@template processPropertyValues}
  /// Transforms property values before they are applied to the pod.
  /// 
  /// This method allows for modification, enhancement, or replacement of the
  /// property values that will be set on the pod instance.
  /// 
  /// ## Transformation Capabilities
  /// 
  /// - Modify existing property values
  /// - Add new property values
  /// - Remove property values
  /// - Resolve additional dependencies
  /// - Return `null` to skip all property population
  /// 
  /// ## Parameters
  /// 
  /// @param pvs The property values about to be applied
  /// @param pod The pod instance that will receive the properties
  /// @param podClass The class metadata of the pod
  /// @param name The name of the pod in the container
  /// @return The modified property values, or `null` to skip property population
  /// 
  /// Example:
  /// ```dart
  /// @override
  /// Future<PropertyValues?> processPropertyValues(
  ///   PropertyValues pvs, Object pod, Class podClass, String name) async {
  ///   // Add runtime configuration to property values
  ///   if (pod is Configurable) {
  ///     pvs.add('runtimeConfig', await loadRuntimeConfig(name));
  ///   }
  ///   return pvs;
  /// }
  /// ```
  /// {@endtemplate}
  Future<PropertyValues?> processPropertyValues(PropertyValues pvs, Object pod, Class podClass, String name) async => pvs;

  /// {@template populateValues}
  /// Performs additional value population after standard property population.
  /// 
  /// This method is called after all standard property population has completed
  /// and allows for additional initialization that may require the pod to be
  /// in a partially populated state.
  /// 
  /// ## Use Cases
  /// 
  /// - Complex initialization requiring multiple property values
  /// - Async resource loading or configuration
  /// - Cross-property validation or normalization
  /// - Registration with external systems
  /// 
  /// ## Parameters
  /// 
  /// @param pod The pod instance with properties populated
  /// @param podClass The class metadata of the pod
  /// @param name The name of the pod in the container
  /// 
  /// Example:
  /// ```dart
  /// @override
  /// Future<void> populateValues(Object pod, Class podClass, String name) async {
  ///   if (pod is DatabaseService) {
  ///     // Perform async initialization after properties are set
  ///     await pod.initializeConnection();
  ///   }
  /// }
  /// ```
  /// {@endtemplate}
  Future<void> populateValues(Object pod, Class podClass, String name) async {}
}

/// {@template PodSmartInstantiationProcessor}
/// Advanced processor that provides sophisticated control over pod instantiation.
/// 
/// This processor extends [PodInstantiationProcessor] with additional capabilities
/// for constructor selection, argument resolution, and early pod reference handling.
/// It enables complex instantiation scenarios like circular dependency resolution
/// and advanced AOP integration.
/// 
/// ## Advanced Features
/// 
/// - **Constructor Resolution**: Custom logic for selecting which constructor to use
/// - **Argument Determination**: Sophisticated argument resolution beyond standard DI
/// - **Early References**: Support for circular dependencies through proxy mechanisms
/// - **AOP Integration**: Hook points for aspect-oriented programming frameworks
/// 
/// Example:
/// ```dart
/// @Pod
/// class SmartProcessor implements PodSmartInstantiationProcessor {
///   @override
///   Future<List<Constructor>?> determineCandidateConstructors(Class podClass, String name) async {
///     // Prefer constructors with @Inject annotation
///     final constructors = podClass.getConstructors();
///     final injected = constructors.where((c) => c.hasAnnotation<Inject>()).toList();
///     return injected.isNotEmpty ? injected : null;
///   }
/// }
/// ```
/// {@endtemplate}
abstract class PodSmartInstantiationProcessor extends PodInstantiationProcessor {
  /// {@template determineCandidateConstructors}
  /// Determines which constructors should be considered for pod instantiation.
  /// 
  /// This method allows custom logic for constructor selection, enabling
  /// scenarios like annotation-based constructor preference or environment-specific
  /// constructor choices.
  /// 
  /// ## Constructor Selection
  /// 
  /// The container will use the returned constructors in order of preference.
  /// If `null` is returned, the container uses its default constructor resolution.
  /// 
  /// ## Parameters
  /// 
  /// @param podClass The raw class of the pod
  /// @param name The name of the pod in the container
  /// @return An ordered list of candidate constructors, or `null` for default resolution
  /// 
  /// Example:
  /// ```dart
  /// @override
  /// Future<List<Constructor>?> determineCandidateConstructors(Class podClass, String name) async {
  ///   // Prefer factory methods over constructors
  ///   final factories = podClass.getMethods().where((m) => m.hasAnnotation<Factory>());
  ///   if (factories.isNotEmpty) {
  ///     return [factories.first];
  ///   }
  ///   return null; // Use default constructor resolution
  /// }
  /// ```
  /// {@endtemplate}
  Future<List<Constructor>?> determineCandidateConstructors(Class podClass, String name) async => null;

  /// {@template determineCandidateArguments}
  /// Determines the arguments to use for a specific constructor or factory method.
  /// 
  /// This method provides fine-grained control over argument resolution, enabling
  /// custom dependency resolution logic beyond the standard container capabilities.
  /// 
  /// ## Argument Resolution
  /// 
  /// The returned arguments will be used in place of standard dependency resolution.
  /// If `null` is returned, the container uses its default argument resolution.
  /// 
  /// ## Parameters
  /// 
  /// @param podName The name of the pod being instantiated
  /// @param executable The constructor or factory method being invoked
  /// @param parameters The parameters that need argument values
  /// @return A list of argument values, or `null` for default resolution
  /// 
  /// Example:
  /// ```dart
  /// @override
  /// Future<List<ArgumentValue>?> determineCandidateArguments(
  ///   String podName, Executable executable, List<Parameter> parameters) async {
  ///   // Provide custom arguments for specific parameters
  ///   return parameters.map((param) {
  ///     if (param.hasAnnotation<CustomValue>()) {
  ///       return ArgumentValue(param, await resolveCustomValue(param));
  ///     }
  ///     return null; // Use default resolution for this parameter
  ///   }).where((value) => value != null).toList();
  /// }
  /// ```
  /// {@endtemplate}
  Future<List<ArgumentValue>?> determineCandidateArguments(String podName, Executable executable, List<Parameter> parameters) async => null;

  /// {@template getEarlyPodReference}
  /// Provides an early reference to a pod before its initialization completes.
  /// 
  /// This method enables circular dependency resolution by allowing a partially
  /// constructed pod to be exposed to other pods that depend on it. It's commonly
  /// used by AOP frameworks to provide proxy instances.
  /// 
  /// ## Circular Dependencies
  /// 
  /// When pod A depends on pod B and pod B depends on pod A, this method allows
  /// providing a proxy for pod A to pod B during pod B's construction, breaking
  /// the circular dependency.
  /// 
  /// ## Proxy Integration
  /// 
  /// AOP frameworks can override this method to return proxy instances that
  /// delegate to the real pod once initialization completes.
  /// 
  /// ## Parameters
  /// 
  /// @param podHolder The holder containing the raw pod instance
  /// @param podClass The class metadata of the pod
  /// @param name The name of the pod in the container
  /// @return A holder containing either the original pod or a proxy instance
  /// 
  /// Example:
  /// ```dart
  /// @override
  /// Future<ObjectHolder<Object>> getEarlyPodReference(
  ///   ObjectHolder<Object> podHolder, Class podClass, String name) async {
  ///   if (needsProxy(podClass)) {
  ///     // Return a proxy that will delegate to the real instance
  ///     return ObjectHolder(createProxy(podHolder.get()));
  ///   }
  ///   return podHolder; // Return the original instance
  /// }
  /// ```
  /// {@endtemplate}
  Future<ObjectHolder<Object>> getEarlyPodReference(ObjectHolder<Object> podHolder, Class podClass, String name) async => podHolder;
}

// ---------------------------------------------------------------------------------------------------------
// PodDestructionProcessor
// ---------------------------------------------------------------------------------------------------------

/// {@template PodDestructionProcessor}
/// Processor that provides hooks into the pod destruction and cleanup lifecycle.
/// 
/// This processor enables custom cleanup logic, resource release, and finalization
/// operations when pods are being destroyed by the container. It ensures proper
/// resource management and graceful shutdown of pod instances.
/// 
/// ## Destruction Phases
/// 
/// The pod destruction process follows this sequence:
/// 1. `requiresDestruction()` - Check if pod needs destruction processing
/// 2. `processBeforeDestruction()` - Pre-destruction cleanup and preparation
/// 3. `@PreDestroy` method invocations
/// 4. Destruction-aware interface callbacks
/// 5. `processAfterDestruction()` - Post-destruction finalization
/// 6. Resource cleanup and garbage collection eligibility
/// 
/// ## Resource Management
/// 
/// - **Connection Cleanup**: Close database connections, network sockets
/// - **File Handling**: Release file handles, temporary files
/// - **Cache Eviction**: Clear in-memory caches, release references
/// - **External Integration**: Notify external systems of pod destruction
/// - **Statistics Finalization**: Record final metrics, log destruction events
/// 
/// Example:
/// ```dart
/// @Pod
/// class ResourceCleanupProcessor implements PodDestructionProcessor {
///   @override
///   Future<void> processBeforeDestruction(Object pod, Class podClass, String name) async {
///     if (pod is ConnectionHolder) {
///       await pod.closeAllConnections();
///     }
///   }
/// 
///   @override
///   Future<bool> requiresDestruction(Object pod, Class podClass, String name) async {
///     return pod is Disposable || pod is ConnectionHolder;
///   }
/// }
/// ```
/// {@endtemplate}
abstract class PodDestructionProcessor implements PodProcessor {
  /// {@template processBeforeDestruction}
  /// Processes the pod before any destruction callbacks are invoked.
  /// 
  /// This method is called before `@PreDestroy` methods and destruction-aware
  /// interface callbacks. It's the ideal point for proactive resource cleanup
  /// and preparation for destruction.
  /// 
  /// ## Cleanup Responsibilities
  /// 
  /// - Release expensive resources (connections, file handles)
  /// - Stop active processes or background tasks
  /// - Cancel pending operations or timeouts
  /// - Prepare for graceful shutdown
  /// 
  /// ## Parameters
  /// 
  /// @param pod The pod instance being destroyed
  /// @param podClass The class metadata of the pod
  /// @param name The name of the pod in the container
  /// 
  /// Example:
  /// ```dart
  /// @override
  /// Future<void> processBeforeDestruction(Object pod, Class podClass, String name) async {
  ///   if (pod is BackgroundTaskManager) {
  ///     await pod.stopAllTasks();
  ///   }
  ///   if (pod is ConnectionPool) {
  ///     await pod.drainConnections();
  ///   }
  /// }
  /// ```
  /// {@endtemplate}
  Future<void> processBeforeDestruction(Object pod, Class podClass, String name);

  /// {@template processAfterDestruction}
  /// Processes the pod after all destruction callbacks have completed.
  /// 
  /// This method is called after all `@PreDestroy` methods and destruction-aware
  /// interface callbacks. The pod is no longer functional but may still hold
  /// references to resources that need final cleanup.
  /// 
  /// ## Finalization Tasks
  /// 
  /// - Final logging or metrics recording
  /// - Notification of external systems
  /// - Release of final resource references
  /// - Cleanup of static or global state
  /// 
  /// ## Parameters
  /// 
  /// @param pod The destroyed pod instance
  /// @param podClass The class metadata of the pod
  /// @param name The name of the pod in the container
  /// 
  /// Example:
  /// ```dart
  /// @override
  /// Future<void> processAfterDestruction(Object pod, Class podClass, String name) async {
  ///   // Record final metrics
  ///   Metrics.recordPodDestruction(name, podClass.getQualifiedName());
  ///   
  ///   // Notify monitoring system
  ///   await MonitoringService.notifyPodDestroyed(name);
  /// }
  /// ```
  /// {@endtemplate}
  Future<void> processAfterDestruction(Object pod, Class podClass, String name);

  /// {@template requiresDestruction}
  /// Determines whether the pod requires destruction processing by this processor.
  /// 
  /// This method allows for conditional destruction processing, avoiding
  /// unnecessary cleanup operations for pods that don't require them.
  /// 
  /// ## Evaluation Criteria
  /// 
  /// Common criteria include:
  /// - Pod implements specific interfaces (Disposable, Closeable)
  /// - Pod has specific annotations requiring cleanup
  /// - Pod holds specific types of resources
  /// - Environment-specific destruction requirements
  /// 
  /// ## Parameters
  /// 
  /// @param pod The pod instance to evaluate
  /// @param podClass The class metadata of the pod
  /// @param name The name of the pod in the container
  /// @return `true` if the pod requires destruction processing, `false` otherwise
  /// 
  /// Example:
  /// ```dart
  /// @override
  /// Future<bool> requiresDestruction(Object pod, Class podClass, String name) async {
  ///   // Only process pods that hold resources or need cleanup
  ///   return pod is ResourceHolder || 
  ///          podClass.hasAnnotation<RequiresCleanup>() ||
  ///          pod is ExecutorService;
  /// }
  /// ```
  /// {@endtemplate}
  Future<bool> requiresDestruction(Object pod, Class podClass, String name) async => true;
}