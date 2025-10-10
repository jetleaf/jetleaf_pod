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
import 'package:jetleaf_logging/logging.dart';
import 'package:meta/meta.dart';

import '../exceptions.dart';
import '../helpers/nullable_pod.dart';
import '../helpers/object.dart';
import '../singleton/default_singleton_pod_registry.dart';

/// {@template abstract_pod_provider_factory}
/// Abstract factory for creating and managing `PodProvider` instances in Jetleaf.
///
/// This class extends [DefaultSingletonPodRegistry] to leverage singleton
/// management while providing additional caching and post-processing
/// support for objects produced by `PodProvider`s. It is intended to be
/// subclassed by concrete Pod provider factories.
///
/// Features:
/// - Caches singleton objects returned by `PodProvider`s for performance.
/// - Supports post-processing of objects before caching.
/// - Handles circular references and partially initialized singletons.
///
/// ## Example
/// ```dart
/// class MyPodFactory extends AbstractPodProviderFactory {
///   @override
///   ObjectHolder<Object> postProcessObjectFromPodProvider(ObjectHolder<Object> object, String name) {
///     // Custom post-processing logic
///     return object;
///   }
/// }
/// 
/// final factory = MyPodFactory();
/// final podProvider = MyCustomPodProvider();
/// final objHolder = await factory.getCachedProviderObject(podProvider, null, "myPod", true);
/// print(objHolder.getValue());
/// ```
/// {@endtemplate}
abstract class AbstractPodProviderFactory extends DefaultSingletonPodRegistry {
  /// {@macro abstract_pod_provider_factory}
  ///
  /// Cache for objects created by singleton PodProviders.
  @protected
  final Map<String, ObjectHolder<Object>> podProviderInstanceCache = {};

  /// Logger for this class.
  final Log logger = LogFactory.getLog(AbstractPodProviderFactory);

  /// The [PodProvider] class reference for internal usage.
  @protected
  final Class<PodProvider> POD_PROVIDER_CLASS = Class<PodProvider>(null, PackageNames.CORE);

  /// {@macro abstract_pod_provider_factory}
  AbstractPodProviderFactory();

  @override
  void removeSingleton(String name) {
    super.removeSingleton(name);
    podProviderInstanceCache.remove(name);
  }

  @override
  void clearSingletonCache() {
    super.clearSingletonCache();
    podProviderInstanceCache.clear();
  }

  @override
  Future<void> registerSingleton(String name, Class type, {ObjectHolder<Object>? object, ObjectFactory<Object>? factory}) async {
    await super.registerSingleton(name, type, object: object, factory: factory);
    
    if(object != null) {
      podProviderInstanceCache[name] = object;
    }

    if(factory != null) {
      podProviderInstanceCache[name] = await factory.get();
    }
    
    return Future<void>.value();
  }

  /// {@template nullable_provider_object}
  /// Returns the cached raw object for a provider-managed pod, if present.
  ///
  /// This is a **direct cache accessor** that bypasses provider calls,
  /// lifecycle checks, and post-processing. Intended for diagnostics and
  /// advanced container internals.
  ///
  /// # Parameters
  /// - [name]: The logical pod name.
  ///
  /// # Returns
  /// - The cached [ObjectHolder], or `null` if no cached raw instance exists.
  ///
  /// # Notes
  /// - This does not invoke the provider.
  /// - Returned objects are always the **raw pre-processed** form.
  /// - Use [getProviderObject] for full provider semantics.
  /// {@endtemplate}
  @protected
  ObjectHolder<Object>? getNullableProviderObject(String name) => podProviderInstanceCache[name];

