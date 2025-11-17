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

import '../core/pod_factory.dart';
import '../scope/scope.dart';
import '../exceptions.dart';

part '_object.dart';
part '_value.dart';
part 'value.dart';

/// {@template object_holder}
/// A generic container that holds an object along with optional metadata
/// such as its package name and qualified name.
///
/// The [ObjectHolder] is useful for cases where you want to associate
/// an object with extra metadata that describes where it came from
/// (e.g., reflection, classpath scanning, or dependency resolution).
///
/// - [T] is the type of object being held.  
/// - `_packageName` represents the Dart package in which the object resides.  
/// - `_qualifiedName` represents the fully qualified class or type name.  
///
/// ### Example
/// ```dart
/// void main() {
///   final holder = ObjectHolder<String>(
///     'MyClass',
///     packageName: 'my_app',
///     qualifiedName: 'package:my_app/my_app.dart.MyClass',
///   );
///
///   print('Value: ${holder.getValue()}');
///   print('Package: ${holder.getPackageName()}');
///   print('Qualified name: ${holder.getQualifiedName()}');
/// }
/// ```
///
/// **Constraints**:
/// - Either `packageName` or `qualifiedName` must be provided.  
/// - If provided, neither may be an empty string.  
/// {@endtemplate}
@Generic(ObjectHolder)
class ObjectHolder<T> with EqualsAndHashCode, ToString {
  /// {@template object_holder_value}
  /// The underlying object being held.
  ///
  /// This is the primary value of type [T] wrapped by the [ObjectHolder].
  /// {@endtemplate}
  final T _value;

  /// {@template object_holder_package}
  /// The optional package name associated with the object.
  ///
  /// This is typically the Dart package where the class or resource
  /// originates from.
  ///
  /// Example: `"my_app"`
  /// {@endtemplate}
  final String? _packageName;

  /// {@template object_holder_qualified}
  /// The optional fully qualified name of the object.
  ///
  /// Typically includes the package and the full namespace path.
  ///
  /// Example: `"package:my_app/my_app.dart.User"`
  /// {@endtemplate}
  final String? _qualifiedName;

  /// {@macro object_holder}
  ///
  /// Creates a new [ObjectHolder] wrapping a value of type [T].
  ///
  /// Throws an [IllegalArgumentException] if:
  /// - Both [packageName] and [qualifiedName] are `null`.  
  /// - Either [packageName] or [qualifiedName] are provided but empty.  
  ///
  /// ### Example
  /// ```dart
  /// final holder = ObjectHolder<int>(
  ///   42,
  ///   packageName: 'core',
  ///   qualifiedName: 'core.constants.Answer',
  /// );
  /// print(holder.getValue()); // 42
  /// ```
  ObjectHolder(this._value, {String? packageName, String? qualifiedName}) : _packageName = packageName, _qualifiedName = qualifiedName {
    if(packageName == null && qualifiedName == null) {
      throw IllegalArgumentException('Package name or qualified name must be provided');
    }

    if(packageName != null && packageName.isEmpty) {
      throw IllegalArgumentException('Package name must not be empty');
    }

    if(qualifiedName != null && qualifiedName.isEmpty) {
      throw IllegalArgumentException('Qualified name must not be empty');
    }
  }

  /// {@template object_holder_get_package}
  /// Returns the package name associated with the held object, or `null`
  /// if not provided.
  ///
  /// ### Example
  /// ```dart
  /// final holder = ObjectHolder<String>('User', packageName: 'my_app');
  /// print(holder.getPackageName()); // "my_app"
  /// ```
  /// {@endtemplate}
  String? getPackageName() => _packageName;

  /// {@template object_holder_get_qualified}
  /// Returns the fully qualified name associated with the held object,
  /// or `null` if not provided.
  ///
  /// ### Example
  /// ```dart
  /// final holder = ObjectHolder<String>(
  ///   'User',
  ///   qualifiedName: 'package:my_app/my_app.dart.User',
  /// );
  /// print(holder.getQualifiedName()); // "package:my_app/my_app.dart.User"
  /// ```
  /// {@endtemplate}
  String? getQualifiedName() => _qualifiedName;

