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

import 'package:jetleaf_convert/convert.dart';
import 'package:jetleaf_lang/lang.dart';

import '../alias/alias_registry.dart';
import '../definition/pod_definition.dart';
import '../definition/pod_definition_registry.dart';
import '../expression/pod_expression.dart';
import '../helpers/object.dart';
import '../lifecycle/pod_processors.dart';
import '../scope/scope.dart';
import '../singleton/singleton_pod_registry.dart';
import '../startup/application_startup.dart';

/// {@template pod_factory}
/// The core factory interface for managing and retrieving pods (components) in Jetleaf.
/// 
/// A PodFactory is responsible for creating, managing, and providing access to application
/// components (pods) throughout their lifecycle. It serves as the central container
/// for dependency injection and component management in Jetleaf applications.
/// 
/// ## Usage Example:
/// ```dart
/// class MyService {
///   void doWork() => print('Working...');
/// }
/// 
/// class MyController {
///   final MyService service;
///   
///   MyController(this.service);
///   
///   void execute() => service.doWork();
/// }
/// 
/// // Register pods and retrieve them
/// final factory = getPodFactory();
/// await factory.get<MyService>();
/// final controller = await factory.get<MyController>();
/// controller.execute();
/// ```
/// 
/// See also:
/// - [AutowirePodFactory] for automatic dependency injection capabilities
/// - [HierarchicalPodFactory] for parent-child factory hierarchies
/// - [ConfigurablePodFactory] for configurable factory implementations
/// {@endtemplate}
abstract interface class PodFactory implements PackageIdentifier {
  /// {@template pod_factory_get_pod}
  /// Retrieves a pod instance by its name with optional arguments.
  /// 
  /// This method looks up a pod by its registered name and returns an instance
  /// of the specified type. Optional arguments can be provided for constructor
  /// injection or parameter resolution.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// // Assuming 'databaseService' pod is registered
  /// final database = await factory.getPod<DatabaseService>('databaseService');
  /// 
  /// // With constructor arguments
  /// final service = await factory.getPod<MyService>('myService', [
  ///   ArgumentValue('url', 'https://api.example.com'),
  ///   ArgumentValue('timeout', 30),
  /// ]);
  /// ```
  /// 
  /// @param podName The name of the pod to retrieve
  /// @param args Optional list of argument values for pod construction
  /// @return A Future that completes with the pod instance of type T
  /// @throws PodNotFoundException if the pod name is not registered
  /// @throws PodCreationException if the pod cannot be instantiated
  /// {@endtemplate}
  Future<T> getPod<T>(String podName, [List<ArgumentValue>? args, Class<T>? type]);

  /// {@template pod_factory_get}
  /// Retrieves a pod instance by its type with optional arguments.
  /// 
  /// This method looks up a pod by its class type and returns an instance.
  /// It's useful when you want to retrieve pods by type rather than by name.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final service = await factory.get<MyService>();
  /// 
  /// // With constructor arguments
  /// final controller = await factory.get<MyController>([
  ///   ArgumentValue('maxRetries', 3),
  ///   ArgumentValue('enableLogging', true),
  /// ]);
  /// ```
  /// 
  /// @param type The class type of the pod to retrieve
  /// @param args Optional list of argument values for pod construction
  /// @return A Future that completes with the pod instance of type T
  /// @throws PodNotFoundException if no pod of the specified type is registered
  /// {@endtemplate}
  Future<T> get<T>(Class<T> type, [List<ArgumentValue>? args]);

  /// {@template pod_factory_get_named_object}
  /// Retrieves a pod as a generic Object by its name with optional arguments.
  /// 
  /// This method is useful when the exact type of the pod is not known at compile time
  /// or when working with dynamic pod retrieval scenarios.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final pod = await factory.getNamedObject('dataProcessor');
  /// if (pod is DataProcessor) {
  ///   pod.processData();
  /// }
  /// ```
  /// 
  /// @param podName The name of the pod to retrieve
  /// @param args Optional list of argument values for pod construction
  /// @return A Future that completes with the pod instance as Object
  /// {@endtemplate}
  Future<Object> getNamedObject(String podName, [List<ArgumentValue>? args]);

  /// {@template pod_factory_get_object}
  /// Retrieves a pod as a generic Object by its type with optional arguments.
  /// 
  /// Similar to [getNamedObject] but uses type-based lookup instead of name-based.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final pod = await factory.getObject(Class<DataProcessor>());
  /// if (pod is DataProcessor) {
  ///   pod.processData();
  /// }
  /// ```
  /// 
  /// @param type The class type of the pod to retrieve
  /// @param args Optional list of argument values for pod construction
  /// @return A Future that completes with the pod instance as Object
  /// {@endtemplate}
  Future<Object> getObject(Class<Object> type, [List<ArgumentValue>? args]);

  /// {@template pod_factory_get_provider}
  /// Retrieves a provider for a pod, allowing for lazy or eager initialization.
  /// 
  /// A provider gives more control over when and how a pod is instantiated.
  /// This is useful for lazy loading or when you need to manage the lifecycle
  /// of pods more precisely.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final provider = await factory.getProvider<DatabaseService>(
  ///   'databaseService', 
  ///   Class<DatabaseService>(),
  ///   allowEagerInit: true,
  /// );
  /// 
  /// // Get the instance when needed
  /// final database = await provider.get();
  /// ```
  /// 
  /// @param podName The name of the pod to provide
  /// @param type The class type of the pod
  /// @param allowEagerInit Whether to allow eager initialization
  /// @return A Future that completes with an ObjectProvider for the pod
  /// {@endtemplate}
  Future<ObjectProvider<T>> getProvider<T>(Class<T> type, {String? podName, bool allowEagerInit = false});

