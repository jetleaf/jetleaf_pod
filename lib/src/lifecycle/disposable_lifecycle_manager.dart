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

import 'lifecycle.dart';
import '../definition/pod_definition.dart';
import '../exceptions.dart';
import '../helpers/utils.dart';
import 'pod_processors.dart';

/// {@template disposable_lifecycle_manager}
/// An adapter that handles the destruction lifecycle of a managed pod
/// in the **Jetleaf IoC container**.
///
/// The `DisposableLifecycleManager` ensures that pods are properly destroyed
/// by invoking:
///
/// - The `destroy()` method from the [`DisposablePod`] interface (if implemented).
/// - The `close()` method from the [`AutoCloseable`] interface (if applicable).
/// - Any **custom destroy methods** defined in the [`RootPodDefinition`].
///
/// It also applies any configured
/// [`DestructionAwarePodProcessor`] before destruction to allow
/// pre-destroy callbacks or additional cleanup logic.
///
/// ### When to use
/// - When integrating custom pods into Jetleaf that need explicit cleanup.
/// - When you want pods to participate in lifecycle management without
///   tightly coupling them to framework APIs.
///
/// ### Example
/// ```dart
/// class MyService implements DisposablePod {
///   @override
///   void destroy() {
///     print("Cleaning up MyService...");
///   }
/// }
///
/// void main() {
///   final service = MyService();
///   final definition = RootPodDefinition(type: Class<MyService>())..name = "myService";
///   final adapter = DisposableLifecycleManager(
///     service,
///     "myService",
///     definition,
///     [],
///   );
///
///   adapter.destroy(); // Invokes MyService.destroy()
/// }
/// ```
/// {@endtemplate}
class DisposableLifecycleManager implements DisposablePod, Runnable {
  /// Default method name that the adapter looks for if no explicit
  /// destroy method is provided in the pod definition.
  static final String _DESTROY_METHOD_NAME = "destroy";

  /// Alternative destroy method that may be invoked if available.
  static final String _CLOSE_METHOD_NAME = "close";

  /// Another valid destroy method name that is checked when
  /// inferring destroy methods from a pod.
  static final String _SHUTDOWN_METHOD_NAME = "shutdown";

  /// Another valid destroy method name that is checked when
  /// inferring destroy methods from a pod.
  static final String _CANCEL_METHOD_NAME = "cancel";

  /// Logger instance used to report destruction lifecycle steps
  /// and potential warnings.
  final Log logger = LogFactory.getLog(DisposableLifecycleManager);

  /// List of processors that can participate in pod destruction
  /// by running custom logic before the pod is actually destroyed.
  final List<DestructionAwarePodProcessor> processors;

  /// Internal reference to the `DisposablePod` type.
  static final Class _disposablePod = Class<DisposablePod>(null, PackageNames.POD);

  /// Internal reference to the `AutoCloseable` type.
  static final Class _autoCloseable = Class<AutoCloseable>(null, PackageNames.LANG);

  /// Whether the pod should invoke its `DisposablePod.destroy()` method.
  bool _invokeDisposablePod = false;

  /// Whether the pod should invoke its `StreamSubscription.cancel()` method.
  bool _invokeStreamSubscription = false;

  /// Whether the pod should invoke its `AutoCloseable.close()` method.
  bool _invokeAutoCloseable = true;

  /// Custom destroy method names specified for this pod.
  List<String> _destroyMethodNames = [];

  /// Reflected `Method` objects representing the actual destroy methods.
  List<Method> _destroyMethods = [];

  /// The reflected class representation of the pod.
  late Class _podClass;

  /// The actual pod instance being managed and destroyed.
  final Object pod;

  /// Logical name of the pod within the IoC container.
  final String name;

