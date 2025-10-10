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

import 'helpers/object.dart';

/// {@template pods_exception}
/// Base exception type for all pod-related errors in JetLeaf.
///
/// This exception is typically thrown when a pod cannot be created,
/// resolved, injected, or initialized properly within the application context.
///
/// It acts as the root of the JetLeaf pod exception hierarchy and may be
/// subclassed to represent more specific errors (e.g., `NoSuchPodDefinitionException`,
/// `PodCreationException`, etc.).
///
/// ---
///
/// ### Example
/// ```dart
/// throw PodsException('Failed to create pod of type MyService');
/// ```
///
/// {@endtemplate}
class PodException extends NestedRuntimeException {
  /// {@macro pods_exception}
  PodException(super.message, [super.cause]);
}

/// {@template no_unique_pod_definition_exception}
/// Exception thrown when multiple pod definitions are found for a given type in the application context.
///
/// This exception typically occurs when trying to retrieve a pod by its type from the application context,
/// but multiple matching pod definitions are found, making it ambiguous which pod to use.
///
/// ---
///
/// ### Example
/// ```dart
/// throw NoUniquePodDefinitionException('Multiple pod definitions found for type MyService');
/// ```
/// {@endtemplate}
class NoUniquePodDefinitionException extends NoSuchPodDefinitionException {
  final int numberOfPodsFound;
  final List<String>? podNamesFound;

  /// Create a new [NoUniquePodDefinitionException] with a type, pod names, and custom message.
  NoUniquePodDefinitionException.byTypeWithNamesAndMessage(
      Class type, List<String> podNamesFound, String message)
      : numberOfPodsFound = podNamesFound.length,
        podNamesFound = List.unmodifiable(podNamesFound),
        super.byTypeWithMessage(type, message);

  /// Create a new [NoUniquePodDefinitionException] with a type and count of pods.
  NoUniquePodDefinitionException.byTypeWithCount(
      Class type, int numberOfPodsFound, String message)
      : numberOfPodsFound = numberOfPodsFound,
        podNamesFound = null,
        super.byTypeWithMessage(type, message);

  /// Create a new [NoUniquePodDefinitionException] with a type and pod names.
  NoUniquePodDefinitionException.byTypeWithNames(
      Class type, List<String> podNamesFound)
      : numberOfPodsFound = podNamesFound.length,
        podNamesFound = List.unmodifiable(podNamesFound),
        super.byTypeWithMessage(
          type,
          "Expected a single candidate for type '${type.getOriginal()}', but found ${podNamesFound.length} matches: ${podNamesFound.join(', ')}. "
          "Disambiguate by requesting by name/qualifier or mark one definition as primary.",
        );

  /// Return the number of pods found when only one matching pod was expected.
  @override
  int getNumberOfPodsFound() => numberOfPodsFound;

  /// Return the names of all pods found when only one matching pod was expected.
  List<String>? getPodNamesFound() => podNamesFound;
}

/// {@template pod_creation_exception}
/// Exception thrown when a pod cannot be created.
///
/// This typically wraps the underlying error or misconfiguration that occurred
/// during the creation of a pod in the context.
///
/// Example:
/// ```dart
/// throw PodCreationException('myService', 'Missing dependency');
/// ```
/// {@endtemplate}
class PodCreationException extends FatalPodException {
  final String? name;
  final String? resourceDescription;
  final List<Throwable>? _relatedCauses;

  /// Create a new [PodCreationException] with a simple message.
  PodCreationException(String msg, {Throwable? cause})
      : name = null,
        resourceDescription = null,
        _relatedCauses = null,
        super(msg, cause);

  /// Create a new [PodCreationException] with a pod name.
  PodCreationException.withPodName(String name, String msg, {Throwable? cause})
      : name = name,
        resourceDescription = null,
        _relatedCauses = null,
        super("Failed to create pod '$name': $msg", cause);

  /// Create a new [PodCreationException] with resource description and pod name.
  PodCreationException.withResource(
    this.resourceDescription,
    this.name,
    String? msg, {
    Throwable? cause,
  })  : _relatedCauses = null,
        super(
          "Failed to create pod '${name ?? '<unknown>'}'${resourceDescription != null ? " (defined in $resourceDescription)" : ""}: ${msg ?? 'unspecified error'}",
          cause,
        );

