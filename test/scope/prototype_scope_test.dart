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

// test/prototype_scope_test.dart
import 'dart:async';

import 'package:jetleaf_pod/src/helpers/enums.dart';
import 'package:jetleaf_pod/src/helpers/object.dart';
import 'package:jetleaf_pod/src/scope/_scope.dart';
import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

// Mock ObjectFactory for testing
class MockObjectFactory implements ObjectFactory<Object> {
  final Object? value;
  int callCount = 0;

  MockObjectFactory(this.value);

  @override
  FutureOr<ObjectHolder<Object>> get([List<ArgumentValue>? args]) {
    callCount++;
    return ObjectHolder(value!, packageName: "test");
  }

  @override
  Future<List<Object>> createMultiple(int count) async => List.filled(count, value!);

  @override
  Future<ObjectFactory<R>> chain<R>(ObjectFactory<R> Function(Object) nextFactory) async {
    return MockObjectFactory(null) as ObjectFactory<R>;
  }

  @override
  Future<ObjectFactory<Object>> withSideEffect(void Function(Object) sideEffect) async {
    return this;
  }

  @override
  ObjectFactory<Object> copyWith({ObjectFactoryFunction<Object>? creator}) {
    return this;
  }
}

void main() {
  group('PrototypeScope', () {
    late PrototypeScope scope;

    setUp(() {
      scope = PrototypeScope();
    });

    test('should create instance', () {
      expect(scope, isA<PrototypeScope>());
    });

    test('get() should return different instances for same name', () async {
      final factory = MockObjectFactory('testValue');
      final result1 = await scope.get('testName', factory);
      final result2 = await scope.get('testName', factory);

      expect(result1.getValue(), equals('testValue'));
      expect(result2.getValue(), equals('testValue'));
      expect(identical(result1, result2), isFalse); // Different instances
      expect(factory.callCount, equals(2)); // Factory called twice
    });

    test('get() should return different instances for different names', () async {
      final factory = MockObjectFactory('testValue');
      final result1 = await scope.get('name1', factory);
      final result2 = await scope.get('name2', factory);

      expect(result1.getValue(), equals('testValue'));
      expect(result2.getValue(), equals('testValue'));
      expect(identical(result1, result2), isFalse);
      expect(factory.callCount, equals(2)); // Factory called twice
    });

    test('remove() should return null (not supported in prototype scope)', () {
      expect(scope.remove('anyName'), isNull);
    });

    test('registerDestructionCallback should do nothing', () {
      final runnable = MockRunnable();
      
      // Should not throw and should not store callback
      expect(() => scope.registerDestructionCallback('anyName', runnable), returnsNormally);
      
      // Since remove() does nothing, callback should never run
      expect(runnable.runCount, equals(0));
    });

    test('getConversationId() should return prototype constant', () {
      expect(scope.getConversationId(), equals(ScopeType.PROTOTYPE.name));
    });

    test('should handle complex objects', () async {
      final complexObject = {'key': 'value', 'list': [1, 2, 3]};
      final factory = MockObjectFactory(complexObject);
      
      final result1 = await scope.get('complexPod', factory);
      final result2 = await scope.get('complexPod', factory);
      
      expect(result1.getValue(), equals(complexObject));
      expect(result2.getValue(), equals(complexObject));
      expect(identical(result1, result2), isFalse); // Different instances
    });

    test('should handle concurrent access', () async {
      final factory = MockObjectFactory('value');
      final futures = <Future>[];
      
      for (int i = 0; i < 100; i++) {
        futures.add(Future(() async {
          final result = await scope.get('concurrentPod', factory);
          expect(result.getValue(), equals('value'));
        }));
      }
      
      await Future.wait(futures);
      
      // Each call should create a new instance
      expect(factory.callCount, equals(100));
    });

    test('should handle very long pod names', () async {
      final longName = 'a' * 1000;
      final factory = MockObjectFactory('value');
      
      final result = await scope.get(longName, factory);
      expect(result.getValue(), equals('value'));
    });

    test('should handle special characters in pod names', () async {
      final specialNames = ['pod-1', 'pod_2', 'pod.3', 'pod@4', 'pod#5'];
      final factory = MockObjectFactory('value');
      
      for (final name in specialNames) {
        final result = await scope.get(name, factory);
        expect(result.getValue(), equals('value'));
      }
    });

    test('should handle unicode pod names', () async {
      final unicodeNames = ['ñame', '中文', '🚀pod', '🌍service'];
      final factory = MockObjectFactory('value');
      
      for (final name in unicodeNames) {
        final result = await scope.get(name, factory);
        expect(result.getValue(), equals('value'));
      }
    });

    test('should handle empty pod name', () async {
      final factory = MockObjectFactory('value');
      
      final result = await scope.get('', factory);
      expect(result.getValue(), equals('value'));
    });

    test('should handle multiple identical calls', () async {
      final factory = MockObjectFactory('value');
      
      for (int i = 0; i < 10; i++) {
        final result = await scope.get('samePod', factory);
        expect(result.getValue(), equals('value'));
      }
      
      expect(factory.callCount, equals(10)); // New instance each time
    });

    test('should handle different factories for same name', () async {
      final factory1 = MockObjectFactory('value1');
      final factory2 = MockObjectFactory('value2');
      
      final result1 = await scope.get('samePod', factory1);
      final result2 = await scope.get('samePod', factory2);
      
      expect(result1.getValue(), equals('value1'));
      expect(result2.getValue(), equals('value2'));
    });

    test('should not maintain state between calls', () async {
      final factory = MockObjectFactory('value');
      
      final result1 = await scope.get('pod', factory);
      final result2 = await scope.get('pod', factory);
      final result3 = await scope.get('pod', factory);
      
      // All should be different instances
      expect(identical(result1, result2), isFalse);
      expect(identical(result2, result3), isFalse);
      expect(identical(result1, result3), isFalse);
    });

    test('should work with various object types', () async {
      final testCases = [
        MockObjectFactory('string'),
        MockObjectFactory(123),
        MockObjectFactory(true),
        MockObjectFactory(['list']),
        MockObjectFactory({'map': 'value'}),
      ];
      
      for (final factory in testCases) {
        final result1 = await scope.get('pod', factory);
        final result2 = await scope.get('pod', factory);
        
        expect(result1.getValue(), equals(result2.getValue()));
        expect(identical(result1, result2), isFalse);
      }
    });
  });
}

// Mock Runnable for testing
class MockRunnable implements Runnable {
  int runCount = 0;

  @override
  void run() {
    runCount++;
  }
}