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

/// {@template autowire_mode}
/// Defines strategies for automatically wiring dependencies in a system.
///
/// Each mode indicates how a dependency should be resolved and injected
/// into a class or component.
///
/// ### Example
/// ```dart
/// void configurePod(AutowireMode mode) {
///   switch (mode) {
///     case AutowireMode.NO:
///       print("No autowiring will be applied.");
///       break;
///     case AutowireMode.BY_NAME:
///       print("Dependencies will be autowired by matching names.");
///       break;
///     case AutowireMode.BY_TYPE:
///       print("Dependencies will be autowired by matching types.");
///       break;
///   }
/// }
/// ```
/// {@endtemplate}
enum AutowireMode {
  /// No autowiring is applied. All dependencies must be explicitly configured.
  NO(0),

  /// Autowires dependencies by matching their names.
  BY_NAME(1),

  /// Autowires dependencies by matching their types.
  BY_TYPE(2);

  /// Numeric representation of the mode for easier serialization or mapping.
  final int value;

  /// Creates an [AutowireMode] with the given [value].
  const AutowireMode(this.value);

  /// Returns the [AutowireMode] that matches the given [name].
  ///
  /// The [name] is case-insensitive. For example:
  ///
  /// ```dart
  /// final mode = AutowireMode.valueOf("by_type");
  /// print(mode == AutowireMode.BY_TYPE); // true
  /// ```
  ///
  /// Throws an [IllegalArgumentException] if no matching mode exists.
  static AutowireMode valueOf(String name) {
    return switch (name.toLowerCase()) {
      'no' => NO,
      'by_name' => BY_NAME,
      'by_type' => BY_TYPE,
      _ => throw IllegalArgumentException('No AutowireMode with name $name')
    };
  }

  /// Returns the [AutowireMode] that corresponds to the given integer [value].
  ///
  /// ```dart
  /// final mode = AutowireMode.fromValue(1);
  /// print(mode == AutowireMode.BY_NAME); // true
  /// ```
  ///
  /// Throws an [IllegalArgumentException] if the value does not map to any mode.
  static AutowireMode fromValue(int value) {
    return switch (value) {
      0 => NO,
      1 => BY_NAME,
      2 => BY_TYPE,
      _ => throw IllegalArgumentException('No AutowireMode with value $value')
    };
  }
}

/// {@template design_role}
/// Defines the architectural role of a component within a system.
///
/// This enum helps categorize classes based on their responsibilities,
/// making it easier to organize and reason about the system design.
///
/// ### Example
/// ```dart
/// void assignRole(DesignRole role) {
///   if (role == DesignRole.APPLICATION) {
///     print("This is core application logic.");
///   } else if (role == DesignRole.SUPPORT) {
///     print("This is a supporting component.");
///   } else if (role == DesignRole.INFRASTRUCTURE) {
///     print("This provides infrastructure support.");
///   }
/// }
/// ```
/// {@endtemplate}
enum DesignRole {
  /// Represents the core application logic layer.
  APPLICATION(0),

  /// Represents supportive components, such as utilities or helpers.
  SUPPORT(1),

  /// Represents infrastructure-level components, such as persistence or networking.
  INFRASTRUCTURE(2);

  /// Numeric representation of the role for easier serialization or mapping.
  final int value;

  /// Creates a [DesignRole] with the given [value].
  const DesignRole(this.value);

  /// Returns the [DesignRole] that matches the given [name].
  ///
  /// ```dart
  /// final role = DesignRole.valueOf("support");
  /// print(role == DesignRole.SUPPORT); // true
  /// ```
  ///
  /// Throws an [IllegalArgumentException] if no matching role exists.
  static DesignRole valueOf(String name) {
    return switch (name.toLowerCase()) {
      'application' => APPLICATION,
      'support' => SUPPORT,
      'infrastructure' => INFRASTRUCTURE,
      _ => throw IllegalArgumentException('No DesignRole with name $name')
    };
  }

  /// Returns the [DesignRole] that corresponds to the given integer [value].
  ///
  /// ```dart
  /// final role = DesignRole.fromValue(2);
  /// print(role == DesignRole.INFRASTRUCTURE); // true
  /// ```
  ///
  /// Throws an [IllegalArgumentException] if the value does not map to any role.
  static DesignRole fromValue(int value) {
    return switch (value) {
      0 => APPLICATION,
      1 => SUPPORT,
      2 => INFRASTRUCTURE,
      _ => throw IllegalArgumentException('No DesignRole with value $value')
    };
  }
}