  /// {@template get_provider_object}
  /// Retrieves the object managed by a [PodProvider], applying caching
  /// and optional post-processing semantics.
  ///
  /// This method encapsulates the complete retrieval lifecycle for provider-based
  /// pods, balancing **performance** (fast cached return) and **correctness**
  /// (safe singleton initialization and decoration).
  ///
  /// # Retrieval Flow
  ///
  /// 1. **Fast path: cache hit**
  ///    - If a raw [ObjectHolder] is already cached in
  ///      [podProviderInstanceCache], return it directly.
  ///    - If [shouldPostProcess] is `true`, and the singleton is not currently
  ///      being created, apply [postProcessObjectFromPodProvider] *on-the-fly*
  ///      without overwriting the raw cache.
  ///
  /// 2. **Singleton path: uncached**
  ///    - If the provider is a singleton and [containsSingleton] reports that
  ///      the registry knows the name, invoke [_doGet] to retrieve the raw object.
  ///    - If another thread/path cached the object while awaiting, prefer the
  ///      cached one and apply optional post-processing.
  ///    - Cache only the **raw** object, never the post-processed variant.
  ///
  /// 3. **Non-singleton path**
  ///    - For prototype or non-registered providers, call [_doGet] each time.
  ///    - Apply optional post-processing immediately; no caching is performed.
  ///
  /// # Error Handling
  /// - Wraps any post-processing errors into [PodCreationException].
  /// - Protects against circular singleton creation by skipping post-processing
  ///   when [isCurrentlyCreatingSingleton] is true.
  ///
  /// # Parameters
  /// - [provider]: The [PodProvider] to query.
  /// - [type]: The expected type (may be `null`).
  /// - [name]: The logical pod name.
  /// - [shouldPostProcess]: If `true`, applies [postProcessObjectFromPodProvider]
  ///   before returning.
  ///
  /// # Returns
  /// - An [ObjectHolder] wrapping the resolved object.
  /// - Will never return `null`, but may wrap a [NullablePod].
  ///
  /// # Throws
  /// - [PodCreationException] if post-processing fails.
  /// - Other exceptions surfaced by [_doGet].
  ///
  /// # Notes
  /// - The **raw instance cache** always stores *unprocessed* objects.
  /// - Post-processing is transient, applied per-request, and never cached.
  /// {@endtemplate}
  @protected
  Future<ObjectHolder<Object>> getProviderObject(PodProvider provider, Class? type, String name, bool shouldPostProcess) async {
    // Fast path: if cached raw object exists, return it (or a processed view) without calling provider.
    final ObjectHolder<Object>? cached = podProviderInstanceCache[name];
    if (cached != null) {
      if (!shouldPostProcess) {
        return cached;
      }

      // Caller wants a post-processed view. If we're currently creating the singleton,
      // don't attempt to post-process — return the raw cached value.
      if (isCurrentlyCreatingSingleton(name)) {
        return cached;
      }

      // Perform post-processing on-the-fly, but DO NOT overwrite the cached raw value.
      beforeSingletonCreation(name);
      try {
        return await postProcessObjectFromPodProvider(cached, name);
      } catch (ex) {
        throw PodCreationException(
          "Post-processing of PodProvider's singleton object failed",
          cause: ex is Throwable ? ex : RuntimeException(ex.toString()),
        );
      } finally {
        afterSingletonCreation(name);
      }
    }

    // No cached raw object. If the provider claims singleton and registry knows about it,
    // get from provider and (by previous behavior) cache the raw result.
    if (provider.isSingleton() && containsSingleton(name)) {
      // Obtain raw object from provider
      ObjectHolder<Object> object = await _doGet(provider, type, name);

      // Another concurrent path may have populated the cache while we awaited — prefer that
      final ObjectHolder<Object>? seen = podProviderInstanceCache[name];
      if (seen != null) {
        // If caller wants post-process, apply it on-the-fly to the seen value
        if (shouldPostProcess) {
          if (isCurrentlyCreatingSingleton(name)) {
            return seen;
          }

          beforeSingletonCreation(name);
          try {
            return await postProcessObjectFromPodProvider(seen, name);
          } catch (ex) {
            throw PodCreationException(
              "Post-processing of PodProvider's singleton object failed",
              cause: ex is Throwable ? ex : RuntimeException(ex.toString()),
            );
          } finally {
            afterSingletonCreation(name);
          }
        }

        return seen;
      }

      // Cache the raw object (maintain previous caching semantics)
      if (containsSingleton(name)) {
        podProviderInstanceCache[name] = object;
      }

      // If post-processing requested, process the raw object on-the-fly and DO NOT overwrite cache.
      if (shouldPostProcess) {
        if (isCurrentlyCreatingSingleton(name)) {
          return object;
        }

        beforeSingletonCreation(name);
        try {
          return await postProcessObjectFromPodProvider(object, name);
        } catch (ex) {
          throw PodCreationException(
            "Post-processing of PodProvider's singleton object failed",
            cause: ex is Throwable ? ex : RuntimeException(ex.toString()),
          );
        } finally {
          afterSingletonCreation(name);
        }
      }

      // No post-processing requested, return the raw cached object
      return object;
    } else {
      // Non-singleton or not registered as singleton: just call provider (no caching)
      ObjectHolder<Object> object = await _doGet(provider, type, name);
      if (shouldPostProcess) {
        try {
          return await postProcessObjectFromPodProvider(object, name);
        } catch (ex) {
          throw PodCreationException(
            "Post-processing of PodProvider's object failed for $name",
            cause: ex is Throwable ? ex : RuntimeException(ex.toString()),
          );
        }
      }

      return object;
    }
  }