  /// {@template pod_factory_contains_pod}
  /// Checks if a pod with the given name is registered in the factory.
  /// 
  /// This method checks both the current factory and parent factories
  /// in hierarchical configurations.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// if (await factory.containsPod('emailService')) {
  ///   final emailService = await factory.getPod<EmailService>('emailService');
  ///   await emailService.sendWelcomeEmail();
  /// }
  /// ```
  /// 
  /// @param podName The name of the pod to check
  /// @return A Future that completes with true if the pod exists
  /// {@endtemplate}
  Future<bool> containsPod(String podName);

  /// {@template pod_factory_is_singleton}
  /// Checks if the specified pod is configured as a singleton.
  /// 
  /// Singleton pods are instantiated only once and the same instance
  /// is returned for all subsequent requests.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// if (await factory.isSingleton('appConfig')) {
  ///   print('AppConfig is a singleton - all components share the same instance');
  /// }
  /// ```
  /// 
  /// @param podName The name of the pod to check
  /// @return A Future that completes with true if the pod is a singleton
  /// {@endtemplate}
  Future<bool> isSingleton(String podName);

  /// {@template pod_factory_is_prototype}
  /// Checks if the specified pod is configured as a prototype.
  /// 
  /// Prototype pods create a new instance every time they are requested.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// if (await factory.isPrototype('requestContext')) {
  ///   print('RequestContext is a prototype - new instance for each request');
  /// }
  /// ```
  /// 
  /// @param podName The name of the pod to check
  /// @return A Future that completes with true if the pod is a prototype
  /// {@endtemplate}
  Future<bool> isPrototype(String podName);

  /// {@template pod_factory_get_aliases}
  /// Retrieves all alias names for the specified pod.
  /// 
  /// Pods can have multiple names (aliases) for flexible referencing.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final aliases = factory.getAliases('primaryDataSource');
  /// print('Primary data source aliases: $aliases');
  /// ```
  /// 
  /// @param podName The name of the pod to get aliases for
  /// @return A list of alias names for the pod
  /// {@endtemplate}
  List<String> getAliases(String podName);

  /// {@template pod_factory_get_pod_class}
  /// Retrieves the Class object for the specified pod name.
  /// 
  /// This method is useful for reflection-based operations or when
  /// you need to inspect the type of a pod at runtime.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final podClass = await factory.getPodClass('userRepository');
  /// print('Pod class: ${podClass.name}');
  /// ```
  /// 
  /// @param podName The name of the pod to get the class for
  /// @return A Future that completes with the Class object of the pod
  /// {@endtemplate}
  Future<Class> getPodClass(String podName);

  /// {@template pod_factory_contains_type}
  /// Checks if the factory contains a pod of the specified type.
  /// 
  /// This method is useful for checking the availability of a pod
  /// before attempting to retrieve it.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// if (await factory.containsType(Class<UserService>())) {
  ///   final userService = await factory.getPod<UserService>('userService');
  ///   userService.doSomething();
  /// }
  /// ```
  /// 
  /// @param type The class type of the pod to check
  /// @return A Future that completes with true if the pod exists
  /// {@endtemplate}
  Future<bool> containsType(Class type, [bool allowPodProviderInit = false]);

  /// {@template pod_factory_is_type_match}
  /// Checks if the pod with the specified name matches the given type.
  /// 
  /// This method is useful for checking the type of a pod before attempting to retrieve it.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// if (await factory.isTypeMatch('userService', Class<UserService>())) {
  ///   final userService = await factory.getPod<UserService>('userService');
  ///   userService.doSomething();
  /// }
  /// ```
  /// 
  /// @param name The name of the pod to check
  /// @param typeToMatch The class type to match
  /// @return A Future that completes with true if the pod matches the type
  /// {@endtemplate}
  Future<bool> isTypeMatch(String name, Class typeToMatch, [bool allowPodProviderInit = false]);

  /// {@template pod_factory_resolve_dependency}
  /// Resolves a dependency based on the provided descriptor.
  /// 
  /// This is an advanced method used internally by the framework for
  /// dependency injection resolution. It examines the dependency
  /// descriptor and returns the appropriate pod instance.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final descriptor = DependencyDescriptor(
  ///   Source.controller, 
  ///   'userController', 
  ///   'userService', 
  ///   Class<UserService>(),
  /// );
  /// final dependency = await factory.resolveDependency(descriptor);
  /// ```
  /// 
  /// @param descriptor The dependency descriptor containing resolution information
  /// @return A Future that completes with the resolved dependency object
  /// {@endtemplate}
  Future<Object?> resolveDependency(DependencyDescriptor descriptor, [Set<String>? autowiredPods]);
}

