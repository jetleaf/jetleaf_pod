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
import 'package:meta/meta.dart';

import 'alias_registry.dart';

/// {@template simple_alias_registry}
/// A thread-safe implementation of [AliasRegistry] using [LocalThread] storage.
/// 
/// This implementation maintains separate alias mappings for each thread with support for:
/// - Alias overriding control
/// - Circular reference detection
/// - Alias resolution and canonical name resolution
/// - Thread-local storage using ThreadLocal
/// 
/// ## Key Features:
/// - Thread-safe alias management using ThreadLocal
/// - Support for alias chains and transitive alias resolution
/// - Configurable alias overriding behavior
/// - Circular reference detection during registration
/// - Efficient thread-local alias lookup and management
/// 
/// ## Storage Structure (per thread):
/// - `_aliasMap`: Map of alias → canonical name mappings
/// - `_aliasNames`: List of alias names in registration order
/// 
/// ## Usage Example:
/// ```dart
/// final registry = SimpleAliasRegistry();
/// 
/// // Register aliases in the current thread
/// registry.registerAlias('userService', 'userManager');
/// registry.registerAlias('userService', 'accountService');
/// 
/// // Check if a name is an alias
/// print(registry.isAlias('userManager')); // true
/// 
/// // Get all aliases for a name (including transitive aliases)
/// final aliases = registry.getAliases('userService');
/// print(aliases); // ['userManager', 'accountService']
/// 
/// // Resolve canonical name
/// print(registry.canonicalName('userManager')); // 'userService'
/// ```
/// {@endtemplate}
class SimpleAliasRegistry implements AliasRegistry {
  /// Thread-local map from alias to canonical name
  final LocalThread<Map<String, String>> _aliasMap = LocalThread<Map<String, String>>();
  
  /// Thread-local list of alias names in registration order
  final LocalThread<List<String>> _aliasNames = LocalThread<List<String>>();

  /// {@macro simple_alias_registry}
  SimpleAliasRegistry() {
    // Initialize thread-local storage
    _aliasMap.set({});
    _aliasNames.set([]);
  }

  /// {@template simple_alias_registry_get_alias_map}
  /// Gets the alias map for the current thread, initializing if necessary.
  /// 
  /// This internal method ensures that each thread has its own alias mapping
  /// and handles lazy initialization of the thread-local storage.
  /// 
  /// ## Returns:
  /// The thread-local alias map (alias → canonical name)
  /// {@endtemplate}
  Map<String, String> _getAliasMap() {
    var map = _aliasMap.get();
    if (map == null) {
      map = {};
      _aliasMap.set(map);
    }
    return map;
  }

  /// {@template simple_alias_registry_get_alias_names}
  /// Gets the alias names list for the current thread, initializing if necessary.
  /// 
  /// This internal method ensures that each thread has its own list of
  /// alias names and handles lazy initialization of the thread-local storage.
  /// 
  /// ## Returns:
  /// The thread-local list of alias names in registration order
  /// {@endtemplate}
  List<String> _getAliasNames() {
    var list = _aliasNames.get();
    if (list == null) {
      list = [];
      _aliasNames.set(list);
    }
    return list;
  }

  @override
  void registerAlias(String name, String alias) {
    if (name.isEmpty) {
      throw IllegalArgumentException("'name' must not be empty");
    }
    if (alias.isEmpty) {
      throw IllegalArgumentException("'alias' must not be empty");
    }

    return synchronized(this, () {
      final aliasMap = _getAliasMap();
      final aliasNames = _getAliasNames();

      if (alias == name) {
        aliasMap.remove(alias);
        aliasNames.remove(alias);
        // Log debug: Alias definition ignored since it points to same name
        return;
      }

      final registeredName = aliasMap[alias];
      if (registeredName != null) {
        if (registeredName == name) {
          // An existing alias - no need to re-register
          return;
        }
        if (!allowAliasOverriding()) {
          throw IllegalStateException("Cannot define alias '$alias' for name '$name': It is already registered for name '$registeredName'.");
        }
        // Log debug: Overriding alias definition
      }

      checkForAliasCircle(name, alias);
      aliasMap[alias] = name;
      aliasNames.add(alias);
      // Log trace: Alias definition registered
    });
  }

