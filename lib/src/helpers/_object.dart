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

part of 'object.dart';

// --------------------------------------------------------------------------------------------------------
// _ObjectFactory
// --------------------------------------------------------------------------------------------------------

/// {@template default_object_factory}
/// Default implementation of the [ObjectFactory] interface that uses a creator function.
///
/// This class provides a simple, flexible way to create objects on demand
/// using a provided creator function. It's the standard implementation
/// used throughout the JetLeaf framework for object creation scenarios.
///
/// Key features:
/// - Simple delegation to a creator function
/// - Type-safe generic implementation
/// - Lightweight and efficient
/// - No internal state or caching
/// - Easy to compose and decorate
///
/// Usage scenarios:
/// - Pod instantiation in dependency injection
/// - Prototype scope object creation
/// - Factory method implementations
/// - Ad-hoc object creation requirements
/// - Decorator and wrapper patterns
///
/// Example usage:
/// ```dart
/// // Create a factory for UserService
/// final userServiceFactory = _ObjectFactory<UserService>(
///   () => UserService()..initialize(),
/// );
///
/// // Create instances as needed
/// final userService1 = userServiceFactory.getObject();
/// final userService2 = userServiceFactory.getObject();
///
/// // Each call creates a new instance
/// print(identical(userService1, userService2)); // false
/// ```
/// {@endtemplate}
@Generic(SimpleObjectFactory)
class SimpleObjectFactory<T> extends ObjectFactory<T> {
  /// {@template default_object_factory_creator}
  /// The creator function that produces new instances of type [T].
  ///
  /// This function is invoked each time [getObject] is called to create
  /// a new instance. The function should return a fully initialized
  /// and ready-to-use object.
  ///
  /// The creator function can:
  /// - Create simple object instances
  /// - Perform complex initialization logic
  /// - Apply configuration and dependencies
  /// - Return cached or pooled objects (though caching should be implemented in the function itself)
  /// - Throw exceptions if object creation fails
  /// {@endtemplate}
  final ObjectFactoryFunction<T> creator;

  /// {@macro default_object_factory}
  ///
  /// [creator]: The function that creates new instances of type [T].
  ///            Must not be null and should handle its own error cases.
  ///
  /// Example:
  /// ```dart
  /// // Simple constructor
  /// final factory = _ObjectFactory<UserService>(() => UserService());
  ///
  /// // Complex initialization
  /// final factory = _ObjectFactory<DatabaseConnection>(() {
  ///   final connection = DatabaseConnection();
  ///   connection.connect('jdbc:mysql://localhost:3306/mydb');
  ///   connection.authenticate('user', 'password');
  ///   return connection;
  /// });
  ///
  /// // With dependencies
  /// final factory = _ObjectFactory<OrderService>(() {
  ///   final config = loadConfiguration();
  ///   final repository = OrderRepository(config);
  ///   return OrderService(repository);
  /// });
  /// ```
  SimpleObjectFactory(this.creator);
  
  @override
  FutureOr<ObjectHolder<T>> get([List<ArgumentValue>? args]) => creator();
}

// --------------------------------------------------------------------------------------------------------
// ScopedObjectFactory
// --------------------------------------------------------------------------------------------------------

/// {@template scoped_object_factory}
/// An [ObjectFactory] implementation that retrieves objects from a specific [PodScope].
///
/// This factory combines a pod scope with a fallback factory to provide
/// scope-aware object retrieval. It first attempts to get the object from
/// the specified scope, and if not found, uses the fallback factory to
/// create and register the object in the scope.
///
/// Key features:
/// - Scope-aware object retrieval and creation
/// - Lazy initialization with fallback factory
/// - Thread-safe scope operations
/// - Support for various scope types (singleton, prototype, request, session, etc.)
/// - Integration with scope lifecycle management
///
/// This is particularly useful for:
/// - Managing objects with specific lifecycle requirements
/// - Handling request-scoped or session-scoped objects
/// - Implementing custom scope strategies
/// - Integrating with web frameworks and other scope-aware environments
///
/// Example usage:
/// ```dart
/// // Create a fallback factory for UserService
/// final fallbackFactory = () {
///   final service = UserService();
///   service.initialize();
///   return service;
/// };
///
/// // Create a scoped factory for request scope
/// final scopedFactory = ScopedObjectFactory<UserService>(
///   'userService',
///   requestScope,
///   fallbackFactory,
/// );
///
/// // Get the UserService instance from the scope
/// final userService = scopedFactory.getObject();
/// ```
/// {@endtemplate}
@Generic(ScopedObjectFactory)
class ScopedObjectFactory<T> extends ObjectFactory<T> {
  /// {@template scoped_object_factory_pod_name}
  /// The name of the pod to retrieve or create in the scope.
  ///
  /// This name is used to identify the object within the scope and must
  /// follow the naming conventions of the target scope.
  /// {@endtemplate}
  final String name;

