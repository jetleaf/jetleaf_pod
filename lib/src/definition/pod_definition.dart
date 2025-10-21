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

import '../expression/pod_expression.dart';
import '../helpers/enums.dart';
import '../helpers/object.dart';
import 'commons.dart';

/// {@template pod_definition}
/// Defines the **blueprint of a pod** (component) in the dependency injection
/// system.
///
/// A [PodDefinition] encapsulates all metadata required to configure a component:
/// - Its **name** and **type** ([Class])  
/// - How dependencies are **checked** ({@macro dependency_check})  
/// - Its **scope** ({@macro scope_type})  
/// - Its **design role** ({@macro design_role})  
/// - Lifecycle behavior ({@macro lifecycle_design})  
/// - Dependency relationships ([DependencyDesign])  
/// - Property values ([MutablePropertyValues])  
/// - Method overrides ([MethodOverrides])  
/// - Factory methods ([FactoryMethodDesign])  
/// - Autowiring configuration ({@macro autowire_mode})  
/// - Constructor arguments ([ConstructorArgumentValues])  
///
/// This abstraction allows the system to define, manage, and wire components
/// consistently.
///
/// ### Example
/// ```dart
/// final pod = MyPodDefinition(
///   name: "userService",
///   type: Class<OtherService>(),
///   scope: ScopeDescriptor(
///     type: ScopeType.SINGLETON,
///     isSingleton: true,
///     isPrototype: false,
///   ),
///   design: DesignDescriptor(
///     role: DesignRole.APPLICATION,
///     isPrimary: true,
///     isInfrastructure: false,
///   ),
///   lifecycle: LifecycleDesign(
///     isLazy: true,
///     initMethods: ["initialize"],
///     destroyMethods: ["dispose"],
///   ),
///   dependsOn: [DependencyDescriptor("databaseService")],
///   factoryMethod: FactoryMethodDescriptor("UserServicePod", "create"),
///   autowireCandidate: AutowireCandidateDescriptor(
///     autowireCandidate: true,
///     autowireMode: AutowireMode.BY_TYPE,
///   ),
/// );
///
/// print(pod.name); // "userService"
/// print(pod.scope.type); // ScopeType.SINGLETON
/// ```
/// {@endtemplate}
abstract class PodDefinition with EqualsAndHashCode, ToString {
  /// The unique name of the pod (component).
  String name;

  /// The [Class] type that this pod represents.
  /// 
  /// {@macro class}
  Class type;

  /// A description of the pod.
  String? description;

  /// Whether this pod is a provider of other pods.
  bool isPodProvider;

  /// Defines the dependency validation strategy.  
  /// 
  /// {@macro dependency_check}
  DependencyCheck dependencyCheck;

  /// Defines the scope of the pod.  
  /// 
  /// {@macro scope_descriptor}
  ScopeDesign scope;

  /// Defines the design role of the pod.  
  /// 
  /// {@macro design_descriptor}
  DesignDescriptor design;

  /// Defines the lifecycle behavior of the pod.  
  /// 
  /// {@macro lifecycle_design}
  LifecycleDesign lifecycle;

  /// Other dependencies that this pod depends on.
  /// 
  /// {@macro dependency_descriptor}
  List<DependencyDesign> dependsOn;

  /// Mutable property values assigned to this pod.
  /// 
  /// {@macro mutable_property_values}
  MutablePropertyValues propertyValues;

  /// The factory method used to create this pod.
  /// 
  /// {@macro factory_method_descriptor}
  FactoryMethodDesign factoryMethod;

  /// Whether this pod is eligible for proxying.
  bool canProxy = true;

  /// Whether this pod has been resolved before instantiation.
  bool hasBeforeInstantiationResolved = false;

  /// Defines whether this pod is eligible for autowiring.  
  /// 
  /// {@macro autowire_candidate_descriptor}
  AutowireCandidateDescriptor autowireCandidate;

  /// Arguments to be passed to the pod’s constructor.
  /// 
  /// {@macro constructor_argument_values}
  ConstructorArgumentValues executableArgumentValues;

