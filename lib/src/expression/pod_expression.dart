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

import 'dart:async';

import 'package:jetleaf_lang/lang.dart';

import '../core/pod_factory.dart';
import '../helpers/object.dart';
import '../scope/scope.dart';

// ---------------------------------------------------------------------------------------------------------
// PodExpression
// ---------------------------------------------------------------------------------------------------------

/// {@template pod_expression}
/// **Pod Expression Contract**
///
/// Represents an abstract, generic expression that evaluates into a
/// [Pod] or related object in the dependency injection container.
///
/// A `PodExpression` is part of the evaluation pipeline for JetLeaf-style
/// dependency injection. It acts like an AST (abstract syntax tree) node
/// that can be:
/// - A literal reference to a pod.
/// - A composite expression combining multiple pods.
/// - A dynamic expression resolved at runtime.
///
/// The generic type parameter [T] represents the expected result type
/// of the evaluation, typically the type of object the pod produces.
///
/// # Usage
/// Developers typically do not implement `PodExpression` directly.
/// Instead, it is used by the DI framework when parsing, combining,
/// or lazily evaluating pod configurations.
///
/// Example:
/// ```dart
/// final expr = SomeConcretePodExpression<String>();
/// final context = PodExpressionContext(factory, scope);
///
/// // Evaluates expression into an ObjectHolder<String>
/// final result = expr.evaluate(context);
/// print(result.getPod()); // e.g., prints a singleton String pod
/// ```
///
/// # Notes for Implementors
/// - Must be immutable and thread-safe.
/// - Should perform minimal work until [evaluate] is invoked.
/// - Designed to support async or sync evaluation (via [FutureOr]).
/// {@endtemplate}
@Generic(PodExpression)
abstract interface class PodExpression<T> {
  /// {@macro pod_expression}
  const PodExpression();

  /// {@template pod_expression_evaluate}
  /// **Evaluate the Pod Expression**
  ///
  /// Executes this expression within the given [PodExpressionContext].
  /// The context provides:
  /// - The pod factory, used to construct or retrieve pod instances.
  /// - The scope, determining pod lifecycle and visibility.
  ///
  /// The result is an [ObjectHolder] of type [T], which safely wraps
  /// the resolved pod instance. `ObjectHolder` ensures type consistency
  /// and may include metadata such as caching or lifecycle status.
  ///
  /// # Return Value
  /// A [FutureOr] of [ObjectHolder<T>]:
  /// - May return immediately if resolution is synchronous.
  /// - May return a [Future] if resolution requires async operations.
  ///
  /// # Example
  /// ```dart
  /// final expr = SomeConcretePodExpression<int>();
  /// final context = PodExpressionContext(factory, scope);
  ///
  /// final holder = await expr.evaluate(context);
  /// print(holder.getPod()); // e.g., 42
  /// ```
  ///
  /// # Error Handling
  /// - Throws if the pod cannot be resolved in the given context.
  /// - Subclasses should provide meaningful error messages when evaluation fails.
  /// {@endtemplate}
  FutureOr<ObjectHolder<T>> evaluate(PodExpressionContext context);
}

// ---------------------------------------------------------------------------------------------------------
// PodExpressionContext
// ---------------------------------------------------------------------------------------------------------

/// {@template pod_expression_context}
/// Context for evaluating expressions in a pod environment.
///
/// Provides access to the [ConfigurablePodFactory] and optional [PodScope], which
/// are necessary for resolving values dynamically during pod initialization.
///
/// Example:
/// ```dart
/// class MyPodExpressionContext implements PodExpressionContext {
///   final ConfigurablePodFactory factory;
///   final Scope? scope;
///
///   MyPodExpressionContext(this.factory, this.scope);
///
///   @override
///   ConfigurablePodFactory getPodFactory() => factory;
///
///   @override
///   Scope? getScope() => scope;
/// }
/// ```
/// {@endtemplate}
final class PodExpressionContext {
  /// {@template pod_expression_context_get_factory}
  /// Returns the [ConfigurablePodFactory] that owns this context.
  ///
  /// Example:
  /// ```dart
  /// final factory = context.getPodFactory();
  /// print(factory.containsPod("mypod")); // true/false
  /// ```
  /// {@endtemplate}
  ConfigurablePodFactory podFactory;

