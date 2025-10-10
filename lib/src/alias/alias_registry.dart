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

/// {@template alias_registry_aware}
/// Contract for objects that support alias registration.
///
/// This interface allows a registry to associate multiple aliases with a
/// single primary name. Aliases provide alternative identifiers for the same
/// registered object, making the registry more flexible in terms of lookup.
///
/// ### Example
/// ```dart
/// final registry = MyAliasRegistry();
///
/// // Register the primary name
/// registry.registerPrimary('userService');
///
/// // Register multiple aliases for the same service
/// registry.registerAlias('userService', 'accountService');
/// registry.registerAlias('userService', 'profileService');
///
/// // All names resolve to the same object
/// final service1 = registry.get('userService');
/// final service2 = registry.get('accountService');
/// final service3 = registry.get('profileService');
/// ```
/// {@endtemplate}
abstract interface class AliasRegistryAware {
  /// {@template alias_registry_register_alias}
  /// Registers an alias for an existing name in the registry.
  /// 
  /// Associates a new [alias] with an existing [name], allowing the object
  /// registered under [name] to be accessed using the [alias] as well.
  /// 
  /// ## Parameters:
  /// - [name]: The primary name that already exists in the registry
  /// - [alias]: The alternative name to register for the primary name
  /// 
  /// ## Throws:
  /// - [InvalidArgumentException] if [alias] is already registered as a primary name
  /// - [InvalidArgumentException] if [alias] is already registered as an alias
  /// - [InvalidArgumentException] if [name] does not exist in the registry
  /// 
  /// ## Example:
  /// ```dart
  /// final registry = MyAliasRegistry();
  /// 
  /// // First register a primary name
  /// registry.registerPrimary('emailService');
  /// 
  /// // Then register aliases for it
  /// registry.registerAlias('emailService', 'mailService');
  /// registry.registerAlias('emailService', 'smtpService');
  /// 
  /// // Now the service can be accessed by any of these names
  /// final service1 = registry.get('emailService');
  /// final service2 = registry.get('mailService'); // Same as service1
  /// final service3 = registry.get('smtpService'); // Same as service1
  /// ```
  /// {@endtemplate}
  void registerAlias(String name, String alias);
}

/// {@template alias_registry}
/// An abstract interface for managing name aliases in a registry system.
/// 
/// The [AliasRegistry] provides a contract for classes that need to manage
/// alternative names (aliases) for registered objects. This is particularly
/// useful in dependency injection systems, configuration management, or
/// any scenario where objects need to be accessible by multiple names.
/// 
/// ## Key Features:
/// - Register alternative names for existing entries
/// - Remove aliases when they are no longer needed
/// - Check if a given name is an alias
/// - Retrieve all aliases for a specific name
/// 
/// ## Implementation Notes:
/// Implementations should ensure that:
/// - Aliases cannot conflict with existing primary names
/// - Circular alias references are handled appropriately
/// - Alias management is thread-safe if used in concurrent environments
/// 
/// ## Usage Example:
/// ```dart
/// class MyAliasRegistry implements AliasRegistry {
///   final _aliases = <String, String>{};
///   final _reverseMap = <String, List<String>>{};
/// 
///   @override
///   void registerAlias(String name, String alias) {
///     if (_aliases.containsKey(alias)) {
///       throw InvalidArgumentException('Alias $alias already exists');
///     }
///     _aliases[alias] = name;
///     _reverseMap.putIfAbsent(name, () => []).add(alias);
///   }
/// 
///   // ... other method implementations
/// }
/// 
/// void main() {
///   final registry = MyAliasRegistry();
///   
///   // Register a service with its primary name and aliases
///   registry.registerAlias('databaseService', 'db');
///   registry.registerAlias('databaseService', 'dataSource');
///   
///   print(registry.isAlias('db')); // true
///   print(registry.isAlias('databaseService')); // false
///   print(registry.getAliases('databaseService')); // ['db', 'dataSource']
/// }
/// ```
/// {@endtemplate}
abstract interface class AliasRegistry implements AliasRegistryAware {
  /// {@template alias_registry_remove_alias}
  /// Removes an alias from the registry.
  /// 
  /// Removes the specified [alias] from the registry, making it no longer
  /// valid for accessing the associated object. This does not affect the
  /// primary name or the object itself.
  /// 
  /// ## Parameters:
  /// - [alias]: The alias to remove from the registry
  /// 
  /// ## Throws:
  /// - [InvalidArgumentException] if [alias] is not registered as an alias
  /// 
  /// ## Example:
  /// ```dart
  /// final registry = MyAliasRegistry();
  /// registry.registerAlias('logService', 'logger');
  /// 
  /// // Alias is active
  /// print(registry.isAlias('logger')); // true
  /// 
  /// // Remove the alias
  /// registry.removeAlias('logger');
  /// 
  /// // Alias is no longer active
  /// print(registry.isAlias('logger')); // false
  /// 
  /// // Primary name remains unaffected
  /// final service = registry.get('logService'); // Still works
  /// ```
  /// {@endtemplate}
  void removeAlias(String alias);

