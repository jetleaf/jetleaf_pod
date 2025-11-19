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

/// 🫘 A lightweight, modular dependency injection (DI) and inversion-of-control (IoC) library.
///
/// The `jetleaf_pod` library provides a flexible set of factories, registries,
/// definitions, and lifecycle hooks to manage object creation, dependency resolution,
/// and application startup in a structured way.
///
/// ## 🫘 Overview
///
/// - **Alias Registry** – Manage alternative names for pods (objects).
/// - **Core Factories** – Define and resolve object creation strategies.
/// - **Pod Definitions** – Represent metadata and configuration for pods.
/// - **Expressions** – Evaluate or transform pod references.
/// - **Helpers** – Utilities for nullable handling, enums, and object wrapping.
/// - **Instantiation** – Strategies for creating pod instances.
/// - **Lifecycle** – Hooks and processors for object lifecycle events.
/// - **Name Generators** – Strategies for naming pods consistently.
/// - **Scopes** – Contextual lifetimes (e.g., singleton, prototype).
/// - **Singleton Registry** – Manage global singleton instances.
/// - **Startup** – Application bootstrap and initialization.
/// - **Exceptions** – Common error types for the DI container.
///
/// ## 🫘 Example
///
/// ```dart
/// import 'package:jetleaf_pod/jetleaf_pod.dart';
///
/// void main() {
///   final factory = DefaultListablePodFactory();
///
///   factory.registerDefinition(
///     PodDefinition(
///       name: 'service',
///       create: () => MyService(),
///     ),
///   );
///
///   final service = factory.getPod<MyService>('service');
///   service.run();
/// }
/// ```
///
/// ## 🫘 Key Benefits
///
/// - Lightweight and modular.
/// - Flexible factories, scopes, and lifecycle processors.
/// - Extensible with custom implementations.
/// - Application-ready with startup orchestration.
///
/// See the individual sub-libraries for detailed API documentation.
library;

export 'src/alias/alias_registry.dart';
export 'src/alias/simple_alias_registry.dart';

export 'src/core/pod_factory.dart';
export 'src/core/abstract_autowire_pod_factory.dart';
export 'src/core/abstract_pod_factory.dart';
export 'src/core/abstract_pod_provider_factory.dart';
export 'src/core/default_listable_pod_factory.dart';
export 'src/core/factory_aware_order_source_provider.dart';

export 'src/definition/pod_definition_registry.dart';
export 'src/definition/pod_definition.dart';
export 'src/definition/commons.dart';
export 'src/definition/simple_pod_definition_registry.dart';

export 'src/expression/pod_expression.dart';

export 'src/helpers/enums.dart';
export 'src/helpers/nullable_pod.dart';
export 'src/helpers/object.dart';

export 'src/instantiation/executable_strategy.dart';
export 'src/instantiation/argument_value_holder.dart';

export 'src/lifecycle/pod_processors.dart';
export 'src/lifecycle/lifecycle.dart';

export 'src/name_generator/pod_name_generator.dart';
export 'src/name_generator/simple_pod_name_generator.dart';

export 'src/scope/scope.dart';

export 'src/singleton/singleton_pod_registry.dart';

export 'src/startup/startup.dart';
export 'src/startup/application_startup.dart';

export 'src/exceptions.dart';