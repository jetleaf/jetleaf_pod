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

import '../alias/simple_alias_registry.dart';
import '../exceptions.dart';
import 'pod_definition.dart';
import 'pod_definition_registry.dart';

/// {@template simple_pod_definition_registry}
/// A **basic registry for managing pod definitions**.
///
/// This registry stores and retrieves [PodDefinition]s by name.  
/// It provides the ability to:
/// - Register new pod definitions.
/// - Look up existing pod definitions.
/// - Check if a pod definition exists.
/// - Remove pod definitions.
/// - Track the total count and names of registered definitions.
/// - Handle conflicts with alias names inherited from [SimpleAliasRegistry].
///
/// This is commonly used as the **backbone for dependency injection containers**, 
/// where pods must be defined before they can be instantiated.
///
/// ### Example usage:
/// ```dart
/// void main() {
///   final registry = SimplePodDefinitionRegistry();
///
///   // Create a simple pod definition (hypothetical).
///   final userPod = PodDefinition('UserPod');
///
///   // Register it.
///   registry.registerDefinition('user', userPod);
///
///   // Retrieve it.
///   final retrieved = registry.getDefinition('user');
///   print(retrieved?.name); // Output: UserPod
///
///   // Check existence.
///   print(registry.containsDefinition('user')); // true
///
///   // Get total count.
///   print(registry.getDefinitionCount()); // 1
///
///   // Remove definition.
///   registry.removeDefinition('user');
///
///   // Accessing a removed pod throws an exception.
///   try {
///     registry.getDefinition('user');
///   } catch (e) {
///     print(e); // NoSuchPodDefinitionException: No pod named 'user' is defined
///   }
/// }
/// ```
/// {@endtemplate}
class SimplePodDefinitionRegistry extends SimpleAliasRegistry implements PodDefinitionRegistry {
  /// Internal storage for pod definitions, keyed by pod name.
  final Map<String, PodDefinition> _definitions = HashMap<String, PodDefinition>();

  /// {@macro simple_pod_definition_registry}
  ///
  /// Creates a new simple pod definition registry instance.
  ///
  /// Example:
  /// ```dart
  /// final registry = SimplePodDefinitionRegistry();
  /// ```
  SimplePodDefinitionRegistry();

  @override
  bool containsDefinition(String name) => _definitions.containsKey(name);

  @override
  PodDefinition getDefinition(String name) {
    final pod = _definitions[name];
    if(pod == null) {
      throw NoSuchPodDefinitionException.byName(name);
    }

    return pod;
  }

  @override
  int getNumberOfPodDefinitions() => _definitions.length;

  @override
  List<String> getDefinitionNames() => List.unmodifiable(_definitions.keys.toList());

  @override
  Future<bool> isNameInUse(String name) async => isAlias(name) || containsDefinition(name);

  @override
  Future<void> registerDefinition(String name, PodDefinition pod) async {
    if(name.isEmpty) {
      throw IllegalArgumentException('Pod name cannot be empty');
    }

    if(isAlias(name)) {
      throw IllegalArgumentException('Pod name cannot be an alias');
    }

    _definitions[name] = pod;
  }

  @override
  Future<void> removeDefinition(String name) async {
    final removed = _definitions.remove(name);
    if (removed == null) {
      throw NoSuchPodDefinitionException.byName(name);
    }

    // Clean up aliases pointing to this name
    final aliases = getAliases(name).toList();
    for (final alias in aliases) {
      removeAlias(alias);
    }
  }
}