  /// {@template simple_alias_registry_allow_alias_overriding}
  /// Determine whether alias overriding is allowed.
  /// 
  /// Subclasses can override this method to control alias overriding behavior.
  /// When returns `false`, attempting to register an alias that already exists
  /// for a different name will throw an exception.
  /// 
  /// ## Returns:
  /// `true` if alias overriding is allowed (default), `false` otherwise
  /// 
  /// ## Example:
  /// ```dart
  /// class StrictAliasRegistry extends SimpleAliasRegistry {
  ///   @override
  ///   bool allowAliasOverriding() => false; // Disallow overriding
  /// }
  /// 
  /// final registry = StrictAliasRegistry();
  /// registry.registerAlias('service1', 'alias1');
  /// 
  /// try {
  ///   registry.registerAlias('service2', 'alias1'); // Throws exception
  /// } on IllegalStateException catch (e) {
  ///   print('Alias overriding not allowed');
  /// }
  /// ```
  /// {@endtemplate}
  @protected
  bool allowAliasOverriding() => true;

  /// {@template simple_alias_registry_has_alias}
  /// Determine whether the given name has the given alias registered.
  /// 
  /// Checks both direct aliases and transitive aliases (aliases of aliases).
  /// 
  /// ## Parameters:
  /// - [name]: The canonical name to check
  /// - [alias]: The alias to check for
  /// 
  /// ## Returns:
  /// `true` if the alias is registered for the name (directly or transitively),
  /// `false` otherwise
  /// 
  /// ## Example:
  /// ```dart
  /// final registry = SimpleAliasRegistry();
  /// registry.registerAlias('service', 'alias1');
  /// registry.registerAlias('alias1', 'alias2');
  /// 
  /// print(registry.hasAlias('service', 'alias1')); // true - direct
  /// print(registry.hasAlias('service', 'alias2')); // true - transitive
  /// print(registry.hasAlias('service', 'nonexistent')); // false
  /// ```
  /// {@endtemplate}
  @protected
  bool hasAlias(String name, String alias) {
    return synchronized(this, () {
      final aliasMap = _getAliasMap();
      final registeredName = aliasMap[alias];
      return registeredName == name || (registeredName != null && hasAlias(name, registeredName));
    });
  }

  @override
  void removeAlias(String alias) {
    return synchronized(this, () {
      final aliasMap = _getAliasMap();
      final aliasNames = _getAliasNames();
      
      final name = aliasMap.remove(alias);
      if (name == null) {
        throw IllegalStateException("No alias '$alias' registered");
      }

      aliasNames.remove(alias);
    });
  }

  @override
  bool isAlias(String name) {
    return synchronized(this, () {
      final aliasMap = _getAliasMap();
      return aliasMap.containsKey(name);
    });
  }

  @override
  List<String> getAliases(String name) {
    return synchronized(this, () {
      final aliasMap = _getAliasMap();
      final result = <String>[];
      _retrieveAliases(name, result, aliasMap);

      return List.unmodifiable(result);
    });
  }

  /// {@template simple_alias_registry_retrieve_aliases}
  /// Transitively retrieve all aliases for the given name.
  /// 
  /// This internal method recursively collects all aliases that point to
  /// the given name, including indirect aliases through alias chains.
  /// 
  /// ## Parameters:
  /// - [name]: The canonical name to retrieve aliases for
  /// - [result]: The list to collect aliases into
  /// - [aliasMap]: The alias map to search through
  /// 
  /// ## Example:
  /// ```dart
  /// // Given: alias1 → service, alias2 → alias1, alias3 → alias2
  /// // Calling _retrieveAliases('service', result, aliasMap)
  /// // result becomes: ['alias1', 'alias2', 'alias3']
  /// ```
  /// {@endtemplate}
  void _retrieveAliases(String name, List<String> result, Map<String, String> aliasMap) {
    aliasMap.forEach((alias, registeredName) {
      if (registeredName == name) {
        result.add(alias);
        _retrieveAliases(alias, result, aliasMap);
      }
    });
  }

