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

import '../helpers/enums.dart';

/// {@template dependency_descriptor}
/// Describes a dependency required by a component or pod.
///
/// This class is used to specify the **name** of the dependency, an optional
/// **qualifier** (to disambiguate multiple beans of the same type), and whether
/// the dependency is **required**.
///
/// ### Example
/// ```dart
/// final descriptor = DependencyDesign(
///   "databaseService",
/// );
///
/// print(descriptor.name); // "databaseService"
/// ```
/// {@endtemplate}
class DependencyDesign with EqualsAndHashCode, ToString {
  /// The unique name of the dependency being described.
  String? name;

  /// Whether this dependency is a prototype in a singleton scope.
  /// 
  /// This is used to determine whether the dependency should be created
  /// as a new instance each time it is requested, or whether it should be
  /// shared across all requests.
  bool prototypeInSingleton;

  /// Creates a [DependencyDesign] with the given [name],
  /// optional [qualifier], and required flag.
  /// 
  /// {@macro dependency_descriptor}
  DependencyDesign({this.name, this.prototypeInSingleton = false});

  @override
  List<Object?> equalizedProperties() => [name, prototypeInSingleton];

  @override
  ToStringOptions toStringOptions() => ToStringOptions()
    ..customParameterNames = ['name', 'prototypeInSingleton']
    ..includeClassName = true;
}

/// {@template lifecycle_design}
/// Describes lifecycle behavior of a component, such as initialization
/// and destruction methods.
///
/// This class allows you to specify whether the component should be **lazy-loaded**,
/// which methods should be called at **initialization** and **destruction**, and
/// whether those lifecycle methods are **enforced**.
///
/// ### Example
/// ```dart
/// final lifecycle = LifecycleDesign(
///   isLazy: true,
///   initMethods: ["initDatabase"],
///   destroyMethods: ["closeDatabase"],
///   enforceInitMethod: true,
///   enforceDestroyMethod: true,
/// );
///
/// print(lifecycle.isLazy); // true
/// print(lifecycle.initMethods); // ["initDatabase"]
/// ```
/// {@endtemplate}
class LifecycleDesign with EqualsAndHashCode, ToString {
  /// Whether the component should be lazily initialized.
  bool? isLazy;

  /// Methods to be executed when the component is initialized.
  List<String> initMethods;

  /// Methods to be executed when the component is destroyed.
  List<String> destroyMethods;

  /// Whether initialization methods must be present.
  bool enforceInitMethod;

  /// Whether destruction methods must be present.
  bool enforceDestroyMethod;

  /// Creates a [LifecycleDesign] with optional lifecycle configurations.
  /// 
  /// {@macro lifecycle_design}
  LifecycleDesign({
    this.isLazy,
    this.initMethods = const [],
    this.destroyMethods = const [],
    this.enforceInitMethod = true,
    this.enforceDestroyMethod = true,
  });

  @override
  List<Object?> equalizedProperties() => [isLazy, initMethods, destroyMethods];

  @override
  ToStringOptions toStringOptions() => ToStringOptions()
    ..customParameterNames = ['isLazy', 'initMethods', 'destroyMethods']
    ..includeClassName = true;
}

/// {@template factory_method_descriptor}
/// Describes a **factory method** used to create a pod (component).
///
/// This includes the **name of the pod** and the **method name**
/// that acts as the factory.
///
/// ### Example
/// ```dart
/// final factory = FactoryMethodDesign("UserPod", "createUser");
///
/// print(factory.podName); // "UserPod"
/// print(factory.methodName); // "createUser"
/// ```
/// {@endtemplate}
class FactoryMethodDesign with EqualsAndHashCode, ToString {
  /// The name of the pod (component) this factory belongs to.
  String podName;

  /// The name of the factory method to invoke.
  String methodName;

  /// The [Class] type that this pod factory method belongs to.
  /// 
  /// Mostly for pods that is not designed as a class but a factory method.
  Class? factoryType;

  /// Creates a [FactoryMethodDesign] for the given [podName] and [methodName].
  /// 
  /// {@macro factory_method_descriptor}
  FactoryMethodDesign(this.podName, this.methodName, [this.factoryType]);

  /// Returns the factory method for this pod definition.
  /// 
  /// ### Example
  /// ```dart
  /// final factoryMethod = factoryMethodDesign.getFactoryMethod();
  /// if (factoryMethod != null) {
  ///   print("Factory method: ${factoryMethod.getName()}");
  /// }
  /// ```
  Method? getFactoryMethod() => factoryType?.getMethod(methodName);

  @override
  List<Object?> equalizedProperties() => [podName, methodName];

  @override
  ToStringOptions toStringOptions() => ToStringOptions()
    ..customParameterNames = ['podName', 'methodName']
    ..includeClassName = true;
}

