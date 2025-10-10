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

import 'pod_processors.dart';

/// {@template pod_post_processor_cache}
/// A cache that categorizes and stores different types of
/// [InitializationAwarePodProcessor] implementations for quick lookup and reuse.
///
/// Instead of iterating through all registered post-processors each time,
/// the cache keeps them grouped by type:
///
/// - [InstantiationAwarePodProcessor]
/// - [SmartInstantiationAwarePodProcessor]
/// - [DestructionAwarePodProcessor]
/// - [MergedPodDefinitionPostProcessor]
///
/// This significantly optimizes the pod lifecycle management process
/// by allowing direct access to the relevant post-processors.
///
/// ### Example
/// ```dart
/// final cache = PodProcessorCacheManager();
///
/// // Adding post-processors
/// cache.instantiation.add(MyInstantiationAwareProcessor());
/// cache.smartInstantiation.add(MySmartInstantiationAwareProcessor());
///
/// // Accessing them later
/// for (var processor in cache.instantiation) {
///   processor.postProcessBeforeInstantiation(...);
/// }
/// ```
/// {@endtemplate}
final class PodProcessorCacheManager {
  /// {@template pod_post_processor_cache_instantiation}
  /// Stores all registered [InstantiationAwarePodProcessor]s.
  ///
  /// These post-processors allow custom logic to run *before* and *after*
  /// pod instantiation, giving full control over pod creation.
  ///
  /// Example:
  /// ```dart
  /// final cache = PodProcessorCacheManager();
  /// cache.instantiation.add(MyInstantiationAwareProcessor());
  /// ```
  /// {@endtemplate}
  final Set<InstantiationAwarePodProcessor> instantiation = {};

  /// {@template pod_post_processor_cache_destruction}
  /// Stores all registered [DestructionAwarePodProcessor]s.
  ///
  /// These post-processors allow custom cleanup logic to run
  /// *before* a pod is destroyed.
  ///
  /// Example:
  /// ```dart
  /// final cache = PodProcessorCacheManager();
  /// cache.destruction.add(MyDestructionAwareProcessor());
  /// ```
  /// {@endtemplate}
  final Set<DestructionAwarePodProcessor> destruction = {};

  /// {@template pod_post_processor_cache_pod_aware}
  /// Stores all registered [PodAwareProcessor]s.
  ///
  /// These post-processors allow custom logic to run *before* and *after*
  /// pod instantiation, giving full control over pod creation.
  ///
  /// Example:
  /// ```dart
  /// final cache = PodProcessorCacheManager();
  /// cache.processors.add(MyPodAwareProcessor());
  /// ```
  /// {@endtemplate}
  final Set<PodAwareProcessor> processors = {};

  /// {@macro pod_post_processor_cache}
  PodProcessorCacheManager._();

  /// {@macro pod_post_processor_cache}
  factory PodProcessorCacheManager([List<PodAwareProcessor> processors = const [], PodProcessorCacheManager? currentCache]) {
    return synchronized(processors, () {
			final cache = currentCache ?? PodProcessorCacheManager._();

      // Always process new processors, even when reusing an existing cache
      processors.process((processor) {
        cache.processors.add(processor);

        // Handle DestructionAwarePodProcessor
        if (processor is DestructionAwarePodProcessor) {
          cache.destruction.add(processor);
        }

        // Handle InstantiationAwarePodProcessor
        if (processor is InstantiationAwarePodProcessor) {
          cache.instantiation.add(processor);
        }
      });

      return cache;
		});
  }

  /// {@macro pod_post_processor_cache}
  void add(PodAwareProcessor processor) {
    processors.add(processor);

    if (processor is DestructionAwarePodProcessor) {
      destruction.add(processor);
    }

    if (processor is InstantiationAwarePodProcessor) {
      instantiation.add(processor);
    }
  }

  /// {@macro pod_post_processor_cache}
  void remove(PodAwareProcessor processor) {
    processors.remove(processor);

    if (processor is DestructionAwarePodProcessor) {
      destruction.remove(processor);
    }

    if (processor is InstantiationAwarePodProcessor) {
      instantiation.remove(processor);
    }
  }
}