  /// {@template object_holder_get_value}
  /// Returns the underlying held value of type [T].
  ///
  /// ### Example
  /// ```dart
  /// final holder = ObjectHolder<int>(99, packageName: 'core');
  /// print(holder.getValue()); // 99
  /// ```
  /// {@endtemplate}
  T getValue() => _value;

  /// {@template object_holder_get_type}
  /// Returns the type of the held value.
  ///
  /// If a qualified name is provided, it returns the class from the qualified name.
  /// Otherwise, it returns the class of the held value.
  ///
  /// ### Example
  /// ```dart
  /// final holder = ObjectHolder<int>(99, packageName: 'core');
  /// print(holder.getType()); // int
  /// ```
  /// {@endtemplate}
  Class? getType() {
    if (_qualifiedName != null) {
      return Class.fromQualifiedName(_qualifiedName);
    }

    if (_value == null) {
      return null;
    }

    return _value.getClass(null, _packageName);
  }

  @override
  List<Object?> equalizedProperties() => [_value, _packageName, _qualifiedName];

  @override
  ToStringOptions toStringOptions() => ToStringOptions(
    customParameterNames: ['value', 'packageName', 'qualifiedName'],
    includeParameterNames: true,
  );
}

// --------------------------------------------------------------------------------------------------------
// ObjectFactory
// --------------------------------------------------------------------------------------------------------

/// {@template object_factory_function}
/// A function that creates an instance of type [T].
///
/// This function is used by [ObjectFactory] to create instances of type [T].
///
/// [args]: Optional arguments to pass to the creator function.
/// Returns a FutureOr<ObjectHolder<T>>
///
/// Example:
/// ```dart
/// final factory = ObjectFactory<String>(([args]) => ObjectHolder('test', packageName: 'test', qualifiedName: 'test'));
/// ```
/// {@endtemplate}
typedef ObjectFactoryFunction<T> = FutureOr<ObjectHolder<T>> Function([List<ArgumentValue>? args]);

/// {@template object_factory}
/// A generic factory interface for producing instances of a given type [T].
///
/// Used by JetLeaf and dependency injection containers to lazily create or
/// retrieve instances of objects—especially in scenarios where you want to
/// delay instantiation until explicitly requested.
///
/// Implementations may return new instances each time, or cache and return
/// the same instance (singleton-style).
///
/// ---
///
/// ### Example
/// ```dart
/// class MyFactory implements ObjectFactory<Foo> {
///   @override
///   Foo get() => Foo();
/// }
///
/// final factory = MyFactory();
/// final foo = factory.get();
/// ```
///
/// In more complex scenarios, the factory might retrieve from a container:
/// ```dart
/// class PodFactoryObjectFactory implements ObjectFactory<MyService> {
///   final PodFactory factory;
///
///   PodFactoryObjectFactory(this.factory);
///
///   @override
///   MyService get() => factory.get<MyService>();
/// }
/// ```
/// {@endtemplate}
@Generic(ObjectFactory)
abstract class ObjectFactory<T> {
  /// {@macro object_factory}
  const ObjectFactory();

  /// Returns an instance of the object managed by this factory.
  ///
  /// May throw a [PodException] if the object could not be created or retrieved.
  ///
  /// {@macro throws}
  FutureOr<ObjectHolder<T>> get([List<ArgumentValue>? args]);

  /// {@template default_object_factory_create_multiple}
  /// Creates multiple instances of type [T] in a single call.
  ///
  /// This convenience method can be useful when you need several instances
  /// at once, such as for batch processing or collection population.
  ///
  /// [count]: The number of instances to create
  /// Returns a list containing [count] new instances
  ///
  /// Example:
  /// ```dart
  /// final factory = ObjectFactory<RandomNumber>(() => RandomNumber());
  /// final numbers = factory.createMultiple(5);
  /// print('Created ${numbers.length} random numbers');
  /// ```
  /// {@endtemplate}
  Future<List<T>> createMultiple(int count) async {
    final result = <T>[];
    
    for (int i = 0; i < count; i++) {
      final object = await get();
      result.add(object.getValue());
    }

    return result;
  }

