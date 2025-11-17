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

import '../core/pod_factory.dart';
import '../exceptions.dart';
import 'enums.dart';

/// {@template pod_factory_utils}
/// A comprehensive utility class that provides static helper methods for working with 
/// pod factories in the JetLeaf framework. This class offers functionality for pod name 
/// transformation, hierarchical pod factory traversal, and pod retrieval operations.
/// 
/// The utility methods handle complex scenarios such as:
/// - Factory pod dereferencing and name transformation
/// - Generated pod name detection and processing
/// - Hierarchical pod factory navigation with ancestor inclusion
/// - Pod retrieval by type, annotation, and resolvable type
/// - Unique pod resolution with proper exception handling
/// 
/// ## Usage Examples
/// 
/// ### Basic Pod Name Operations
/// ```dart
/// // Check if a name references a factory pod
/// bool isFactory = PodUtils.isFactoryDereference('&myPod');
/// print(isFactory); // true
/// 
/// // Transform factory pod name
/// String transformed = PodUtils.transformedName('&myPod');
/// print(transformed); // 'myPod'
/// 
/// // Check for generated pod names
/// bool isGenerated = PodUtils.isGeneratedName('myPod#0');
/// print(isGenerated); // true
/// ```
/// 
/// ### Pod Retrieval Operations
/// ```dart
/// // Get all pod names including from parent factories
/// List<String> allNames = PodUtils.podNamesIncludingAncestors(factory);
/// 
/// // Get pods of specific type from hierarchy
/// Map<String, MyService> services = PodUtils.podsOfTypeIncludingAncestors(
///   factory, 
///   MyService
/// );
/// 
/// // Get unique pod of type
/// MyService service = PodUtils.podOfTypeIncludingAncestors(
///   factory, 
///   MyService
/// );
/// ```
/// {@endtemplate}
abstract class PodUtils {
  /// {@template pod_factory_scope_default}
  /// Default scope: singleton.
  /// {@endtemplate}
  static const ScopeType SCOPE_DEFAULT = ScopeType.SINGLETON;

  /// {@template generated_pod_name_separator}
  /// The separator character used in generated pod names to distinguish between
  /// the original pod name and the generated suffix.
  /// 
  /// Generated pod names follow the pattern: `originalName^suffix`
  /// {@endtemplate}
  static final String GENERATED_POD_NAME_SEPARATOR = "^";

  /// {@template pod_provider_prefix}
  /// Prefix used to dereference a factory pod and distinguish it from pods
  /// created by the factory.
  /// 
  /// When you want to get the factory pod itself rather than the pod it produces,
  /// prefix the pod name with this character.
  /// 
  /// Example:
  /// ```dart
  /// // Get the pod produced by the factory
  /// var product = podFactory.getPod('myPod');
  /// 
  /// // Get the factory pod itself
  /// var factory = podFactory.getPod('*myPod');
  /// ```
  /// {@endtemplate}
  static String POD_PROVIDER_PREFIX = "*";

  /// {@template original_instance_suffix}
  /// Suffix used to indicate that the original, raw instance should be returned
  /// instead of a proxied one, for example: `package:example/example.dart.MyClass.ORIGINAL`.
  /// {@endtemplate}
  static String ORIGINAL_INSTANCE_SUFFIX = ".ORIGINAL_INSTANCE";

  /// {@template infer_method}
  /// This tells Jetleaf to infer method names like for destroy methods.
  /// 
  /// It acts as a placeholder, but does not in any way, simulate a real method name.
  /// {@endtemplate}
  static final String DEFAULT_METHOD_NAME = "(#inferred_method#)";

  /// Attribute name used to store the object type in pod definitions.
  /// 
  /// This constant is used internally by the container to cache type information
  /// for factory pods, improving performance during dependency resolution.
  static const String OBJECT_TYPE_ATTRIBUTE = "factoryPodObjectType";

  /// {@template transformed_pod_name_cache}
  /// Internal cache that stores transformed pod names to improve performance
  /// when repeatedly processing factory pod names. The cache maps original
  /// factory pod names (with '&' prefix) to their transformed versions.
  /// {@endtemplate}
  
  /// {@macro transformed_pod_name_cache}
  static final Map<String, String> _transformedNameCache = {};

