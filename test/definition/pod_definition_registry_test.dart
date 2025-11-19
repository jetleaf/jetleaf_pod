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

// test/pod_definition_registry_test.dart
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/src/definition/pod_definition.dart';
import 'package:jetleaf_pod/src/definition/pod_definition_registry.dart';
import 'package:test/test.dart';

import '../_dependencies.dart';

// Mock implementation for testing
class MockPodDefinitionRegistry implements PodDefinitionRegistry {
  final Map<String, PodDefinition> _definitions = {};

  @override
  bool containsDefinition(String name) => _definitions.containsKey(name);

  @override
  List<String> getDefinitionNames() => _definitions.keys.toList();

  @override
  int getNumberOfPodDefinitions() => _definitions.length;

  @override
  Future<void> registerDefinition(String name, PodDefinition pod) async {
    _definitions[name] = pod;
  }

  @override
  Future<void> removeDefinition(String name) async {
    if (!_definitions.containsKey(name)) {
      throw Exception('Pod not found');
    }
    _definitions.remove(name);
  }

  @override
  PodDefinition getDefinition(String name) {
    if (!_definitions.containsKey(name)) {
      throw Exception('Pod not found');
    }
    return _definitions[name]!;
  }

  @override
  PodDefinition getDefinitionByClass(Class type) {
    for (final definition in _definitions.values) {
      final defType = definition.type;

      if (defType == type || defType.isSubclassOf(type) || type.isAssignableFrom(defType)) {
        return definition;
      }
    }

    throw Exception('Pod not found');
  }

  @override
  Future<bool> isNameInUse(String name) async => _definitions.containsKey(name);
}

// Mock pod definition
class MockPodDefinition extends PodDefinition {
  MockPodDefinition({required super.name, required super.type});

  @override
  PodDefinition clone() {
    return MockPodDefinition(name: name, type: type);
  }
}

void main() {
  setUpAll(() async {
    await setupRuntime();
    return Future<void>.value();
  });

  group('PodDefinitionRegistry', () {
    late PodDefinitionRegistry registry;

    setUp(() {
      registry = MockPodDefinitionRegistry();
    });

    test('should implement all interface methods', () {
      expect(registry, isA<PodDefinitionRegistry>());
      expect(registry, isA<ListablePodDefinitionRegistry>());
    });

    test('registerDefinition should add pod', () async {
      final pod = MockPodDefinition(name: 'TestPod', type: Class<String>());
      await registry.registerDefinition('test', pod);

      expect(registry.containsDefinition('test'), isTrue);
    });

    test('getDefinition should retrieve pod', () async {
      final pod = MockPodDefinition(name: 'TestPod', type: Class<String>());
      await registry.registerDefinition('test', pod);

      expect(registry.getDefinition('test'), equals(pod));
    });

    test('removeDefinition should remove pod', () async {
      final pod = MockPodDefinition(name: 'TestPod', type: Class<String>());
      await registry.registerDefinition('test', pod);

      expect(registry.containsDefinition('test'), isTrue);
      await registry.removeDefinition('test');
      expect(registry.containsDefinition('test'), isFalse);
    });

    test('isNameInUse should check name availability', () async {
      final pod = MockPodDefinition(name: 'TestPod', type: Class<String>());
      await registry.registerDefinition('test', pod);

      bool isInUse = await registry.isNameInUse('test');
      expect(isInUse, isTrue);

      isInUse = await registry.isNameInUse('nonexistent');
      expect(isInUse, isFalse);
    });

    test('getDefinitionNames should return all names', () async {
      final pod1 = MockPodDefinition(name: 'Pod1', type: Class<String>());
      final pod2 = MockPodDefinition(name: 'Pod2', type: Class<int>());

      await registry.registerDefinition('pod1', pod1);
      await registry.registerDefinition('pod2', pod2);

      final names = registry.getDefinitionNames();
      expect(names, hasLength(2));
      expect(names, contains('pod1'));
      expect(names, contains('pod2'));
    });

    test('getNumberOfPodDefinitions should return count', () async {
      expect(registry.getNumberOfPodDefinitions(), equals(0));

      final pod = MockPodDefinition(name: 'TestPod', type: Class<String>());
      await registry.registerDefinition('test', pod);

      expect(registry.getNumberOfPodDefinitions(), equals(1));
    });

    test('should handle interface contract', () async {
      // Test that the interface methods work together correctly
      final pod = MockPodDefinition(name: 'TestPod', type: Class<String>());
      
      // Register
      await registry.registerDefinition('test', pod);
      
      // Verify registration
      expect(registry.containsDefinition('test'), isTrue);

      bool isInUse = await registry.isNameInUse('test');
      expect(isInUse, isTrue);
      expect(registry.getNumberOfPodDefinitions(), equals(1));
      expect(registry.getDefinitionNames(), contains('test'));
      
      // Retrieve
      final retrieved = registry.getDefinition('test');
      expect(retrieved, equals(pod));
      
      // Remove
      await registry.removeDefinition('test');
      
      // Verify removal
      expect(registry.containsDefinition('test'), isFalse);

      isInUse = await registry.isNameInUse('test');
      expect(isInUse, isFalse);
      expect(registry.getNumberOfPodDefinitions(), equals(0));
      expect(registry.getDefinitionNames(), isNot(contains('test')));
    });

    test('should handle error conditions', () {
      // Test getDefinition with non-existent pod
      expect(() => registry.getDefinition('nonexistent'), throwsException);
      
      // Test removeDefinition with non-existent pod
      expect(() => registry.removeDefinition('nonexistent'), throwsException);
    });

    test('should handle multiple operations', () async {
      final pods = List.generate(5, (i) => MockPodDefinition(name: 'Pod$i', type: Class<String>()));

      // Register multiple pods
      for (int i = 0; i < pods.length; i++) {
        await registry.registerDefinition('pod$i', pods[i]);
      }

      expect(registry.getNumberOfPodDefinitions(), equals(5));

      // Remove some pods
      await registry.removeDefinition('pod0');
      await registry.removeDefinition('pod2');
      await registry.removeDefinition('pod4');

      expect(registry.getNumberOfPodDefinitions(), equals(2));
      expect(registry.containsDefinition('pod1'), isTrue);
      expect(registry.containsDefinition('pod3'), isTrue);
    });
  });
}