  /// {@template default_object_factory_chain}
  /// Creates a new [ObjectFactory] that uses this factory's output as input to another factory.
  ///
  /// This method enables chaining of factories for more complex creation logic.
  ///
  /// [nextFactory]: A function that takes a [T] instance and returns an [ObjectFactory<R>]
  /// Returns a new ObjectFactory that produces [R] instances
  ///
  /// Example:
  /// ```dart
  /// final configFactory = ObjectFactory<Config>(() => Config.load());
  ///
  /// // Chain with a service factory that needs config
  /// final serviceFactory = configFactory.chain<Service>((config) =>
  ///   ObjectFactory<Service>(() => Service(config))
  /// );
  ///
  /// final service = serviceFactory.getObject(); // Service with configured dependencies
  /// ```
  /// {@endtemplate}
  Future<ObjectFactory<R>> chain<R>(ObjectFactory<R> Function(T) nextFactory) async {
    Future<ObjectFactory<R>> create() async {
      final firstResult = await get();
      final next = nextFactory(firstResult.getValue());
      return next;
    }

    final result = await create();
    return SimpleObjectFactory<R>(([args]) => result.get(args));
  }

  /// {@template default_object_factory_with_side_effect}
  /// Creates a new factory that performs a side effect after object creation.
  ///
  /// This is useful for logging, metrics, or other observability needs
  /// without modifying the core creation logic.
  ///
  /// [sideEffect]: A function that receives the created object and performs a side effect
  /// Returns a new ObjectFactory that performs the side effect after creation
  ///
  /// Example:
  /// ```dart
  /// final factory = ObjectFactory<Connection>(() => Connection());
  ///
  /// // Add logging side effect
  /// final loggedFactory = factory.withSideEffect((connection) {
  ///   print('Created new connection: ${connection.id}');
  ///   metrics.recordConnectionCreated();
  /// });
  /// ```
  /// {@endtemplate}
  Future<ObjectFactory<T>> withSideEffect(void Function(T) sideEffect) async {
    Future<ObjectHolder<T>> create([args]) async {
      final result = await get(args);
      sideEffect(result.getValue());
      return result;
    }

    return SimpleObjectFactory<T>(([args]) => create(args));
  }

  /// {@template default_object_factory_to_string}
  /// Returns a string representation of this ObjectFactory.
  ///
  /// The string includes the type [T] and indicates it's a default factory
  /// implementation for debugging and logging purposes.
  ///
  /// Returns a string in the format: 'ObjectFactory<[T]>'
  ///
  /// Example:
  /// ```dart
  /// final factory = ObjectFactory<UserService>(() => UserService());
  /// print(factory.toString()); // 'ObjectFactory<UserService>'
  /// ```
  /// {@endtemplate}
  @override
  String toString() => 'ObjectFactory<$T>';

  /// {@template default_object_factory_copy_with}
  /// Creates a copy of this ObjectFactory with a new creator function.
  ///
  /// This method is useful when you want to create a similar factory but
  /// with slight modifications to the creation logic.
  ///
  /// [creator]: Optional new creator function (uses current if null)
  /// Returns a new ObjectFactory instance with the specified creator
  ///
  /// Example:
  /// ```dart
  /// final originalFactory = ObjectFactory<String>(() => 'hello');
  ///
  /// // Create a factory with different creation logic
  /// final upperCaseFactory = originalFactory.copyWith(
  ///   creator: () => 'HELLO',
  /// );
  /// ```
  /// {@endtemplate}
  ObjectFactory<T> copyWith({ObjectFactoryFunction<T>? creator}) {
    return SimpleObjectFactory<T>(([args]) => creator?.call(args) ?? get(args));
  }
}