  /// {@template simple_alias_registry_check_for_alias_circle}
  /// Check whether the given name points back to the given alias as an alias
  /// in the other direction already, catching a circular reference.
  /// 
  /// ## Parameters:
  /// - [name]: The canonical name being registered
  /// - [alias]: The alias being registered
  /// 
  /// ## Throws:
  /// - [IllegalStateException] if a circular reference is detected
  /// 
  /// ## Example:
  /// ```dart
  /// final registry = SimpleAliasRegistry();
  /// registry.registerAlias('serviceA', 'serviceB');
  /// 
  /// try {
  ///   registry.registerAlias('serviceB', 'serviceA'); // Circular!
  ///   // Throws: "Cannot register alias 'serviceA' for name 'serviceB': 
  ///   // Circular reference - 'serviceB' is a direct or indirect alias for 
  ///   // 'serviceA' already"
  /// } on IllegalStateException catch (e) {
  ///   print('Circular reference prevented');
  /// }
  /// ```
  /// {@endtemplate}
  @protected
  void checkForAliasCircle(String name, String alias) {
    if (hasAlias(alias, name)) {
      throw IllegalStateException(
        "Cannot register alias '$alias' for name '$name': "
        "Circular reference - '$name' is a direct or indirect alias for "
        "'$alias' already"
      );
    }
  }

  /// {@template simple_alias_registry_canonical_name}
  /// Determine the target name, resolving aliases to their ultimate target.
  /// 
  /// Follows alias chains recursively until it finds the ultimate target name
  /// that is not itself an alias of another name.
  /// 
  /// ## Parameters:
  /// - [name]: The name to resolve (can be an alias or target name)
  /// 
  /// ## Returns:
  /// The ultimate target name after resolving all aliases
  /// 
  /// ## Example:
  /// ```dart
  /// final registry = SimpleAliasRegistry();
  /// registry.registerAlias('ultimateService', 'alias1');
  /// registry.registerAlias('alias1', 'alias2');
  /// registry.registerAlias('alias2', 'alias3');
  /// 
  /// print(registry.targetName('alias3')); // 'ultimateService'
  /// print(registry.targetName('alias1')); // 'ultimateService'
  /// print(registry.targetName('ultimateService')); // 'ultimateService'
  /// ```
  /// {@endtemplate}
  @protected
  String targetName(String name) {
    return synchronized(this, () {
      final aliasMap = _getAliasMap();
      var targetName = name;
      String? resolvedName;
      
      do {
        resolvedName = aliasMap[targetName];
        if (resolvedName != null) {
          targetName = resolvedName;
        }
      } while (resolvedName != null);
      
      return targetName;
    });
  }

  @override
  String? getAlias(String name) => synchronized(this, () {
    final aliasMap = _getAliasMap();
    return aliasMap[name];
  });

