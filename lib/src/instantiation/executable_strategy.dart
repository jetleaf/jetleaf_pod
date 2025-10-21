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

// import 'package:jetleaf_lang/lang.dart';

// import '../core/abstract_autowire_pod_factory.dart';
// import '../definition/pod_definition.dart';
// import '../helpers/object.dart';

// final class ConstructorResolver {
//   final AbstractAutowirePodFactory factory;

//   ConstructorResolver(this.factory);

//   Future<Object> instantiateUsingFactoryMethod(String podName, PodDefinition pd, List<ArgumentValue>? args) async {
//     // String factoryMethodName = root.factoryMethod.methodName;
//     // Class podClass = getDefinition(root.factoryMethod.podName).type;
//     // Object factoryInstance = await getObject(Class.fromQualifiedName(podClass.getQualifiedName()));
//     // List<ArgumentValue> factoryArgs = List.from(args ?? []);
    
//     // // Cache factory methods for performance
//     // List<Method>? cachedMethods = _factoryMethodCache[podClass];
//     // if (cachedMethods == null) {
//     //   cachedMethods = podClass.getMethods();
//     //   _factoryMethodCache[podClass] = cachedMethods;
//     // }
    
//     // if (cachedMethods.isEmpty) {
//     //   throw PodCreationException.withResource(
//     //     root.description,
//     //     podName,
//     //     "No factory method '$factoryMethodName' found in class '${podClass.getName()}'"
//     //   );
//     // }

//     // final method = cachedMethods.firstWhere((m) => m.getName() == factoryMethodName);
//     // resolveParameterArguments(method.getParameters(), factoryArgs, podName);
    
//     // return await getInstantiationStrategy().byFactory(root, podName, factoryInstance, method, factoryArgs);
//   }

//   Future<Object> autowireConstructor(String podName, PodDefinition pd, List<Constructor>? constructors, List<ArgumentValue>? args) async {
//     // Constructor? constructorToUse;
//     // List<ArgumentValue> argsToUse = List.from(explicitArgs ?? []);
    
//     // if (constructors != null && constructors.isNotEmpty) {
//     //   constructorToUse ??= constructors.find((c) => c.canAcceptArguments(argsToUse.toMap((a) => a.getName() ?? "", (a) => a.getValue()))) ?? constructors.first;
//     // } else {
//     //   Class podClass = root.type;
//     //   List<Constructor> constructors = podClass.getConstructors();
      
//     //   if (constructors.isEmpty) {
//     //     return await getInstantiationStrategy().byDefault(root, podName, argsToUse);
//     //   }
      
//     //   // Choose constructor with most parameters that can be satisfied
//     //   final paramTypes = getInstantiationStrategy().getResolvedArgumentClasses(root, explicitArgs);
//     //   constructorToUse ??= podClass.getBestConstructor(paramTypes);
//     //   constructorToUse ??= constructors.reduce((a, b) => a.getParameterCount() > b.getParameterCount() ? a : b);
//     // }
    
//     // // Resolve constructor arguments
//     // List<Parameter> parameters = constructorToUse.getParameters();
//     // resolveParameterArguments(parameters, argsToUse, podName);
    
//     // return await getInstantiationStrategy().byConstructor(root, podName, constructorToUse, argsToUse);
//   }

//   /// {@macro resolve_parameter_arguments}
//   /// 
//   /// Resolves parameter arguments for method or constructor invocation.
//   /// 
//   /// This method ensures that all required parameters have corresponding
//   /// argument values, resolving dependencies as needed.
//   /// 
//   /// @param parameters The parameters to resolve arguments for
//   /// @param args The existing arguments (will be modified)
//   /// @param podName The name of the pod being created
//   @protected
//   void resolveParameterArguments(List<Parameter> parameters, List<ArgumentValue>? args, String podName) async {
//     for (Parameter param in parameters) {
//       if (args != null) {
//         if (!args.any((a) => a.getName() == param.getName())) {
//           args.add(await _buildArgumentValue(param, podName));
//         }
//       }
//     }
//   }

