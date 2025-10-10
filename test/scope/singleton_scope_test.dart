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

// test/singleton_scope_test.dart
import 'dart:async';

import 'package:jetleaf_pod/src/helpers/enums.dart';
import 'package:jetleaf_pod/src/helpers/object.dart';
import 'package:jetleaf_pod/src/scope/_scope.dart';
import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

// Mock ObjectFactory for testing
class MockObjectFactory extends ObjectFactory<Object> {
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

// Mock Runnable for testing
class MockRunnable implements Runnable {
  int runCount = 0;

  @override
  void run() {
    runCount++;
  }
}

void main() {
  group('SingletonScope', () {
    late SingletonScope scope;

    setUp(() {
      scope = SingletonScope();
    });

    test('should create instance', () {
      expect(scope, isA<SingletonScope>());
    });

    test('get() should return same instance for same name', () async {
      final factory = MockObjectFactory('testValue');
      final result1 = await scope.get('testName', factory);
      final result2 = await scope.get('testName', factory);

      expect(result1.getValue(), equals('testValue'));
      expect(result2.getValue(), equals('testValue'));
      expect(identical(result1, result2), isTrue);
      expect(factory.callCount, equals(1));  // Factory called once
    });

    test('get() should create different instances for different names', () async {
      final factory = MockObjectFactory('testValue');
      final result1 = await scope.get('name1', factory);
      final result2 = await scope.get('name2', factory);

      expect(result1.getValue(), equals('testValue'));
      expect(result2.getValue(), equals('testValue'));
      expect(identical(result1, result2), isFalse);
      expect(factory.callCount, equals(2)); // Factory called twice
    });

    test('remove() should remove instance and return it', () async {
      final factory = MockObjectFactory('testValue');
      await scope.get('testName', factory);
      
      final removed = scope.remove('testName');
      
      expect(removed?.getValue(), equals('testValue'));
      expect(scope.remove('testName'), isNull); // Should be gone now
    });

    test('remove() should run destruction callbacks', () async {
      final factory = MockObjectFactory('testValue');
      await scope.get('testName', factory);
      
      final callback1 = MockRunnable();
      final callback2 = MockRunnable();
      
      scope.registerDestructionCallback('testName', callback1);
      scope.registerDestructionCallback('testName', callback2);
      
      scope.remove('testName');
      
      expect(callback1.runCount, equals(1));
      expect(callback2.runCount, equals(1));
    });

    test('remove() should not run callbacks for non-existent pod', () {
      final callback = MockRunnable();
      scope.registerDestructionCallback('nonExistent', callback);
      
      expect(() => scope.remove('nonExistent'), returnsNormally);
      expect(callback.runCount, equals(0)); // Should not run
    });

    test('registerDestructionCallback should work for multiple pods', () async {
      final factory = MockObjectFactory('testValue');
      await scope.get('pod1', factory);
      await scope.get('pod2', factory);
      
      final callback1 = MockRunnable();
      final callback2 = MockRunnable();
      final callback3 = MockRunnable();
      
      scope.registerDestructionCallback('pod1', callback1);
      scope.registerDestructionCallback('pod1', callback2);
      scope.registerDestructionCallback('pod2', callback3);
      
      scope.remove('pod1');
      
      expect(callback1.runCount, equals(1));
      expect(callback2.runCount, equals(1));
      expect(callback3.runCount, equals(0)); // Not called for pod2
    });

    test('getConversationId() should return singleton constant', () {
      expect(scope.getConversationId(), equals(ScopeType.SINGLETON.name));
    });

    test('getAllScopedPods() should return all instances', () async {
      final factory1 = MockObjectFactory('value1');
      final factory2 = MockObjectFactory('value2');
      
      await scope.get('pod1', factory1);
      await scope.get('pod2', factory2);
      
      final allPods = scope.getAllScopedPods();
      
      expect(allPods.length, equals(2));
      expect(allPods['pod1']?.getValue(), equals('value1'));
      expect(allPods['pod2']?.getValue(), equals('value2'));
    });

    test('getAllScopedPods() should return empty map when no instances', () {
      expect(scope.getAllScopedPods(), isEmpty);
    });

    test('should handle complex objects', () async {
      final complexObject = {'key': 'value', 'list': [1, 2, 3]};
      final factory = MockObjectFactory(complexObject);
      
      final result = await scope.get('complexPod', factory);
      expect(result.getValue(), equals(complexObject));
    });

    test('should handle multiple removals', () async {
      final factory = MockObjectFactory('value');
      await scope.get('pod', factory);
      
      final firstRemoval = scope.remove('pod');
      final secondRemoval = scope.remove('pod'); // Already removed
      
      expect(firstRemoval?.getValue(), equals('value'));
      expect(secondRemoval, isNull);
    });

    test('should handle callbacks after pod removal', () async {
      final factory = MockObjectFactory('value');
      await scope.get('pod', factory);
      
      scope.remove('pod');
      
      // Register callback after removal - should not be stored
      final callback = MockRunnable();
      scope.registerDestructionCallback('pod', callback);
      
      // Should not run since pod was already removed
      expect(callback.runCount, equals(0));
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
      
      expect(factory.callCount, equals(1));
    });

    test('should handle very long pod names', () async {
      final longName = 'a' * 1000;
      final factory = MockObjectFactory('value');
      
      final result = await scope.get(longName, factory);
      expect(result.getValue(), equals('value'));
      
      final removed = scope.remove(longName);
      expect(removed?.getValue(), equals('value'));
    });

    test('should handle special characters in pod names', () async {
      final specialNames = ['pod-1', 'pod_2', 'pod.3', 'pod@4', 'pod#5'];
      final factory = MockObjectFactory('value');
      
      for (final name in specialNames) {
        final result = await scope.get(name, factory);
        expect(result.getValue(), equals('value'));
        
        final removed = scope.remove(name);
        expect(removed?.getValue(), equals('value'));
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
      
      final removed = scope.remove('');
      expect(removed?.getValue(), equals('value'));
    });

    test('_runDestructionCallbacks should handle non-existent pod', () {
      expect(() => scope.remove('nonExistent'), returnsNormally);
    });

    test('_runDestructionCallbacks should handle empty callback list', () async {
      final factory = MockObjectFactory('value');
      await scope.get('pod', factory);
      
      // Register no callbacks, just ensure removal works
      expect(() => scope.remove('pod'), returnsNormally);
    });

    test('should handle multiple callbacks for same pod', () async {
      final factory = MockObjectFactory('value');
      await scope.get('pod', factory);
      
      final callbacks = List.generate(10, (_) => MockRunnable());
      for (final callback in callbacks) {
        scope.registerDestructionCallback('pod', callback);
      }
      
      scope.remove('pod');
      
      for (final callback in callbacks) {
        expect(callback.runCount, equals(1));
      }
    });

    test('should handle callback exceptions gracefully', () async {
      final factory = MockObjectFactory('value');
      await scope.get('pod', factory);
      
      final goodCallback = MockRunnable();
      final anotherGoodCallback = MockRunnable();
      
      scope.registerDestructionCallback('pod', goodCallback);
      scope.registerDestructionCallback('pod', anotherGoodCallback);
      
      // Should still remove pod and run all callbacks despite exception
      expect(() => scope.remove('pod'), returnsNormally);
      
      expect(goodCallback.runCount, equals(1));
      expect(anotherGoodCallback.runCount, equals(1));
    });
  });
}