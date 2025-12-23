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

import '../helpers/object.dart';
import 'pod_expression.dart';

/// {@template default_pod_expression_resolver}
/// Default implementation of [PodExpressionResolver] in **Jetleaf**.
///
/// This class is responsible for evaluating [PodExpression] instances
/// within a given [PodExpressionContext]. It transforms the evaluated
/// result into an [ObjectHolder], which contains metadata such as the
/// qualified name and package of the resolved object.
///
/// ### Example
/// ```dart
/// final resolver = DefaultPodExpressionResolver();
/// final context = PodExpressionContext({
///   "userName": "Alice",
/// });
///
/// final expression = MyCustomPodExpression(); // implements PodExpression
/// final result = await resolver.evaluate(expression, context);
///
/// print(result?.object); // resolved object
/// print(result?.qualifiedName); // type information
/// ```
///
/// This is part of Jetleaf – a framework which developers can use
/// to build web applications.
/// {@endtemplate}
final class DefaultPodExpressionResolver extends PodExpressionResolver {
  /// {@macro default_pod_expression_resolver}
  const DefaultPodExpressionResolver();
  
  @override
  Future<PodExpression<Object>> parseExpression(Object expression) async {
    return DefaultPodExpression(expression);
  }
}

/// {@template default_pod_expression}
/// **Default Pod Expression**
///
/// A concrete implementation of [PodExpression] that directly wraps
/// an existing [Object] instance as an expression. This is the simplest
/// possible pod expression — it does not parse, transform, or lazily
/// compute values, but instead returns the provided [expression] as-is.
///
/// # Purpose
/// - Serves as the baseline or "identity" pod expression.
/// - Useful for registering pre-constructed objects into the pod
///   evaluation system.
/// - Ensures that every value can be treated as a [PodExpression],
///   even if it was not declared via a more complex expression DSL.
///
/// # Metadata Handling
/// On evaluation, `DefaultPodExpression` attempts to enrich the result
/// with metadata:
/// - `packageName` → the package of the underlying object’s class.
/// - `qualifiedName` → the fully qualified class name of the object.
///
/// These values are passed to the [ObjectHolder] constructor for
/// inspection and debugging.
///
/// # Example
/// ```dart
/// final expr = DefaultPodExpression("hello world");
/// final context = PodExpressionContext(factory, scope);
///
/// final holder = await expr.evaluate(context);
/// print(holder.getPod()); // "hello world"
/// print(holder.packageName); // e.g., "dart.core"
/// print(holder.qualifiedName); // e.g., "dart:core/string.dart.String"
/// ```
///
/// # Notes
/// - Always evaluates immediately (no async work).
/// - Safe to use for constants, primitives, or pre-constructed objects.
/// - Not suitable for complex dependency resolution.
/// {@endtemplate}
final class DefaultPodExpression implements PodExpression<Object> {
  /// The raw object wrapped by this pod expression.
  ///
  /// This value is returned directly during evaluation.
  final Object expression;

  /// {@macro default_pod_expression}
  DefaultPodExpression(this.expression);

  @override
  Future<ObjectHolder<Object>> evaluate(PodExpressionContext context) {
    String? packageName = expression.getClass().getPackage().getName();
    String? qualifiedName = expression.getClass().getQualifiedName();

    return Future.value(
      ObjectHolder<Object>(
        expression,
        packageName: packageName,
        qualifiedName: qualifiedName,
      ),
    );
  }
}