  /// The complete list of annotations discovered on the class
  /// and its meta-annotations.
  ///
  /// This list is populated eagerly during construction and may include:
  /// - Direct annotations (e.g., `@Configuration`, `@Scope`).
  /// - Meta-annotations applied on other annotations (e.g., `@Conditional` inside `@Configuration`).
  final List<Annotation> annotations = [];

  /// The list of annotation classes which the [type] of this pod definition is annotated with.
  /// 
  /// This list is populated eagerly during construction and may include:
  /// - Direct annotations (e.g., `@Configuration - Configuration`, `@Scope - Scope`).
  /// - Meta-annotations applied on other annotations (e.g., `@Conditional - Conditional`).
  final List<Class> annotatedClasses = [];

  /// List of preferred constructors for autowiring.
  /// 
  /// {@macro constructor}
  final List<Constructor> preferredConstructors = [];

  /// Creates a [PodDefinition] with the provided configuration.
  ///
  /// Default values:
  /// - [dependencyCheck] → `DependencyCheck.NONE`
  /// - [scope] → `ScopeType.SINGLETON`
  /// - [design] → `DesignRole.APPLICATION`
  /// - [lifecycle] → defaults to no init/destroy methods
  /// - [autowireCandidate] → enabled with `AutowireMode.NO`
  /// - [factoryMethod] → empty placeholder
  /// - [propertyValues] → empty
  /// - [constructorArgumentValues] → empty
  /// 
  /// {@macro pod_definition}
  PodDefinition({
    this.name = "",
    required this.type,
    this.isPodProvider = false,
    this.description,
    this.dependencyCheck = DependencyCheck.NONE,
    ScopeDesign? scope,
    DesignDescriptor? design,
    LifecycleDesign? lifecycle,
    this.dependsOn = const [],
    MutablePropertyValues? propertyValues,
    FactoryMethodDesign? factoryMethod,
    AutowireCandidateDescriptor? autowireCandidate,
    ConstructorArgumentValues? constructorArgumentValues,
  }) : scope = scope ?? ScopeDesign(
        type: ScopeType.SINGLETON.name,
        isSingleton: true,
        isPrototype: false,
      ),
      design = design ?? DesignDescriptor(
        role: DesignRole.APPLICATION,
        isPrimary: false,
      ),
      lifecycle = lifecycle ?? LifecycleDesign(
        isLazy: false,
        initMethods: const [],
        destroyMethods: const [],
        enforceInitMethod: true,
        enforceDestroyMethod: true,
      ),
      autowireCandidate = autowireCandidate ?? AutowireCandidateDescriptor(
        autowireCandidate: true,
        autowireMode: AutowireMode.NO,
      ),
      propertyValues = propertyValues ?? MutablePropertyValues(),
      executableArgumentValues = constructorArgumentValues ?? ConstructorArgumentValues(),
      factoryMethod = factoryMethod ?? FactoryMethodDesign('', '')
  {
    final visited = <Class>{};

    annotatedClasses.add(type);
    _collectAnnotations(type, visited);
  }

  /// Recursively collects annotations and their meta-annotations
  /// for the given [cls], avoiding cycles with the [visited] set.
  void _collectAnnotations(Class cls, Set<Class> visited) {
    if (visited.contains(cls)) {
      return;
    }
    visited.add(cls);

    for (final annotation in cls.getAllDirectAnnotations()) {
      annotations.add(annotation);
      annotatedClasses.add(annotation.getClass());
      _collectAnnotations(annotation.getClass(), visited);
    }
  }

  /// Returns `true` if this definition has an annotation of type [A].
  ///
  /// ### Example:
  /// ```dart
  /// if (def.hasAnnotation<Scope>()) {
  ///   print("Scoped pod detected");
  /// }
  /// ```
  bool hasAnnotation<A>() => annotations.find((a) => a.getInstance() is A) != null
    || annotatedClasses.find((c) => c.getType() == A) != null
    || annotatedClasses.find((c) => c == Class<A>()) != null;