/// {@template dependency_check}
/// Defines the type of dependency validation to be performed when initializing
/// a component or system.
///
/// This is used to ensure that required dependencies are available and properly
/// configured before usage.
///
/// ### Example
/// ```dart
/// void validateDependencies(DependencyCheck check) {
///   switch (check) {
///     case DependencyCheck.NONE:
///       print("No dependency check will be performed.");
///       break;
///     case DependencyCheck.OBJECTS:
///       print("Only object references will be checked.");
///       break;
///     case DependencyCheck.ALL:
///       print("All dependencies will be validated.");
///       break;
///   }
/// }
/// ```
/// {@endtemplate}
enum DependencyCheck {
  /// No dependency validation is performed.
  NONE(0),

  /// Only checks object references for availability.
  OBJECTS(1),

  /// Performs validation on all dependencies.
  ALL(2);

  /// Numeric representation of the dependency check type.
  final int value;

  /// Creates a [DependencyCheck] with the given [value].
  const DependencyCheck(this.value);

  /// Returns the [DependencyCheck] that matches the given [name].
  ///
  /// ```dart
  /// final check = DependencyCheck.valueOf("all");
  /// print(check == DependencyCheck.ALL); // true
  /// ```
  ///
  /// Throws an [IllegalArgumentException] if no matching check exists.
  static DependencyCheck valueOf(String name) {
    return switch (name.toLowerCase()) {
      'none' => NONE,
      'objects' => OBJECTS,
      'all' => ALL,
      _ => throw IllegalArgumentException('No DependencyCheck with name $name')
    };
  }

  /// Returns the [DependencyCheck] that corresponds to the given integer [value].
  ///
  /// ```dart
  /// final check = DependencyCheck.fromValue(1);
  /// print(check == DependencyCheck.OBJECTS); // true
  /// ```
  ///
  /// Throws an [IllegalArgumentException] if the value does not map to any check.
  static DependencyCheck fromValue(int value) {
    return switch (value) {
      0 => NONE,
      1 => OBJECTS,
      2 => ALL,
      _ => throw IllegalArgumentException('No DependencyCheck with value $value')
    };
  }
}

/// {@template scope_type}
/// Defines the lifecycle scope of a component within a dependency injection
/// container.
///
/// This determines whether a single instance should be reused or a new
/// instance created each time.
///
/// ### Example
/// ```dart
/// void configureScope(ScopeType scope) {
///   if (scope == ScopeType.SINGLETON) {
///     print("A single shared instance will be used.");
///   } else if (scope == ScopeType.PROTOTYPE) {
///     print("A new instance will be created each time.");
///   }
/// }
/// ```
/// {@endtemplate}
enum ScopeType {
  /// A single shared instance is used throughout the application.
  SINGLETON(0),

  /// A new instance is created each time it is requested.
  PROTOTYPE(1);

  /// Numeric representation of the scope type.
  final int value;

  /// Creates a [ScopeType] with the given [value].
  const ScopeType(this.value);

  /// Returns the [ScopeType] that matches the given [name].
  ///
  /// ```dart
  /// final scope = ScopeType.valueOf("singleton");
  /// print(scope == ScopeType.SINGLETON); // true
  /// ```
  ///
  /// Throws an [IllegalArgumentException] if no matching scope exists.
  static ScopeType valueOf(String name) {
    return switch (name.toLowerCase()) {
      'singleton' => SINGLETON,
      'prototype' => PROTOTYPE,
      _ => throw IllegalArgumentException('No ScopeType with name $name')
    };
  }

  /// Returns the [ScopeType] that corresponds to the given integer [value].
  ///
  /// ```dart
  /// final scope = ScopeType.fromValue(1);
  /// print(scope == ScopeType.PROTOTYPE); // true
  /// ```
  ///
  /// Throws an [IllegalArgumentException] if the value does not map to any scope.
  static ScopeType fromValue(int value) {
    return switch (value) {
      0 => SINGLETON,
      1 => PROTOTYPE,
      _ => throw IllegalArgumentException('No ScopeType with value $value')
    };
  }
}