// --------------------------------------------------------------------------------------------------------
// PodProvider
// --------------------------------------------------------------------------------------------------------

/// {@template pod_provider}
/// Interface for objects that are themselves factories for other objects.
///
/// This interface is used when you need more control over object creation than
/// simple instantiation provides. PodProvider can create objects dynamically,
/// perform complex initialization, or return different instances based on
/// configuration or runtime conditions.
///
/// PodProvider is a powerful pattern for:
/// - Creating objects that require complex initialization
/// - Returning different implementations based on configuration
/// - Integrating with external libraries or legacy code
/// - Creating proxy objects or decorators
///
/// ## Key Concepts
///
/// - **Object Creation**: The [get] method creates and returns the actual object
/// - **Type Information**: The [getClass] method provides type information for dependency injection
/// - **Lifecycle**: The [isSingleton] method controls whether the same instance is returned each time
///
/// ## Usage
///
/// Implement this interface to create custom factory pods:
///
/// ```dart
/// class DatabaseConnectionFactory implements PodProvider<DatabaseConnection> {
///   final String connectionUrl;
///   final String username;
///   final String password;
///   
///   DatabaseConnectionFactory(this.connectionUrl, this.username, this.password);
///   
///   @override
///   ObjectHolder<DatabaseConnection>? get() {
///     return DatabaseConnection.create(
///       url: connectionUrl,
///       username: username,
///       password: password,
///     );
///   }
///   
///   @override
///   Class? getClass() => Class<DatabaseConnection>();
///   
///   @override
///   bool isSingleton() => true; // Reuse the same connection
/// }
/// ```
///
/// ## Registration
///
/// Factory pods are registered like normal pods:
///
/// ```dart
/// @Pod
/// DatabaseConnectionFactory databaseConnectionFactory() {
///   return DatabaseConnectionFactory(
///     'jdbc:postgresql://localhost:5432/mydb',
///     'user',
///     'password',
///   );
/// }
/// ```
///
/// ## Accessing Factory vs Product
///
/// - To get the product: `context.getPod<DatabaseConnection>()`
/// - To get the factory: `context.getPod<PodProvider>('&databaseConnectionFactory')`
/// {@endtemplate}
@Generic(PodProvider)
abstract class PodProvider<T> {
  /// {@macro pod_provider}
  /// 
  /// Creates and returns an instance of the object this factory manages.
  /// 
  /// This method is called by the container when a pod of type `T` is requested.
  /// The implementation should create and configure the object as needed.
  /// 
  /// ## Return Value
  /// 
  /// - Returns an instance of type `T`, or `null` if the object cannot be created
  /// - For singleton factories, the same instance should be returned on subsequent calls
  /// - For prototype factories, a new instance should be created each time
  /// 
  /// ## Example
  /// 
  /// ```dart
  /// @override
  /// ObjectHolder<DatabaseConnection>? get() {
  ///   final service = MyService();
  ///   service.initialize(configurationProperties);
  ///   return ObjectHolder(service);
  /// }
  /// ```
  /// 
  /// ## Error Handling
  /// 
  /// If object creation fails, this method can:
  /// - Return `null` to indicate failure
  /// - Throw an exception with details about the failure
  /// 
  /// ```dart
  /// @override
  /// Future<ObjectHolder<DatabaseConnection>?> get() async {
  ///   try {
  ///     return ObjectHolder(DatabaseConnection.connect(connectionString));
  ///   } catch (e) {
  ///     throw PodCreationException('Failed to create database connection: $e');
  ///   }
  /// }
  /// ```
  FutureOr<ObjectHolder<T>?> get([Class? requiredType]);

