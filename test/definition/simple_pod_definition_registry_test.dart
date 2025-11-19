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

// test/simple_pod_definition_registry_test.dart
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/src/definition/pod_definition.dart';
import 'package:jetleaf_pod/src/definition/pod_definition_registry.dart';
import 'package:jetleaf_pod/src/definition/simple_pod_definition_registry.dart';
import 'package:jetleaf_pod/src/exceptions.dart';
import 'package:test/test.dart';

import '../_dependencies.dart';

// Mock PodDefinition for testing
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

  group('SimplePodDefinitionRegistry', () {
    late SimplePodDefinitionRegistry registry;

    setUp(() {
      registry = SimplePodDefinitionRegistry();
    });

    test('should create instance', () {
      expect(registry, isA<SimplePodDefinitionRegistry>());
      expect(registry, isA<PodDefinitionRegistry>());
      expect(registry, isA<ListablePodDefinitionRegistry>());
    });

    test('containsDefinition should return false for empty registry', () {
      expect(registry.containsDefinition('nonexistent'), isFalse);
    });

    test('registerDefinition and getDefinition should work', () {
      final pod = MockPodDefinition(name: 'TestPod', type: Class<String>());
      registry.registerDefinition('test', pod);

      expect(registry.containsDefinition('test'), isTrue);
      expect(registry.getDefinition('test'), equals(pod));
    });

    test('getDefinition should throw for non-existent pod', () {
      expect(() => registry.getDefinition('nonexistent'),
          throwsA(isA<NoSuchPodDefinitionException>()));
    });

    test('getNumberOfPodDefinitions should return correct count', () {
      expect(registry.getNumberOfPodDefinitions(), equals(0));

      final pod1 = MockPodDefinition(name: 'Pod1', type: Class<String>());
      final pod2 = MockPodDefinition(name: 'Pod2', type: Class<int>());

      registry.registerDefinition('pod1', pod1);
      expect(registry.getNumberOfPodDefinitions(), equals(1));

      registry.registerDefinition('pod2', pod2);
      expect(registry.getNumberOfPodDefinitions(), equals(2));
    });

    test('getDefinitionNames should return all names', () {
      expect(registry.getDefinitionNames(), isEmpty);

      final pod1 = MockPodDefinition(name: 'Pod1', type: Class<String>());
      final pod2 = MockPodDefinition(name: 'Pod2', type: Class<int>());

      registry.registerDefinition('pod1', pod1);
      registry.registerDefinition('pod2', pod2);

      final names = registry.getDefinitionNames();
      expect(names, hasLength(2));
      expect(names, contains('pod1'));
      expect(names, contains('pod2'));
    });

    test('isNameInUse should check both definitions and aliases', () async {
      final pod = MockPodDefinition(name: 'TestPod', type: Class<String>());
      registry.registerDefinition('test', pod);

      bool isInUse = await registry.isNameInUse('test');
      expect(isInUse, isTrue);

      isInUse = await registry.isNameInUse('nonexistent');
      expect(isInUse, isFalse);

      // Test with aliases
      registry.registerAlias('test', 'alias');

      isInUse = await registry.isNameInUse('alias');
      expect(isInUse, isTrue);
    });

    test('removeDefinition should remove pod', () {
      final pod = MockPodDefinition(name: 'TestPod', type: Class<String>());
      registry.registerDefinition('test', pod);

      expect(registry.containsDefinition('test'), isTrue);
      registry.removeDefinition('test');
      expect(registry.containsDefinition('test'), isFalse);
    });

    test('removeDefinition should throw for non-existent pod', () {
      expect(() => registry.removeDefinition('nonexistent'),
          throwsA(isA<NoSuchPodDefinitionException>()));
    });

    test('should handle multiple registrations and removals', () {
      final pods = List.generate(5, (i) =>
          MockPodDefinition(name: 'Pod$i', type: Class<String>()));

      for (int i = 0; i < pods.length; i++) {
        registry.registerDefinition('pod$i', pods[i]);
      }

      expect(registry.getNumberOfPodDefinitions(), equals(5));

      // Remove some pods
      registry.removeDefinition('pod0');
      registry.removeDefinition('pod2');
      registry.removeDefinition('pod4');

      expect(registry.getNumberOfPodDefinitions(), equals(2));
      expect(registry.containsDefinition('pod1'), isTrue);
      expect(registry.containsDefinition('pod3'), isTrue);
    });

    test('should handle duplicate registration (overwrite)', () {
      final pod1 = MockPodDefinition(name: 'Pod1', type: Class<String>());
      final pod2 = MockPodDefinition(name: 'Pod2', type: Class<int>());

      registry.registerDefinition('test', pod1);
      expect(registry.getDefinition('test'), equals(pod1));

      registry.registerDefinition('test', pod2);
      expect(registry.getDefinition('test'), equals(pod2));
    });

    test('should handle empty name', () {
      final pod = MockPodDefinition(name: 'TestPod', type: Class<String>());

      expect(() => registry.registerDefinition('', pod),
          throwsA(isA<IllegalArgumentException>()));
      expect(() => registry.getDefinition(''),
          throwsA(isA<NoSuchPodDefinitionException>()));
      expect(() => registry.removeDefinition(''),
          throwsA(isA<NoSuchPodDefinitionException>()));
    });

    test('should handle very long names', () {
      final longName = 'a' * 1000;
      final pod = MockPodDefinition(name: 'TestPod', type: Class<String>());

      registry.registerDefinition(longName, pod);
      expect(registry.containsDefinition(longName), isTrue);
      expect(registry.getDefinition(longName), equals(pod));
    });

    test('should handle special characters in names', () {
      final specialNames = ['pod-1', 'pod_2', 'pod.3', 'pod@4', 'pod#5'];
      final pod = MockPodDefinition(name: 'TestPod', type: Class<String>());

      for (final name in specialNames) {
        registry.registerDefinition(name, pod);
        expect(registry.containsDefinition(name), isTrue);
      }
    });

    test('should handle concurrent access patterns', () async {
      final pods = List.generate(10, (i) =>
          MockPodDefinition(name: 'Pod$i', type: Class<String>()));

      final futures = <Future>[];
      for (int i = 0; i < pods.length; i++) {
        futures.add(Future(() {
          registry.registerDefinition('pod$i', pods[i]);
        }));
      }

      await Future.wait(futures);
      expect(registry.getNumberOfPodDefinitions(), equals(10));
    });

    test('should integrate with alias registry functionality', () async {
      final pod = MockPodDefinition(name: 'TestPod', type: Class<String>());
      registry.registerDefinition('original', pod);
      registry.registerAlias('original', 'alias');

      // Both original and alias should be considered "in use"
      bool isInUse = await registry.isNameInUse('original');
      expect(isInUse, isTrue);

      isInUse = await registry.isNameInUse('alias');
      expect(isInUse, isTrue);

      // But only original should be in definitions
      expect(registry.containsDefinition('original'), isTrue);
      expect(registry.containsDefinition('alias'), isFalse);
    });

    test('should handle mixed definition and alias operations', () async {
      final pod1 = MockPodDefinition(name: 'Pod1', type: Class<String>());
      final pod2 = MockPodDefinition(name: 'Pod2', type: Class<int>());

      registry.registerDefinition('pod1', pod1);
      registry.registerDefinition('pod2', pod2);
      registry.registerAlias('pod1', 'alias1');
      registry.registerAlias('pod2', 'alias2');

      expect(registry.getNumberOfPodDefinitions(), equals(2));

      bool isInUse = await registry.isNameInUse('alias1');
      expect(isInUse, isTrue);

      isInUse = await registry.isNameInUse('alias2');
      expect(isInUse, isTrue);

      registry.removeDefinition('pod1');
      expect(registry.containsDefinition('pod1'), isFalse);

      isInUse = await registry.isNameInUse('alias1');
      expect(isInUse, isFalse); // Alias should also be removed
    });
  });
}