  /// Returns the annotation of type [A], if present.
  ///
  /// Throws a cast error if the annotation does not exist.
  ///
  /// ### Example:
  /// ```dart
  /// final scope = def.getAnnotation<Scope>();
  /// print(scope.value); // "singleton" or "prototype"
  /// ```
  A? getAnnotation<A>() {
    for (final annotation in annotations) {
      final instance = annotation.getInstance();
      if (instance is A) {
        return instance;
      }
    }

    for (final cls in annotatedClasses) {
      try {
        final instance = cls.newInstance();
        if (instance is A) {
          return instance;
        }
      } catch (e) {
        // ignore
      }
    }
    return null;
  }

  /// Returns a list of annotations of type [A].
  ///
  /// ### Example:
  /// ```dart
  /// final scopes = def.getAnnotations<Scope>();
  /// for (final scope in scopes) {
  ///   print(scope.value); // "singleton" or "prototype"
  /// }
  /// ```
  List<A> getAnnotations<A>() {
    final result = <A>{};
    for (final annotation in annotations) {
      final instance = annotation.getInstance();
      if (instance is A) {
        result.add(instance);
      }
    }

    for (final cls in annotatedClasses) {
      try {
        final instance = cls.newInstance();
        if (instance is A) {
          result.add(instance);
        }
      } catch (e) {
        // ignore
      }
    }

    return result.toList();
  }

  /// Returns `true` if this definition is non-instantiable.
  /// 
  /// A non-instantiable definition is one that cannot be instantiated
  /// directly, such as a pod definition without a factory method or definition with an abstract class.
  /// 
  /// ### Example
  /// ```dart
  /// if (podDef.isAbstractAndNoFactory()) {
  ///   print("Pod is non-instantiable.");
  /// }
  /// ```
  bool isAbstractAndNoFactory() {
    final hasFactoryConstructor = type.getConstructors().any((c) => c.isFactory());
    final hasFactoryMethod = factoryMethod.methodName.isNotEmpty || factoryMethod.podName.isNotEmpty;

    // Non-instantiable if abstract and no factory constructor and no factory method
    if (type.isAbstract() && !hasFactoryConstructor && !hasFactoryMethod) {
      return true;
    }

    return false;
  }

  /// {@template pod_definition_has_constructor_argument_values}
  /// Returns whether this pod definition contains any
  /// **constructor argument values**.
  ///
  /// This is used to check if a pod is expected to be
  /// constructed with specific arguments during instantiation.
  ///
  /// ### Example
  /// ```dart
  /// if (podDef.hasConstructorArgumentValues()) {
  ///   print("Pod requires constructor arguments.");
  /// }
  /// ```
  /// {@endtemplate}
  bool hasConstructorArgumentValues() => !executableArgumentValues.isEmpty();

  /// Returns whether this pod definition has any preferred constructors.
  /// 
  /// This is used to check if a pod is expected to be
  /// constructed with specific arguments during instantiation.
  /// 
  /// ### Example
  /// ```dart
  /// if (podDef.hasPreferredConstructors()) {
  ///   print("Pod has preferred constructors.");
  /// }
  /// ```
  bool hasPreferredConstructors() => !preferredConstructors.isEmpty;

  /// {@template pod_definition_has_property_values}
  /// Returns whether this pod definition contains any
  /// **property values**.
  ///
  /// Property values represent setter-based injection or field
  /// initialization for the pod after it is constructed.
  ///
  /// ### Example
  /// ```dart
  /// if (podDef.hasPropertyValues()) {
  ///   print("Pod has property values to apply.");
  /// }
  /// ```
  /// {@endtemplate}
  bool hasPropertyValues() => propertyValues.isNotEmpty;

  /// {@template pod_definition_clone}
  /// Creates and returns a **deep clone** of this pod definition.
  ///
  /// A cloned pod definition is typically used when:
  /// - Reusing configuration across multiple pods
  /// - Creating prototype-scoped pods
  /// - Applying modifications without affecting the original definition
  ///
  /// Subclasses must implement this method to ensure all fields
  /// are copied correctly.
  ///
  /// ### Example
  /// ```dart
  /// class RootPodDefinition extends PodDefinition {
  ///   RootPodDefinition({required super.name, required super.type});
  ///
  ///   @override
  ///   PodDefinition clone() {
  ///     return RootPodDefinition(name: name, type: type);
  ///   }
  /// }
  ///
  /// final rootDef = RootPodDefinition(name: "root", type: Class<OtherService>());
  /// final cloned = rootDef.clone();
  /// print(cloned.name); // "root"
  /// ```
  /// {@endtemplate}
  PodDefinition clone();