  /// Returns the type of object that this factory creates.
  /// 
  /// This method provides type information to the container for dependency
  /// injection and type checking. It's used to determine if this factory
  /// can satisfy dependencies of a particular type.
  /// 
  /// ## Return Value
  /// 
  /// - Returns a [Class] object representing the type `T`
  /// - Returns `null` if the type cannot be determined at registration time
  /// - Should be consistent with the actual type returned by [get]
  /// 
  /// ## Example
  /// 
  /// ```dart
  /// @override
  /// Class? getClass() => Class<MyService>();
  /// ```
  /// 
  /// ## Dynamic Types
  /// 
  /// For factories that create different types based on configuration:
  /// 
  /// ```dart
  /// @override
  /// Class? getClass() {
  ///   if (useRedisCache) {
  ///     return Class<RedisCache>();
  ///   } else {
  ///     return Class<InMemoryCache>();
  ///   }
  /// }
  /// ```
  Class? getClass();

  /// Returns whether this factory creates singleton or prototype instances.
  /// 
  /// This method controls the lifecycle of objects created by this factory:
  /// - `true`: The container will cache the first instance and return it for all subsequent requests
  /// - `false`: The container will call [get] for each request, creating new instances
  /// 
  /// ## Default Implementation
  /// 
  /// The default implementation returns `true`, making objects singletons by default.
  /// This is the most common use case and provides better performance.
  /// 
  /// ## Example - Singleton Factory
  /// 
  /// ```dart
  /// @override
  /// bool isSingleton() => true; // Default behavior
  /// ```
  /// 
  /// ## Example - Prototype Factory
  /// 
  /// ```dart
  /// class SessionFactory implements PodProvider<UserSession> {
  ///   @override
  ///   UserSession? get() => UserSession(); // New session each time
  ///   
  ///   @override
  ///   bool isSingleton() => false; // Create new instances
  /// }
  /// ```
  /// 
  /// ## Performance Considerations
  /// 
  /// - Singleton factories are more efficient for expensive-to-create objects
  /// - Prototype factories are necessary for stateful objects that cannot be shared
  bool isSingleton() => true;

  /// Returns whether this factory creates prototype instances instead of singletons.
  /// 
  /// This method provides the inverse of [isSingleton] for clearer intent when
  /// dealing with prototype-scoped pods. It's particularly useful in contexts
  /// where prototype behavior is the focus.
  /// 
  /// ## Return Value
  /// 
  /// - `true` if this factory creates new instances for each request (prototype scope)
  /// - `false` if this factory reuses the same instance (singleton scope)
  /// 
  /// ## Default Implementation
  /// 
  /// The default implementation returns `false`, meaning pods are singletons by default.
  /// Override this method to create prototype-scoped pods.
  /// 
  /// ## Example
  /// 
  /// ```dart
  /// class SessionFactory extends PodProvider<UserSession> {
  ///   @override
  ///   ObjectHolder<UserSession>? get() => UserSession();
  ///   
  ///   @override
  ///   bool isPrototype() => true; // New session for each request
  ///   
  ///   @override
  ///   bool isSingleton() => !isPrototype(); // Consistent with prototype setting
  /// }
  /// ```
  /// 
  /// ## Consistency with isSingleton
  /// 
  /// Ensure this method is consistent with [isSingleton]:
  /// 
  /// ```dart
  /// @override
  /// bool isPrototype() => !isSingleton();
  /// ```
  bool isPrototype() => false;