  /// {@template scoped_object_factory_scope}
  /// The pod scope from which to retrieve or register the object.
  ///
  /// This scope determines the lifecycle and visibility characteristics
  /// of the object. Common scope types include:
  /// - Singleton: One instance per container
  /// - Prototype: New instance each time
  /// - Request: One instance per HTTP request
  /// - Session: One instance per user session
  /// - Custom application-specific scopes
  /// {@endtemplate}
  final PodScope scope;

  /// {@template scoped_object_factory_fallback_factory}
  /// The fallback factory used to create the object if it doesn't exist in the scope.
  ///
  /// This factory is invoked when the scope doesn't contain the requested object.
  /// The created object is then registered in the scope for future requests.
  /// {@endtemplate}
  final ObjectFactory<T> fallbackFactory;

  /// {@macro scoped_object_factory}
  ///
  /// [name]: The name of the pod to manage in the scope
  /// [scope]: The pod scope to use for object retrieval and registration
  /// [fallbackFactory]: The factory to use when the object needs to be created
  ///
  /// Example:
  /// ```dart
  /// final factory = ScopedObjectFactory<UserService>(
  ///   'userService',
  ///   sessionScope,
  ///   () => UserService()..initialize(),
  /// );
  /// ```
  ScopedObjectFactory(this.name, this.scope, this.fallbackFactory);

  @override
  FutureOr<ObjectHolder<T>> get([List<ArgumentValue>? args]) async {
    final result = await scope.get(name, fallbackFactory as ObjectFactory<Object>);
    return ObjectHolder<T>(result.getValue() as T, qualifiedName: result.getQualifiedName(), packageName: result.getPackageName());
  }

  /// {@template scoped_object_factory_get_pod_name}
  /// Returns the pod name used by this factory.
  ///
  /// Returns the pod name that this factory manages in the scope
  ///
  /// Example:
  /// ```dart
  /// final name = scopedFactory.getPodName();
  /// print('Managing pod: $name'); // e.g., 'userService'
  /// ```
  /// {@endtemplate}
  String getPodName() => name;

  /// {@template scoped_object_factory_remove_from_scope}
  /// Removes the object from the scope if it exists.
  ///
  /// This method can be used to force cleanup of the object from the scope,
  /// which may be necessary for certain scope types (e.g., request scope
  /// cleanup after request processing).
  ///
  /// Returns the removed object, or null if no object was found
  ///
  /// Example:
  /// ```dart
  /// // After request processing, clean up request-scoped objects
  /// final removed = scopedFactory.removeFromScope();
  /// if (removed is DisposablePod) {
  ///   removed.destroy();
  /// }
  /// ```
  /// {@endtemplate}
  T? removeFromScope() {
    final removed = scope.remove(name);
    return removed?.getValue() as T?;
  }

  /// {@template scoped_object_factory_to_string}
  /// Returns a string representation of this ScopedObjectFactory.
  ///
  /// The string includes the pod name, scope type, and whether the object
  /// is currently cached for debugging and logging purposes.
  ///
  /// Returns a string in the format: 'ScopedObjectFactory{name: [name], scope: [type], cached: [cached]}'
  ///
  /// Example:
  /// ```dart
  /// print(scopedFactory.toString());
  /// // Output: ScopedObjectFactory{name: userService, scope: RequestScope, cached: true}
  /// ```
  /// {@endtemplate}
  @override
  String toString() => 'ScopedObjectFactory{name: $name, scope: ${scope.runtimeType}}';

