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

// test/abstract_pod_definition_test.dart
import 'package:jetleaf_pod/src/definition/commons.dart';
import 'package:jetleaf_pod/src/definition/pod_definition.dart';
import 'package:jetleaf_pod/src/helpers/enums.dart';
// import 'package:jetleaf_pod/src/helpers/object.dart';
import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../_dependencies.dart';

// Mock implementation for testing
class TestAbstractPodDefinition extends AbstractPodDefinition {
  TestAbstractPodDefinition({required super.type});

  @override
  PodDefinition clone() {
    return TestAbstractPodDefinition(type: type)
      ..setIsStale(getIsStale())
      ..isPodProvider = isPodProvider
      ..setPodExpression(getPodExpression()!);
  }
}

void main() {
  setUpAll(() async {
    await setupRuntime();
    return Future<void>.value();
  });
  
  group('AbstractPodDefinition', () {
    test('should create with required parameters', () {
      final pod = TestAbstractPodDefinition(type: Class<String>())..name = 'testPod';

      expect(pod.name, equals('testPod'));
      expect(pod.type, equals(Class<String>()));
    });

    test('getIsStale should return initial value', () {
      final pod = TestAbstractPodDefinition(type: Class<String>())..name = 'testPod';

      expect(pod.getIsStale(), isFalse);
    });

    test('setIsStale should update value', () {
      final pod = TestAbstractPodDefinition(type: Class<String>())..name = 'testPod';

      pod.setIsStale(true);
      expect(pod.getIsStale(), isTrue);

      pod.setIsStale(false);
      expect(pod.getIsStale(), isFalse);
    });

    test('getIsPodProvider should return initial value', () {
      final pod = TestAbstractPodDefinition(type: Class<String>())..name = 'testPod';

      expect(pod.isPodProvider, isFalse);
    });

    test('setIsPodProvider should update value', () {
      final pod = TestAbstractPodDefinition(type: Class<String>())..name = 'testPod';

      pod.isPodProvider = true;
      expect(pod.isPodProvider, isTrue);

      pod.isPodProvider = false;
      expect(pod.isPodProvider, isFalse);
    });

    test('getPodExpression should return null initially', () {
      final pod = TestAbstractPodDefinition(type: Class<String>())..name = 'testPod';

      expect(pod.getPodExpression(), isNull);
    });

    // test('setPodExpression should update value', () {
    //   final pod = TestAbstractPodDefinition(
    //     name: 'testPod',
    //     type: Class<String>(),
    //   );
    //   final expression = PodExpression<Object>('Test()');

    //   pod.setPodExpression(expression);
    //   expect(pod.getPodExpression(), equals(expression));
    // });

    test('hasDestroyMethod should check lifecycle methods', () {
      final pod = TestAbstractPodDefinition(type: Class<String>())..name = 'testPod';

      // Add destroy methods to lifecycle
      pod.lifecycle = LifecycleDesign(
        isLazy: false,
        initMethods: [],
        destroyMethods: ['destroy', 'cleanup'],
        enforceInitMethod: true,
        enforceDestroyMethod: true,
      );

      expect(pod.hasDestroyMethod('destroy'), isTrue);
      expect(pod.hasDestroyMethod('cleanup'), isTrue);
      expect(pod.hasDestroyMethod('nonexistent'), isFalse);
    });

    test('equalsAndHashCode should include additional properties', () {
      final pod1 = TestAbstractPodDefinition(type: Class<String>())..name = 'testPod';
      final pod2 = TestAbstractPodDefinition(type: Class<String>())..name = 'testPod';

      pod1.setIsStale(true);
      pod1.isPodProvider = true;

      expect(pod1.equals(pod2), isFalse);

      pod2.setIsStale(true);
      pod2.isPodProvider = true;
      expect(pod1.equals(pod2), isTrue);
    });

    test('toString should include additional properties', () {
      final pod = TestAbstractPodDefinition(type: Class<String>())..name = 'testPod';

      pod.setIsStale(true);
      pod.isPodProvider = true;

      final str = pod.toString();
      expect(str, contains('isStale: true'));
      expect(str, contains('isPodProvider: true'));
    });

    // test('should handle pod expression in equality', () {
    //   final pod1 = TestAbstractPodDefinition(
    //     name: 'testPod',
    //     type: Class<String>(),
    //   );
    //   final pod2 = TestAbstractPodDefinition(
    //     name: 'testPod',
    //     type: Class<String>(),
    //   );

    //   final expression = PodExpression<Object>('Test()');
    //   pod1.setPodExpression(expression);

    //   expect(pod1.equals(pod2), isFalse);

    //   pod2.setPodExpression(expression);
    //   expect(pod1.equals(pod2), isTrue);
    // });

    test('should work with inheritance from PodDefinition', () {
      final pod = TestAbstractPodDefinition(type: Class<String>())..name = 'testPod';

      // Test inherited properties
      expect(pod.name, equals('testPod'));
      expect(pod.type, equals(Class<String>()));
      expect(pod.dependencyCheck, equals(DependencyCheck.NONE));
      expect(pod.hasConstructorArgumentValues(), isFalse);
    });
  });
}