  /// {@macro disposable_lifecycle_manager}
  ///
  /// Creates a new adapter for the given [pod], with its associated
  /// [name], and lifecycle definition ([pd]).
  ///
  /// The adapter inspects the pod definition to determine whether
  /// to call:
  /// - `destroy()` from `DisposablePod`
  /// - `close()` from `AutoCloseable`
  /// - or a custom destroy method.
  DisposableLifecycleManager(this.pod, this.name, RootPodDefinition pd, this.processors) {
    _handleDestroyMethods(pd);
  }

  /// Handles the resolution of destroy methods from the pod definition
  /// and determines which destroy method to invoke.
  void _handleDestroyMethods(RootPodDefinition pd) {
    _podClass = pd.type;

    // Determine destroy method names (from definition or inference)
    final destroyMethodNames = buildMethodIfRequired(_podClass, pd);

    // Decide whether to invoke interface-based lifecycle methods.
    // These are independent flags — a pod can implement both and both should be invoked.
    _invokeDisposablePod = pod is DisposablePod && !pd.hasDestroyMethod(_DESTROY_METHOD_NAME);

    // Call close() when the pod implements AutoCloseable and the definition
    // does not explicitly override/declare a 'close' destroy method.
    _invokeAutoCloseable = pod is AutoCloseable && !pd.hasDestroyMethod(_CLOSE_METHOD_NAME);

    // Call cancel() when the pod implements StreamSubscription and the definition
    // does not explicitly override/declare a 'cancel' destroy method.
    _invokeStreamSubscription = pod is StreamSubscription && !pd.hasDestroyMethod(_CANCEL_METHOD_NAME);

    // Always attempt to resolve any destroy methods named in the pod definition (or inferred).
    if (destroyMethodNames != null && destroyMethodNames.isNotEmpty) {
      _destroyMethodNames = List<String>.from(destroyMethodNames);
      final resolvedMethods = <Method>[];

      for (final destroyMethodName in destroyMethodNames) {
        final found = _determineMethodToUse(destroyMethodName);
        if (found == null && pd.lifecycle.enforceDestroyMethod) {
          throw PodDefinitionValidationException(
              "Could not find a destroy method named $destroyMethodName on pod with name $name");
        }

        if (found != null) {
          // Parameter checks: 0 params or 1 boolean param allowed
          final paramCount = found.getParameterCount();
          if (paramCount > 1) {
            throw PodDefinitionValidationException(
                "Method $destroyMethodName of pod $name has more than one parameter - not supported as destroy method");
          }
          if (paramCount == 1) {
            final paramTypes = found.getParameterTypes();
            if (paramTypes.isNotEmpty && paramTypes.first.getType() != bool) {
              throw PodDefinitionValidationException(
                  "Method $destroyMethodName of pod $name has a non-boolean parameter - not supported as destroy method");
            }
          }

          resolvedMethods.add(found);
        }
      }

      _destroyMethods = resolvedMethods;
    }
  }