  @override
  List<Object?> equalizedProperties() => [
    name,
    type,
    dependencyCheck,
    scope,
    design,
    lifecycle,
    dependsOn,
    propertyValues,
    factoryMethod,
    autowireCandidate,
    executableArgumentValues,
    isPodProvider,
  ];

  @override
  ToStringOptions toStringOptions() => ToStringOptions()
    ..customParameterNames = [
      'name',
      'type',
      'dependencyCheck',
      'scope',
      'design',
      'lifecycle',
      'dependsOn',
      'propertyValues',
      'factoryMethod',
      'autowireCandidate',
      'constructorArgumentValues',
      'isPodProvider',
    ]
    ..includeClassName = true;
}

// ----------------------------------------------------------------------------------------------------------
// ABSTRACT POD DEFINITION
// ----------------------------------------------------------------------------------------------------------

/// {@template abstract_pod_definition}
/// An abstract base class for pod definitions that extends [PodDefinition].
///
/// [AbstractPodDefinition] adds mutable state and utility methods
/// to support advanced features such as:
///
/// - Tracking whether a pod definition is **stale**  
/// - Marking whether a pod is a **provider (factory)** of other pods  
/// - Attaching a [PodExpression] to represent its creation logic  
/// - Checking whether lifecycle methods like `destroy` exist  
///
/// Typically, concrete pod definitions (e.g., `RootPodDefinition`)
/// extend this class to customize behavior while leveraging the
/// shared mutability features.
///
/// ### Example
/// ```dart
/// class RootPodDefinition extends AbstractPodDefinition {
///   RootPodDefinition() : super(name: "root", type: Class<OtherService>());
/// }
///
/// final rootDef = RootPodDefinition();
/// rootDef.setIsStale(true);
///
/// if (rootDef.getIsStale()) {
///   print("Pod definition needs re-evaluation");
/// }
///
/// rootDef.setIsPodProvider(true);
/// print(rootDef.getIsPodProvider()); // true
/// ```
/// {@endtemplate}
abstract class AbstractPodDefinition extends PodDefinition {
  bool _isStale = false;
  Object? _podExpression;
  String? resolvedDestroyMethodName;

  /// The instance of the pod definition.
  /// 
  /// This is used to store the instance of the pod definition
  /// when it is created.
  Object? instance;

  /// Creates an [AbstractPodDefinition] with a given [name] and [type].
  /// 
  /// - [name]: The name of the pod.
  /// - [type]: The type of the pod.
  /// 
  /// {@macro abstract_pod_definition}
  AbstractPodDefinition({required super.type, this.instance, this.resolvedDestroyMethodName});

  /// {@template root_pod_definition_is_stale}
  /// Returns whether this pod definition is **stale**.
  ///
  /// A stale pod definition indicates that it was modified
  /// after being merged. This means the merged version
  /// may need to be **re-evaluated** or rebuilt.
  ///
  /// ### Example
  /// ```dart
  /// final rootDef = RootPodDefinition();
  ///
  /// rootDef.setIsStale(true);
  /// if (rootDef.getIsStale()) {
  ///   // Pod definition has been modified
  ///   rootDef.setIsStale(false);
  /// }
  /// ```
  /// {@endtemplate}
  bool getIsStale() => _isStale;

  /// {@template root_pod_definition_set_stale}
  /// Marks this pod definition as **stale** or not.
  ///
  /// When marked stale, dependency resolution may re-run
  /// to reflect the updated configuration.
  ///
  /// - [value]: `true` to mark as stale, `false` otherwise.
  ///
  /// ### Example
  /// ```dart
  /// final rootDef = RootPodDefinition();
  /// rootDef.setIsStale(true);
  /// ```
  /// {@endtemplate}
  void setIsStale(bool value) => _isStale = value;

  /// {@template root_pod_definition_get_pod_expression}
  /// Returns the [PodExpression] representing this pod’s creation logic.
  ///
  /// The expression may be `null` if none was set.
  ///
  /// ### Example
  /// ```dart
  /// final expr = podDef.getPodExpression();
  /// if (expr != null) {
  ///   print("Pod creation expression: ${expr.code}");
  /// }
  /// ```
  /// {@endtemplate}
  Object? getPodExpression() => _podExpression;

