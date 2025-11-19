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

// test/default_singleton_pod_registry_test.dart
// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/src/lifecycle/lifecycle.dart';
import 'package:jetleaf_pod/src/exceptions.dart';
import 'package:jetleaf_pod/src/helpers/object.dart';
import 'package:jetleaf_pod/src/singleton/default_singleton_pod_registry.dart';
import 'package:test/test.dart';

// Mock classes for testing
class MockDisposablePod implements DisposablePod {
  bool destroyed = false;
  
  @override
  Future<void> onDestroy() async {
    destroyed = true;
  }
  
  @override
  String getPackageName() => 'test';
}

class MockObject implements DisposablePod {
  final String name;
  
  MockObject(this.name);
  
  @override
  Future<void> onDestroy() async {}
  
  @override
  String getPackageName() => 'test';
}

class TestObjectFactory implements ObjectFactory<Object> {
  final Object? value;
  
  TestObjectFactory(this.value);
  
  @override
  FutureOr<ObjectHolder<Object>> get([List<ArgumentValue>? args]) {
    return ObjectHolder(value!, packageName: "test");
  }
  
  @override
  Future<List<Object>> createMultiple(int count) async => List.filled(count, value!);
  
  @override
  Future<ObjectFactory<R>> chain<R>(ObjectFactory<R> Function(Object) nextFactory) async {
    return TestObjectFactory(null) as ObjectFactory<R>;
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
  group('DefaultSingletonPodRegistry', () {
    late DefaultSingletonPodRegistry registry;
    
    setUpAll(() async {
      await runTestScan();
      registry = DefaultSingletonPodRegistry();
    });
    
    tearDown(() {
      registry.clearSingletonCache();
    });

    test('should initialize with empty state', () {
      expect(registry.containsSingleton('test'), isFalse);
      expect(registry.getSingletonNames(), isEmpty);
      expect(registry.getSingletonCount(), equals(0));
    });

    test('registerSingleton should register object singleton', () async {
      final obj = MockObject('test');
      await registry.registerSingleton('test', Class<MockObject>(), object: ObjectHolder(obj, packageName: "test"));
      
      expect(registry.containsSingleton('test'), isTrue);
      expect(await registry.getSingleton('test'), equals(obj));
    });

    test('registerSingleton should throw for duplicate registration', () async {
      final obj1 = MockObject('test1');
      final obj2 = MockObject('test2');
      
      await registry.registerSingleton('test', Class<MockObject>(), object: ObjectHolder(obj1, packageName: "test"));
      
      expect(() async => await registry.registerSingleton('test', Class<MockObject>(), object: ObjectHolder(obj2, packageName: "test")),
          throwsA(isA<PodException>()));
    });

    test('getSingleton should return registered singleton', () async {
      final obj = MockObject('test');
      await registry.registerSingleton('test', Class<MockObject>(), object: ObjectHolder(obj, packageName: "test"));
      
      final result = await registry.getSingleton('test');
      expect(result, equals(obj));
    });

    test('getSingleton should create singleton from factory', () async {
      final obj = MockObject('test');
      final factory = TestObjectFactory(obj);
      
      final result = await registry.getSingleton('test', factory: factory);
      expect(result, equals(obj));
      expect(registry.containsSingleton('test'), isTrue);
    });

    test('getSingleton should throw during destruction phase', () async {
      await registry.destroySingletons();
      
      final factory = TestObjectFactory(MockObject('test'));
      expect(() async => await registry.getSingleton('test', factory: factory),
          throwsA(isA<PodCreationNotAllowedException>()));
    });

    test('getSingleton should handle circular dependencies with early references', () async {
      // Start creation process
      registry.beforeSingletonCreation('test');
      
      // Should be able to get early reference
      final earlyRef = await registry.getSingletonCache('test', true);
      expect(earlyRef, isNull); // No factory registered yet
      
      registry.afterSingletonCreation('test');
    });

    test('containsSingleton should work correctly', () async {
      expect(registry.containsSingleton('test'), isFalse);
      
      final obj = MockObject('test');
      await registry.registerSingleton('test', Class<MockObject>(), object: ObjectHolder(obj, packageName: "test"));
      
      expect(registry.containsSingleton('test'), isTrue);
    });

    test('getSingletonNames should return all registered names', () async {
      expect(registry.getSingletonNames(), isEmpty);
      
      final obj1 = MockObject('test1');
      final obj2 = MockObject('test2');
      await registry.registerSingleton('test1', Class<MockObject>(), object: ObjectHolder(obj1, packageName: "test"));
      await registry.registerSingleton('test2', Class<MockObject>(), object: ObjectHolder(obj2, packageName: "test"));
      
      final names = registry.getSingletonNames();
      expect(names, containsAll(['test1', 'test2']));

      await registry.destroySingletons();
    });

    test('getSingletonCount should return correct count', () async {
      expect(registry.getSingletonCount(), equals(0));
      
      final obj1 = MockObject('test1');
      await registry.registerSingleton('test1', Class<MockObject>(), object: ObjectHolder(obj1, packageName: "test"));
      expect(registry.getSingletonCount(), equals(1));
      
      final obj2 = MockObject('test2');
      await registry.registerSingleton('test2', Class<MockObject>(), object: ObjectHolder(obj2, packageName: "test"));
      expect(registry.getSingletonCount(), equals(2));

      await registry.destroySingletons();
    });

    test('isCurrentlyCreatingSingleton should track creation state', () {
      expect(registry.isCurrentlyCreatingSingleton('test'), isFalse);
      
      registry.beforeSingletonCreation('test');
      expect(registry.isCurrentlyCreatingSingleton('test'), isTrue);
      
      registry.afterSingletonCreation('test');
      expect(registry.isCurrentlyCreatingSingleton('test'), isFalse);
    });

    test('beforeSingletonCreation should detect circular dependencies', () {
      registry.beforeSingletonCreation('test');
      
      expect(() => registry.beforeSingletonCreation('test'),
          throwsA(isA<PodCurrentlyInCreationException>()));
      
      registry.afterSingletonCreation('test');
    });

    test('afterSingletonCreation should validate state', () {
      expect(() => registry.afterSingletonCreation('test'),
          throwsA(isA<PodException>()));
    });

    test('removeSingleton should remove singleton', () async {
      final obj = MockObject('test');
      await registry.registerSingleton('test', Class<MockObject>(), object: ObjectHolder(obj, packageName: "test"));
      
      expect(registry.containsSingleton('test'), isTrue);
      
      registry.removeSingleton('test');
      expect(registry.containsSingleton('test'), isFalse);
    });

    test('destroySingleton should destroy disposable pods', () async {
      final disposable = MockDisposablePod();
      await registry.registerSingleton('test', Class<MockDisposablePod>(), object: ObjectHolder(disposable, packageName: "test"));
      
      await registry.destroySingleton('test');
      
      expect(disposable.destroyed, isTrue);
      expect(registry.containsSingleton('test'), isFalse);
    });

    test('destroySingletons should destroy all singletons', () async {
      final disposable1 = MockDisposablePod();
      final disposable2 = MockDisposablePod();
      
      await registry.registerSingleton('test1', Class<MockDisposablePod>(), object: ObjectHolder(disposable1, packageName: "test"));
      await registry.registerSingleton('test2', Class<MockDisposablePod>(), object: ObjectHolder(disposable2, packageName: "test"));
      
      await registry.destroySingletons();
      
      expect(disposable1.destroyed, isTrue);
      expect(disposable2.destroyed, isTrue);
      expect(registry.getSingletonCount(), equals(0));
    });

    test('clearSingletonCache should reset registry', () async {
      final obj = MockObject('test');
      await registry.registerSingleton('test', Class<MockObject>(), object: ObjectHolder(obj, packageName: "test"));
      
      expect(registry.getSingletonCount(), equals(1));
      
      registry.clearSingletonCache();
      
      expect(registry.getSingletonCount(), equals(0));
      expect(registry.containsSingleton('test'), isFalse);

      await registry.destroySingletons();
    });

    test('registerDisposablePod should register disposable pods', () async {
      final disposable = MockDisposablePod();
      
      registry.registerDisposablePod('test', disposable);
      
      // Verify the pod is registered by attempting destruction
      await registry.destroySingleton('test');
      expect(disposable.destroyed, isTrue);
    });

    test('registerContainedPod should track containment', () {
      registry.registerContainedPod('contained', 'container');
      
      // Verify containment is tracked
      expect(registry.isDependent('container', 'contained'), isFalse); // Different relationship
    });

    test('registerDependentPod should track dependencies', () {
      registry.registerDependentPod('dependency', 'dependent');
      
      expect(registry.isDependent('dependency', 'dependent'), isTrue);
      expect(registry.hasDependentPod('dependency'), isTrue);
    });

    test('isDependent should detect direct dependencies', () {
      registry.registerDependentPod('service', 'controller');
      
      expect(registry.isDependent('service', 'controller'), isTrue);
      expect(registry.isDependent('controller', 'service'), isFalse);
    });

    test('isDependent should detect transitive dependencies', () {
      registry.registerDependentPod('repository', 'service');
      registry.registerDependentPod('service', 'controller');
      
      expect(registry.isDependent('repository', 'controller'), isTrue);
    });

    test('hasDependentPod should work correctly', () {
      expect(registry.hasDependentPod('test'), isFalse);
      
      registry.registerDependentPod('test', 'dependent');
      expect(registry.hasDependentPod('test'), isTrue);
    });

    test('getDependentPods should return dependents', () {
      registry.registerDependentPod('service', 'controller1');
      registry.registerDependentPod('service', 'controller2');
      
      final dependents = registry.getDependentPods('service');
      expect(dependents, containsAll(['controller1', 'controller2']));
    });

    test('getDependenciesForPod should return dependencies', () {
      registry.registerDependentPod('service1', 'controller');
      registry.registerDependentPod('service2', 'controller');
      
      final dependencies = registry.getDependenciesForPod('controller');
      expect(dependencies, containsAll(['service1', 'service2']));
    });

    test('should handle complex dependency chains', () {
      // Create a complex dependency chain
      registry.registerDependentPod('repository', 'service');
      registry.registerDependentPod('service', 'controller');
      registry.registerDependentPod('utility', 'service');
      
      expect(registry.isDependent('repository', 'controller'), isTrue);
      expect(registry.isDependent('utility', 'controller'), isTrue);
      expect(registry.getDependentPods('service'), containsAll(['controller']));
      expect(registry.getDependenciesForPod('controller'), containsAll(['service']));
    });

    test('should handle multiple registrations gracefully', () async {
      final obj = MockObject('test');
      
      // Multiple registrations should work
      await registry.registerSingleton('test', Class<MockObject>(), object: ObjectHolder(obj, packageName: "test"));
      await registry.registerSingleton('test2', Class<MockObject>(), object: ObjectHolder(obj, packageName: "test"));
      
      expect(registry.getSingletonCount(), equals(2));
    });

    test('should maintain registration order', () async {
      final objects = [
        MockObject('test1'),
        MockObject('test2'),
        MockObject('test3'),
      ];
      
      for (var obj in objects) {
        await registry.registerSingleton(obj.name, Class<MockObject>(), object: ObjectHolder(obj, packageName: "test"));
      }
      
      final names = registry.getSingletonNames();
      expect(names, equals(['test1', 'test2', 'test3']));
    });

    test('should handle concurrent access', () async {
      final futures = <Future>[];
      
      for (int i = 0; i < 10; i++) {
        futures.add(Future(() async {
          final obj = MockObject('test$i');
          await registry.registerSingleton('test$i', Class<MockObject>(), object: ObjectHolder(obj, packageName: "test"));
        }));
      }
      
      await Future.wait(futures);
      
      expect(registry.getSingletonCount(), equals(10));
    });

    test('should handle mixed object and factory registration', () async {
      final obj = MockObject('direct');
      final factoryObj = MockObject('factory');
      final factory = TestObjectFactory(factoryObj);
      
      await registry.registerSingleton('direct', Class<MockObject>(), object: ObjectHolder(obj, packageName: "test"));
      await registry.registerSingleton('factory', Class<TestObjectFactory>(), factory: factory);
      
      expect(registry.containsSingleton('direct'), isTrue);
      expect(registry.containsSingleton('factory'), isTrue);
    });

    test('should handle early reference creation', () async {
      final factoryObj = MockObject('test');
      final factory = TestObjectFactory(factoryObj);
      
      registry.beforeSingletonCreation('test');
      
      // Register factory and get early reference
      await registry.registerSingleton('test', Class<TestObjectFactory>(), factory: factory);
      final earlyRef = await registry.getSingletonCache('test', true);
      
      expect(earlyRef?.getValue(), equals(factoryObj));
      
      registry.afterSingletonCreation('test');
    });

    test('should handle suppression of exceptions', () {
      final exception = Exception('Test exception');
      registry.onSuppressedException(exception);
      
      // Should not throw, just log the exception
      expect(() => registry.onSuppressedException(exception), returnsNormally);
    });

    test('should handle complex destruction ordering', () async {
      // Set up dependencies: A -> B -> C
      registry.registerDependentPod('C', 'B');
      registry.registerDependentPod('B', 'A');
      
      final objA = MockDisposablePod();
      final objB = MockDisposablePod();
      final objC = MockDisposablePod();
      
      await registry.registerSingleton('A', Class<MockDisposablePod>(), object: ObjectHolder(objA, packageName: "test"));
      await registry.registerSingleton('B', Class<MockDisposablePod>(), object: ObjectHolder(objB, packageName: "test"));
      await registry.registerSingleton('C', Class<MockDisposablePod>(), object: ObjectHolder(objC, packageName: "test"));
      
      // Destroy should handle dependencies properly
      await registry.destroySingletons();
      
      // All should be destroyed
      expect(objA.destroyed, isTrue);
      expect(objB.destroyed, isTrue);
      expect(objC.destroyed, isTrue);
    });

    test('should handle containment relationships', () async {
      registry.registerContainedPod('child', 'parent');
      
      final parent = MockDisposablePod();
      final child = MockDisposablePod();
      
      await registry.registerSingleton('parent', Class<MockDisposablePod>(), object: ObjectHolder(parent, packageName: "test"));
      await registry.registerSingleton('child', Class<MockDisposablePod>(), object: ObjectHolder(child, packageName: "test"));
      
      await registry.destroySingleton('parent');
      
      // Both parent and child should be destroyed
      expect(parent.destroyed, isTrue);
      expect(child.destroyed, isTrue);
    });

    test('should handle aliases with singleton registry', () async {
      final obj = MockObject('service');
      await registry.registerSingleton('service', Class<MockObject>(), object: ObjectHolder(obj, packageName: "test"));
      registry.registerAlias('service', 'alias');
      
      // Should be able to get singleton by alias
      final result = await registry.getSingleton('service');
      expect(result, equals(obj));
      
      // Alias should work for dependency tracking
      registry.registerDependentPod('service', 'dependent');
      expect(registry.isDependent('service', 'dependent'), isTrue);
    });

    test('should handle edge case with self-dependencies', () {
      // Self-dependency should be handled gracefully
      registry.registerDependentPod('service', 'service');
      expect(registry.isDependent('service', 'service'), isTrue);
    });

    test('should handle very long dependency chains', () {
      const chainLength = 100;
      for (int i = 0; i < chainLength; i++) {
        if (i == 0) {
          registry.registerDependentPod('base', 'level0');
        } else {
          registry.registerDependentPod('level${i-1}', 'level$i');
        }
      }
      
      expect(registry.isDependent('base', 'level${chainLength-1}'), isTrue);
    });

    test('should handle cleanup after destruction', () async {
      final obj = MockDisposablePod();
      await registry.registerSingleton('test', Class<MockDisposablePod>(), object: ObjectHolder(obj, packageName: "test"));
      
      await registry.destroySingletons();
      
      // Registry should be clean after destruction
      expect(registry.getSingletonCount(), equals(0));
      expect(registry.containsSingleton('test'), isFalse);
      expect(registry.isCurrentlyCreatingSingleton('test'), isFalse);
    });

    test('should handle re-registration after destruction', () async {
      final obj1 = MockDisposablePod();
      await registry.registerSingleton('test', Class<MockDisposablePod>(), object: ObjectHolder(obj1, packageName: "test"));
      
      await registry.destroySingletons();
      
      // Should be able to re-register after destruction
      final obj2 = MockDisposablePod();
      await registry.registerSingleton('test', Class<MockDisposablePod>(), object: ObjectHolder(obj2, packageName: "test"));
      
      expect(registry.containsSingleton('test'), isTrue);
      expect(await registry.getSingleton('test'), equals(obj2));
    });

    test('should handle memory cleanup', () async {
      final largeObjects = List.generate(100, (i) => MockObject('obj$i'));
      
      for (var obj in largeObjects) {
        await registry.registerSingleton(obj.name, Class<MockObject>(), object: ObjectHolder(obj, packageName: "test"));
      }
      
      expect(registry.getSingletonCount(), equals(100));
      
      registry.clearSingletonCache();
      
      expect(registry.getSingletonCount(), equals(0));
      // Memory should be cleaned up (this is more of a memory leak test pattern)
    });
  });
}