  @override
  Future<void> onDestroy() async {
    // Run pre-destroy processors first
    processors.process((processor) => processor.processBeforeDestruction(pod, _podClass, name));

    // Call DisposablePod.onDestroy() if applicable
		if (_invokeDisposablePod) {
			if (logger.getIsTraceEnabled()) {
				logger.trace("Invoking onDestroy() on pod with name '$name'");
			}

			try {
				await (pod as DisposablePod).onDestroy();
			} catch (ex) {
        // Log any errors during destroy
				if (logger.getIsWarnEnabled()) {
					String msg = "Invocation of onDestroy() method failed on pod with name '$name'";
					if (logger.getIsDebugEnabled()) {
						logger.warn(msg, error: ex);
					} else {
						logger.warn("$msg: ${ex.toString()}");
					}
				}
			}
		}

    // Call StreamSubscription.cancel() if applicable
		if (_invokeStreamSubscription) {
			if (logger.getIsTraceEnabled()) {
				logger.trace("Invoking cancel() on pod with name '$name'");
			}

			try {
				await (pod as StreamSubscription).cancel();
			} catch (ex) {
        // Log any errors during destroy
				if (logger.getIsWarnEnabled()) {
					String msg = "Invocation of cancel() method failed on pod with name '$name'";
					if (logger.getIsDebugEnabled()) {
						logger.warn(msg, error: ex);
					} else {
						logger.warn("$msg: ${ex.toString()}");
					}
				}
			}
		}

    // Call AutoCloseable.close() if applicable
    if (_invokeAutoCloseable) {
			if (logger.getIsTraceEnabled()) {
				logger.trace("Invoking close() on pod with name '$name'");
			}

			try {
				await (pod as AutoCloseable).close();
			} catch (ex) {
        // Log any errors during close
				if (logger.getIsWarnEnabled()) {
					String msg = "Invocation of close method failed on pod with name '$name'";
					if (logger.getIsDebugEnabled()) {
						logger.warn(msg, error: ex);
					} else {
						logger.warn("$msg: ${ex.toString()}");
					}
				}
			}
		} else if (_destroyMethods.isNotEmpty) { // Otherwise, invoke custom destroy methods
			_destroyMethods.process((method) => _invokeCustomMethod(method));
		} else if (_destroyMethodNames.isNotEmpty) {
			_destroyMethodNames.process((destroyMethodName) {
				Method? destroyMethod = _determineMethodToUse(destroyMethodName);
				if (destroyMethod != null) {
					_invokeCustomMethod(destroyMethod);
				}
			});
		}

    // Run post-destroy processors last
    processors.process((processor) => processor.processAfterDestruction(pod, _podClass, name));
  }

  @override
  FutureOr<void> run() {
    // Run the destroy process
    return onDestroy();
  }

  @override
  String getPackageName() => PackageNames.POD;

  /// Determines if the given [pod] has a valid destroy method based
  /// on its definition.
  /// 
  /// [destroyMethodName]: The name of the destroy method to look for
  Method? _determineMethodToUse(String destroyMethodName) {
    // Try to find the method in the pod class
    final method = _podClass.getMethod(destroyMethodName);
    if (method != null) {
      return method;
    }

    // Try to find the method in the pod's superclass if not found in the pod class
    final superClass = _podClass.getDeclaredSuperClass();
    if (superClass != null) {
      final method = superClass.getMethod(destroyMethodName);
      if (method != null) {
        return method;
      }
    }
    
    // Try to find the method in the pod's interfaces if not found in the pod class or superclass
    _podClass.getAllInterfaces().process((interface) {
      final method = interface.getMethod(destroyMethodName);
      if (method != null) {
        return method;
      }
    });
    
    return null;
  }

  /// Invokes the given [destroyMethod] on the pod.
  /// 
  /// [destroyMethod]: The method to invoke
  void _invokeCustomMethod(Method destroyMethod) async {
    // Log the method being invoked
    if (logger.getIsTraceEnabled()) {
			logger.trace("Invoking custom destroy method '${destroyMethod.getName()}' on pod with name '$name': $destroyMethod");
		}

    // Build the arguments list for the method invocation
		int paramCount = destroyMethod.getParameterCount();
    List<Object> args = [];

    // If method expects a boolean param, pass true
    if (paramCount == 1) {
      args.add(true);
    }

    // Invoke the method
    try {
      dynamic returnValue = destroyMethod.invoke(pod, null, args);

      // If method is synchronous void or returns no value
      if (returnValue == null) {
				_logCompletedDestroyMethod(destroyMethod, false);
			} else if (returnValue is Future) {
				// If method is asynchronous, await its completion
				await returnValue;
				_logCompletedDestroyMethod(destroyMethod, true);
			}
    } catch (ex) {
      // Handle and log exceptions from custom destroy methods
      Object cause = ex is Throwable ? ex.getCause() ?? ex.getMessage() : ex;
      if (logger.getIsWarnEnabled()) {
        String msg = "Invocation of custom destroy method failed on pod with name '$name'";
        if (logger.getIsDebugEnabled()) {
          logger.warn(msg, error: cause);
        } else {
          logger.warn("$msg: $cause");
        }
      }
    }
  }

