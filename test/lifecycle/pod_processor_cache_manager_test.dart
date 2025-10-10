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

// test/pod_processor_manager_test.dart
import 'package:jetleaf_pod/src/helpers/object.dart';
import 'package:jetleaf_pod/src/lifecycle/pod_processor_cache_manager.dart';
import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/src/lifecycle/pod_processors.dart';

import '../_dependencies.dart';

// Mock processor implementations for testing
class MockInstantiationAwarePodProcessor extends InstantiationAwarePodProcessor {
  int beforeInstantiationCallCount = 0;
  int afterInstantiationCallCount = 0;
  int processPropertyValuesCallCount = 0;

  @override
  Future<Object?> processBeforeInstantiation(Class podClass, String name) async {
    beforeInstantiationCallCount++;
    return null;
  }

  @override
  Future<bool> processAfterInstantiation(Object pod, Class podClass, String name) async {
    afterInstantiationCallCount++;
    return true;
  }

  @override
  Future<PropertyValues?> processPropertyValues(PropertyValues pvs, Object pod, Class podClass, String name) async {
    processPropertyValuesCallCount++;
    return pvs;
  }

  @override
  Future<List<Constructor>?> determineCandidateConstructors(Class clazz, String name) async => null;
}

class MockDestructionAwarePodProcessor extends DestructionAwarePodProcessor {
  int beforeDestructionCallCount = 0;
  int afterDestructionCallCount = 0;
  int requiresDestructionCallCount = 0;

  @override
  Future<void> processBeforeDestruction(Object pod, Class podClass, String name) async {
    beforeDestructionCallCount++;
  }

  @override
  Future<void> processAfterDestruction(Object pod, Class podClass, String name) async {
    afterDestructionCallCount++;
  }

  @override
  Future<bool> requiresDestruction(Object pod, Class podClass, String name) async {
    requiresDestructionCallCount++;
    return true;
  }
}

class MockPodAwareProcessor extends PodAwareProcessor {
  // Base processor with no specific functionality
}

class MockMultiInterfaceProcessor implements InstantiationAwarePodProcessor, DestructionAwarePodProcessor {
  int instantiationCallCount = 0;
  int destructionCallCount = 0;

  @override
  Future<Object?> processBeforeInstantiation(Class podClass, String name) async {
    instantiationCallCount++;
    return null;
  }

  @override
  Future<List<ArgumentValue>?> determineCandidateArguments(String podName, Executable executable, List<Parameter> parameters) async => null;

  @override
  Future<bool> processAfterInstantiation(Object pod, Class podClass, String name) async {
    instantiationCallCount++;
    return true;
  }

  @override
  Future<PropertyValues?> processPropertyValues(PropertyValues pvs, Object pod, Class podClass, String name) async => pvs;

  @override
  Future<List<Constructor>?> determineCandidateConstructors(Class clazz, String name) async => null;

  @override
  Future<void> processBeforeDestruction(Object pod, Class podClass, String name) async {
    destructionCallCount++;
  }

  @override
  Future<void> processAfterDestruction(Object pod, Class podClass, String name) async {
    destructionCallCount++;
  }

  @override
  Future<bool> requiresDestruction(Object pod, Class podClass, String name) async => true;
  
  @override
  Future<Object?> processAfterInitialization(Object pod, Class podClass, String name) async {
    throw UnimplementedError();
  }
  
  @override
  Future<Object?> processBeforeInitialization(Object pod, Class podClass, String name) async {
    throw UnimplementedError();
  }

  @override
  Future<ObjectHolder<Object>> getEarlyPodReference(ObjectHolder<Object> podHolder, Class podClass, String name) async => podHolder;
  
  @override
  Future<bool> shouldProcessBeforeInitialization(Object pod, Class podClass, String name) => Future.value(true);
}

