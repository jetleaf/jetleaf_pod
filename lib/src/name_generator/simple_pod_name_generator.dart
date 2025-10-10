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

import '../definition/pod_definition.dart';
import '../definition/pod_definition_registry.dart';
import 'pod_name_generator.dart';

/// {@template default_pod_name_generator}
/// Default implementation of the [PodNameGenerator] interface.
///
/// This generator produces pod names by taking the simple class name of the
/// pod's type and decapitalizing the first character, following standard conventions.
///
/// For example, a class `package:my_app/services/my_service.dart.MyService` would be registered with the
/// name `myService`.
///
/// Acronyms or all-uppercase prefixes (e.g. `URLService`) are **not** decapitalized,
/// preserving the original class name casing.
///
/// This is the default pod name generation strategy used throughout the JetLeaf
/// framework when no explicit pod name is provided via annotations or configuration.
///
/// Example usage:
/// ```dart
/// final generator = SimplePodNameGenerator();
/// final podDef = RootPodDefinition(type: Class<UserService>());
/// final podName = generator.generate(podDef, registry);
/// print(podName); // 'userService'
/// ```
/// {@endtemplate}
class SimplePodNameGenerator implements PodNameGenerator {
  /// {@macro default_pod_name_generator}
  ///
  /// Creates a new default pod name generator instance.
  ///
  /// Example:
  /// ```dart
  /// final generator = SimplePodNameGenerator();
  /// ```
  const SimplePodNameGenerator();

  @override
  String generate(PodDefinition definition, PodDefinitionRegistry registry) {
    final className = definition.type.getQualifiedName();
    final simpleName = className.split('.').last;
    return _decapitalize(simpleName);
  }

  /// {@template default_pod_name_generator_decapitalize}
  /// Decapitalizes the given class name unless it starts with multiple uppercase letters.
  ///
  /// This method defines a naming convention where:
  /// - Regular class names get the first character lowercased: `UserService` → `userService`
  /// - Acronyms and all-uppercase prefixes are preserved: `URLService` → `URLService`
  /// - Single character class names are lowercased: `A` → `a`
  ///
  /// [name]: The class name to decapitalize
  /// Returns the decapitalized pod name following naming conventions
  ///
  /// Example:
  /// ```dart
  /// final generator = SimplePodNameGenerator();
  /// print(generator._decapitalize('UserService'));    // 'userService'
  /// print(generator._decapitalize('URLService'));     // 'URLService'
  /// print(generator._decapitalize('XMLParser'));      // 'XMLParser'
  /// print(generator._decapitalize('MyService'));      // 'myService'
  /// print(generator._decapitalize('a'));              // 'a'
  /// print(generator._decapitalize('A'));              // 'a'
  /// ```
  /// {@endtemplate}
  String _decapitalize(String name) {
    if (name.isEmpty) return name;
    if (name.length > 1 && _isUpperCase(name[0]) && _isUpperCase(name[1])) {
      return name;
    }
    return name[0].toLowerCase() + name.substring(1);
  }

  /// {@template default_pod_name_generator_is_upper_case}
  /// Checks if a character is uppercase.
  ///
  /// This helper method determines if a character is uppercase by comparing
  /// it to its uppercase version. This handles Unicode characters correctly.
  ///
  /// [char]: The character to check (must be a single character string)
  /// Returns true if the character is uppercase, false otherwise
  ///
  /// Example:
  /// ```dart
  /// print(_isUpperCase('A')); // true
  /// print(_isUpperCase('a')); // false
  /// print(_isUpperCase('1')); // false
  /// print(_isUpperCase('À')); // true (Unicode uppercase)
  /// ```
  /// {@endtemplate}
  bool _isUpperCase(String char) {
    if (char.isEmpty) return false;
    if (char.length != 1) return false;
    final upper = char.toUpperCase();
    final lower = char.toLowerCase();
    return upper == char && lower != char;
  }

  @override
  String getPackageName() => PackageNames.POD;
}