  /// Return the description of the resource that the pod definition came from, if any.
  String? getResourceDescription() => resourceDescription;

  /// Return the name of the pod requested, if any.
  String? getPodName() => name;

  /// Add a related cause to this pod creation exception,
  /// not being a direct cause of the failure but having occurred
  /// earlier in the creation of the same pod instance.
  void addRelatedCause(Throwable ex) {
    (_relatedCauses ?? <Throwable>[]).add(ex);
  }

  /// Return the related causes, if any.
  List<Throwable>? getRelatedCauses() => _relatedCauses;

  @override
  String toString() {
    final sb = StringBuffer(super.toString());
    if (_relatedCauses != null) {
      for (var relatedCause in _relatedCauses) {
        sb.writeln("\nRelated cause: $relatedCause");
      }
    }
    return sb.toString();
  }

  @override
  bool contains(Class? exType) {
    if (super.contains(exType)) {
      return true;
    }
    if (_relatedCauses != null) {
      for (var relatedCause in _relatedCauses) {
        if (relatedCause.runtimeType == exType) {
          return true;
        }
        if (relatedCause is NestedRuntimeException &&
            relatedCause.contains(exType)) {
          return true;
        }
      }
    }
    return false;
  }
}

/// {@template no_such_pod_definition_exception}
/// Exception thrown when a `PodFactory` is asked for a pod instance by name,
/// and no definition for that pod name exists.
///
/// Example:
/// ```dart
/// throw NoSuchPodDefinitionException('myService');
/// ```
/// {@endtemplate}
class NoSuchPodDefinitionException extends PodException {
  final String? name;
  final ResolvableType? resolvableType;

  /// Create a new [NoSuchPodDefinitionException] by pod name.
  NoSuchPodDefinitionException.byName(String name)
      : name = name,
        resolvableType = null,
        super("No pod named '$name' available in the current context");

  /// Create a new [NoSuchPodDefinitionException] by pod name with custom message.
  NoSuchPodDefinitionException.byNameWithMessage(String name, String message)
      : name = name,
        resolvableType = null,
        super("No pod named '$name' available: $message");

  /// Create a new [NoSuchPodDefinitionException] by type.
  NoSuchPodDefinitionException.byType(Class type)
      : name = null,
        resolvableType = ResolvableType.forClass(type.getOriginal()),
        super("No qualifying pod of type '${type.getOriginal()}' available in the current context");

  /// Create a new [NoSuchPodDefinitionException] by type with custom message.
  NoSuchPodDefinitionException.byTypeWithMessage(Class type, String message)
      : name = null,
        resolvableType = ResolvableType.forClass(type.getOriginal()),
        super("No qualifying pod of type '${type.getOriginal()}' available: $message");

  /// Create a new [NoSuchPodDefinitionException] by resolvable type.
  NoSuchPodDefinitionException.byResolvableType(ResolvableType type)
      : name = null,
        resolvableType = type,
        super("No qualifying pod of type '$type' available in the current context");

  /// Create a new [NoSuchPodDefinitionException] by resolvable type with custom message.
  NoSuchPodDefinitionException.byResolvableTypeWithMessage(
      ResolvableType type, String message)
      : name = null,
        resolvableType = type,
        super("No qualifying pod of type '$type' available: $message");

  /// Return the name of the missing pod, if lookup by name failed.
  String? getPodName() => name;

  /// Return the required type of the missing pod, if lookup by type failed.
  Class? getPodType() => resolvableType?.resolve();

  /// Return the required [ResolvableType] of the missing pod, if lookup by type failed.
  ResolvableType? getResolvableType() => resolvableType;

  /// Number of pods found when only one was expected.
  /// For a normal NoSuchPodDefinitionException, always `0`.
  int getNumberOfPodsFound() => 0;
}

/// {@template pod_creation_not_allowed_exception}
/// Exception thrown when a pod creation is not allowed in the current context.
///
/// This exception typically occurs when trying to create a pod in a context where pod creation is not allowed,
/// such as when the application context is shutting down or when the pod factory is in a state where pod creation is disabled.
///
/// Example:
/// ```dart
/// throw PodCreationNotAllowedException('Pod creation not allowed in current context');
/// ```
/// {@endtemplate}
class PodCreationNotAllowedException extends RuntimeException {
  final String name;

