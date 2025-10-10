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

/// {@template disposable_pod}
/// Interface to be implemented by pods that need to release resources
/// or perform cleanup when being removed from the container or shut down.
///
/// Typically used to close file streams, database connections, or other
/// disposable resources.
///
/// ### Usage Example:
/// ```dart
/// class MyService implements DisposablePod {
///   @override
///   void onDestroy() {
///     print('Cleaning up resources');
///   }
/// }
/// ```
///
/// The container should call `onDestroy()` during shutdown or pod destruction phase.
/// {@endtemplate}
abstract interface class DisposablePod implements PackageIdentifier {
  /// {@macro disposable_pod}
  Future<void> onDestroy();
}

/// {@template initializing_pod}
/// Interface to be implemented by pods that require initialization logic
/// after their properties have been set by the container.
///
/// This can be used to validate configuration, open connections, or perform
/// any logic that depends on dependency injection being complete.
///
/// ### Usage Example:
/// ```dart
/// class MyRepository implements InitializingPod {
///   late DatabaseClient client;
///
///   @override
///   void onReady() {
///     if (client == null) {
///       throw Exception('Database client must be set');
///     }
///   }
/// }
/// ```
///
/// Called automatically after dependency injection and before the pod is used.
/// {@endtemplate}
abstract interface class InitializingPod implements PackageIdentifier {
  /// {@macro initializing_pod}
  Future<void> onReady();
}

/// {@template smart_initializing_singleton}
/// Callback interface triggered at the end of the singleton pre-instantiation phase.
///
/// Implement this interface if your singleton pod needs to react once
/// **all other singleton pods** have been created and initialized by the container.
///
/// This is useful for pods that depend on the full initialization of the context,
/// such as event broadcasters, context validators, or components that aggregate
/// other singleton pods.
///
/// Unlike `InitializingPod` or `@PostConstruct`, which run *per pod*,
/// this hook runs **once globally**, after all singletons are ready.
///
/// ### Example
/// ```dart
/// class StartupLogger implements SmartInitializingSingleton {
///   @override
///   void onSingletonReady() {
///     print('All singletons are initialized!');
///   }
/// }
/// ```
///
/// The framework will call this after refreshing the context, once the entire singleton
/// graph has been created.
/// {@endtemplate}
abstract interface class SmartInitializingSingleton implements PackageIdentifier {
  /// {@macro smart_initializing_singleton}
  ///
  /// Called once at the end of the singleton pre-instantiation phase.
  ///
  /// This is the last callback point before the application context is considered fully initialized.
  Future<void> onSingletonReady();
}