/// {@template autowire_pod_factory}
/// Extends [PodFactory] with automatic dependency injection capabilities.
/// 
/// This interface provides methods for automatic wiring of dependencies,
/// pod configuration, and lifecycle management. It's used by Jetleaf
/// to perform dependency injection without manual configuration.
/// 
/// ## Usage Example:
/// ```dart
/// class ServiceA {
///   void operate() => print('ServiceA operating');
/// }
/// 
/// class ServiceB {
///   final ServiceA serviceA;
///   
///   ServiceB(this.serviceA); // Autowired dependency
///   
///   void execute() => serviceA.operate();
/// }
/// 
/// final factory = getAutowirePodFactory();
/// await factory.createPod(ServiceA(), Class<ServiceA>());
/// await factory.autowirePod(ServiceB(serviceA), Class<ServiceB>());
/// ```
/// {@endtemplate}
abstract interface class AutowirePodFactory implements PodFactory {
  /// {@template autowire_pod_factory_create_pod}
  /// Creates and registers a pod from an existing instance.
  /// 
  /// This method is useful when you have an existing instance that
  /// you want to register as a pod in the factory for dependency injection.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final existingService = MyService();
  /// await factory.createPod(existingService, Class<MyService>());
  /// 
  /// // Now other pods can autowire MyService
  /// final consumer = await factory.get<ServiceConsumer>();
  /// ```
  /// 
  /// @param instance The existing instance to register as a pod
  /// @param type The class type of the pod
  /// @return A Future that completes with the pod instance
  /// {@endtemplate}
  Future<T> createPod<T>(T instance, Class type);

  /// {@template autowire_pod_factory_autowire_pod}
  /// Performs autowiring on an existing pod instance.
  /// 
  /// This method injects dependencies into an already created pod instance.
  /// It's useful for cases where you need to manually control instance creation
  /// but still want dependency injection benefits.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final controller = MyController(); // Created manually
  /// await factory.autowirePod(controller, Class<MyController>());
  /// // Now controller has all dependencies injected
  /// ```
  /// 
  /// @param existingPod The pod instance to autowire
  /// @param type The class type of the pod
  /// @param autowireMode The autowiring mode to use
  /// @param checkDependency Whether to check dependency validity
  /// @return A Future that completes when autowiring is done
  /// {@endtemplate}
  Future<void> autowirePod(Object existingPod, Class type, {int? autowireMode, bool? checkDependency});

  /// {@template autowire_pod_factory_configure_pod}
  /// Configures a pod instance with factory-specific settings.
  /// 
  /// This method applies configuration such as property values,
  /// lifecycle callbacks, and other factory-specific settings to a pod instance.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final rawPod = MyConfiguredPod();
  /// final configuredPod = factory.configurePod(rawPod, 'myConfiguredPod');
  /// ```
  /// 
  /// @param existingPod The pod instance to configure
  /// @param podName The name of the pod being configured
  /// @return The configured pod instance
  /// {@endtemplate}
  Future<Object> configurePod(Object existingPod, String podName);

  /// {@template autowire_pod_factory_autowire}
  /// Creates and autowires a new pod instance from a class.
  /// 
  /// This method combines instance creation and dependency injection
  /// in a single operation.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final pod = await factory.autowire(
  ///   Class<ComplexService>(), 
  ///   AutowireMode.byType, 
  ///   true,
  /// );
  /// ```
  /// 
  /// @param podClass The class of the pod to create and autowire
  /// @param autowireMode The autowiring mode to use
  /// @param checkDependency Whether to check dependency validity
  /// @return A Future that completes with the autowired pod instance
  /// {@endtemplate}
  Future<Object> autowire(Class podClass, int autowireMode, bool checkDependency);

  /// {@template autowire_pod_factory_apply_pod_property_values}
  /// Applies property values to a pod instance based on its configuration.
  /// 
  /// This method sets property values defined in the pod configuration
  /// to the existing pod instance.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final pod = MyConfigurablePod();
  /// await factory.applyPodPropertyValues(pod, 'myConfigurablePod');
  /// // Now pod has all configured property values set
  /// ```
  /// 
  /// @param existingPod The pod instance to apply properties to
  /// @param podName The name of the pod being configured
  /// @return A Future that completes when properties are applied
  /// {@endtemplate}
  Future<void> applyPodPropertyValues(Object existingPod, String podName);

  /// {@template autowire_pod_factory_initialize_pod}
  /// Initializes a pod instance by invoking its lifecycle methods.
  /// 
  /// This method calls initialization callbacks such as @PostConstruct
  /// methods or InitializingBean interfaces.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final pod = MyLifecyclePod();
  /// await factory.initializePod(pod, Class<MyLifecyclePod>(), 'myLifecyclePod');
  /// // Now pod's @PostConstruct methods have been called
  /// ```
  /// 
  /// @param existingPod The pod instance to initialize
  /// @param type The class type of the pod
  /// @param podName The name of the pod being initialized
  /// @return A Future that completes when initialization is done
  /// {@endtemplate}
  Future<void> initializePod(Object existingPod, Class type, String podName);

  /// {@template autowire_pod_factory_destroy_existing_pod}
  /// Destroys an existing pod instance by invoking its destruction methods.
  /// 
  /// This method calls destruction callbacks such as @PreDestroy methods
  /// or DisposableBean interfaces.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final pod = getExistingPod();
  /// await factory.destroyExistingPod(pod, Class<MyPod>(), 'myPod');
  /// // Now pod's @PreDestroy methods have been called
  /// ```
  /// 
  /// @param existingPod The pod instance to destroy
  /// @param type The class type of the pod
  /// @param podName The name of the pod being destroyed
  /// @return A Future that completes when destruction is done
  /// {@endtemplate}
  Future<void> destroyExistingPod(Object existingPod, Class type, String podName);

  /// {@template autowire_pod_factory_destroy_pod}
  /// Destroys a pod instance by name and instance.
  /// 
  /// This method handles the complete destruction lifecycle including
  /// removal from registries and invocation of destruction callbacks.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final pod = await factory.getPod<MyPod>('myPod');
  /// await factory.destroyPod('myPod', pod);
  /// ```
  /// 
  /// @param podName The name of the pod to destroy
  /// @param podInstance The pod instance to destroy
  /// @return A Future that completes when destruction is done
  /// {@endtemplate}
  Future<void> destroyPod(String podName, Object podInstance);
}