  /// {@macro pod_creation_not_allowed_exception}
  PodCreationNotAllowedException(super.message, {required this.name});
}

/// {@template pod_currently_in_creation_exception}
/// Exception thrown when a pod is currently in the process of being created.
///
/// This exception typically occurs when a pod is being created and another pod
/// depends on it, but the pod is still in the process of being created.
///
/// Example:
/// ```dart
/// throw PodCurrentlyInCreationException('Pod is currently in creation');
/// ```
/// {@endtemplate}
class PodCurrentlyInCreationException extends RuntimeException {
  final String name;

  /// {@macro pod_currently_in_creation_exception}
  PodCurrentlyInCreationException({String? msg, required this.name, Throwable? cause}) : super(msg ?? '''
Requested pod '$name' is currently being created. This commonly indicates:
  * an unresolvable circular dependency, or
  * that the pod factory has not exposed an early reference (early singleton) yet, or
  * an asynchronous initialization step blocking other creations.

Suggested actions: introduce lazy injection, use a provider/factory or proxy, or refactor to break the cycle.
''', cause: cause);
}

/// {@template pod_definition_store_exception}
/// Exception thrown when a pod definition store error occurs.
///
/// This exception typically occurs when a pod definition is being stored in the application context,
/// but an error occurs during the storage process.
///
/// Example:
/// ```dart
/// throw PodDefinitionStoreException('Pod definition store error');
/// ```
/// {@endtemplate}
class PodDefinitionStoreException extends PodCreationException {
  final String name;

  /// {@macro pod_definition_store_exception}
  PodDefinitionStoreException({String? msg, required this.name, String? resourceDescription, Throwable? cause}) : super.withResource(
    resourceDescription,
    name,
    'Failed to register pod definition "$name"${resourceDescription != null ? " (from $resourceDescription)" : ""}: ${msg ?? 'unspecified error'}. Check declaration and uniqueness of the pod name.',
    cause: cause
  );
}

/// {@template pod_is_abstract_exception}
/// Exception thrown when attempting to instantiate a pod that is marked as abstract.
///
/// Abstract pods serve as templates or parent definitions for other pods
/// and cannot be instantiated directly. This exception occurs when the
/// application context tries to create an instance of such a pod.
///
/// ### Example:
/// ```dart
/// // Pod definition marked as abstract
/// @Pod(abstract: true)
/// abstract class BaseService {
///   // Common configuration
/// }
///
/// // This will throw PodIsAbstractException
/// try {
///   final pod = podFactory.getPod<BaseService>();
/// } catch (e) {
///   if (e is PodIsAbstractException) {
///     print('Cannot instantiate abstract pod: ${e.name}');
///   }
/// }
/// ```
/// {@endtemplate}
class PodIsAbstractException extends RuntimeException {
  /// The name of the abstract pod that cannot be instantiated.
  final String name;

  /// {@macro pod_is_abstract_exception}
  PodIsAbstractException(super.message, {required this.name});
}

/// {@template pod_not_of_required_type_exception}
/// Exception thrown when a pod retrieved from the context is not of the expected type.
///
/// This typically occurs when there's a type mismatch between what was requested
/// and what was actually registered in the pod factory. It can happen due to
/// incorrect pod definitions, generic type erasure, or configuration errors.
///
/// ### Example:
/// ```dart
/// // Requesting a specific type
/// try {
///   final service = podFactory.getPod<UserService>('userService');
/// } catch (e) {
///   if (e is PodNotOfRequiredTypeException) {
///     print('Expected: ${e.requiredType}');
///     print('Actual: ${e.actualType}');
///     print('Pod name: ${e.name}');
///   }
/// }
/// ```
///
/// ### Common causes:
/// ```dart
/// // Wrong pod registration
/// @Pod('userService')
/// AdminService createUserService() => AdminService(); // Returns wrong type
///
/// // Generic type issues
/// @Pod()
/// List<String> createList() => <int>[1, 2, 3]; // Type mismatch
/// ```
/// {@endtemplate}
class PodNotOfRequiredTypeException extends RuntimeException {
  /// The name of the pod that has the wrong type.
  final String name;
  
