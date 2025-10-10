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

part of 'startup.dart';

/// {@template default_startup_step}
/// A no-op implementation of [StartupStep] used by [DefaultApplicationStartup].
///
/// This step returns default values and ignores all tagging and `end()` calls.
/// It is designed for cases where performance is critical or startup tracking
/// is explicitly disabled.
///
/// ### Example
/// ```dart
/// final step = DefaultStartupStep();
/// print(step.name); // "default"
/// step.tag('ignored', 'value'); // no-op
/// step.end(); // no-op
/// ```
/// {@endtemplate}
class DefaultStartupStep extends StartupStep {
  final DefaultStartupStepTags _tags = DefaultStartupStepTags();

  @override
  String get name => 'default';

  @override
  int get id => 0;

  @override
  int? get parentId => null;

  @override
  StartupStep tag(String key, {String? value, String Function()? supplied}) => this;

  @override
  StartupStepTags get tags => _tags;

  @override
  void end() {
    // No-op
  }
}

// ======================================= DEFAULT STARTUP STEP TAGS ===========================================

/// {@template default_startup_step_tags}
/// A no-op, empty tag collection returned by [DefaultStartupStep].
///
/// Implements [StartupStepTags] with an empty iterator, ensuring that
/// no tags are ever recorded or iterated over.
///
/// ### Example
/// ```dart
/// final tags = DefaultStartupStepTags();
/// print(tags.isEmpty); // true
/// for (final tag in tags) {
///   print(tag); // never executed
/// }
/// ```
/// {@endtemplate}
class DefaultStartupStepTags extends StartupStepTags {
  @override
  Iterator<StartupStepTag> get iterator => const <StartupStepTag>[].iterator;
}

// =========================================== STANDARD STARTUP ===============================================

/// {@template standard_startup}
/// Standard implementation of the {@macro startup} interface.
///
/// This tracker captures the system time when instantiated and uses it
/// as the reference point for all startup timing calculations. It is
/// suitable for most JetLeaf applications where basic timing and
/// readiness metrics are sufficient.
///
/// ---
///
/// ### Example
/// ```dart
/// void main() {
///   final startup = StandardStartupTracker();
///
///   // After your application has initialized
///   startup.started();
///
///   print(
///     'JetLeaf started in '
///     '${startup.getTimeTakenToStarted().inMilliseconds}ms',
///   );
/// }
/// ```
/// {@endtemplate}
class StandardStartupTracker extends StartupTracker {
  /// Captures the current time in milliseconds since epoch
  /// when the tracker is created.
  final int _startTime = DateTime.now().millisecondsSinceEpoch;

  @override
  int getStartTime() => _startTime;

  @override
  int? getProcessUptime() => null;

  @override
  String getAction() => 'Started';
}