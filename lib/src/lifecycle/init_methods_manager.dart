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

import '../definition/pod_definition.dart';
import '../exceptions.dart';
import 'lifecycle.dart';

/// {@template init_methods_manager}
/// Manages the initialization lifecycle of pods in the Jetleaf IoC container.
///
/// The `InitMethodsManager` handles the invocation of initialization methods
/// for pods, including:
/// - Built-in lifecycle interfaces (`InitializingPod`, `SmartInitializingSingleton`)
/// - Custom initialization methods defined in pod definitions
/// - Proper error handling and logging
///
/// This class separates initialization concerns from the main factory logic,
/// providing a clean and focused approach to pod lifecycle management.
///
/// ### Example
/// ```dart
/// final manager = InitMethodsManager();
/// await manager.invokeInitMethods('userService', userServiceInstance, podDefinition);
/// ```
/// {@endtemplate}
final class InitMethodsManager {
  /// Logger for this class
  final Log logger = LogFactory.getLog(InitMethodsManager);

  /// {@macro init_methods_manager}
  InitMethodsManager();

  /// {@template init_methods_manager_invoke_init_methods}
  /// Invokes all applicable initialization methods for the given pod.
  ///
  /// This method handles the complete initialization lifecycle:
  /// 1. Calls `InitializingPod.onReady()` if the pod implements the interface
  /// 2. Calls `SmartInitializingSingleton.onSingletonReady()` if applicable
  /// 3. Invokes custom initialization methods defined in the pod definition
  ///
  /// [podName]: The name of the pod being initialized
  /// [pod]: The pod instance to initialize
  /// [root]: The pod definition containing initialization configuration
  ///
  /// Throws [PodCreationException] if any initialization method fails
  /// {@endtemplate}
  Future<void> invokeInitMethods(String podName, Object pod, PodDefinition? root) async {
    // Call InitializingPod.onReady() if implemented
    if (pod is InitializingPod) {
      try {
        if (logger.getIsTraceEnabled()) {
          logger.trace("Invoking onReady() on pod with name '$podName'");
        }
        
        await pod.onReady();
        
        if (logger.getIsTraceEnabled()) {
          logger.trace("Successfully invoked onReady() on pod '$podName'");
        }
      } on PodException catch (e) {
        if (logger.getIsTraceEnabled()) {
          logger.trace("Failed to invoke onReady() on pod '$podName': $e");
        }
        rethrow;
      } catch (e) {
        throw PodCreationException.withResource(
          root?.description,
          podName,
          "Invocation of onReady() method failed: $e"
        );
      }
    }
    
    // Call custom init methods if defined
    if (root != null && root.lifecycle.initMethods.isNotEmpty) {
      await _invokeCustomInitMethods(podName, pod, root);
    }
  }

  /// Invokes custom initialization methods defined in the pod definition
  Future<void> _invokeCustomInitMethods(String podName, Object pod, PodDefinition root) async {
    final podClass = root.type;
    
    for (String initMethodName in root.lifecycle.initMethods) {
      Method? initMethod = _findInitMethod(podClass, initMethodName);
      
      if (initMethod == null) {
        if (root.lifecycle.enforceInitMethod) {
          throw PodCreationException.withResource(
            root.description,
            podName,
            "Could not find init method '$initMethodName' on pod class '${podClass.getName()}'"
          );
        } else {
          if (logger.getIsWarnEnabled()) {
            logger.warn("Init method '$initMethodName' not found on pod '$podName', but enforcement is disabled");
          }
          continue;
        }
      }

      await _invokeInitMethod(podName, pod, initMethod, root);
    }
  }

  /// Finds an initialization method by name in the pod class hierarchy
  Method? _findInitMethod(Class podClass, String methodName) {
    // Try to find the method in the pod class
    if (podClass.getMethod(methodName) case final method?) {
      return method;
    }

    // Try to find the method in the pod's superclass
    if (podClass.getSuperClass() case final superClass?) {
      if (superClass.getMethod(methodName) case final method?) {
        return method;
      }
    }
    
    // Try to find the method in the pod's interfaces
    for (final interface in podClass.getAllInterfaces()) {
      if (interface.getMethod(methodName) case final method?) {
        return method;
      }
    }
    
    return null;
  }

  /// Invokes a specific initialization method
  Future<void> _invokeInitMethod(String podName, Object pod, Method initMethod, PodDefinition root) async {
    try {
      if (logger.getIsTraceEnabled()) {
        logger.trace("Invoking init method '${initMethod.getName()}' on pod '$podName'");
      }

      // Validate method parameters
      final paramCount = initMethod.getParameterCount();
      if (paramCount > 0) {
        throw PodCreationException.withResource(
          root.description,
          podName,
          "Init method '${initMethod.getName()}' should not have parameters, but has $paramCount"
        );
      }

      // Invoke the method
      final result = initMethod.invoke(pod);
      
      // Handle async methods
      if (result is Future) {
        await result;
        if (logger.getIsTraceEnabled()) {
          logger.trace("Successfully invoked async init method '${initMethod.getName()}' on pod '$podName'");
        }
      } else {
        if (logger.getIsTraceEnabled()) {
          logger.trace("Successfully invoked init method '${initMethod.getName()}' on pod '$podName'");
        }
      }
    } catch (e) {
      final cause = e is Throwable ? e : RuntimeException(e.toString());
      throw PodCreationException.withResource(
        root.description,
        podName,
        "Invocation of init method '${initMethod.getName()}' failed: $e",
        cause: cause
      );
    }
  }

  /// {@template init_methods_manager_has_init_methods}
  /// Checks if the given pod has any initialization methods to invoke.
  ///
  /// This includes both built-in lifecycle interfaces and custom init methods.
  ///
  /// [pod]: The pod instance to check
  /// [root]: The pod definition to check for custom init methods
  /// Returns true if the pod has initialization methods, false otherwise
  /// {@endtemplate}
  bool hasInitMethods(Object pod, PodDefinition? root) {
    // Check for built-in lifecycle interfaces
    if (pod is InitializingPod || pod is SmartInitializingSingleton) {
      return true;
    }

    // Check for custom init methods
    if (root != null && root.lifecycle.initMethods.isNotEmpty) {
      return true;
    }

    return false;
  }

  /// {@template init_methods_manager_validate_init_methods}
  /// Validates that all required initialization methods exist on the pod class.
  ///
  /// This method can be called during pod definition registration to catch
  /// configuration errors early.
  ///
  /// [podClass]: The class of the pod to validate
  /// [root]: The pod definition containing init method configuration
  /// Throws [PodDefinitionValidationException] if validation fails
  /// {@endtemplate}
  void validateInitMethods(Class podClass, PodDefinition root) {
    if (!root.lifecycle.enforceInitMethod) {
      return; // Skip validation if enforcement is disabled
    }

    for (String initMethodName in root.lifecycle.initMethods) {
      Method? initMethod = _findInitMethod(podClass, initMethodName);
      
      if (initMethod == null) {
        throw PodDefinitionValidationException(
          "Could not find init method '$initMethodName' on pod class '${podClass.getName()}'"
        );
      }

      // Validate method signature
      final paramCount = initMethod.getParameterCount();
      if (paramCount > 0) {
        throw PodDefinitionValidationException(
          "Init method '$initMethodName' on pod class '${podClass.getName()}' should not have parameters, but has $paramCount"
        );
      }
    }
  }
}