  /// The expected type of the pod.
  final Class requiredType;
  
  /// The actual type of the pod found in the context.
  final Class actualType;

  /// {@macro pod_not_of_required_type_exception}
  PodNotOfRequiredTypeException({required this.name, required this.requiredType, required this.actualType}) : super(
    '''
Pod named '$name' was expected to be of type '${requiredType.getQualifiedName()}'
but was actually registered as '${actualType.getQualifiedName()}'. Verify the registration or request the expected type.
'''
  );
}

/// {@template pod_is_not_a_factory_exception}
/// Exception thrown when a pod is expected to be a [PodProvider] but is not.
///
/// This occurs when the application context expects to work with a factory pod
/// (a pod that produces other pods) but the registered pod doesn't implement
/// the [PodProvider] interface. This is a specialized case of [PodNotOfRequiredTypeException].
///
/// ### Example:
/// ```dart
/// // Expected: A factory pod
/// @Pod('serviceFactory')
/// UserServiceFactory createFactory() => UserServiceFactory();
///
/// // Actual: Regular pod (not a factory)
/// @Pod('serviceFactory') 
/// UserService createService() => UserService(); // Wrong!
///
/// // This will throw PodIsNotAFactoryException
/// try {
///   final factory = podFactory.getPod<PodProvider>('serviceFactory');
/// } catch (e) {
///   if (e is PodIsNotAFactoryException) {
///     print('Pod is not a factory: ${e.name}');
///   }
/// }
/// ```
/// {@endtemplate}
class PodIsNotAProviderException extends PodNotOfRequiredTypeException {
  /// {@macro pod_is_not_a_factory_exception}
  PodIsNotAProviderException(String name, Class actualType) : super(
    name: name,
    requiredType: Class<PodProvider>(null, PackageNames.CORE),
    actualType: actualType
  );
}

/// {@template fatal_pod_exception}
/// Base class for fatal pod-related exceptions that indicate unrecoverable errors.
///
/// Fatal pod exceptions represent serious configuration or system-level problems
/// that prevent the application context from functioning properly. These exceptions
/// typically require immediate attention and often indicate that the application
/// cannot continue normal operation.
///
/// ### Example:
/// ```dart
/// // Custom fatal pod exception
/// class CustomFatalPodException extends FatalPodException {
///   CustomFatalPodException(String message) : super(message);
/// }
///
/// // Handling fatal exceptions
/// try {
///   applicationContext.refresh();
/// } catch (e) {
///   if (e is FatalPodException) {
///     print('Fatal pod error: ${e.message}');
///     // Log and potentially shut down application
///   }
/// }
/// ```
/// {@endtemplate}
class FatalPodException extends PodException {
  /// {@macro fatal_pod_exception}
  FatalPodException(super.message, [super.cause]);

  @override
  String toString() => "FatalPodException: $message${cause != null ? " (cause: $cause)" : ""}";
}

/// {@template factory_pod_not_initialized_exception}
/// Exception thrown when attempting to use a [PodProvider] that hasn't been fully initialized.
///
/// Factory pods go through an initialization process before they can produce
/// other pods. This exception occurs when code tries to access the factory
/// pod's product before the factory itself is ready.
///
/// ### Example:
/// ```dart
/// class MyPodProvider implements PodProvider<MyService> {
///   bool _initialized = false;
///   
///   @override
///   MyService getObject() {
///     if (!_initialized) {
///       throw PodProviderNotInitializedException();
///     }
///     return MyService();
///   }
/// }
///
/// // Usage
/// try {
///   final service = factoryPod.getObject();
/// } catch (e) {
///   if (e is PodProviderNotInitializedException) {
///     print('Factory pod not ready yet');
///   }
/// }
/// ```
/// {@endtemplate}
class PodProviderNotInitializedException extends FatalPodException {
  /// Create a new [PodProviderNotInitializedException] with the default message.
  /// 
  /// {@macro factory_pod_not_initialized_exception}
  PodProviderNotInitializedException()
      : super("PodProvider has not completed initialization and cannot produce objects yet");