  /// {@template is_factory_dereference}
  /// Determines whether the given pod name represents a factory pod dereference.
  /// Factory pods are prefixed with '&' to indicate they should return the
  /// factory instance rather than the pod it produces.
  /// 
  /// ## Parameters
  /// - `name`: The pod name to check (can be null)
  /// 
  /// ## Returns
  /// `true` if the name starts with the factory pod prefix ('&'), `false` otherwise
  /// 
  /// ## Example
  /// ```dart
  /// bool isFactory1 = PodUtils.isFactoryDereference('&myFactory');
  /// print(isFactory1); // true
  /// 
  /// bool isFactory2 = PodUtils.isFactoryDereference('regularPod');
  /// print(isFactory2); // false
  /// 
  /// bool isFactory3 = PodUtils.isFactoryDereference(null);
  /// print(isFactory3); // false
  /// ```
  /// {@endtemplate}
  
  /// {@macro is_factory_dereference}
  static bool isFactoryDereference(String? name) {
    return (name != null && name.isNotEmpty && name.startsWith(POD_PROVIDER_PREFIX));
  }

  /// {@template transformed_pod_name}
  /// Transforms a factory pod name by removing all factory pod prefixes ('&').
  /// This method handles nested factory pod references by removing multiple
  /// consecutive prefixes. Results are cached for performance optimization.
  /// 
  /// ## Parameters
  /// - `name`: The pod name to transform
  /// 
  /// ## Returns
  /// The transformed pod name with all '&' prefixes removed
  /// 
  /// ## Example
  /// ```dart
  /// String name1 = PodUtils.transformedName('*myFactory');
  /// print(name1); // 'myFactory'
  /// 
  /// String name2 = PodUtils.transformedName('*nestedFactory');
  /// print(name2); // 'nestedFactory'
  /// 
  /// String name3 = PodUtils.transformedName('regularPod');
  /// print(name3); // 'regularPod'
  /// ```
  /// {@endtemplate}
  
  /// {@macro transformed_pod_name}
  static String transformedName(String name) {
    if (name.isEmpty || !name.startsWith(POD_PROVIDER_PREFIX)) {
			return name;
		}
		return _transformedNameCache.computeIfAbsent(name, (podName) {
			do {
				podName = podName.substring(1);  // length of [POD_PROVIDER_PREFIX]
			}
			while (podName.startsWith(POD_PROVIDER_PREFIX));
			return podName;
		});
  }

  /// {@template is_generated_pod_name}
  /// Checks whether the given pod name is a generated name. Generated pod names
  /// contain the separator character to distinguish between multiple instances
  /// of the same pod type.
  /// 
  /// ## Parameters
  /// - `name`: The pod name to check (can be null)
  /// 
  /// ## Returns
  /// `true` if the name contains the generated pod name separator, `false` otherwise
  /// 
  /// ## Example
  /// ```dart
  /// bool isGenerated1 = PodUtils.isGeneratedName('myPod^0');
  /// print(isGenerated1); // true
  /// 
  /// bool isGenerated2 = PodUtils.isGeneratedName('regularPod');
  /// print(isGenerated2); // false
  /// 
  /// bool isGenerated3 = PodUtils.isGeneratedName(null);
  /// print(isGenerated3); // false
  /// ```
  /// {@endtemplate}
  
  /// {@macro is_generated_pod_name}
  static bool isGeneratedName(String? name) {
    return (name != null && name.isNotEmpty && name.contains(GENERATED_POD_NAME_SEPARATOR));
  }

  /// {@template original_pod_name}
  /// Extracts the original pod name from a generated pod name by removing
  /// the separator and suffix. If no separator is found, returns the name unchanged.
  /// 
  /// ## Parameters
  /// - `name`: The potentially generated pod name
  /// 
  /// ## Returns
  /// The original pod name without the generated suffix
  /// 
  /// ## Example
  /// ```dart
  /// String original1 = PodUtils.originalName('myPod^0');
  /// print(original1); // 'myPod'
  /// 
  /// String original2 = PodUtils.originalName('myPod^instance1');
  /// print(original2); // 'myPod'
  /// 
  /// String original3 = PodUtils.originalName('regularPod');
  /// print(original3); // 'regularPod'
  /// ```
  /// {@endtemplate}
  
