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

/// {@template aware_pod_processor}
/// The `AwarePodProcessor` is an abstract interface class provided by **Jetleaf**.
///
/// This interface is designed to be implemented by classes that handle or 
/// process "Pods" in the Jetleaf ecosystem. A "Pod" can be considered 
/// as a modular unit in a Jetleaf application, often used to encapsulate 
/// state, logic, or services.
///
/// Since this is an abstract interface, it does not provide any 
/// implementation by itself. Instead, it defines a contract that concrete 
/// classes must follow when implementing pod processing features.
///
/// ### Usage Example:
/// ```dart
/// import 'package:jetleaf/jetleaf.dart';
///
/// // A custom implementation of the AwarePodProcessor interface.
/// class LoggingPodProcessor implements AwarePodProcessor {
///   void logPodProcessing(String podId) {
///     print('Processing pod with ID: $podId');
///   }
/// }
///
/// void main() {
///   final processor = LoggingPodProcessor();
///   processor.logPodProcessing('user_pod_001');
/// }
/// ```
///
/// In this example, the `LoggingPodProcessor` implements `AwarePodProcessor` 
/// and provides a custom behavior for handling pods (logging in this case).
///
/// Developers are expected to extend or implement this interface when 
/// they want to provide custom logic for pod processing within their 
/// Jetleaf applications.
/// {@endtemplate}
abstract class PodAwareProcessor {
  /// {@macro pod_post_processor}
  /// 
  /// Apply this post-processor to the given new pod instance before
  /// any pod initialization callbacks.
  /// 
  /// The pod will already be populated with property values at this point.
  /// The returned pod instance may be a wrapper around the original.
  /// 
  /// ## Parameters
  /// 
  /// - [pod]: The new pod instance
  /// - [podClass]: The class of the pod
  /// - [name]: The name of the pod
  /// 
  /// ## Return Value
  /// 
  /// Returns the pod instance to use, either the original or a wrapped one.
  /// If null is returned, subsequent post-processors will not be invoked.
  Future<Object?> processBeforeInitialization(Object pod, Class podClass, String name) async => null;

  /// Apply this post-processor to the given new pod instance after
  /// any pod initialization callbacks.
  /// 
  /// The pod will already be initialized at this point. The returned
  /// pod instance may be a wrapper around the original.
  /// 
  /// ## Parameters
  /// 
  /// - [pod]: The new pod instance
  /// - [podClass]: The class of the pod
  /// - [name]: The name of the pod
  /// 
  /// ## Return Value
  /// 
  /// Returns the pod instance to use, either the original or a wrapped one.
  /// If null is returned, subsequent post-processors will not be invoked.
  Future<Object?> processAfterInitialization(Object pod, Class podClass, String name) async => null;

  /// Determine whether this post-processor should be applied to the given pod.
  /// 
  /// ## Parameters
  /// 
  /// - [pod]: The new pod instance
  /// - [podClass]: The class of the pod
  /// - [name]: The name of the pod
  /// 
  /// ## Return Value
  /// 
  /// Returns true if this post-processor should be applied to the given pod,
  /// false otherwise.
  Future<bool> shouldProcessBeforeInitialization(Object pod, Class podClass, String name) async => false;
}

// ---------------------------------------------------------------------------------------------------------
// InstantiationAwarePodProcessor
// ---------------------------------------------------------------------------------------------------------