/// {@template scope_descriptor}
/// Describes the **scope configuration** of a component.
///
/// A scope determines the **lifecycle behavior** of the component.
/// See {@macro scope_type}.
///
/// ### Example
/// ```dart
/// final scope = ScopeDesign(
///   type: ScopeType.SINGLETON,
///   isSingleton: true,
///   isPrototype: false,
/// );
///
/// print(scope.type); // ScopeType.SINGLETON
/// print(scope.isSingleton); // true
/// ```
/// {@endtemplate}
class ScopeDesign with EqualsAndHashCode, ToString {
  /// The [ScopeType] of this descriptor.  
  /// See {@macro scope_type}.
  String type;

  /// Whether the scope is **singleton**.
  bool isSingleton;

  /// Whether the scope is **prototype**.
  bool isPrototype;

  /// Creates a [ScopeDesign] with the given [type],
  /// [isSingleton], and [isPrototype] flags.
  /// 
  /// {@macro scope_descriptor}
  ScopeDesign({
    required this.type,
    required this.isSingleton,
    required this.isPrototype,
  });

  /// Creates a [ScopeDesign] with the given [type] flag.
  /// 
  /// {@macro scope_descriptor}
  ScopeDesign.type(this.type) : isPrototype = type.equalsIgnoreCase(ScopeType.PROTOTYPE.name), isSingleton = type.equalsIgnoreCase(ScopeType.SINGLETON.name);

  @override
  List<Object?> equalizedProperties() => [type, isSingleton, isPrototype];

  @override
  ToStringOptions toStringOptions() => ToStringOptions()
    ..customParameterNames = ['type', 'isSingleton', 'isPrototype']
    ..includeClassName = true;
}

/// {@template design_descriptor}
/// Describes the **design role configuration** of a component.
///
/// A design role indicates whether a component is **application-level**,
/// **supporting**, or **infrastructure-related**.  
/// See {@macro design_role}.
///
/// ### Example
/// ```dart
/// final design = DesignDescriptor(
///   role: DesignRole.SUPPORT,
///   isPrimary: false,
///   isInfrastructure: true,
/// );
///
/// print(design.role); // DesignRole.SUPPORT
/// print(design.isInfrastructure); // true
/// ```
/// {@endtemplate}
class DesignDescriptor with EqualsAndHashCode, ToString {
  /// The [DesignRole] assigned to the component.  
  /// See {@macro design_role}.
  DesignRole role;

  /// Whether the component is marked as **primary**.
  bool isPrimary;

  /// The order of the component.
  int? order;

  /// Creates a [DesignDescriptor] with the given [role],
  /// [isPrimary], and [isInfrastructure] flags.
  /// 
  /// {@macro design_descriptor}
  DesignDescriptor({required this.role, required this.isPrimary, this.order});

  /// Whether the component is marked as **infrastructure**.
  bool get isInfrastructure => role == DesignRole.INFRASTRUCTURE;

  @override
  List<Object?> equalizedProperties() => [role, isPrimary, isInfrastructure, order];

  @override
  ToStringOptions toStringOptions() => ToStringOptions()
    ..customParameterNames = ['role', 'isPrimary', 'isInfrastructure', 'order']
    ..includeClassName = true;
}

/// {@template autowire_candidate_descriptor}
/// Describes whether a component is eligible for **autowiring**.
///
/// Autowiring automatically injects dependencies into a component.
/// This descriptor includes a flag indicating if the component
/// is an **autowire candidate**, and the [AutowireMode] to use.  
/// See {@macro autowire_mode}.
///
/// ### Example
/// ```dart
/// final candidate = AutowireCandidateDescriptor(
///   autowireCandidate: true,
///   autowireMode: AutowireMode.BY_TYPE,
/// );
///
/// print(candidate.autowireCandidate); // true
/// print(candidate.autowireMode); // AutowireMode.BY_TYPE
/// ```
/// {@endtemplate}
class AutowireCandidateDescriptor with EqualsAndHashCode, ToString {
  /// Whether the component is eligible for autowiring.
  bool autowireCandidate;

  /// The [AutowireMode] used for this component.  
  /// See {@macro autowire_mode}.
  AutowireMode autowireMode;

  /// Creates an [AutowireCandidateDescriptor] with the given [autowireCandidate] flag
  /// and [autowireMode].
  /// 
  /// {@macro autowire_candidate_descriptor}
  AutowireCandidateDescriptor({
    required this.autowireCandidate,
    required this.autowireMode,
  });

  @override
  List<Object?> equalizedProperties() => [autowireCandidate, autowireMode];

  @override
  ToStringOptions toStringOptions() => ToStringOptions()
    ..customParameterNames = ['autowireCandidate', 'autowireMode']
    ..includeClassName = true;
}