  /// {@macro original_pod_name}
  static String originalName(String name) {
    int separatorIndex = name.indexOf(GENERATED_POD_NAME_SEPARATOR);
    return separatorIndex != -1 ? name.substring(0, separatorIndex) : name;
  }

  /// {@template validate_pod_name}
  /// Validate a pod name according to Jetleaf naming conventions.
  /// 
  /// [name] the pod name to validate
  /// Throws [IllegalArgumentException] if the name is invalid
  /// {@endtemplate}
  static void validateName(String name) {
    if (name.isEmpty) {
      throw IllegalArgumentException("Pod name cannot be empty");
    }

    if (name.trim() != name) {
      throw IllegalArgumentException("Pod name cannot have leading or trailing whitespace: '$name'");
    }

    // Check for invalid characters
    final invalidChars = ['\n', '\r', '\t'];
    for (final char in invalidChars) {
      if (name.contains(char)) {
        throw IllegalArgumentException("Pod name cannot contain whitespace characters: '$name'");
      }
    }
  }

  /// {@template is_valid_pod_name}
  /// Check if a pod name is valid according to Jetleaf naming conventions.
  /// 
  /// [name] the pod name to check
  /// Returns true if the name is valid
  /// {@endtemplate}
  static bool isValidName(String name) {
    try {
      validateName(name);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// {@template unique_pod}
  /// Validates that exactly one pod exists in the provided map and returns it.
  /// This is a utility method for ensuring pod uniqueness and providing appropriate exceptions.
  /// 
  /// ## Parameters
  /// - `type`: The expected pod type for error messages
  /// - `podsOfType`: Map of pod names to instances
  /// 
  /// ## Returns
  /// The single pod instance if exactly one exists
  /// 
  /// ## Throws
  /// - `NoSuchPodDefinitionException`: If the map is empty
  /// - `NoUniquePodDefinitionException`: If the map contains multiple pods
  /// 
  /// ## Example
  /// ```dart
  /// Map<String, MyService> pods = {'service1': serviceInstance};
  /// MyService service = PodUtils.uniquePod(MyService, pods);
  /// // Returns serviceInstance
  /// 
  /// Map<String, MyService> multiplePods = {
  ///   'service1': serviceInstance1,
  ///   'service2': serviceInstance2
  /// };
  /// // Throws NoUniquePodDefinitionException
  /// MyService service = PodUtils.uniquePod(MyService, multiplePods);
  /// ```
  /// {@endtemplate}
  
  /// {@macro unique_pod}
  static T uniquePod<T>(Class<T> type, Map<String, T> podsOfType) {
    int count = podsOfType.length;

		if (count == 1) {
			return podsOfType.values.first;
		} else if (count > 1) {
			throw NoUniquePodDefinitionException.byTypeWithNames(type, podsOfType.keys.toList());
		} else {
			throw NoSuchPodDefinitionException.byType(type);
		}
  }

  /// {@template count_pods_including_ancestors}
  /// Counts the total number of pods in the given factory and all its ancestor
  /// factories in the hierarchy. This provides a complete count of available pods.
  /// 
  /// ## Parameters
  /// - `factory`: The pod factory to count pods from
  /// 
  /// ## Returns
  /// The total number of pods including those from ancestor factories
  /// 
  /// ## Example
  /// ```dart
  /// int totalPods = PodUtils.countPodsIncludingAncestors(myFactory);
  /// print('Total pods available: $totalPods');
  /// ```
  /// {@endtemplate}
  
  /// {@macro count_pods_including_ancestors}
  static Future<int> countPodsIncludingAncestors(ListablePodFactory factory) async {
		return (await podNamesIncludingAncestors(factory)).length;
	}

  /// {@template pod_names_including_ancestors}
  /// Retrieves all pod names from the given factory and its ancestor factories.
  /// This method traverses the entire hierarchy to collect pod names from all levels.
  /// 
  /// ## Parameters
  /// - `listable`: The listable pod factory to search
  /// 
  /// ## Returns
  /// A list of all pod names from the factory hierarchy
  /// 
  /// ## Example
  /// ```dart
  /// List<String> allNames = PodUtils.podNamesIncludingAncestors(factory);
  /// print('Available pods: ${allNames.join(', ')}');
  /// ```
  /// {@endtemplate}
  
  /// {@macro pod_names_including_ancestors}
  static Future<List<String>> podNamesIncludingAncestors(ListablePodFactory listable) async {
    return await podNamesForTypeIncludingAncestors(listable, Class<Object>());
  }

  /// {@template pod_names_for_type_including_ancestors_and_more}
  /// Retrieves pod names of a specific type with additional filtering options.
  /// Provides fine-grained control over singleton inclusion and eager initialization.
  /// 
  /// ## Parameters
  /// - `listable`: The listable pod factory to search
  /// - `type`: The class type to search for
  /// - `includeNonSingletons`: Whether to include non-singleton pods
  /// - `allowEagerInit`: Whether to allow eager initialization of lazy pods
  /// 
  /// ## Returns
  /// A filtered list of pod names matching the criteria
  /// 
  /// ## Example
  /// ```dart
  /// List<String> serviceNames = PodUtils.podNamesForTypeIncludingAncestorsAndMore(
  ///   factory, 
  ///   MyService,
  ///   true,  // include non-singletons
  ///   false  // don't eager init
  /// );
  /// ```
  /// {@endtemplate}
  
  /// {@macro pod_names_for_type_including_ancestors_and_more}
  static Future<List<String>> podNamesForTypeIncludingAncestors(ListablePodFactory listable, Class type, {bool? includeNonSingletons, bool? allowEagerInit}) async {
    List<String> names = await listable.getPodNames(type, includeNonSingletons: includeNonSingletons ?? false, allowEagerInit: allowEagerInit ?? false);

    if(listable is HierarchicalPodFactory && (listable as HierarchicalPodFactory).getParentFactory() is ListablePodFactory) {
      final hiera = listable as HierarchicalPodFactory;
      final parentResult = await podNamesForTypeIncludingAncestors(
        hiera.getParentFactory() as ListablePodFactory,
        type,
        includeNonSingletons: includeNonSingletons,
        allowEagerInit: allowEagerInit
      );

      names = await mergeNamesWithParent(names, parentResult, hiera);
    }

    return names;
  }

  /// {@template pod_names_for_annotation_including_ancestors}
  /// Retrieves pod names annotated with a specific annotation type from the hierarchy.
  /// Searches through the factory and all ancestor factories for annotated pods.
  /// 
  /// ## Parameters
  /// - `listable`: The listable pod factory to search
  /// - `annotationType`: The annotation class to search for
  /// 
  /// ## Returns
  /// A list of pod names that have the specified annotation
  /// 
  /// ## Example
  /// ```dart
  /// List<String> serviceNames = PodUtils.podNamesForAnnotationIncludingAncestors(
  ///   factory, 
  ///   Service
  /// );
  /// print('Service annotated pods: ${serviceNames.join(', ')}');
  /// ```
  /// {@endtemplate}
  
  /// {@macro pod_names_for_annotation_including_ancestors}
  static Future<List<String>> podNamesForAnnotationIncludingAncestors(ListablePodFactory listable, Class annotationType) async {
    List<String> names = await listable.getPodNamesForAnnotation(annotationType);

    if(listable is HierarchicalPodFactory && (listable as HierarchicalPodFactory).getParentFactory() is ListablePodFactory) {
      final hiera = listable as HierarchicalPodFactory;
      final parentResult = await podNamesForAnnotationIncludingAncestors(hiera.getParentFactory() as ListablePodFactory, annotationType);
      names = await mergeNamesWithParent(names, parentResult, hiera);
    }

    return names;
  }

  /// {@template merge_names_with_parent}
  /// Merges pod names from a child factory with names from parent factories.
  /// Ensures no duplicates and respects local pod definitions that override parent pods.
  /// 
  /// ## Parameters
  /// - `names`: Pod names from the child factory
  /// - `parentNames`: Pod names from parent factories
  /// - `hiera`: The hierarchical pod factory for local pod checking
  /// 
  /// ## Returns
  /// A merged list of unique pod names
  /// {@endtemplate}
  
  /// {@macro merge_names_with_parent}
  static Future<List<String>> mergeNamesWithParent(List<String> names, List<String> parentNames, HierarchicalPodFactory hiera) async {
    if(parentNames.isEmpty) {
      return names;
    }

    List<String> merged = ArrayList.withCapacity(names.length + parentNames.length);
    merged.addAll(names);

    for (final name in parentNames) {
      if(!merged.contains(name) && !await hiera.containsLocalPod(name)) {
        merged.add(name);
      }
    }

    return merged;
  }

  /// {@template pods_of_type_including_ancestors_and_more}
  /// Retrieves pod instances of a specific type with additional filtering options.
  /// Provides control over singleton inclusion and eager initialization behavior.
  /// 
  /// ## Parameters
  /// - `listable`: The listable pod factory to search
  /// - `type`: The class type to retrieve
  /// - `includeNonSingletons`: Whether to include non-singleton pods
  /// - `allowEagerInit`: Whether to allow eager initialization of lazy pods
  /// 
  /// ## Returns
  /// A filtered map of pod names to instances
  /// {@endtemplate}
  
  /// {@macro pods_of_type_including_ancestors_and_more}
  static Future<Map<String, T>> podsOfTypeIncludingAncestors<T>(ListablePodFactory listable, Class<T> type, {bool? includeNonSingletons, bool? allowEagerInit}) async {
    final result = <String, T>{};
    result.addAll(await listable.getPodsOf(type, includeNonSingletons: includeNonSingletons ?? false, allowEagerInit: allowEagerInit ?? false));

    if(listable is HierarchicalPodFactory && (listable as HierarchicalPodFactory).getParentFactory() is ListablePodFactory) {
      final hiera = listable as HierarchicalPodFactory;
      final parentResult = await podsOfTypeIncludingAncestors(
        hiera.getParentFactory() as ListablePodFactory,
        type,
        includeNonSingletons: includeNonSingletons,
        allowEagerInit: allowEagerInit
      );
      
      for (final entry in parentResult.entries) {
        final podName = entry.key;
        final podInstance = entry.value;
        
        if (!result.containsKey(podName) && !await hiera.containsLocalPod(podName)) {
          result.put(podName, podInstance);
        }
      }
    }

    return result;
  }

  /// {@template pod_of_type_including_ancestors_and_more}
  /// Retrieves a single unique pod instance with additional filtering options.
  /// Combines unique pod resolution with singleton and initialization controls.
  /// 
  /// ## Parameters
  /// - `listable`: The listable pod factory to search
  /// - `type`: The class type to retrieve
  /// - `includeNonSingletons`: Whether to include non-singleton pods
  /// - `allowEagerInit`: Whether to allow eager initialization of lazy pods
  /// 
  /// ## Returns
  /// The unique pod instance matching the criteria
  /// 
  /// ## Throws
  /// - `NoSuchPodDefinitionException`: If no matching pod is found
  /// - `NoUniquePodDefinitionException`: If multiple matching pods are found
  /// {@endtemplate}
  
  /// {@macro pod_of_type_including_ancestors_and_more}
  static Future<T> podOfTypeIncludingAncestors<T>(ListablePodFactory listable, Class<T> type, {bool? includeNonSingletons, bool? allowEagerInit}) async {
    final podsOfType = await podsOfTypeIncludingAncestors(
      listable,
      type,
      includeNonSingletons: includeNonSingletons ?? false,
      allowEagerInit: allowEagerInit ?? false
    );

		return uniquePod(type, podsOfType);
  }

  /// {@template pod_of_type_of_class}
  /// Retrieves a single unique pod instance from the local factory with filtering options.
  /// Provides control over singleton inclusion and eager initialization without hierarchy traversal.
  /// 
  /// ## Parameters
  /// - `listable`: The listable pod factory to search
  /// - `type`: The class type to retrieve
  /// - `includeNonSingletons`: Whether to include non-singleton pods
  /// - `allowEagerInit`: Whether to allow eager initialization of lazy pods
  /// 
  /// ## Returns
  /// The unique pod instance matching the local factory criteria
  /// {@endtemplate}
  
  /// {@macro pod_of_type_of_class}
  static Future<T> podOfType<T>(ListablePodFactory listable, Class<T> type, {bool? includeNonSingletons, bool? allowEagerInit}) async {
    final podsOfType = await listable.getPodsOf(type, includeNonSingletons: includeNonSingletons ?? false, allowEagerInit: allowEagerInit ?? false);
		return uniquePod(type, podsOfType);
  }
}