  /// Logs the completion of a destroy method invocation.
  /// 
  /// [destroyMethod]: The method that was invoked
  /// [async]: Whether the method was invoked asynchronously
  void _logCompletedDestroyMethod(Method destroyMethod, bool async) {
		if (logger.getIsDebugEnabled()) {
			logger.debug("Custom destroy method '${destroyMethod.getName()}' on pod with name '$name' completed ${(async ? " asynchronously" : "")}");
		}
	}

  /// Determines if the given [pod] has a valid destroy method based
  /// on its definition.
  /// 
  /// [pod]: The pod to check
  /// [pd]: The pod definition to check
  static bool hasDestroyMethod(Object pod, RootPodDefinition pd) {
    return (pod is DisposablePod || buildMethodIfRequired(pd.type, pd) != null);
  }

  /// Infers which destroy methods should be called on the given
  /// [podClass], taking into account the [pd].
  ///
  /// This method attempts to detect:
  /// - Custom destroy methods
  /// - `close()` if the pod implements `AutoCloseable`
  /// - `shutdown()` as a fallback
  static List<String>? buildMethodIfRequired(Class podClass, RootPodDefinition pd) {
    // Get the destroy method names from the pod definition
    List<String>? _destroyMethodNames = pd.lifecycle.destroyMethods;
		if (_destroyMethodNames.isNotEmpty) {
			return _destroyMethodNames;
		}

    // Get the destroy method name from the pod definition
    String? destroyMethodName = pd.resolvedDestroyMethodName;
		if (destroyMethodName == null) {
			bool autoCloseable = podClass.isSubclassOf(_autoCloseable);

      // If inference required, try resolving close() or shutdown()
			if (PodUtils.DEFAULT_METHOD_NAME == destroyMethodName || autoCloseable) {
				// Only perform destroy method inference in case of the pod
				// not explicitly implementing the DisposablePod interface
				destroyMethodName = null;
				if (!podClass.isSubclassOf(_disposablePod)) {
					if (autoCloseable) {
						destroyMethodName = _CLOSE_METHOD_NAME;
					} else {
						destroyMethodName = podClass.getMethod(_CLOSE_METHOD_NAME)?.getName() ?? podClass.getMethod(_SHUTDOWN_METHOD_NAME)?.getName();
					}
				}
			}

      // Set the resolved destroy method name in the pod definition
			pd.resolvedDestroyMethodName = destroyMethodName ?? "";
		}

    // Return the destroy method name if found
    return destroyMethodName != null ? [destroyMethodName] : null;
  }

  /// Determines if the given [pod] has any applicable
  /// [DestructionAwarePodProcessor]s.
  /// 
  /// [pod]: The pod to check
  /// [pd]: The pod definition to check
  /// [processors]: Set of post-processors to check
  static Future<bool> hasApplicableProcessors(Object pod, RootPodDefinition pd, Set<DestructionAwarePodProcessor> processors) async {
    // Return true if any applicable post-processors found
    if (processors.isEmpty) {
      return false;
    }
    
    // Check if any post-processors require destruction
    for (final processor in processors) {
      if (await processor.requiresDestruction(pod, pd.type, pd.name)) {
        return true;
      }
    }
    
    return false;
	}

  /// Filters the given [processors] to include only those that require
  /// destruction for the given [pod].
  /// 
  /// [processors]: Set of post-processors to filter
  /// [pod]: The pod to check
  /// [pd]: The pod definition to check
  static Future<List<DestructionAwarePodProcessor>> filterPostProcessors(Set<DestructionAwarePodProcessor> processors, Object pod, RootPodDefinition pd) async {
    // Return the filtered list of post-processors
    List<DestructionAwarePodProcessor> filteredProcessors = [];
    
    for (final processor in processors) {
      if (await processor.requiresDestruction(pod, pd.type, pd.name)) {
        filteredProcessors.add(processor);
      }
    }
    
		return filteredProcessors;
  }
}