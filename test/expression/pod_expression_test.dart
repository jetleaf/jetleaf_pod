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
import 'package:jetleaf_pod/src/core/pod_factory.dart';
import 'package:jetleaf_pod/src/expression/pod_expression.dart';
import 'package:jetleaf_pod/src/helpers/object.dart';
import 'package:jetleaf_pod/src/scope/scope.dart';
import 'package:test/test.dart';

import '../_dependencies.dart';

// Test implementation of PodExpression
class TestPodExpression implements PodExpression<String> {
  final String value;
  
  const TestPodExpression(this.value);
  
  @override
  Future<ObjectHolder<String>> evaluate(PodExpressionContext context) async {
    return ObjectHolder<String>(value, qualifiedName: 'dart.core.String');
  }
}

class TestPodExpressionResolver extends PodExpressionResolver {
  @override
  Future<PodExpression<Object>> parseExpression(Object expression) async {
    if (expression is String) {
      return TestPodExpression(expression);
    }
    throw UnimplementedError();
  }
}

// Mock implementations for testing
class MockConfigurablePodFactory implements ConfigurablePodFactory {
  final Map<String, Object> _pods = {};
  
  void addPod(String name, Object pod) {
    _pods[name] = pod;
  }
  
  @override
  Future<bool> containsPod(String name) async => _pods.containsKey(name);
  
  @override
  Future<T> getPod<T>(String name, [List<ArgumentValue>? args, Class<T>? type]) async {
    final pod = _pods[name];
    if (pod == null) throw Exception('Pod not found: $name');
    return pod as T;
  }
  
  // Minimal implementation for other required methods
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockPodScope implements PodScope {
  final Map<String, Object> _contextualObjects = {};
  
  void addContextualObject(String key, Object value) {
    _contextualObjects[key] = value;
  }
  
  @override
  Object? resolveContextualObject(String key) => _contextualObjects[key];
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    await setupRuntime();
    return Future<void>.value();
  });

  group('PodExpression Tests', () {
    late TestPodExpression expression;
    late PodExpressionContext context;
    late MockConfigurablePodFactory factory;
    late MockPodScope scope;
    
    setUp(() {
      expression = TestPodExpression('test-value');
      factory = MockConfigurablePodFactory();
      scope = MockPodScope();
      context = PodExpressionContext(factory, scope);
    });
    
    test('should evaluate expression correctly', () async {
      final result = await expression.evaluate(context);
      
      expect(result.getValue(), equals('test-value'));
      expect(result.getQualifiedName(), equals('dart.core.String'));
    });
    
    test('should handle null expression', () async {
      final resolver = TestPodExpressionResolver();
      final result = await resolver.evaluate(null, context);
      
      expect(result, isNull);
    });
  });
  
  group('PodExpressionContext Tests', () {
    late MockConfigurablePodFactory factory;
    late MockPodScope scope;
    late PodExpressionContext context;
    
    setUp(() {
      factory = MockConfigurablePodFactory();
      scope = MockPodScope();
      context = PodExpressionContext(factory, scope);
    });
    
    test('should check if pod exists in factory', () async {
      factory.addPod('testPod', 'test-value');
      
      final contains = await context.contains('testPod');
      expect(contains, isTrue);
    });
    
    test('should check if object exists in scope', () async {
      scope.addContextualObject('contextKey', 'context-value');
      
      final contains = await context.contains('contextKey');
      expect(contains, isTrue);
    });
    
    test('should return false for non-existent key', () async {
      final contains = await context.contains('nonExistent');
      expect(contains, isFalse);
    });
    
    test('should get pod from factory', () async {
      factory.addPod('testPod', 'test-value');
      
      final result = await context.get('testPod');
      expect(result, equals('test-value'));
    });
    
    test('should get object from scope', () async {
      scope.addContextualObject('contextKey', 'context-value');
      
      final result = await context.get('contextKey');
      expect(result, equals('context-value'));
    });
    
    test('should return null for non-existent key', () async {
      final result = await context.get('nonExistent');
      expect(result, isNull);
    });
    
    test('should prioritize factory over scope', () async {
      factory.addPod('sharedKey', 'factory-value');
      scope.addContextualObject('sharedKey', 'scope-value');
      
      final result = await context.get('sharedKey');
      expect(result, equals('factory-value'));
    });
  });
}