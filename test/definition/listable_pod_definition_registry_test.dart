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

// test/listable_pod_definition_registry_test.dart
import 'package:jetleaf_pod/src/definition/pod_definition_registry.dart';
import 'package:test/test.dart';

// Mock implementation for testing
class MockListablePodDefinitionRegistry implements ListablePodDefinitionRegistry {
  final Map<String, MockPodDefinition> _definitions = {};

  @override
  bool containsDefinition(String name) => _definitions.containsKey(name);

  @override
  List<String> getDefinitionNames() => List.unmodifiable(_definitions.keys.toList());

  @override
  int getNumberOfPodDefinitions() => _definitions.length;

  // Helper method for testing
  void registerDefinition(String name, MockPodDefinition pod) {
    _definitions[name] = pod;
  }
}

// Mock pod definition
class MockPodDefinition {
  final String name;
  final Type type;

  MockPodDefinition({required this.name, required this.type});
}

void main() {
  group('ListablePodDefinitionRegistry', () {
    late ListablePodDefinitionRegistry registry;

    setUp(() {
      registry = MockListablePodDefinitionRegistry();
    });

    test('should implement interface methods', () {
      expect(registry, isA<ListablePodDefinitionRegistry>());
    });

    test('containsDefinition should return false for empty registry', () {
      expect(registry.containsDefinition('nonexistent'), isFalse);
    });

    test('containsDefinition should return true for existing pod', () {
      final pod = MockPodDefinition(name: 'TestPod', type: String);
      (registry as MockListablePodDefinitionRegistry).registerDefinition('test', pod);

      expect(registry.containsDefinition('test'), isTrue);
    });

    test('getDefinitionNames should return empty list initially', () {
      expect(registry.getDefinitionNames(), isEmpty);
    });

    test('getDefinitionNames should return all names', () {
      final pod1 = MockPodDefinition(name: 'Pod1', type: String);
      final pod2 = MockPodDefinition(name: 'Pod2', type: int);

      (registry as MockListablePodDefinitionRegistry).registerDefinition('pod1', pod1);
      (registry as MockListablePodDefinitionRegistry).registerDefinition('pod2', pod2);

      final names = registry.getDefinitionNames();
      expect(names, hasLength(2));
      expect(names, contains('pod1'));
      expect(names, contains('pod2'));
    });

    test('getNumberOfPodDefinitions should return 0 initially', () {
      expect(registry.getNumberOfPodDefinitions(), equals(0));
    });

    test('getNumberOfPodDefinitions should return correct count', () {
      final pod1 = MockPodDefinition(name: 'Pod1', type: String);
      final pod2 = MockPodDefinition(name: 'Pod2', type: int);

      (registry as MockListablePodDefinitionRegistry).registerDefinition('pod1', pod1);
      expect(registry.getNumberOfPodDefinitions(), equals(1));

      (registry as MockListablePodDefinitionRegistry).registerDefinition('pod2', pod2);
      expect(registry.getNumberOfPodDefinitions(), equals(2));
    });

    test('should handle empty registry', () {
      expect(registry.containsDefinition('any'), isFalse);
      expect(registry.getDefinitionNames(), isEmpty);
      expect(registry.getNumberOfPodDefinitions(), equals(0));
    });

    test('should handle single pod', () {
      final pod = MockPodDefinition(name: 'TestPod', type: String);
      (registry as MockListablePodDefinitionRegistry).registerDefinition('test', pod);

      expect(registry.containsDefinition('test'), isTrue);
      expect(registry.containsDefinition('other'), isFalse);
      expect(registry.getDefinitionNames(), equals(['test']));
      expect(registry.getNumberOfPodDefinitions(), equals(1));
    });

    test('should handle multiple pods', () {
      final pods = List.generate(5, (i) =>
          MockPodDefinition(name: 'Pod$i', type: String));

      for (int i = 0; i < pods.length; i++) {
        (registry as MockListablePodDefinitionRegistry).registerDefinition('pod$i', pods[i]);
      }

      expect(registry.getNumberOfPodDefinitions(), equals(5));
      expect(registry.getDefinitionNames(), hasLength(5));

      for (int i = 0; i < 5; i++) {
        expect(registry.containsDefinition('pod$i'), isTrue);
      }
    });

    test('getDefinitionNames should return unmodifiable list', () {
      final pod = MockPodDefinition(name: 'TestPod', type: String);
      (registry as MockListablePodDefinitionRegistry).registerDefinition('test', pod);

      final names = registry.getDefinitionNames();
      expect(() => names.add('new'), throwsA(isA<UnsupportedError>()));
    });

    test('should handle name case sensitivity', () {
      final pod = MockPodDefinition(name: 'TestPod', type: String);
      (registry as MockListablePodDefinitionRegistry).registerDefinition('Test', pod);

      expect(registry.containsDefinition('Test'), isTrue);
      expect(registry.containsDefinition('test'), isFalse); // Assuming case-sensitive
    });

    test('should handle special characters in names', () {
      final specialNames = ['pod-1', 'pod_2', 'pod.3', 'pod@4', 'pod#5'];
      final pod = MockPodDefinition(name: 'TestPod', type: String);

      for (final name in specialNames) {
        (registry as MockListablePodDefinitionRegistry).registerDefinition(name, pod);
        expect(registry.containsDefinition(name), isTrue);
      }
    });

    test('should handle very long names', () {
      final longName = 'a' * 1000;
      final pod = MockPodDefinition(name: 'TestPod', type: String);

      (registry as MockListablePodDefinitionRegistry).registerDefinition(longName, pod);
      expect(registry.containsDefinition(longName), isTrue);
      expect(registry.getDefinitionNames(), contains(longName));
    });
  });
}