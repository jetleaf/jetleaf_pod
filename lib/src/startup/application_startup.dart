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

import 'startup.dart';

part '_application_startup.dart';

/// {@template application_startup}
/// Instruments the application startup phase using [StartupStep]s.
///
/// Framework and infrastructure components can use this abstraction to
/// record actions that occur during application bootstrapping. These steps
/// can include tagging, parent-child relationships, and timing metrics
/// depending on the concrete implementation.
///
/// This is primarily used for diagnostics, profiling, or debugging.
///
/// ### Example:
/// ```dart
/// final startup = MyApplicationStartup(); // or use ApplicationStartup.DEFAULT
/// final step = startup.start('context.refresh');
/// step.tag('pod.count', '25');
/// step.end();
/// ```
///
/// {@endtemplate}
abstract class ApplicationStartup {
  /// {@template application_startup_start}
  /// Creates and starts a new [StartupStep] with the given [name].
  ///
  /// The name should follow dot-notation (e.g. `context.pods.load`) to
  /// represent technical steps during startup.
  ///
  /// Repeated calls with the same name are allowed.
  ///
  /// Example:
  /// ```dart
  /// final step = startup.start('webserver.init');
  /// step.tag('port', '8080');
  /// step.end();
  /// ```
  /// {@endtemplate}
  StartupStep start(String name);
}

/// {@template application_startup_aware}
/// Defines a contract for components that are aware of and can interact with
/// an [ApplicationStartup] strategy.
///
/// An [ApplicationStartup] provides hooks or strategies to monitor and measure
/// different stages of the application startup lifecycle.  
///
/// Implementations of [ApplicationStartupAware] allow the framework (or user code)
/// to inject an [ApplicationStartup] instance so that components can report or
/// adjust their startup behavior accordingly.
///
/// ### Example
/// ```dart
/// class LoggingStartupAware implements ApplicationStartupAware {
///   late ApplicationStartup _startup;
///
///   @override
///   ApplicationStartup getApplicationStartup() => _startup;
///
///   @override
///   void setApplicationStartup(ApplicationStartup applicationStartup) {
///     _startup = applicationStartup;
///   }
///
///   void startComponent() {
///     final step = _startup.start("Initialize component");
///     // Perform initialization work...
///     step.end();
///   }
/// }
///
/// void main() {
///   final aware = LoggingStartupAware();
///   final startup = DefaultApplicationStartup();
///   aware.setApplicationStartup(startup);
///
///   aware.startComponent();
/// }
/// ```
/// {@endtemplate}
abstract interface class ApplicationStartupAware {
  /// {@macro application_startup_aware}
  /// 
  /// {@template configurable_pod_factory_get_application_startup}
  /// Return the [ApplicationStartup] strategy currently in use.
  ///
  /// Implementations should always return the same instance that was previously
  /// set via [setApplicationStartup].
  ///
  /// ### Example
  /// ```dart
  /// final startup = component.getApplicationStartup();
  /// print("Using startup: $startup");
  /// ```
  /// {@endtemplate}
  ApplicationStartup getApplicationStartup();

  /// {@macro application_startup_aware}
  /// 
  /// {@template configurable_pod_factory_set_application_startup}
  /// Set the [ApplicationStartup] strategy to use for this component.
  ///
  /// This method is typically called during application context initialization,
  /// so that all startup-aware components share the same [ApplicationStartup]
  /// instance provided by the framework.
  ///
  /// ### Example
  /// ```dart
  /// component.setApplicationStartup(DefaultApplicationStartup());
  /// ```
  /// {@endtemplate}
  void setApplicationStartup(ApplicationStartup applicationStartup);
}