  /// {@template root_pod_definition_set_pod_expression}
  /// Attaches a [PodExpression] representing this pod’s creation logic.
  ///
  /// - [podExpression]: The expression to assign.
  ///
  /// ### Example
  /// ```dart
  /// podDef.setPodExpression(Object("MyService()"));
  /// ```
  /// {@endtemplate}
  void setPodExpression(Object podExpression) {
    _podExpression = podExpression;
  }

  /// {@template root_pod_definition_has_destroy_method}
  /// Checks whether this pod definition defines a **destroy method**
  /// with the given [methodName].
  ///
  /// This is useful for lifecycle management to determine whether
  /// cleanup should be invoked at shutdown.
  ///
  /// ### Example
  /// ```dart
  /// final podDef = RootPodDefinition();
  ///
  /// if (podDef.hasDestroyMethod("dispose")) {
  ///   // Cleanup logic exists, handle accordingly
  /// }
  /// ```
  /// {@endtemplate}
  bool hasDestroyMethod(String methodName) => lifecycle.destroyMethods.contains(methodName);

  @override
  List<Object?> equalizedProperties() {
    return [
      ...super.equalizedProperties(),
      _isStale,
      _podExpression
    ];
  }

  @override
  ToStringOptions toStringOptions() => super.toStringOptions()
    ..customParameterNames = [
      ...super.toStringOptions().customParameterNames?.toList() ?? [],
      'isStale',
      'podExpression'
    ]
    ..includeClassName = true;
}

// ----------------------------------------------------------------------------------------------------------
// ROOT POD DEFINITION
// ----------------------------------------------------------------------------------------------------------

/// {@template root_pod_definition}
/// A concrete implementation of [AbstractPodDefinition] that serves as
/// the **default pod definition** in the system.
///
/// [RootPodDefinition] is commonly used as the base representation of a pod’s
/// configuration and lifecycle. It supports cloning, copying from another
/// [AbstractPodDefinition], and extending with additional metadata.
///
/// ### Example
/// ```dart
/// final rootDef = RootPodDefinition(
///   name: "myService",
///   type: Class<OtherService>(),
/// );
///
/// rootDef.setIsStale(true);
/// if (rootDef.getIsStale()) {
///   print("Pod is stale and needs re-evaluation.");
/// }
///
/// // Cloning
/// final cloned = rootDef.clone();
/// print(cloned.name); // "myService"
/// ```
/// {@endtemplate}
final class RootPodDefinition extends AbstractPodDefinition {
  /// {@macro root_pod_definition}
  RootPodDefinition({required super.type});

  /// {@template root_pod_definition_from}
  /// Creates a new [RootPodDefinition] by copying the state of another
  /// [AbstractPodDefinition].
  ///
  /// This is useful for scenarios where you want to transform or re-wrap
  /// an existing pod definition while keeping all its configuration intact.
  ///
  /// ### Example
  /// ```dart
  /// final other = RootPodDefinition(name: "other", type: Class<OtherService>());
  /// other.setIsPodProvider(true);
  ///
  /// final copy = RootPodDefinition.from(other);
  /// print(copy.getIsPodProvider()); // true
  /// ```
  /// {@endtemplate}
  factory RootPodDefinition.from(PodDefinition other) {
    final result = RootPodDefinition(type: other.type)
      ..name = other.name
      ..description = other.description
      ..scope = other.scope
      ..design = other.design
      ..lifecycle = other.lifecycle
      ..dependsOn = other.dependsOn
      ..propertyValues = other.propertyValues
      ..factoryMethod = other.factoryMethod
      ..autowireCandidate = other.autowireCandidate
      ..executableArgumentValues = other.executableArgumentValues
      ..isPodProvider = other.isPodProvider
      ..dependencyCheck = other.dependencyCheck;

    if (other is AbstractPodDefinition) {
      result._isStale = other._isStale;
      result._podExpression = other._podExpression;
    }

    return result;
  }

  @override
  PodDefinition clone() => RootPodDefinition.from(this);
}