  /// {@template simple_alias_registry_resolve_aliases}
  /// Resolve all alias target names and aliases registered in this registry,
  /// applying the given [StringValueResolver] to them.
  /// 
  /// The value resolver may for example resolve placeholders
  /// in target pod names and even in alias names. This is useful for
  /// processing aliases that contain placeholders that need to be resolved
  /// at runtime.
  /// 
  /// ## Parameters:
  /// - [valueResolver]: A function that resolves string values (e.g., placeholders)
  /// 
  /// ## Throws:
  /// - [IllegalStateException] if resolution would cause conflicts
  /// 
  /// ## Example:
  /// ```dart
  /// final registry = SimpleAliasRegistry();
  /// registry.registerAlias('${database.service}', '${db.alias}');
  /// 
  /// // Resolve placeholders
  /// registry.resolveAliases((value) {
  ///   if (value == '${database.service}') return 'mysqlService';
  ///   if (value == '${db.alias}') return 'database';
  ///   return value;
  /// });
  /// 
  /// // Now aliases are resolved
  /// print(registry.getAlias('database')); // 'mysqlService'
  /// ```
  /// {@endtemplate}
  @protected
  void resolveAliases(String Function(String) valueResolver) {
    return synchronized(this, () {
      final aliasMap = _getAliasMap();
      final aliasNames = _getAliasNames();
      final aliasNamesCopy = List<String>.from(aliasNames);
      
      for (final alias in aliasNamesCopy) {
        final registeredName = aliasMap[alias];
        if (registeredName != null) {
          final resolvedAlias = valueResolver(alias);
          final resolvedName = valueResolver(registeredName);
          
          if (resolvedAlias.isEmpty || resolvedName.isEmpty || resolvedAlias == resolvedName) {
            aliasMap.remove(alias);
            aliasNames.remove(alias);
          } else if (resolvedAlias != alias) {
            final existingName = aliasMap[resolvedAlias];
            if (existingName != null) {
              if (existingName == resolvedName) {
                // Pointing to existing alias - just remove placeholder
                aliasMap.remove(alias);
                aliasNames.remove(alias);
                continue;
              }
              throw IllegalStateException(
                "Cannot register resolved alias '$resolvedAlias' (original: '$alias') "
                "for name '$resolvedName': It is already registered for name '$existingName'."
              );
            }

            checkForAliasCircle(resolvedName, resolvedAlias);

            aliasMap.remove(alias);
            aliasNames.remove(alias);
            
            aliasMap[resolvedAlias] = resolvedName;
            aliasNames.add(resolvedAlias);
          } else if (registeredName != resolvedName) {
            aliasMap[alias] = resolvedName;
          }
        }
      }
    });
  }

  /// {@template simple_alias_registry_get_alias_names_list}
  /// Returns all registered aliases as an unmodifiable view for the current thread.
  /// 
  /// The list is returned in the order aliases were registered.
  /// 
  /// ## Returns:
  /// An unmodifiable list of all alias names in registration order
  /// 
  /// ## Example:
  /// ```dart
  /// final registry = SimpleAliasRegistry();
  /// registry.registerAlias('service1', 'alias1');
  /// registry.registerAlias('service2', 'alias2');
  /// registry.registerAlias('service3', 'alias3');
  /// 
  /// final aliases = registry.getAliasNames();
  /// print(aliases); // ['alias1', 'alias2', 'alias3'] in registration order
  /// ```
  /// {@endtemplate}
  @protected
  List<String> getAliasNames() {
    return synchronized(this, () {
      final aliasNames = _getAliasNames();
      return List.unmodifiable(aliasNames);
    });
  }

  /// {@template simple_alias_registry_get_canonical_names}
  /// Returns all registered target names as an unmodifiable view for the current thread.
  /// 
  /// Target names are the ultimate targets that aliases point to,
  /// after resolving any alias chains.
  /// 
  /// ## Returns:
  /// An unmodifiable list of all target names
  /// 
  /// ## Example:
  /// ```dart
  /// final registry = SimpleAliasRegistry();
  /// registry.registerAlias('ultimateService', 'alias1');
  /// registry.registerAlias('alias1', 'alias2');
  /// registry.registerAlias('otherService', 'alias3');
  /// 
  /// final names = registry.getUltimateNames();
  /// print(names); // ['ultimateService', 'otherService']
  /// ```
  /// {@endtemplate}
  @protected
  List<String> getUltimateNames() {
    return synchronized(this, () {
      final aliasMap = _getAliasMap();
      final names = <String>{};
      for (final name in aliasMap.values) {
        names.add(name);
      }
      return List.unmodifiable(names.toList());
    });
  }

  /// {@template simple_alias_registry_clear}
  /// Clears all alias registrations for the current thread.
  /// 
  /// Removes all alias mappings and resets the registry to its initial state
  /// for the current thread. Other threads are unaffected.
  /// 
  /// ## Example:
  /// ```dart
  /// final registry = SimpleAliasRegistry();
  /// registry.registerAlias('service1', 'alias1');
  /// registry.registerAlias('service2', 'alias2');
  /// 
  /// print(registry.aliasCount); // 2
  /// 
  /// registry.clear();
  /// 
  /// print(registry.aliasCount); // 0
  /// print(registry.isEmpty); // true
  /// ```
  /// {@endtemplate}
  @protected
  void clear() {
    return synchronized(this, () {
      final aliasMap = _getAliasMap();
      final aliasNames = _getAliasNames();
      aliasMap.clear();
      aliasNames.clear();
    });
  }

