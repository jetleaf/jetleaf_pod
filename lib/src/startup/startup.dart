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

part '_startup.dart';

/// {@template startup}
/// Represents a startup lifecycle monitor for JetLeaf-based applications.
///
/// This interface defines timing-related hooks that allow modules and tools
/// to track the time it takes for the application to start and be ready.
///
/// It can be used to expose startup metrics, perform readiness checks,
/// or log time durations at various points during the boot process.
///
/// ---
///
/// ### Example
/// ```dart
/// class JetLeafStartup extends Startup {
///   final int _start = DateTime.now().millisecondsSinceEpoch;
///
///   @override
///   int getStartTime() => _start;
///
///   @override
///   int? getProcessUptime() => DateTime.now().millisecondsSinceEpoch - _start;
///
///   @override
///   String getAction() => 'JetLeaf started';
/// }
/// ```
/// {@endtemplate}
abstract class StartupTracker with EqualsAndHashCode, ToString {
  /// The time taken to reach the `started()` phase.
  late Duration _timeTakenToStarted;

  /// Returns the system timestamp (in milliseconds since epoch) at which
  /// the application startup began.
  ///
  /// This value is used to calculate startup durations.
  int getStartTime();

  /// Returns the current process uptime in milliseconds since the
  /// application start time, or `null` if unsupported.
  ///
  /// Can be used for long-running diagnostic tools.
  int? getProcessUptime();

  /// Returns a string representation of the startup action,
  /// such as `'ApplicationContext refreshed'` or `'JetLeaf ready'`.
  String getAction();

  /// Marks the application as "started" and calculates the duration
  /// since `getStartTime()`.
  ///
  /// Stores the result in `_timeTakenToStarted` for future reference.
  ///
  /// ---
  ///
  /// ### Example
  /// ```dart
  /// final duration = startup.started();
  /// print('Started in ${duration.inMilliseconds}ms');
  /// ```
  Duration started() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _timeTakenToStarted = Duration(milliseconds: now - getStartTime());
    return _timeTakenToStarted;
  }

  /// Returns the time it took to reach the `started()` state.
  ///
  /// This will throw if `started()` has not yet been called.
  Duration getTimeTakenToStarted() => _timeTakenToStarted;

  /// Returns the current time elapsed since the application began starting.
  ///
  /// This is a live measure and recalculates on every call.
  ///
  /// ---
  ///
  /// ### Example
  /// ```dart
  /// print('App has been booting for: ${startup.getReady()}');
  /// ```
  Duration getReady() => Duration(milliseconds: DateTime.now().millisecondsSinceEpoch - getStartTime());

  /// {@template startup_create}
  /// Creates a new instance of [StartupTracker].
  /// 
  /// This is a factory method that returns a new instance of [StartupTracker].
  /// 
  /// ---
  ///
  /// ### Example
  /// ```dart
  /// final startup = Startup.create();
  /// ```
  /// {@endtemplate}
  static StartupTracker create() => StandardStartupTracker();

  @override
  List<Object?> equalizedProperties() => [getStartTime(), getProcessUptime(), getAction()];

  @override
  ToStringOptions toStringOptions() => ToStringOptions(
    customParameterNames: ["startTime", "processUptime", "action"],
    includeClassName: true,
  );
}

// =========================================== STARTUP STEP ===============================================

/// {@template startup_step}
/// Step recording metrics about a particular phase or action happening during
/// the [ApplicationStartup].
///
/// A `StartupStep` represents a logical segment of application startup.
/// It supports tagging, nesting (via parent-child relationships), and
/// can be timed or analyzed for startup diagnostics.
///
/// ### Lifecycle:
/// 1. The step is created via [ApplicationStartup.start] and assigned a unique [id].
/// 2. One or more tags may be attached using [tag] or [tagWithSupplier].
/// 3. The [end] method is called to finalize the step.
///
/// Implementations can use this for startup profiling, telemetry, or logging.
///
/// ### Example:
/// ```dart
/// final step = applicationStartup.start('context.refresh');
/// step.tag('pod.name', 'dataSource');
/// step.end();
/// ```
/// {@endtemplate}
abstract class StartupStep with EqualsAndHashCode, ToString {
  /// {@template startup_step_name}
  /// The technical name of the startup step.
  ///
  /// This should describe what’s happening in the current phase,
  /// typically in dot notation for hierarchy (e.g., `context.refresh.pods`).
  ///
  /// The same name may be reused by multiple steps.
  /// {@endtemplate}
  String get name;