  /// Returns whether this factory pod should be eagerly initialized.
  /// 
  /// This method controls when the factory pod itself (not the objects it creates)
  /// is initialized. Eager initialization can be useful for:
  /// 
  /// - Validating configuration early in the application startup
  /// - Pre-warming caches or connections
  /// - Failing fast if there are configuration problems
  /// 
  /// ## Return Value
  /// 
  /// - `true` if the factory should be initialized during context startup
  /// - `false` if the factory should be initialized lazily when first accessed
  /// 
  /// ## Default Implementation
  /// 
  /// The default implementation returns `false`, meaning lazy initialization.
  /// This is generally preferred for better startup performance.
  /// 
  /// ## Example - Eager Initialization
  /// 
  /// ```dart
  /// class DatabaseConnectionPoolFactory extends PodProvider<ConnectionPool> {
  ///   @override
  ///   ObjectHolder<ConnectionPool>? get() {
  ///     // Expensive initialization - validate early
  ///     return ConnectionPool.create(connectionString);
  ///   }
  ///   
  ///   @override
  ///   bool isEagerInit() => true; // Initialize during startup
  /// }
  /// ```
  /// 
  /// ## Example - Lazy Initialization
  /// 
  /// ```dart
  /// class ReportGeneratorFactory extends PodProvider<ReportGenerator> {
  ///   @override
  ///   ObjectHolder<ReportGenerator>? get() => ReportGenerator();
  ///   
  ///   @override
  ///   bool isEagerInit() => false; // Initialize when first needed
  /// }
  /// ```
  /// 
  /// ## Performance Considerations
  /// 
  /// - Eager initialization increases startup time but can catch errors early
  /// - Lazy initialization improves startup performance but may delay error detection
  /// - Use eager initialization for critical infrastructure pods
  /// - Use lazy initialization for optional or rarely-used pods
  bool isEagerInit() => false;

  /// Checks whether this factory supports creating objects of the specified type.
  /// 
  /// This method allows callers to verify type compatibility before attempting
  /// object creation, enabling more intelligent factory selection and usage.
  /// 
  /// ## Parameters
  /// 
  /// - [type]: The [Class] object representing the type to check support for
  /// 
  /// ## Return Value
  /// 
  /// - `true` if this factory can create objects assignable to the specified type
  /// - `false` if this factory cannot create compatible objects
  /// 
  /// ## Example
  /// 
  /// ```dart
  /// class DatabaseFactory extends PodProvider<Database> {
  ///   @override
  ///   ObjectHolder<Database>? get() => PostgreSQLDatabase();
  ///   
  ///   @override
  ///   Class? getObjectType() => Class<PostgreSQLDatabase>();
  /// }
  /// 
  /// final factory = DatabaseFactory();
  /// 
  /// // Check type support before using
  /// if (factory.supportsType(Class<PostgreSQLDatabase>())) {
  ///   final db = factory.get() as PostgreSQLDatabase;
  ///   db.enablePostgreSQLFeatures();
  /// }
  /// 
  /// if (factory.supportsType(Class<Database>())) {
  ///   // This will be true since PostgreSQLDatabase extends Database
  ///   final db = factory.get();
  /// }
  /// ```
  /// 
  /// ## Factory Selection
  /// 
  /// Use this method to select appropriate factories from a collection:
  /// 
  /// ```dart
  /// List<PodProvider> factories = [
  ///   PostgreSQLFactory(),
  ///   MySQLFactory(),
  ///   MongoDBFactory(),
  /// ];
  /// 
  /// // Find factories that support SQL databases
  /// final sqlFactories = factories
  ///     .where((f) => f.supportsType(Class<SQLDatabase>()))
  ///     .toList();
  /// ```
  bool supportsType(Class type) => getClass()?.isAssignableTo(type) ?? false;
}

// --------------------------------------------------------------------------------------------------------
// ObjectProvider
// --------------------------------------------------------------------------------------------------------