/// {@template hierarchical_pod_factory}
/// Extends [PodFactory] with hierarchical capabilities for parent-child relationships.
/// 
/// Hierarchical factories allow for creating factory trees where child factories
/// can delegate to parent factories for pod resolution. This enables modular
/// application architectures and configuration inheritance.
/// 
/// ## Usage Example:
/// ```dart
/// final parentFactory = createParentFactory();
/// final childFactory = createChildFactory(parentFactory);
/// 
/// // Child factory can access pods from parent
/// final parentPod = await childFactory.getPod<ParentService>('parentService');
/// ```
/// {@endtemplate}
abstract interface class HierarchicalPodFactory extends PodFactory {
  /// {@template hierarchical_pod_factory_get_parent_factory}
  /// Retrieves the parent factory in the hierarchy, if any.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final parent = factory.getParentFactory();
  /// if (parent != null) {
  ///   print('This factory has a parent factory');
  /// }
  /// ```
  /// 
  /// @return The parent PodFactory or null if this is the root factory
  /// {@endtemplate}
  PodFactory? getParentFactory();

  /// {@template hierarchical_pod_factory_contains_local_pod}
  /// Checks if a pod with the given name is registered locally in this factory.
  /// 
  /// Unlike [containsPod], this method only checks the current factory
  /// and does not delegate to parent factories.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// if (await factory.containsLocalPod('localService')) {
  ///   print('localService is defined in this factory, not inherited from parent');
  /// }
  /// ```
  /// 
  /// @param podName The name of the pod to check
  /// @return A Future that completes with true if the pod exists locally
  /// {@endtemplate}
  Future<bool> containsLocalPod(String podName);

  /// {@template hierarchical_pod_factory_is_pod_provider}
  /// Checks if the specified pod name refers to a pod provider.
  /// 
  /// Pod providers are special pods that can create other pods.
  /// This method checks if the given pod name corresponds to a provider.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// if (await factory.isPodProvider('serviceProvider')) {
  ///   print('serviceProvider is a pod provider');
  /// }
  /// ```
  /// 
  /// @param podName The name of the pod to check
  /// @param rpd Optional root pod definition for direct checking
  /// @return A Future that completes with true if the pod is a provider
  /// {@endtemplate}
  Future<bool> isPodProvider(String podName, [RootPodDefinition? rpd]);
}

/// {@template configurable_pod_factory}
/// A comprehensive pod factory interface with configuration capabilities.
/// 
/// This interface combines hierarchical functionality with configuration
/// features such as scope management, lifecycle processors, and various
/// factory behaviors. It's the main interface used by Jetleaf applications
/// for configurable pod management.
/// 
/// ## Usage Example:
/// ```dart
/// final factory = JetleafPodFactory();
/// factory.setParentFactory(parentFactory);
/// factory.registerScope('request', RequestScope());
/// factory.setAllowCircularReferences(true);
/// factory.addPodAwareProcessor(MyCustomProcessor());
/// 
/// // Start the factory
/// await factory.refresh();
/// ```
/// 
/// See also:
/// - [HierarchicalPodFactory] for parent-child hierarchy functionality
/// - [ApplicationStartupAware] for application lifecycle integration
/// - [SingletonPodRegistry] for singleton management
/// {@endtemplate}
abstract interface class ConfigurablePodFactory implements HierarchicalPodFactory, ApplicationStartupAware, SingletonPodRegistry, AliasRegistryAware {
  /// {@template conversion_service_context_set}
  /// Sets an assigned [ConversionService].
  ///
  /// ### Example
  /// ```dart
  /// final service = context.setConversionService(ConversionServiceImpl());
  /// final result = service?.convert<String, double>("3.14");
  /// print("Parsed double: $result"); // Parsed double: 3.14
  /// ```
  /// {@endtemplate}
  void setConversionService(ConversionService conversionService);

  /// {@template conversion_service_context_get}
  /// Retrieves the currently assigned [ConversionService].
  ///
  /// This method should always return the same instance that was set via
  /// [setConversionService] or a default instance of [ConversionService].
  ///
  /// ### Example
  /// ```dart
  /// final service = context.getConversionService();
  /// final result = service?.convert<String, double>("3.14");
  /// print("Parsed double: $result"); // Parsed double: 3.14
  /// ```
  /// {@endtemplate}
  ConversionService getConversionService();

  /// {@template configurable_pod_factory_set_parent_factory}
  /// Sets the parent factory for this hierarchical factory.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final childFactory = JetleafPodFactory();
  /// childFactory.setParentFactory(parentFactory);
  /// ```
  /// 
  /// @param parentFactory The parent factory to set, or null to remove parent
  /// {@endtemplate}
  void setParentFactory(PodFactory? parentFactory);

  /// {@template configurable_pod_factory_set_cache_pod_metadata}
  /// Enables or disables caching of pod metadata for performance optimization.
  /// 
  /// When enabled, the factory will cache pod definition metadata to
  /// improve performance at the cost of memory usage.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// factory.setCachePodMetadata(true); // Enable for better performance
  /// ```
  /// 
  /// @param cachePodMetadata true to enable caching, false to disable
  /// {@endtemplate}
  void setCachePodMetadata(bool cachePodMetadata);

  /// {@template configurable_pod_factory_is_cache_pod_metadata}
  /// Checks if pod metadata caching is enabled.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// if (factory.isCachePodMetadata()) {
  ///   print('Pod metadata caching is enabled');
  /// }
  /// ```
  /// 
  /// @return true if pod metadata caching is enabled
  /// {@endtemplate}
  bool isCachePodMetadata();