  /// {@template do_get_from_pod_provider}
  /// Internal helper method for retrieving an object from a [PodProvider].
  ///
  /// This method encapsulates the entire provider resolution flow:
  ///
  /// 1. **Delegates to the provider**:
  ///    - Calls [PodProvider.get] with the optional [requiredType].
  ///    - Wraps the result in an [ObjectHolder] with full type metadata
  ///      (package + qualified name).
  ///
  /// 2. **Exception handling**:
  ///    - If the provider is not yet initialized → wraps as
  ///      [PodCurrentlyInCreationException].
  ///    - Any other exception → wraps in [PodCreationException],
  ///      preserving the cause (including non-[Throwable] Dart errors).
  ///
  /// 3. **Null handling**:
  ///    - If the provider returns `null` and the pod is **currently being created**:
  ///      throws [PodCurrentlyInCreationException] (to prevent half-baked returns).
  ///    - Otherwise returns a wrapped [NullablePod] instance as a safe placeholder.
  ///
  /// # Parameters
  /// - [provider]: The [PodProvider] supplying the pod.
  /// - [requiredType]: The expected type of the pod (nullable).
  /// - [name]: The logical pod name, used in error reporting.
  ///
  /// # Returns
  /// A non-null [ObjectHolder] representing the resolved object or a [NullablePod].
  ///
  /// # Throws
  /// - [PodCurrentlyInCreationException] if the provider is requested too early.
  /// - [PodCreationException] if the provider fails during retrieval.
  ///
  /// # Notes
  /// - The returned object is **always wrapped** in [ObjectHolder], even
  ///   if the provider supplies `null`.
  /// - Consumers can check for [NullablePod] to handle unresolved providers.
  /// {@endtemplate}
  Future<ObjectHolder<Object>> _doGet(PodProvider provider, Class? requiredType, String name) async {
    ObjectHolder<Object>? object;

    try {
      final result = await provider.get(requiredType);
      if(result != null) {
        object = ObjectHolder<Object>(result.getValue(), packageName: result.getPackageName(), qualifiedName: result.getQualifiedName());
      }
    } on PodProviderNotInitializedException catch (ex) {
      throw PodCurrentlyInCreationException(name: name, cause: ex);
    } catch (ex) {
      throw PodCreationException("PodProvider threw exception for $name", cause: ex is Throwable ? ex : RuntimeException(ex.toString()));
    }

    if (object == null) {
      if (isCurrentlyCreatingSingleton(name)) {
        throw PodCurrentlyInCreationException(name: name, cause: RuntimeException("PodProvider which is currently in creation returned null"));
      }

      object = ObjectHolder<Object>(NullablePod(), packageName: NullablePod.CLASS.getPackage()?.getName(), qualifiedName: NullablePod.CLASS.getQualifiedName());
    }

    return object;
  }

  /// {@template abstract_pod_provider_factory}
  /// Retrieves the [PodProvider] backing a pod.
  ///
  /// This hook is responsible for validating and casting the pod instance
  /// into a usable [PodProvider].
  ///
  /// # Default Behavior
  /// - Verifies that [instance] is a [PodProvider].
  /// - If not, throws a [PodCreationException] (invalid configuration).
  ///
  /// # Extension
  /// - Override this method in subclasses if pods can wrap or proxy
  ///   providers in non-standard ways.
  ///
  /// # Parameters
  /// - [podName]: Logical pod identifier.
  /// - [instance]: The actual pod object (expected to be a [PodProvider]).
  ///
  /// # Returns
  /// The validated [PodProvider].
  /// {@endtemplate}
  @protected
  PodProvider getPodProvider(String podName, Object instance) {
    if (instance is! PodProvider) {
      throw PodCreationException("Pod $podName is not an instance of PodProvider");
    }

    return instance;
  }

  /// {@macro abstract_pod_provider_factory}
  /// Post-processes the object retrieved from a [PodProvider].
  ///
  /// This hook allows frameworks and extensions to modify or decorate
  /// provider-returned objects before they are exposed to the container.
  ///
  /// # Default Behavior
  /// - Returns the object unchanged.
  ///
  /// # Common Use Cases
  /// - Applying AOP proxies or dynamic decorators.
  /// - Enforcing lifecycle callbacks.
  /// - Validating or transforming provider outputs.
  ///
  /// # Parameters
  /// - [object]: The raw object wrapped in [ObjectHolder].
  /// - [name]: Pod name for context.
  ///
  /// # Returns
  /// The potentially modified [ObjectHolder].
  ///
  /// # Notes
  /// - This method is asynchronous, allowing for deferred transformations.
  @protected
  Future<ObjectHolder<Object>> postProcessObjectFromPodProvider(ObjectHolder<Object> object, String name) async => object;
}