  /// {@template scoped_object_factory_copy_with}
  /// Creates a copy of this ScopedObjectFactory with optional modifications.
  ///
  /// This method is useful for creating variations of the factory with
  /// different parameters while maintaining the same basic configuration.
  ///
  /// [name]: Optional new pod name (uses current if null)
  /// [scope]: Optional new scope (uses current if null)
  /// [fallbackFactory]: Optional new fallback factory (uses current if null)
  /// Returns a new ScopedObjectFactory instance with the specified properties
  ///
  /// Example:
  /// ```dart
  /// // Create a factory for a different pod in the same scope
  /// final otherFactory = scopedFactory.copyWith(name: 'otherService');
  ///
  /// // Create a factory for the same pod in a different scope
  /// final sessionFactory = scopedFactory.copyWith(scope: sessionScope);
  /// ```
  /// {@endtemplate}
  ScopedObjectFactory<T> copyWithScope({String? name, PodScope? scope, ObjectFactory<T>? fallbackFactory}) {
    return ScopedObjectFactory<T>(
      name ?? this.name,
      scope ?? this.scope,
      fallbackFactory ?? this.fallbackFactory,
    );
  }
}

/// {@template default_object_provider}
/// Default implementation of [ObjectProvider] in **Jetleaf**.
///
/// This class is responsible for retrieving pods (objects) from the
/// [PodFactory] and exposing them through a consistent provider interface.
///
/// It supports both direct retrieval (via [get]) and streaming (via [stream]).
///
/// ### Example
/// ```dart
/// final provider = DefaultObjectProvider<MyService>(
///   'myServicePod',
///   factory,
///   [ObjectHolder(MyService())],
/// );
///
/// // Retrieve an object
/// final holder = await provider.get();
/// print(holder.object);
///
/// // Stream objects
/// await for (final obj in provider.stream()) {
///   print('Received: ${obj.object}');
/// }
/// ```
///
/// This is part of Jetleaf – a framework which developers can use
/// to build web applications.
/// {@endtemplate}
@Generic(DefaultObjectProvider)
class DefaultObjectProvider<T> extends ObjectProvider<T> {
  /// {@template default_object_provider_pod_name}
  /// The name of the pod managed by this provider.
  ///
  /// This is used to look up the pod in the [PodFactory].
  ///
  /// Example:
  /// ```dart
  /// final provider = DefaultObjectProvider<MyService>('myServicePod', factory, []);
  /// ```
  /// {@endtemplate}
  final String _podName;

  /// {@template default_object_provider_factory}
  /// The [PodFactory] used to resolve and create pod instances.
  ///
  /// The factory handles the lifecycle and instantiation strategy of
  /// all registered pods.
  /// {@endtemplate}
  final PodFactory _factory;

  /// {@template default_object_provider_objects}
  /// The list of pre-registered [ObjectHolder] instances.
  ///
  /// These represent cached or already instantiated pods available
  /// in this provider.
  ///
  /// Example:
  /// ```dart
  /// final objects = [ObjectHolder(MyService())];
  /// final provider = DefaultObjectProvider('myServicePod', factory, objects);
  /// ```
  /// {@endtemplate}
  final List<ObjectHolder<T>> objects;

  /// {@macro default_object_provider}
  DefaultObjectProvider(this._podName, this._factory, this.objects);

  @override
  GenericStream<ObjectHolder<T>> stream() {
    return GenericStream.of(objects);
  }

  @override
  FutureOr<ObjectHolder<T>> get([List<ArgumentValue>? args]) async {
    if(args?.isNotEmpty ?? false) {
      return await _get(args);
    }

    try {
      return super.get(args);
    } catch (e) {
      return await _get(args);
    }
  }

  /// {@template default_object_provider__get}
  /// Resolves a pod instance using the underlying [PodFactory].
  ///
  /// If the pod requires arguments for construction, they can be provided
  /// through the [args] parameter.
  ///
  /// ### Example
  /// ```dart
  /// final holder = await provider._get([
  ///   ArgumentValue('customDependency'),
  /// ]);
  /// print(holder.qualifiedName); // Prints the class name of the pod
  /// ```
  ///
  /// Returns an [ObjectHolder] that wraps the resolved object.
  ///
  /// This is part of Jetleaf – a framework which developers can use
  /// to build web applications.
  /// {@endtemplate}
  Future<ObjectHolder<T>> _get(List<ArgumentValue>? args) async {
    final result = await _factory.getPod<T>(_podName, args);
    final cls = await _factory.getPodClass(_podName);
    return ObjectHolder<T>(result, qualifiedName: cls.getQualifiedName(), packageName: cls.getPackage()?.getName());
  }
}