/// {@template pod_instantiation_aware_processor}
/// An abstract class in **Jetleaf** that builds upon
/// [AwarePodProcessor].
///
/// This allows you to hook into the **instantiation phase** of a Pod lifecycle,
/// providing extension points to:
/// - Intercept **before instantiation**.
/// - Intercept **after instantiation**.
/// - Process or override **property values** before they are applied.
///
/// Example:
/// ```dart
/// class CustomInstantiationProcessor
///     implements InstantiationAwarePodProcessor {
///   @override
///   Object? beforeInstantiation(Class podClass, String name) {
///     print('Preparing to create pod: $name of type ${podClass.name}');
///     return null;
///   }
///
///   @override
///   bool afterInstantiation(Object pod, Class podClass, String name) {
///     print('Pod $name created successfully.');
///     return true;
///   }
///
///   @override
///   PropertyValues? processPropertyValues(
///       PropertyValues pvs, Object pod, String name) {
///     // Modify or inspect property values before applying
///     return pvs;
///   }
///
///   @override
///   Object? beforeInitialization(Object pod, Class podClass, String name) => pod;
///
///   @override
///   Object? afterInitialization(Object pod, Class podClass, String name) => pod;
/// }
/// ```
/// {@endtemplate}
abstract class InstantiationAwarePodProcessor extends PodAwareProcessor {
  /// Apply this post-processor before the target pod gets instantiated.
  /// 
  /// The returned pod object may be a proxy to use instead of the target pod,
  /// effectively suppressing default instantiation of the target pod.
  /// 
  /// ## Parameters
  /// 
  /// - [podClass]: The class of the pod to be instantiated
  /// - [name]: The name of the pod
  /// 
  /// ## Return Value
  /// 
  /// Returns the pod object to expose instead of a default instance of the
  /// target pod, or null to proceed with default instantiation.
  Future<Object?> processBeforeInstantiation(Class podClass, String name) async => null;

  /// Perform operations after the pod has been instantiated but before
  /// property population.
  /// 
  /// This is the ideal callback for performing custom field injection on
  /// the given pod instance, right before property population.
  /// 
  /// ## Parameters
  /// 
  /// - [pod]: The pod instance created
  /// - [name]: The name of the pod
  /// - [podClass]: The class of the pod
  /// 
  /// ## Return Value
  /// 
  /// Returns true if properties should be set on the pod, false if property
  /// population should be skipped.
  Future<bool> processAfterInstantiation(Object pod, Class podClass, String name) async => true;

  /// Determine the candidate constructors to use for the given pod.
  /// 
  /// This method is called before pod instantiation to allow the post-processor
  /// to determine which constructors should be considered for autowiring.
  /// 
  /// ## Parameters
  /// 
  /// - [podClass]: The raw class of the pod
  /// - [name]: The name of the pod
  /// 
  /// ## Return Value
  /// 
  /// Returns the candidate constructors, or null to use the default constructors
  Future<List<Constructor>?> determineCandidateConstructors(Class podClass, String name) async => null;

  /// Determine the arguments to use for the given pod.
  /// 
  /// This method is called before pod instantiation to allow the post-processor
  /// to determine which arguments should be used for autowiring.
  /// 
  /// ## Parameters
  /// 
  /// - [podName]: The name of the pod
  /// - [executable]: The executable to use
  /// - [parameters]: The parameters to use
  /// 
  /// ## Return Value
  /// 
  /// Returns the arguments to use, or null to use the default arguments
  Future<List<ArgumentValue>?> determineCandidateArguments(String podName, Executable executable, List<Parameter> parameters) async => null;

  /// Post-process the given property values before the factory applies them
  /// to the given pod.
  /// 
  /// This callback allows for resolving additional dependencies or modifying
  /// existing property values before they are applied to the pod.
  /// 
  /// ## Parameters
  /// 
  /// - [pvs]: The property values that the factory is about to apply
  /// - [pod]: The pod instance created
  /// - [podClass]: The class of the pod
  /// - [name]: The name of the pod
  /// 
  /// ## Return Value
  /// 
  /// Returns the actual property values to apply to the given pod, or null
  /// to skip property population entirely.
  Future<PropertyValues?> processPropertyValues(PropertyValues pvs, Object pod, Class podClass, String name) async => pvs;