  /// {@template configurable_pod_factory_register_scope}
  /// Registers a new scope with the given name.
  /// 
  /// Scopes control the lifecycle and visibility of pods. Common scopes
  /// include 'singleton', 'prototype', 'request', 'session', etc.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// factory.registerScope('request', RequestScope());
  /// factory.registerScope('session', SessionScope());
  /// ```
  /// 
  /// @param scopeName The name of the scope to register
  /// @param scope The scope implementation to register
  /// {@endtemplate}
  void registerScope(String scopeName, PodScope scope);

  /// {@template configurable_pod_factory_copy_configuration_from}
  /// Copies configuration from another factory.
  /// 
  /// This method copies various configuration settings including
  /// parent factory, scope registrations, and other factory behaviors.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final newFactory = JetleafPodFactory();
  /// newFactory.copyConfigurationFrom(templateFactory);
  /// ```
  /// 
  /// @param otherFactory The factory to copy configuration from
  /// {@endtemplate}
  void copyConfigurationFrom(ConfigurablePodFactory otherFactory);

  /// {@template configurable_pod_factory_set_allow_definition_overriding}
  /// Allows or disallows overriding of pod definitions.
  /// 
  /// When enabled, later pod definitions can override earlier ones
  /// with the same name. When disabled, duplicate pod definitions
  /// will cause an exception.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// factory.setAllowDefinitionOverriding(true); // Allow overriding in development
  /// ```
  /// 
  /// @param value true to allow definition overriding, false to disallow
  /// {@endtemplate}
  void setAllowDefinitionOverriding(bool value);

  /// {@template configurable_pod_factory_set_allow_circular_references}
  /// Allows or disallows circular references between pods.
  /// 
  /// When enabled, the factory can resolve circular dependencies
  /// using advanced techniques. When disabled, circular dependencies
  /// will cause an exception.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// factory.setAllowCircularReferences(false); // Strict mode - no circular deps
  /// ```
  /// 
  /// @param value true to allow circular references, false to disallow
  /// {@endtemplate}
  void setAllowCircularReferences(bool value);

  /// {@template configurable_pod_factory_set_allow_raw_injection_despite_wrapping}
  /// Allows or disallows raw injection despite wrapping.
  /// 
  /// When enabled, the factory can inject raw pods even if they are wrapped
  /// in a proxy or other wrapper. When disabled, raw pods will be injected
  /// only if they are not wrapped.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// factory.setAllowRawInjectionDespiteWrapping(true); // Allow raw injection
  /// ```
  /// 
  /// @param value true to allow raw injection despite wrapping, false to disallow
  /// {@endtemplate}
  void setAllowRawInjectionEvenWhenWrapped(bool value);

  /// {@template configurable_pod_factory_destroy_singletons}
  /// Destroys all singleton pods in the factory.
  /// 
  /// This method calls destruction callbacks on all singleton pods
  /// and clears the singleton registry. Useful for application shutdown.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// // During application shutdown
  /// await factory.destroySingletons();
  /// ```
  /// {@endtemplate}
  void destroySingletons();

  /// {@template configurable_pod_factory_destroy_scoped_pod}
  /// Destroys all pods in the specified scope.
  /// 
  /// This method destroys pods that belong to a specific scope,
  /// such as all request-scoped pods when a request completes.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// // When request completes
  /// factory.destroyScopedPod('request');
  /// ```
  /// 
  /// @param podName The name of the scope to destroy pods for
  /// {@endtemplate}
  void destroyScopedPod(String podName);

  /// {@macro autowire_pod_factory_destroy_pod}
  Future<void> destroyPod(String podName, Object podInstance);

  /// {@template configurable_pod_factory_is_currently_in_creation}
  /// Checks if a pod with the given name is currently being created.
  /// 
  /// This method is used internally to detect circular dependencies
  /// during pod creation.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// if (factory.isCurrentlyInCreation('complexService')) {
  ///   print('complexService is currently being created - possible circular reference');
  /// }
  /// ```
  /// 
  /// @param podName The name of the pod to check
  /// @return true if the pod is currently being created
  /// {@endtemplate}
  bool isActuallyInCreation(String podName);

  /// {@template configurable_pod_factory_get_registered_scope}
  /// Retrieves a registered scope by name.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final requestScope = factory.getRegisteredScope('request');
  /// if (requestScope != null) {
  ///   await requestScope.destroy();
  /// }
  /// ```
  /// 
  /// @param scopeName The name of the scope to retrieve
  /// @return The registered scope or null if not found
  /// {@endtemplate}
  PodScope? getRegisteredScope(String scopeName);

  /// {@template configurable_pod_factory_get_registered_scope_names}
  /// Retrieves all registered scope names.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final scopeNames = factory.getRegisteredScopeNames();
  /// print('Available scopes: $scopeNames');
  /// ```
  /// 
  /// @return A list of all registered scope names
  /// {@endtemplate}
  List<String> getRegisteredScopeNames();

  /// {@template configurable_pod_factory_get_pod_aware_processor_count}
  /// Gets the number of registered pod-aware processors.
  /// 
  /// Pod-aware processors can modify pods during factory initialization.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final count = factory.getPodAwareProcessorCount();
  /// print('Number of pod-aware processors: $count');
  /// ```
  /// 
  /// @return The number of registered pod-aware processors
  /// {@endtemplate}
  int getPodAwareProcessorCount();