  /// {@template simple_alias_registry_alias_count}
  /// Returns the number of registered aliases for the current thread.
  /// 
  /// ## Returns:
  /// The count of alias mappings in the current thread
  /// 
  /// ## Example:
  /// ```dart
  /// final registry = SimpleAliasRegistry();
  /// print(registry.aliasCount); // 0
  /// 
  /// registry.registerAlias('service1', 'alias1');
  /// registry.registerAlias('service2', 'alias2');
  /// 
  /// print(registry.aliasCount); // 2
  /// ```
  /// {@endtemplate}
  @protected
  int get aliasCount => synchronized(this, () {
    final aliasMap = _getAliasMap();
    return aliasMap.length;
  });

  /// {@template simple_alias_registry_is_empty}
  /// Returns true if no aliases are registered for the current thread.
  /// 
  /// ## Returns:
  /// `true` if the registry is empty, `false` otherwise
  /// 
  /// ## Example:
  /// ```dart
  /// final registry = SimpleAliasRegistry();
  /// print(registry.isEmpty); // true
  /// 
  /// registry.registerAlias('service', 'alias');
  /// print(registry.isEmpty); // false
  /// ```
  /// {@endtemplate}
  @protected
  bool get isEmpty => synchronized(this, () {
    final aliasMap = _getAliasMap();
    return aliasMap.isEmpty;
  });

  /// {@template simple_alias_registry_is_not_empty}
  /// Returns true if aliases are registered for the current thread.
  /// 
  /// ## Returns:
  /// `true` if the registry contains aliases, `false` otherwise
  /// 
  /// ## Example:
  /// ```dart
  /// final registry = SimpleAliasRegistry();
  /// print(registry.isNotEmpty); // false
  /// 
  /// registry.registerAlias('service', 'alias');
  /// print(registry.isNotEmpty); // true
  /// ```
  /// {@endtemplate}
  @protected
  bool get isNotEmpty => synchronized(this, () {
    final aliasMap = _getAliasMap();
    return aliasMap.isNotEmpty;
  });

  /// {@template simple_alias_registry_thread_local_alias_map}
  /// Gets the thread-local alias map for testing or advanced use cases.
  /// 
  /// ## Warning:
  /// This exposes internal state and should be used with caution.
  /// Modifying the returned map may break registry consistency.
  /// 
  /// ## Returns:
  /// The internal thread-local alias map
  /// 
  /// ## Example:
  /// ```dart
  /// final registry = SimpleAliasRegistry();
  /// registry.registerAlias('service', 'alias');
  /// 
  /// final internalMap = registry.threadLocalAliasMap;
  /// print(internalMap['alias']); // 'service'
  /// 
  /// // Use with caution - direct modification may cause issues
  /// internalMap['newAlias'] = 'newService';
  /// ```
  /// {@endtemplate}
  @protected
  Map<String, String> get threadLocalAliasMap => _getAliasMap();

  /// {@template simple_alias_registry_thread_local_alias_names}
  /// Gets the thread-local alias names list for testing or advanced use cases.
  /// 
  /// ## Warning:
  /// This exposes internal state and should be used with caution.
  /// Modifying the returned list may break registry consistency.
  /// 
  /// ## Returns:
  /// The internal thread-local alias names list
  /// 
  /// ## Example:
  /// ```dart
  /// final registry = SimpleAliasRegistry();
  /// registry.registerAlias('service', 'alias');
  /// 
  /// final internalList = registry.threadLocalAliasNames;
  /// print(internalList); // ['alias']
  /// 
  /// // Use with caution - direct modification may cause issues
  /// internalList.add('manualAlias');
  /// ```
  /// {@endtemplate}
  @protected
  List<String> get threadLocalAliasNames => _getAliasNames();
}