  /// {@template pod_expression_context_get_scope}
  /// Returns the active [PodScope] for this context, if any.
  ///
  /// May return `null` if no scope is active.
  ///
  /// Example:
  /// ```dart
  /// final scope = context.getScope();
  /// print(scope?.getName()); // e.g., "singleton"
  /// ```
  /// {@endtemplate}
  PodScope? scope;

  /// {@macro pod_expression_context}
  PodExpressionContext(this.podFactory, this.scope);

  /// {@template pod_expression_context_contains_object}
  /// Returns `true` if the given [key] is a pod in the factory or a contextual object in the scope.
  ///
  /// Example:
  /// ```dart
  /// final context = PodExpressionContext(factory, scope);
  /// final contains = context.contains("mypod");
  /// print(contains); // true/false
  /// ```
  /// {@endtemplate}
  Future<bool> contains(String key) async => (await podFactory.containsPod(key) || (scope != null && scope!.resolveContextualObject(key) != null));

  /// {@template pod_expression_context_get_object}
  /// Returns the pod or contextual object for the given [key], if any.
  ///
  /// If the pod is not found in the factory, it attempts to resolve it from the scope.
  ///
  /// Example:
  /// ```dart
  /// final context = PodExpressionContext(factory, scope);
  /// final pod = context.get("mypod");
  /// print(pod); // pod instance or null
  /// ```
  /// {@endtemplate}
  Future<Object?> get(String key) async {
    if (await podFactory.containsPod(key)) {
      return await podFactory.getPod(key);
    } else if (scope != null) {
      return scope!.resolveContextualObject(key);
    }

    return null;
  }
}

// ---------------------------------------------------------------------------------------------------------
// PodExpressionResolver
// ---------------------------------------------------------------------------------------------------------

/// {@template pod_expression_resolver}
/// Strategy interface for resolving pod definition values and expressions.
///
/// This is commonly used in dependency injection frameworks where pod
/// definitions may contain placeholders, expressions, or SpEL-like syntax
/// that needs to be evaluated at runtime.
///
/// Example:
/// ```dart
/// class SimpleExpressionResolver implements PodExpressionResolver {
///   @override
///   Object? evaluate(PodExpression? expression, PodExpressionContext context) {
///     if (expression == "\${scope}") {
///       return context.getScope()?.toString();
///     }
///     return expression;
///   }
/// }
/// ```
/// {@endtemplate}
abstract class PodExpressionResolver {
  /// {@macro pod_expression_resolver}
  const PodExpressionResolver();

  /// {@template pod_expression_resolver_parse_expression}
  /// Parses the given [expression] string into a [PodExpression].
  ///
  /// Example:
  /// ```dart
  /// final resolver = SimpleExpressionResolver();
  /// final expr = resolver.parseExpression("\${scope}");
  /// print(expr); // e.g., "singleton"
  /// ```
  /// {@endtemplate}
  Future<PodExpression<Object>> parseExpression(Object expression);

  /// {@template pod_expression_resolver_evaluate}
  /// Evaluates the given [expression] string in the context of the provided
  /// [PodExpressionContext].
  ///
  /// The result may be a literal value, a resolved pod reference, or
  /// a computed value based on the framework's expression evaluation rules.
  ///
  /// Example:
  /// ```dart
  /// final context = PodExpressionContext(factory, scope);
  /// final resolver = SimpleExpressionResolver();
  /// final result = resolver.evaluate(expr, context);
  /// print(result); // e.g., "singleton"
  /// ```
  /// {@endtemplate}
  FutureOr<ObjectHolder<Object>?> evaluate(Object? expression, PodExpressionContext context) async {
    if (expression == null) {
      return null;
    }

    final result = await parseExpression(expression);
    return result.evaluate(context);
  }
}