  /// {@template configurable_pod_factory_get_pod_aware_processors}
  /// Retrieves all registered pod-aware processors.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final processors = factory.getPodAwareProcessors();
  /// for (final processor in processors) {
  ///   processor.processBeforeInitialization();
  /// }
  /// ```
  /// 
  /// @return A list of all registered pod-aware processors
  /// {@endtemplate}
  List<PodAwareProcessor> getPodAwareProcessors();

  /// {@template configurable_pod_factory_add_pod_aware_processor}
  /// Registers a new pod-aware processor.
  /// 
  /// Processors are called during pod creation and can modify pod
  /// definitions or instances.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// factory.addPodAwareProcessor(MyCustomPodProcessor());
  /// ```
  /// 
  /// @param processor The processor to register
  /// {@endtemplate}
  void addPodAwareProcessor(PodAwareProcessor processor);

  /// {@template configurable_pod_factory_get_merged_pod_definition}
  /// Retrieves the merged pod definition for the specified pod name.
  /// 
  /// Merged definitions combine parent and child definitions in
  /// hierarchical configurations.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final definition = factory.getMergedPodDefinition('dataService');
  /// print('Pod class: ${definition.podClass}');
  /// ```
  /// 
  /// @param podName The name of the pod to get the definition for
  /// @return The merged root pod definition
  /// {@endtemplate}
  RootPodDefinition getMergedPodDefinition(String podName);

  /// {@template configurable_pod_factory_set_pod_expression_resolver}
  /// Sets the expression resolver for resolving expressions in pod definitions.
  /// 
  /// Expression resolvers can evaluate expressions like "${config.host}"
  /// in pod definition values.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// factory.setPodExpressionResolver(StandardPodExpressionResolver());
  /// ```
  /// 
  /// @param valueResolver The expression resolver to set
  /// {@endtemplate}
  void setPodExpressionResolver(PodExpressionResolver? valueResolver);

  /// {@template configurable_pod_factory_get_pod_expression_resolver}
  /// Retrieves the current expression resolver.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final resolver = factory.getPodExpressionResolver();
  /// if (resolver != null) {
  ///   final value = resolver.evaluateExpression('${api.url}');
  /// }
  /// ```
  /// 
  /// @return The current expression resolver or null if not set
  /// {@endtemplate}
  PodExpressionResolver? getPodExpressionResolver();

  /// {@template configurable_pod_factory_get_allow_circular_references}
  /// Retrieves the current circular reference setting.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final allowCircularRefs = factory.getAllowCircularReferences();
  /// print('Circular references allowed: $allowCircularRefs');
  /// ```
  /// 
  /// @return true if circular references are allowed, false otherwise
  /// {@endtemplate}
  bool getAllowCircularReferences();

  /// {@template configurable_pod_factory_get_allow_definition_overriding}
  /// Retrieves the current definition overriding setting.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final allowOverride = factory.getAllowDefinitionOverriding();
  /// print('Definition overriding allowed: $allowOverride');
  /// ```
  /// 
  /// @return true if definition overriding is allowed, false otherwise
  /// {@endtemplate}
  bool getAllowDefinitionOverriding();

  /// {@template configurable_pod_factory_get_allow_raw_injection_despite_wrapping}
  /// Retrieves the current raw injection despite wrapping setting.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final allowRawInjection = factory.getAllowRawInjectionDespiteWrapping();
  /// print('Raw injection despite wrapping allowed: $allowRawInjection');
  /// ```
  /// 
  /// @return true if raw injection despite wrapping is allowed, false otherwise
  /// {@endtemplate}
  bool getAllowRawInjectionEvenWhenWrapped();
}

/// {@template listable_pod_factory}
/// Extends [PodFactory] with capabilities to list and query pods.
/// 
/// This interface provides methods to discover pods based on type,
/// annotations, and other criteria. Useful for batch operations
/// and framework integration.
/// 
/// ## Usage Example:
/// ```dart
/// final factory = getListablePodFactory();
/// 
/// // Get all service pods
/// final serviceNames = await factory.getPodNames(Class<Service>());
/// 
/// // Get all pods with a specific annotation
/// final annotatedPods = await factory.getPodsWithAnnotation(Class<RestController>());
/// ```
/// {@endtemplate}
abstract interface class ListablePodFactory implements PodFactory, ListablePodDefinitionRegistry {
  /// {@template listable_pod_factory_get_pod_names}
  /// Retrieves all pod names for pods of the specified type.
  /// 
  /// This method can include or exclude non-singleton pods and
  /// control eager initialization behavior.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// // Get all repository pod names
  /// final repoNames = await factory.getPodNames(
  ///   Class<Repository>(), 
  ///   includeNonSingletons: true,
  /// );
  /// 
  /// for (final name in repoNames) {
  ///   final repo = await factory.getPod<Repository>(name);
  ///   await repo.initialize();
  /// }
  /// ```
  /// 
  /// @param type The type of pods to find
  /// @param includeNonSingletons Whether to include non-singleton pods
  /// @param allowEagerInit Whether to allow eager initialization during lookup
  /// @return A Future that completes with a list of pod names
  /// {@endtemplate}
  Future<List<String>> getPodNames(Class type, {bool includeNonSingletons = false, bool allowEagerInit = false});