/// {@template object_provider}
/// A flexible, functional-style provider interface for retrieving and interacting with
/// pods or objects of a particular type.
///
/// This is an extension of [ObjectFactory] and [Iterable] that provides advanced options
/// for conditional retrieval, functional callbacks, filtering, and ordering.
///
/// ---
///
/// ### 🚀 Usage
///
/// ```dart
/// final ObjectProvider<MyService> provider = ...;
///
/// // Get the object, or throw if none or multiple exist
/// MyService service = provider.getObject();
///
/// // Get if available, or null if none exist
/// MyService? maybeService = provider.getIfAvailable();
///
/// // Get a default if not present
/// MyService service = provider.getIfAvailableOrDefault(() => MyService());
///
/// // Use a consumer if available
/// provider.ifAvailable((s) => s.start());
///
/// // Stream through all instances
/// provider.stream().forEach(print);
/// ```
///
/// ---
///
/// ### 🔍 Filtering and Ordering
/// You can stream all matching pods ordered by [Ordered] or [PriorityOrdered]:
///
/// ```dart
/// provider.orderedStream().forEach(print);
/// ```
///
/// Or with a custom type filter (using your [Class<T>] metadata):
///
/// ```dart
/// provider.orderedStreamWithFilter((clazz) => clazz.name.contains('MyType'));
/// ```
///
/// Note: By default, non-singletons are included. Support for filtering them is not yet implemented.
/// {@endtemplate}
@Generic(ObjectProvider)
abstract class ObjectProvider<T> extends ObjectFactory<T> {
  /// {@macro object_provider}
  const ObjectProvider();

  /// Retrieves the single object instance or throws if none or more than one found.
  ///
  /// {@macro Throws}
  /// - [NoSuchPodDefinitionException] if no matching object exists.
  /// - [NoUniquePodDefinitionException] if more than one matching object exists.
  @override
  FutureOr<ObjectHolder<T>> get([List<ArgumentValue>? args]) async {
    final it = stream().iterator();
    if (!it.moveNext()) {
      throw NoSuchPodDefinitionException.byType(Class<Object>());
    }

    final result = it.current;
    if (it.moveNext()) {
      throw NoUniquePodDefinitionException.byTypeWithCount(Class<Object>(), 2, "$T has more than 1 matching pod");
    }

    return result;
  }

  /// Retrieves the object if available, or returns `null` if none exist.
  ///
  /// {@macro Throws}
  /// - [NoUniquePodDefinitionException] if more than one matching object exists.
  Future<ObjectHolder<T>?> getIfAvailable([Supplier<ObjectHolder<T>>? supplier]) async {
    ObjectHolder<T>? result;

    try {
      result = await get();
    } on NoUniquePodDefinitionException catch(_) {
      rethrow;
    } on NoSuchPodDefinitionException catch(_) {
      result = null;
    }

    return result ?? supplier?.call();
  }

  /// Executes [consumer] if the object is available.
  ///
  /// {@macro Throws}
  /// - [NoUniquePodDefinitionException] if more than one matching object exists.
  Future<void> ifAvailable(Consumer<ObjectHolder<T>> consumer) async {
    final dependency = await getIfAvailable();
    if (dependency != null) {
      consumer.call(dependency);
    }
  }

  /// Retrieves the object only if exactly one instance exists, or returns `null`.
  ///
  /// {@macro Throws}
  /// - [NoUniquePodDefinitionException] if more than one matching object exists.
  Future<ObjectHolder<T>?> getIfUnique([Supplier<ObjectHolder<T>>? supplier]) async {
    ObjectHolder<T>? result;

    try {
      result = await get();
    } on NoUniquePodDefinitionException catch(_) {
      rethrow;
    } on NoSuchPodDefinitionException catch(_) {
      result = null;
    }

    return result ?? supplier?.call();
  }

  /// Executes [consumer] only if exactly one instance is available.
  ///
  /// {@macro Throws}
  /// - [NoUniquePodDefinitionException] if more than one matching object exists.
  Future<void> ifUnique(Consumer<ObjectHolder<T>> consumer) async {
    final dependency = await getIfUnique();
    if (dependency != null) {
      consumer.call(dependency);
    }
  }

  /// Returns a [GenericStream] of all available objects.
  GenericStream<ObjectHolder<T>> stream();

  /// Returns an iterator over all available objects.
  Iterator<T> iterator() => stream().map((e) => e.getValue()).iterator();

  /// Returns a list of all available objects.
  List<T> toList() => stream().map((e) => e.getValue()).toList();

  /// Returns `true` if no objects are available.
  bool get isEmpty => toList().isEmpty;

  /// Returns `true` if at least one object is available.
  bool get isNotEmpty => !isEmpty;
}