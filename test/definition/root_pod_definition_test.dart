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

// test/root_pod_definition_test.dart
import 'package:jetleaf_pod/src/definition/commons.dart';
import 'package:jetleaf_pod/src/definition/pod_definition.dart';
import 'package:jetleaf_pod/src/helpers/enums.dart';
import 'package:jetleaf_pod/src/helpers/object.dart';
import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../_dependencies.dart';

void main() {
  setUpAll(() async {
    await setupRuntime();
    return Future<void>.value();
  });
  
  group('RootPodDefinition', () {
    test('should create with required parameters', () {
      final pod = RootPodDefinition(type: Class<String>())..name = 'testPod';

      expect(pod.name, equals('testPod'));
      expect(pod.type, equals(Class<String>()));
      expect(pod.getIsStale(), isFalse);
      expect(pod.isPodProvider, isFalse);
    });

    test('from constructor should copy all properties', () {
      final original = RootPodDefinition(type: Class<String>())..name = 'testPod';

      original.setIsStale(true);
      original.isPodProvider = true;
      original.description = 'Test description';
      original.dependencyCheck = DependencyCheck.ALL;
      original.scope = ScopeDesign(
        type: ScopeType.PROTOTYPE.name,
        isSingleton: false,
        isPrototype: true,
      );
      original.design = DesignDescriptor(
        role: DesignRole.INFRASTRUCTURE,
        isPrimary: true,
      );
      original.lifecycle = LifecycleDesign(
        isLazy: true,
        initMethods: ['init'],
        destroyMethods: ['destroy'],
        enforceInitMethod: false,
        enforceDestroyMethod: false,
      );
      original.dependsOn = [DependencyDesign(name: 'dep1')];
      original.propertyValues.add('prop1', 'value1', packageName: "test");
      original.factoryMethod = FactoryMethodDesign('factory', 'create');
      original.autowireCandidate = AutowireCandidateDescriptor(
        autowireCandidate: true,
        autowireMode: AutowireMode.BY_TYPE,
      );
      original.executableArgumentValues.add('arg1', 'value1', packageName: "test");

      final copy = RootPodDefinition.from(original);

      expect(copy.name, equals(original.name));
      expect(copy.type, equals(original.type));
      expect(copy.getIsStale(), equals(original.getIsStale()));
      expect(copy.isPodProvider, equals(original.isPodProvider));
      expect(copy.description, equals(original.description));
      expect(copy.dependencyCheck, equals(original.dependencyCheck));
      expect(copy.scope.type, equals(original.scope.type));
      expect(copy.design.role, equals(original.design.role));
      expect(copy.lifecycle.isLazy, equals(original.lifecycle.isLazy));
      expect(copy.dependsOn.length, equals(original.dependsOn.length));
      expect(copy.propertyValues.length, equals(original.propertyValues.length));
      expect(copy.factoryMethod.podName, equals(original.factoryMethod.podName));
      expect(copy.autowireCandidate.autowireMode, equals(original.autowireCandidate.autowireMode));
      expect(copy.executableArgumentValues.getCount(), equals(original.executableArgumentValues.getCount()));
    });

    test('clone should create identical copy', () {
      final original = RootPodDefinition(type: Class<String>())..name = 'testPod';

      original.setIsStale(true);
      original.isPodProvider = true;

      final cloned = original.clone() as RootPodDefinition;

      expect(cloned.name, equals(original.name));
      expect(cloned.type, equals(original.type));
      expect(cloned.getIsStale(), equals(original.getIsStale()));
      expect(cloned.isPodProvider, equals(original.isPodProvider));
    });

    // test('should handle pod expression in from constructor', () {
    //   final original = RootPodDefinition(
    //     name: 'testPod',
    //     type: Class<String>(),
    //   );

    //   final expression = PodExpression<Object>('Test()');
    //   original.setPodExpression(expression);

    //   final copy = RootPodDefinition.from(original);
    //   expect(copy.getPodExpression(), equals(expression));
    // });

    test('should handle null properties in from constructor', () {
      final original = RootPodDefinition(type: Class<String>())..name = 'testPod';

      original.description = null;

      final copy = RootPodDefinition.from(original);
      expect(copy.description, isNull);
    });

    test('should handle empty collections in from constructor', () {
      final original = RootPodDefinition(type: Class<String>())..name = 'testPod';

      original.dependsOn = [];
      original.propertyValues = MutablePropertyValues();
      original.executableArgumentValues = ConstructorArgumentValues();

      final copy = RootPodDefinition.from(original);
      expect(copy.dependsOn, isEmpty);
      expect(copy.propertyValues.isEmpty, isTrue);
      expect(copy.executableArgumentValues.isEmpty(), isTrue);
    });

    test('equalsAndHashCode should work with copied instances', () {
      final original = RootPodDefinition(type: Class<String>())..name = 'testPod';

      final copy = RootPodDefinition.from(original);

      expect(original.equals(copy), isTrue);
      expect(original.hashCode, equals(copy.hashCode));
    });

    test('should maintain independent state after copy', () {
      final original = RootPodDefinition(type: Class<String>())..name = 'testPod';

      final copy = RootPodDefinition.from(original);

      // Modify original
      original.setIsStale(true);
      original.isPodProvider = true;

      // Copy should not be affected
      expect(copy.getIsStale(), isFalse);
      expect(copy.isPodProvider, isFalse);
    });
  });
}