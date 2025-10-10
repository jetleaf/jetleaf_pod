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

// --------------------------------------------------------------------------------------------------------
// Scope
// --------------------------------------------------------------------------------------------------------

import 'package:jetleaf_lang/lang.dart';

import '../helpers/object.dart';

/// {@template pod_scope}
/// Interface for pod scopes that manage object lifecycle and contextual storage.
///
/// A Scope defines a contextual boundary for pod instances, controlling
/// their lifecycle, visibility, and destruction. Different scope implementations
/// provide various lifecycle strategies such as singleton, prototype, request,
/// session, and custom scopes.
///
/// Key responsibilities:
/// - Object creation and caching based on scope semantics
/// - Lifecycle management and destruction callbacks
/// - Contextual object resolution
/// - Thread-safe scope operations
/// - Conversation/context identification
///
/// Scope implementations can provide:
/// - Singleton: One instance per container (default)
/// - Prototype: New instance for each request
/// - Request: One instance per HTTP request
/// - Session: One instance per user session
/// - Custom application-specific scopes
///
/// Example usage with custom scope:
/// ```dart
/// class RequestScope implements Scope {
///   final Map<String, Object> _objects = {};
///   final Map<String, List<Runnable>> _destructionCallbacks = {};
///
///   @override
///   Object get(String name, ObjectFactory factory) {
///     return _objects.putIfAbsent(name, () => factory());
///   }
///
///   @override
///   Object? remove(String name) {
///     _runDestructionCallbacks(name);
///     return _objects.remove(name);
///   }
///
///   // ... other interface implementations
/// }
///
/// final requestScope = RequestScope();
/// final userService = requestScope.get('userService', () => UserService());
/// ```
/// {@endtemplate}
abstract class PodScope {
  /// {@template pod_scope_get}
  /// Return the object with the given name from the underlying scope,
  /// creating it if not found in the underlying storage mechanism.
  ///
  /// This is the primary method for obtaining objects from a scope.
  /// The scope implementation determines the lifecycle semantics:
  /// - Singleton: returns the same instance always
  /// - Prototype: creates new instance each time
  /// - Request/Session: returns instance specific to current context
  ///
  /// [name]: The name of the object to retrieve or create
  /// [factory]: Factory function to create the object if it doesn't exist
  ///                  in the scope. The factory is only called if needed.
  /// Returns the object instance from the scope, either existing or newly created
  ///
  /// Throws:
  /// - [IllegalArgumentException] if name is null or empty
  /// - [ScopeException] if the object cannot be created or retrieved
  ///
  /// Example:
  /// ```dart
  /// // Get or create a pod from the scope
  /// final userService = scope.get('userService', () {
  ///   final service = UserService();
  ///   // Perform any initialization
  ///   service.initialize();
  ///   return service;
  /// });
  ///
  /// // Use the scoped object
  /// userService.processRequest();
  /// ```
  /// {@endtemplate}
  Future<ObjectHolder<Object>> get(String name, ObjectFactory<Object> factory);
  
  /// {@template pod_scope_remove}
  /// Remove the object with the given name from the underlying scope.
  ///
  /// This method removes an object from the scope and executes any
  /// registered destruction callbacks. The removal behavior depends
  /// on the scope implementation:
  /// - Singleton: removes and destroys the singleton
  /// - Prototype: typically no-op as prototypes aren't cached
  /// - Request/Session: removes from current context
  ///
  /// [name]: The name of the object to remove
  /// Returns the removed object, or null if no object was found
  ///
  /// Throws:
  /// - [IllegalArgumentException] if name is null or empty
  /// - [ScopeException] if the scope doesn't support removal
  ///
  /// Example:
  /// ```dart
  /// // Remove an object from the scope
  /// final removed = scope.remove('temporaryService');
  /// if (removed != null) {
  ///   print('Removed service: $removed');
  /// }
  /// ```
  /// {@endtemplate}
  ObjectHolder<Object>? remove(String name) => null;
  
  /// {@template pod_scope_register_destruction_callback}
  /// Register a callback to be executed on destruction of the specified
  /// object in the scope (or at destruction of the entire scope, if the
  /// scope does not destroy individual objects but rather only terminates in its entirety).
  ///
  /// Destruction callbacks are essential for proper resource cleanup
  /// and are typically used for:
  /// - Closing database connections
  /// - Releasing file handles
  /// - Stopping background threads
  /// - Cleaning up temporary resources
  ///
  /// [name]: The name of the object to associate the callback with
  /// [callback]: The callback to execute when the object is destroyed
  ///             or when the scope terminates
  ///
  /// Throws:
  /// - [IllegalArgumentException] if name is null or empty, or callback is null
  /// - [UnsupportedOperationException] if the scope doesn't support destruction callbacks
  ///
  /// Example:
  /// ```dart
  /// final databaseConnection = DatabaseConnection();
  /// scope.registerDestructionCallback('databaseConnection', () {
  ///   databaseConnection.close();
  ///   print('Database connection closed');
  /// });
  ///
  /// // Later, when scope is destroyed or object is removed:
  /// // The callback will be executed automatically
  /// ```
  /// {@endtemplate}
  void registerDestructionCallback(String name, Runnable callback) {}
  
  /// {@template pod_scope_resolve_contextual_object}
  /// Resolve the contextual object for the given key, if any.
  ///
  /// This method provides access to context-specific objects that
  /// are not necessarily pods but are available within the scope's
  /// context. Examples include:
  /// - HTTP request/session attributes
  /// - Transaction contexts
  /// - Security contexts
  /// - Custom context attributes
  ///
  /// [key]: The key identifying the contextual object
  /// Returns the contextual object if found, or null if not available
  ///
  /// Example:
  /// ```dart
  /// // Resolve HTTP request context in a web scope
  /// final httpRequest = scope.resolveContextualObject('httpRequest');
  /// if (httpRequest != null) {
  ///   final userAgent = httpRequest.headers['User-Agent'];
  ///   print('User agent: $userAgent');
  /// }
  ///
  /// // Resolve security context
  /// final authContext = scope.resolveContextualObject('securityContext');
  /// if (authContext != null && authContext.isAuthenticated) {
  ///   // Process authenticated request
  /// }
  /// ```
  /// {@endtemplate}
  Object? resolveContextualObject(String key) => null;
  
  /// {@template pod_scope_get_conversation_id}
  /// Return the conversation ID for the current underlying scope, if any.
  ///
  /// The conversation ID identifies the current scope context and is
  /// typically used for:
  /// - Debugging and logging
  /// - Scope identification in distributed systems
  /// - Correlation of scope-related operations
  /// - Transaction management
  ///
  /// Returns a unique identifier for the current scope context,
  /// or null if the scope doesn't support conversation IDs
  ///
  /// Example:
  /// ```dart
  /// final conversationId = scope.getConversationId();
  /// if (conversationId != null) {
  ///   print('Current scope conversation: $conversationId');
  ///   logger.info('Operation in scope: $conversationId');
  /// }
  ///
  /// // Use in distributed tracing
  /// tracer.setScopeContext(conversationId);
  /// ```
  /// {@endtemplate}
  String? getConversationId() => null;
}