  /// {@template listable_pod_factory_get_pods_of}
  /// Retrieves all pods of the specified type as a map of name to instance.
  /// 
  /// This method provides a convenient way to get all pods of a type
  /// along with their registered names.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final services = await factory.getPodsOf<Service>(
  ///   Class<Service>(),
  ///   includeNonSingletons: false, // Only singletons
  /// );
  /// 
  /// for (final entry in services.entries) {
  ///   print('Service ${entry.key}: ${entry.value}');
  /// }
  /// ```
  /// 
  /// @param type The type of pods to find
  /// @param includeNonSingletons Whether to include non-singleton pods
  /// @param allowEagerInit Whether to allow eager initialization during lookup
  /// @return A Future that completes with a map of pod names to instances
  /// {@endtemplate}
  Future<Map<String, T>> getPodsOf<T>(Class<T> type, {bool includeNonSingletons = false, bool allowEagerInit = false});

  /// {@template listable_pod_factory_get_pod_names_for_annotation}
  /// Retrieves pod names for pods annotated with the specified annotation type.
  /// 
  /// This method is useful for discovering pods with specific metadata
  /// such as @Controller, @Service, or custom annotations.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// // Find all controllers
  /// final controllerNames = await factory.getPodNamesForAnnotation(Class<Controller>());
  /// 
  /// for (final name in controllerNames) {
  ///   print('Found controller: $name');
  /// }
  /// ```
  /// 
  /// @param type The annotation type to look for
  /// @return A Future that completes with a list of pod names
  /// {@endtemplate}
  Future<List<String>> getPodNamesForAnnotation<A>(Class<A> type);

  /// {@template listable_pod_factory_get_pods_with_annotation}
  /// Retrieves pods with the specified annotation as a map of name to instance.
  /// 
  /// Similar to [getPodNamesForAnnotation] but returns the actual instances.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final scheduledPods = await factory.getPodsWithAnnotation(Class<Scheduled>());
  /// 
  /// for (final entry in scheduledPods.entries) {
  ///   final pod = entry.value;
  ///   if (pod is ScheduledTask) {
  ///     await pod.schedule();
  ///   }
  /// }
  /// ```
  /// 
  /// @param type The annotation type to look for
  /// @return A Future that completes with a map of pod names to instances
  /// {@endtemplate}
  Future<Map<String, Object>> getPodsWithAnnotation<A>(Class<A> type);

  /// {@template listable_pod_factory_find_annotation_on_pod}
  /// Finds a specific annotation on a pod.
  /// 
  /// This method looks for annotations of the specified type on the
  /// given pod and returns the first one found.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final annotation = await factory.findAnnotationOnPod<RestController>(
  ///   'userController', 
  ///   Class<RestController>(),
  /// );
  /// 
  /// if (annotation != null) {
  ///   print('Controller path: ${annotation.path}');
  /// }
  /// ```
  /// 
  /// @param podName The name of the pod to check
  /// @param type The annotation type to look for
  /// @return A Future that completes with the annotation or null if not found
  /// {@endtemplate}
  Future<A?> findAnnotationOnPod<A>(String podName, Class<A> type);

  /// {@template listable_pod_factory_find_all_annotations_on_pod}
  /// Finds all annotations of the specified type on a pod.
  /// 
  /// Some annotations can be repeated (like @RequestMapping in controllers).
  /// This method returns all instances of the annotation.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final validations = await factory.findAllAnnotationsOnPod<Validated>(
  ///   'userService', 
  ///   Class<Validated>(),
  /// );
  /// 
  /// for (final validation in validations) {
  ///   print('Validation rule: ${validation.rule}');
  /// }
  /// ```
  /// 
  /// @param podName The name of the pod to check
  /// @param type The annotation type to look for
  /// @return A Future that completes with a set of all found annotations
  /// {@endtemplate}
  Future<Set<A>> findAllAnnotationsOnPod<A>(String podName, Class<A> type);
}

/// {@template configurable_listable_pod_factory}
/// The most comprehensive pod factory interface combining listing and configuration capabilities.
/// 
/// This interface is typically implemented by the main application context
/// in Jetleaf applications. It provides full control over pod management,
/// including dependency resolution, metadata caching, and singleton pre-instantiation.
/// 
/// ## Usage Example:
/// ```dart
/// final factory = JetleafApplicationContext();
/// 
/// // Configure the factory
/// factory.setAllowCircularReferences(true);
/// factory.registerResolvableDependency(Class<Config>(), appConfig);
/// 
/// // Pre-instantiate singletons for faster startup
/// await factory.preInstantiateSingletons();
/// 
/// // Use the factory
/// final app = await factory.get<Application>('app');
/// await app.run();
/// ```
/// 
/// See also:
/// - [ConfigurablePodFactory] for configuration capabilities
/// - [ListablePodFactory] for pod discovery capabilities
/// - [PodDefinitionRegistry] for pod definition management
/// {@endtemplate}
abstract interface class ConfigurableListablePodFactory implements ListablePodFactory, ConfigurablePodFactory, PodDefinitionRegistry {
  /// {@template configurable_listable_pod_factory_register_ignored_dependency}
  /// Registers a dependency type that should be ignored during autowiring.
  /// 
  /// Ignored dependencies are not automatically wired even if they match
  /// by type or name. Useful for framework types that shouldn't be injected.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// factory.registerIgnoredDependency(Class<Logger>()); // Framework logger
  /// factory.registerIgnoredDependency(Class<Config>()); // Global config
  /// ```
  /// 
  /// @param type The dependency type to ignore
  /// {@endtemplate}
  void registerIgnoredDependency(Class type);

  /// {@template configurable_listable_pod_factory_register_resolvable_dependency}
  /// Registers a resolvable dependency for autowiring.
  /// 
  /// This method allows you to register specific instances or values
  /// that should be injected when a dependency of the specified type is found.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// factory.registerResolvableDependency(Class<DatabaseConfig>(), productionDbConfig);
  /// factory.registerResolvableDependency(Class<Environment>(), Environment.production);
  /// ```
  /// 
  /// @param type The dependency type to register
  /// @param autowiredValue The value to inject for this dependency type
  /// {@endtemplate}
  void registerResolvableDependency(Class type, [Object? autowiredValue]);