  /// {@template alias_registry_is_alias}
  /// Checks whether the given [name] is registered as an alias.
  /// 
  /// Returns `true` if [name] is currently registered as an alias for
  /// another primary name, `false` otherwise.
  /// 
  /// ## Parameters:
  /// - [name]: The name to check for alias status
  /// 
  /// ## Returns:
  /// `true` if [name] is an alias, `false` if it's a primary name or not registered.
  /// 
  /// ## Example:
  /// ```dart
  /// final registry = MyAliasRegistry();
  /// registry.registerAlias('userRepository', 'userRepo');
  /// 
  /// print(registry.isAlias('userRepository')); // false - primary name
  /// print(registry.isAlias('userRepo')); // true - alias
  /// print(registry.isAlias('nonexistent')); // false - not registered
  /// ```
  /// {@endtemplate}
  bool isAlias(String name);

  /// {@template alias_registry_get_aliases}
  /// Retrieves all aliases registered for the given primary [name].
  /// 
  /// Returns a list of all alternative names that have been registered
  /// for the specified primary [name]. If no aliases exist for the name,
  /// returns an empty list.
  /// 
  /// ## Parameters:
  /// - [name]: The primary name to retrieve aliases for
  /// 
  /// ## Returns:
  /// A list of alias strings for the given primary name, or an empty list
  /// if no aliases are registered.
  /// 
  /// ## Example:
  /// ```dart
  /// final registry = MyAliasRegistry();
  /// registry.registerAlias('paymentGateway', 'payGateway');
  /// registry.registerAlias('paymentGateway', 'paymentProcessor');
  /// registry.registerAlias('paymentGateway', 'gateway');
  /// 
  /// final aliases = registry.getAliases('paymentGateway');
  /// print(aliases); // ['payGateway', 'paymentProcessor', 'gateway']
  /// 
  /// // For a name with no aliases
  /// final noAliases = registry.getAliases('shoppingCart');
  /// print(noAliases); // []
  /// ```
  /// {@endtemplate}
  List<String> getAliases(String name);

  /// {@template alias_registry_get_alias}
  /// Retrieves the primary name associated with the given [alias].
  /// 
  /// Returns the primary name if [alias] is registered as an alias,
  /// or `null` if the alias is not registered.
  /// 
  /// ## Parameters:
  /// - [alias]: The alias to retrieve the primary name for
  /// 
  /// ## Returns:
  /// The primary name associated with the alias, or `null` if not found.
  /// 
  /// ## Example:
  /// ```dart
  /// final registry = MyAliasRegistry();
  /// registry.registerAlias('userRepository', 'userRepo');
  /// 
  /// final primaryName = registry.getAlias('userRepo');
  /// print(primaryName); // 'userRepository'
  /// 
  /// final nonAlias = registry.getAlias('nonexistent');
  /// print(nonAlias); // null
  /// ```
  /// {@endtemplate}
  String? getAlias(String name);
}