void main() {
  setUpAll(() async {
    await setupRuntime();
    return Future<void>.value();
  });

  group('PodProcessorCacheManager', () {
    test('should create empty manager with private constructor', () {
      final manager = PodProcessorCacheManager();
      expect(manager.instantiation, isEmpty);
      expect(manager.destruction, isEmpty);
    });

    test('factory constructor should create empty manager with empty list', () {
      final manager = PodProcessorCacheManager([]);
      expect(manager.instantiation, isEmpty);
      expect(manager.destruction, isEmpty);
    });

    test('should categorize InstantiationAwarePodProcessor', () {
      final processor = MockInstantiationAwarePodProcessor();
      final manager = PodProcessorCacheManager([processor]);

      expect(manager.instantiation, hasLength(1));
      expect(manager.instantiation.first, equals(processor));
      expect(manager.destruction, isEmpty);
    });

    test('should categorize DestructionAwarePodProcessor', () {
      final processor = MockDestructionAwarePodProcessor();
      final manager = PodProcessorCacheManager([processor]);

      expect(manager.instantiation, isEmpty);
      expect(manager.destruction, hasLength(1));
      expect(manager.destruction.first, equals(processor));
    });

    test('should categorize mixed processor types', () {
      final instantiationProcessor = MockInstantiationAwarePodProcessor();
      final destructionProcessor = MockDestructionAwarePodProcessor();

      final manager = PodProcessorCacheManager([
        instantiationProcessor,
        destructionProcessor,
      ]);

      expect(manager.instantiation, hasLength(1));
      expect(manager.destruction, hasLength(1));
    });

    test('should ignore base PodAwareProcessor', () {
      final baseProcessor = MockPodAwareProcessor();
      final manager = PodProcessorCacheManager([baseProcessor]);

      expect(manager.instantiation, isEmpty);
      expect(manager.destruction, isEmpty);
    });

    test('should handle empty processor list', () {
      final manager = PodProcessorCacheManager([]);
      expect(manager.instantiation, isEmpty);
      expect(manager.destruction, isEmpty);
    });

    test('should handle null currentCache parameter', () {
      final processor = MockInstantiationAwarePodProcessor();
      final manager = PodProcessorCacheManager([processor], null);

      expect(manager.instantiation, hasLength(1));
      expect(manager.instantiation.first, equals(processor));
    });

    test('should reuse currentCache when provided', () {
      final initialProcessor = MockInstantiationAwarePodProcessor();
      final initialManager = PodProcessorCacheManager([initialProcessor]);

      final newProcessor = MockDestructionAwarePodProcessor();
      final newManager = PodProcessorCacheManager([newProcessor], initialManager);

      expect(newManager.instantiation, hasLength(1));
      expect(newManager.destruction, hasLength(1));
    });

    test('should not add duplicate processors when reusing cache', () {
      final processor = MockInstantiationAwarePodProcessor();
      final initialManager = PodProcessorCacheManager([processor]);

      final newManager = PodProcessorCacheManager([processor], initialManager);

      expect(newManager.instantiation, hasLength(1)); // Should not duplicate
    });

    test('should add new processors to existing cache', () {
      final processor1 = MockInstantiationAwarePodProcessor();
      final initialManager = PodProcessorCacheManager([processor1]);

      final processor2 = MockDestructionAwarePodProcessor();
      final newManager = PodProcessorCacheManager([processor2], initialManager);

      expect(newManager.instantiation, hasLength(1));
      expect(newManager.destruction, hasLength(1));
    });

    test('should handle processors that implement multiple interfaces', () {
      final multiProcessor = MockMultiInterfaceProcessor();
      final manager = PodProcessorCacheManager([multiProcessor]);

      expect(manager.instantiation, hasLength(1));
      expect(manager.destruction, hasLength(1));
    });

    test('should add processors using add method', () {
      final manager = PodProcessorCacheManager();
      final instantiationProcessor = MockInstantiationAwarePodProcessor();
      final destructionProcessor = MockDestructionAwarePodProcessor();

      manager.add(instantiationProcessor);
      manager.add(destructionProcessor);

      expect(manager.instantiation, hasLength(1));
      expect(manager.destruction, hasLength(1));
    });

    test('should remove processors using remove method', () {
      final instantiationProcessor = MockInstantiationAwarePodProcessor();
      final manager = PodProcessorCacheManager([instantiationProcessor]);

      expect(manager.instantiation, hasLength(1));
      
      manager.remove(instantiationProcessor);
      expect(manager.instantiation, isEmpty);
    });

    test('lists should be mutable and allow adding processors', () {
      final manager = PodProcessorCacheManager();
      final processor = MockInstantiationAwarePodProcessor();

      expect(manager.instantiation, isEmpty);
      manager.instantiation.add(processor);
      expect(manager.instantiation, hasLength(1));
    });

    test('lists should be mutable and allow removing processors', () {
      final processor = MockInstantiationAwarePodProcessor();
      final manager = PodProcessorCacheManager([processor]);

      expect(manager.instantiation, hasLength(1));
      manager.instantiation.remove(processor);
      expect(manager.instantiation, isEmpty);
    });

    test('should handle adding same processor multiple times', () {
      final processor = MockInstantiationAwarePodProcessor();
      final manager = PodProcessorCacheManager();

      manager.add(processor);
      manager.add(processor); // Add same processor again

      expect(manager.instantiation, hasLength(1)); // Should not duplicate
    });

    test('should handle removing non-existent processor', () {
      final processor = MockInstantiationAwarePodProcessor();
      final manager = PodProcessorCacheManager();

      manager.remove(processor); // Remove non-existent processor
      expect(manager.instantiation, isEmpty);
    });
  });

  group('InstantiationAwarePodProcessor', () {
    test('should call beforeInstantiation method', () async {
      final processor = MockInstantiationAwarePodProcessor();
      final podClass = Class<Object>();
      
      await processor.processBeforeInstantiation(podClass, 'testPod');
      
      expect(processor.beforeInstantiationCallCount, 1);
    });

    test('should call afterInstantiation method', () async {
      final processor = MockInstantiationAwarePodProcessor();
      final pod = Object();
      final podClass = Class<Object>();
      
      await processor.processAfterInstantiation(pod, podClass, 'testPod');
      
      expect(processor.afterInstantiationCallCount, 1);
    });

    test('should call processPropertyValues method', () async {
      final processor = MockInstantiationAwarePodProcessor();
      final pod = Object();
      final podClass = Class<Object>();
      final pvs = MockPropertyValues();
      
      await processor.processPropertyValues(pvs, pod, podClass, 'testPod');
      
      expect(processor.processPropertyValuesCallCount, 1);
    });

    test('should return default values for optional methods', () async {
      final processor = MockInstantiationAwarePodProcessor();
      final podClass = Class<Object>();
      
      expect(await processor.determineCandidateConstructors(podClass, 'testPod'), isNull);
    });
  });

  group('DestructionAwarePodProcessor', () {
    test('should call beforeDestruction method', () async {
      final processor = MockDestructionAwarePodProcessor();
      final pod = Object();
      final podClass = Class<Object>();
      
      await processor.processBeforeDestruction(pod, podClass, 'testPod');
      
      expect(processor.beforeDestructionCallCount, 1);
    });

    test('should call afterDestruction method', () async {
      final processor = MockDestructionAwarePodProcessor();
      final pod = Object();
      final podClass = Class<Object>();
      
      await processor.processAfterDestruction(pod, podClass, 'testPod');
      
      expect(processor.afterDestructionCallCount, 1);
    });

    test('should call requiresDestruction method', () async {
      final processor = MockDestructionAwarePodProcessor();
      final pod = Object();
      final podClass = Class<Object>();
      
      await processor.requiresDestruction(pod, podClass, 'testPod');
      
      expect(processor.requiresDestructionCallCount, 1);
    });

    test('should return true by default for requiresDestruction', () async {
      final processor = MockDestructionAwarePodProcessor();
      final pod = Object();
      final podClass = Class<Object>();
      
      expect(await processor.requiresDestruction(pod, podClass, 'testPod'), isTrue);
    });
  });

  group('MultiInterfaceProcessor', () {
    test('should implement both instantiation and destruction interfaces', () async {
      final processor = MockMultiInterfaceProcessor();
      final pod = Object();
      final podClass = Class<Object>();
      final pvs = MockPropertyValues();
      
      // Test instantiation methods
      await processor.processBeforeInstantiation(podClass, 'testPod');
      await processor.processAfterInstantiation(pod, podClass, 'testPod');
      await processor.processPropertyValues(pvs, pod, podClass, 'testPod');
      
      // Test destruction methods
      await processor.processBeforeDestruction(pod, podClass, 'testPod');
      await processor.processAfterDestruction(pod, podClass, 'testPod');
      await processor.requiresDestruction(pod, podClass, 'testPod');
      
      expect(processor.instantiationCallCount, 2); // before + after
      expect(processor.destructionCallCount, 2); // before + after
    });
  });

  group('PodAwareProcessor', () {
    test('should be a valid abstract interface', () {
      final processor = MockPodAwareProcessor();
      expect(processor, isA<PodAwareProcessor>());
    });
  });
}

class MockPropertyValues extends PropertyValues {
  @override
  PropertyValues changesSince(PropertyValues old) {
    throw UnimplementedError();
  }

  @override
  bool containsProperty(String propertyName) {
    throw UnimplementedError();
  }

  @override
  PropertyValue? getPropertyValue(String propertyName) {
    throw UnimplementedError();
  }

  @override
  List<PropertyValue> getPropertyValues() {
    throw UnimplementedError();
  }

  @override
  Iterator<PropertyValue> get iterator => throw UnimplementedError();
}