  /// {@template startup_step_id}
  /// A unique identifier assigned to this step.
  ///
  /// It is guaranteed to be monotonically increasing and unique within the application startup.
  /// {@endtemplate}
  int get id;

  /// {@template startup_step_parent_id}
  /// ID of the parent step, if available.
  ///
  /// Represents nesting or dependency between startup phases.
  /// Can be `null` for root-level steps.
  /// {@endtemplate}
  int? get parentId;

  /// {@template startup_step_tag}
  /// Attaches a static key/value [tag] to this step.
  ///
  /// Tags provide contextual metadata like:
  /// - `pod.name`: `dataSource`
  /// - `phase`: `initialization`
  ///
  /// ### Example:
  /// ```dart
  /// step.tag('pod.name', value: 'userService');
  /// step.tag('pod.name', supplied: () => 'userService');
  /// ```
  /// {@endtemplate}
  StartupStep tag(String key, {String? value, String Function()? supplied});

  /// {@template startup_step_tags}
  /// Returns the complete list of [StartupStepTag]s associated with this step.
  ///
  /// This list is immutable and reflects the final state of tags.
  /// {@endtemplate}
  StartupStepTags get tags;

  /// {@template startup_step_end}
  /// Marks the end of this step.
  ///
  /// After calling this, no further tags can be added, and the step
  /// is considered complete.
  ///
  /// ### Example:
  /// ```dart
  /// final step = startup.start('context.load');
  /// step.tag('source', 'classpath:pods.xml');
  /// step.end(); // marks the step complete
  /// ```
  /// {@endtemplate}
  void end();

  @override
  List<Object?> equalizedProperties() => [name, id, parentId, tags];

  @override
  ToStringOptions toStringOptions() => ToStringOptions(
    customParameterNames: ["name", "id", "parentId", "tags"],
    includeClassName: true,
  );
}

// =========================================== STARTUP STEP TAGS ===============================================

/// {@template startup_step_tags}
/// An immutable collection of [StartupStepTag]s associated with a [StartupStep].
///
/// Implements [Iterable<Tag>] to support iteration:
/// ```dart
/// for (final tag in step.tags) {
///   print('${tag.key}: ${tag.value}');
/// }
/// ```
/// {@endtemplate}
abstract class StartupStepTags extends Iterable<StartupStepTag> {}

// =========================================== STARTUP STEP TAG ===============================================

/// {@template startup_step_tag}
/// A key/value pair used to represent metadata about a [StartupStep].
///
/// Tags are attached to steps to provide diagnostic, profiling, or
/// contextual information during application startup.
///
/// ### Example:
/// ```dart
/// Tag tag = MyTag('pod.name', 'dataSource');
/// print('${tag.key} = ${tag.value}');
/// ```
/// {@endtemplate}
abstract class StartupStepTag with EqualsAndHashCode, ToString {
  /// {@template startup_step_tag_key}
  /// The key associated with this tag, such as `pod.name`, `phase`, etc.
  /// {@endtemplate}
  String get key;

  /// {@template startup_step_tag_value}
  /// The value associated with this tag.
  /// {@endtemplate}
  String get value;

  @override
  List<Object?> equalizedProperties() => [key, value];

  @override
  ToStringOptions toStringOptions() => ToStringOptions(
    customParameterNames: ["key", "value"],
    includeClassName: true,
  );
}