  /// {@template early_pod_reference}
  /// **Early Pod Reference**
  ///
  /// Provides an opportunity to return a reference to a pod *before* its
  /// full lifecycle initialization has completed.  
  ///
  /// # Purpose
  /// - Enables support for circular dependencies by exposing a partially
  ///   constructed pod to other dependents.
  /// - Acts as a hook point where frameworks can intercept and substitute
  ///   proxy instances, such as for:
  ///   - AOP (aspect-oriented programming) proxies
  ///   - Scoped proxies (e.g., request/session scoped)
  ///   - Lazy-initialization wrappers
  ///
  /// # Behavior
  /// - By default, simply returns the given [pod] unchanged.
  /// - Subclasses or frameworks may override this to return an alternate
  ///   proxy object.
  /// - The returned reference is used by dependents until full initialization
  ///   of the pod is complete.
  ///
  /// # Parameters
  /// - [podHolder]: The raw pod instance just created.
  /// - [podClass]: The reflective class metadata for the pod.
  /// - [name]: The logical pod name.
  ///
  /// # Example
  /// ```dart
  /// final myService = await getEarlyPodReference(
  ///   rawInstance,
  ///   Class.of<MyService>(),
  ///   "myService",
  /// );
  ///
  /// // myService may be a proxy if overridden
  /// print(myService.runtimeType);
  /// ```
  ///
  /// # Notes
  /// - The default implementation is identity (`=> pod`).
  /// - Framework users rarely call this directly; it is used internally
  ///   during pod creation.
  /// - Implementors must be careful not to break initialization contracts.
  /// {@endtemplate}
  Future<ObjectHolder<Object>> getEarlyPodReference(ObjectHolder<Object> podHolder, Class podClass, String name) async => podHolder;
}

// ---------------------------------------------------------------------------------------------------------
// DestructionAwarePodProcessor
// ---------------------------------------------------------------------------------------------------------

/// {@template pod_destruction_aware_processor}
/// An abstract class in **Jetleaf** that provides lifecycle hooks for Pod
/// **destruction**.
///
/// It allows developers to:
/// - Run logic **before a Pod is destroyed**.
/// - Run cleanup actions **after a Pod is destroyed**.
/// - Determine whether a Pod **requires destruction**.
///
/// Example:
/// ```dart
/// class CleanupProcessor implements DestructionAwarePodProcessor {
///   @override
///   void beforeDestruction(Object pod, Class podClass, String name) {
///     print('Cleaning up resources for pod: $name');
///   }
///
///   @override
///   void afterDestruction(Object pod, Class podClass, String name) {
///     print('Pod $name destroyed.');
///   }
///
///   @override
///   bool requiresDestruction(Object pod, Class podClass, String name) {
///     // Example: only destroy if pod implements Disposable
///     return pod is Disposable;
///   }
/// }
/// ```
/// {@endtemplate}
abstract class DestructionAwarePodProcessor extends PodAwareProcessor {
  /// Apply this post-processor to the given pod instance before its
  /// destruction, e.g. invoking custom destruction callbacks.
  /// 
  /// Like DisposablePod's destroy and a custom destroy method, this callback
  /// will only apply to pods which the container fully manages the lifecycle for.
  /// 
  /// ## Parameters
  /// 
  /// - [pod]: The pod instance to be destroyed
  /// - [podClass]: The class of the pod
  /// - [name]: The name of the pod
  Future<void> processBeforeDestruction(Object pod, Class podClass, String name);

  /// Apply this post-processor to the given pod instance after its
  /// destruction, e.g. invoking custom destruction callbacks.
  /// 
  /// ## Parameters
  /// 
  /// - [pod]: The pod instance to be destroyed
  /// - [podClass]: The class of the pod
  /// - [name]: The name of the pod
  Future<void> processAfterDestruction(Object pod, Class podClass, String name);

  /// Determine whether the given pod instance requires destruction by this
  /// post-processor.
  /// 
  /// The default implementation returns true.
  /// 
  /// ## Parameters
  /// 
  /// - [pod]: The pod instance to check
  /// - [podClass]: The class of the pod
  /// - [name]: The name of the pod
  /// 
  /// ## Return Value
  /// 
  /// Returns true if processBeforeDestruction should be called for this
  /// pod instance, false otherwise.
  Future<bool> requiresDestruction(Object pod, Class podClass, String name) async => true;
}