  /// Create a new [PodProviderNotInitializedException] with the given message.
  /// 
  /// {@macro factory_pod_not_initialized_exception}
  PodProviderNotInitializedException.withMessage(String msg) : super(msg);
}

/// {@template pod_definition_validation_exception}
/// Exception thrown when a pod definition is invalid during validation.
///
/// This exception is useful in dependency injection containers or frameworks
/// where pod definitions (such as configuration metadata) must meet specific
/// requirements. If validation fails, this exception is raised to indicate
/// what went wrong.
///
/// Example usage:
/// ```dart
/// void validatePodDefinition(String name, Map<String, dynamic> definition) {
///   if (!definition.containsKey('type')) {
///     throw PodDefinitionValidationException(
///       'Missing required "type" property for pod: $name',
///     );
///   }
/// }
///
/// void main() {
///   try {
///     validatePodDefinition('myService', {});
///   } catch (e) {
///     print(e);
///     // Output: PodDefinitionValidationException: Missing required "type" property for pod: myService
///   }
/// }
/// ```
/// {@endtemplate}
class PodDefinitionValidationException extends PodException {
  /// {@macro pod_definition_validation_exception}
  ///
  /// Creates a new [PodDefinitionValidationException] with a [message]
  /// describing the validation failure and an optional [cause] indicating
  /// the underlying error.
  PodDefinitionValidationException(super.message, [super.cause]);

  @override
  String toString() => 'PodDefinitionValidationException: $message';
}

/// {@template scope_not_active_exception}
/// Exception thrown when a pod is requested from a scope that is not active.
///
/// This exception is thrown when a pod is requested from a scope that is not active.
///
/// Example usage:
/// ```dart
/// try {
///   final pod = podFactory.getPod<MyPod>();
/// } catch (e) {
///   if (e is ScopeNotActiveException) {
///     print('Scope not active: ${e.message}');
///   }
/// }
/// ```
/// {@endtemplate}
class ScopeNotActiveException extends PodCreationException {
  final String name;
  final String scopeName;

  /// {@macro scope_not_active_exception}
  ScopeNotActiveException(this.name, this.scopeName, IllegalStateException cause) :
		super.withPodName(
      name,
      "Scope '$scopeName' for pod '$name' is not active on the current thread. "
				"Activate the scope, use a scoped proxy, or avoid referencing this scoped pod from a singleton.",
      cause: cause,
    );

  @override
  String toString() => 'ScopeNotActiveException: $message';
}

/// {@template unsatisfied_dependency_exception}
/// Exception thrown when a dependency is not satisfied for a pod.
///
/// This exception is thrown when a dependency is not satisfied for a pod.
///
/// Example usage:
/// ```dart
/// try {
///   final pod = podFactory.getPod<MyPod>();
/// } catch (e) {
///   if (e is UnsatisfiedDependencyException) {
///     print('Unsatisfied dependency: ${e.message}');
///   }
/// }
/// ```
/// {@endtemplate}
class UnsatisfiedDependencyException extends PodCreationException {
  /// {@macro unsatisfied_dependency_exception}
  UnsatisfiedDependencyException.withResource(
    String? resourceDescription,
    String name,
    String? msg, {
    Throwable? cause,
  })  : super.withPodName(
    name,
    "Unsatisfied dependency while creating pod '$name'"
    "${resourceDescription != null ? " (defined in $resourceDescription)" : ""}: ${msg ?? 'unspecified'}. "
    "Verify that required pods are registered, not ambiguous, and available at creation time.",
    cause: cause,
  );
}

/// {@template pod_definition_override_exception}
/// Exception thrown when a pod definition is overridden.
///
/// This exception is thrown when a pod definition is overridden.
///
/// Example usage:
/// ```dart
/// try {
///   final pod = podFactory.getPod<MyPod>();
/// } catch (e) {
///   if (e is PodDefinitionOverrideException) {
///     print('Pod definition override: ${e.message}');
///   }
/// }
/// ```
/// {@endtemplate}
class PodDefinitionOverrideException extends PodException {
  /// {@macro pod_definition_override_exception}
  PodDefinitionOverrideException(String name) : super("Cannot override pod definition '$name'. Allow definition overriding is disabled");
}