  /// {@template configurable_listable_pod_factory_is_autowire_candidate}
  /// Checks if a pod is a candidate for autowiring for the given dependency.
  /// 
  /// This method considers various factors including dependency type,
  /// qualifiers, and other autowiring conditions.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final candidate = factory.isAutowireCandidate('userService', descriptor);
  /// if (candidate) {
  ///   print('userService is a valid autowire candidate for this dependency');
  /// }
  /// ```
  /// 
  /// @param podName The name of the pod to check
  /// @param descriptor The dependency descriptor
  /// @return true if the pod is a valid autowire candidate
  /// {@endtemplate}
  bool isAutowireCandidate(String podName, DependencyDescriptor descriptor);

  /// {@template configurable_listable_pod_factory_get_pod_names_iterator}
  /// Returns an iterator over all pod names in the factory.
  /// 
  /// This provides low-level access to iterate through all registered pods.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// final iterator = factory.getPodNamesIterator();
  /// while (iterator.moveNext()) {
  ///   print('Pod: ${iterator.current}');
  /// }
  /// ```
  /// 
  /// @return An iterator for all pod names
  /// {@endtemplate}
  Iterator<String> getPodNamesIterator();

  /// {@template configurable_listable_pod_factory_clear_metadata_cache}
  /// Clears the internal metadata cache.
  /// 
  /// Useful when pod definitions change at runtime and the cache
  /// needs to be refreshed.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// // After dynamic configuration changes
  /// factory.clearMetadataCache();
  /// ```
  /// {@endtemplate}
  void clearMetadataCache();

  /// {@template configurable_listable_pod_factory_pre_instantiate_singletons}
  /// Pre-instantiates all singleton pods.
  /// 
  /// This method creates all singleton pods upfront, which can improve
  /// first-request performance at the cost of slower application startup.
  /// 
  /// ## Usage Example:
  /// ```dart
  /// // During application startup for better runtime performance
  /// await factory.preInstantiateSingletons();
  /// print('All singletons have been instantiated');
  /// ```
  /// 
  /// @return A Future that completes when all singletons are instantiated
  /// {@endtemplate}
  Future<void> preInstantiateSingletons();
}

/// {@template dependency_descriptor}
/// Describes a dependency that needs to be resolved by a PodFactory.
/// 
/// This class contains all the information needed to resolve a dependency
/// during autowiring, including the source of the dependency, the pod name,
/// property name, and the required type.
/// 
/// ## Usage Example:
/// ```dart
/// final descriptor = DependencyDescriptor(
///   Source.controller,
///   'userController', 
///   'userService',
///   Class<UserService>(),
/// );
/// 
/// final dependency = await factory.resolveDependency(descriptor);
/// ```
/// 
/// This is primarily used internally by the Jetleaf framework during
/// the dependency injection process.
/// {@endtemplate}
class DependencyDescriptor {
  /// {@template dependency_descriptor_source}
  /// The source of the dependency (where the dependency is needed).
  /// 
  /// This could be a controller, service, repository, or other component type.
  /// {@endtemplate}
  final Source source;

  /// {@template dependency_descriptor_pod_name}
  /// The name of the pod that has the dependency.
  /// 
  /// This identifies which pod requires the dependency to be resolved.
  /// {@endtemplate}
  final String podName;

  /// {@template dependency_descriptor_property_name}
  /// The name of the property or parameter that requires the dependency.
  /// 
  /// This is used for named dependency resolution and error reporting.
  /// {@endtemplate}
  final String propertyName;

  /// {@template dependency_descriptor_type}
  /// The type of the dependency that needs to be resolved.
  /// 
  /// The factory will look for a pod that matches this type (and optionally
  /// the property name) to satisfy the dependency.
  /// {@endtemplate}
  final Class type;

  /// {@template dependency_descriptor_args}
  /// The arguments to pass to the constructor of the dependency.
  /// 
  /// This is used for constructor injection and error reporting.
  /// {@endtemplate}
  final List<ArgumentValue>? args;

  /// {@template dependency_descriptor_component}
  /// The component type of the dependency.
  /// 
  /// This is used for constructor injection and error reporting.
  /// {@endtemplate}
  final Class? component;

  /// {@template dependency_descriptor_key}
  /// The key type of the dependency.
  /// 
  /// This is used for constructor injection and error reporting.
  /// {@endtemplate}
  final Class? key;

  /// {@template dependency_descriptor_is_eager}
  /// Whether the dependency should be resolved eagerly.
  /// 
  /// This is used for constructor injection and error reporting.
  /// {@endtemplate}
  final bool isEager;

  /// {@template dependency_descriptor_is_required}
  /// Whether the dependency is required.
  /// 
  /// This is used for constructor injection and error reporting.
  /// {@endtemplate}
  final bool isRequired;

  /// {@template dependency_descriptor_lookup}
  /// The lookup name of the dependency.
  /// 
  /// This is used for constructor injection and error reporting.
  /// {@endtemplate}
  final String? lookup;

  /// {@macro dependency_descriptor}
  DependencyDescriptor({
    required this.source,
    required this.podName,
    required this.propertyName,
    required this.type,
    this.args,
    this.component,
    this.key,
    this.isEager = false,
    this.isRequired = true,
    this.lookup
  });
}