//   /// {@macro build_argument_value}
//   /// 
//   /// Builds an ArgumentValue for a parameter by resolving its dependency.
//   /// 
//   /// @param param The parameter to build argument for
//   /// @param podName The name of the pod being created
//   /// @return An ArgumentValue containing the resolved dependency
//   Future<ArgumentValue> _buildArgumentValue(Parameter param, String podName) async {
//     final cls = param.getClass();
//     final qualifiedName = cls.getQualifiedName();
//     final packageName = cls.getPackage()?.getName();
//     Object? resolvedArg = cls.isPrimitive() ? param.getDefaultValue() : await resolveDependency(DependencyDescriptor(cls, podName, param.getName(), cls));

//     return ArgumentValue(resolvedArg ?? param.getDefaultValue(), qualifiedName: qualifiedName, name: param.getName(), packageName: packageName);
//   }
// }
import 'package:jetleaf_lang/lang.dart';

import '../definition/pod_definition.dart';
import '../helpers/object.dart';
import 'argument_value_holder.dart';

/// {@template executable_strategy}
/// **Executable Strategy**
///
/// Defines the contract for strategies that determine how a pod
/// (instance) should be created by selecting an appropriate
/// constructor or factory method.  
///
/// This abstraction allows the framework to support multiple
/// instantiation policies (e.g., annotation-driven, autowiring,
/// explicit argument matching).
///
/// # Purpose
/// - Encapsulates the logic of deciding **which executable** (constructor
///   or factory method) to invoke when instantiating a pod.
/// - Provides flexibility so different strategies can be plugged in
///   depending on framework configuration.
/// - Used internally by the [DefaultListablePodFactory] (or equivalents)
///   during pod creation.
///
/// # Common Strategies
/// - **Default constructor strategy**: Always selects the no-arg constructor.
/// - **Annotated strategy**: Selects constructors/methods marked with a
///   specific annotation (e.g., `@Inject`).
/// - **Autowiring strategy**: Resolves arguments automatically from the
///   dependency graph.
/// - **Explicit arguments strategy**: Prefers explicitly provided arguments
///   when available.
///
/// # Example Usage
/// ```dart
/// final strategy = MyAnnotationBasedExecutableStrategy();
/// final holder = await strategy.determineConstructor(
///   rootDef,
///   "myService",
///   rootDef.constructors,
///   [ArgumentValue.positional("db_connection")]
/// );
///
/// print(holder.executable);  // chosen constructor
/// print(holder.arguments);   // resolved arguments
/// ```
///
/// # Notes for Implementors
/// - Must return an [ExecutableHolder] with both the chosen executable
///   and its resolved arguments.
/// - Should fail fast with a clear error if no suitable constructor/factory
///   can be determined.
/// - May use metadata (annotations, profiles, qualifiers) from
///   [RootPodDefinition] to guide selection.
/// {@endtemplate}
abstract interface class ExecutableStrategy {
  /// Determine which constructor should be used for pod creation.
  ///
  /// # Parameters
  /// - [rpd]: The root pod definition containing type and metadata.
  /// - [podName]: The logical name of the pod being instantiated.
  /// - [constructors]: The available constructors for the target class.
  /// - [explicitArgs]: Optional explicitly provided arguments to prefer.
  ///
  /// # Returns
  /// An [ExecutableHolder] containing the chosen constructor and resolved arguments.
  ///
  /// # Throws
  /// - An exception if no valid constructor can be chosen.
  Future<ExecutableHolder> determineConstructor(
    RootPodDefinition rpd,
    String podName,
    List<Constructor>? constructors,
    List<ArgumentValue>? explicitArgs,
  );

  /// Determine which factory method should be used for pod creation.
  ///
  /// # Parameters
  /// - [rpd]: The root pod definition containing type and metadata.
  /// - [podName]: The logical name of the pod being instantiated.
  /// - [explicitArgs]: Optional explicitly provided arguments to prefer.
  ///
  /// # Returns
  /// An [ExecutableHolder] containing the chosen factory method and resolved arguments.
  ///
  /// # Throws
  /// - An exception if no valid factory method can be chosen.
  Future<ExecutableHolder> determineFactoryMethod(
    RootPodDefinition rpd,
    String podName,
    List<ArgumentValue>? explicitArgs,
  );
}