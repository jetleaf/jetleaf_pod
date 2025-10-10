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

part of 'application_startup.dart';

/// {@template default_application_startup}
/// A no-op implementation of [ApplicationStartup] that always returns
/// a singleton [DefaultStartupStep] for any startup operation.
///
/// This implementation is useful when:
/// - Startup tracking is disabled.  
/// - Running in test environments.  
/// - Using lightweight deployments where startup monitoring is unnecessary.  
///
/// The returned [DefaultStartupStep] does nothing when you call
/// methods like `tag` or `end`, making it safe to use in place of a
/// fully functional startup tracker.
///
/// ### Example
/// ```dart
/// void main() {
///   final startup = DefaultApplicationStartup();
///
///   // Start a step
///   final step = startup.start('context.load');
///
///   // These calls do nothing in the no-op implementation
///   step.tag('key', 'value');
///   step.end();
/// }
/// ```
/// {@endtemplate}
class DefaultApplicationStartup extends ApplicationStartup {
  /// {@template default_application_startup_step}
  /// A shared singleton instance of [DefaultStartupStep].
  ///
  /// Since this class is a no-op, reusing the same instance avoids
  /// unnecessary allocations and ensures consistent behavior.
  /// {@endtemplate}
  static final DefaultStartupStep DEFAULT_STARTUP_STEP = DefaultStartupStep();

  @override
  StartupStep start(String name) => DEFAULT_STARTUP_STEP;
}