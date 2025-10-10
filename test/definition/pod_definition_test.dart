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

// test/pod_definition_test.dart
import 'package:jetleaf_pod/src/definition/commons.dart';
import 'package:jetleaf_pod/src/definition/pod_definition.dart';
import 'package:jetleaf_pod/src/helpers/enums.dart';
import 'package:jetleaf_pod/src/helpers/object.dart';
import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../_dependencies.dart';

// Mock implementation for testing
class TestPodDefinition extends PodDefinition {
  TestPodDefinition({
    required super.name,
    required super.type,
    super.description,
    super.dependencyCheck,
    super.scope,
    super.design,
    super.lifecycle,
    super.dependsOn,
    super.propertyValues,
    super.factoryMethod,
    super.autowireCandidate,
    super.constructorArgumentValues,
  });

  @override
  PodDefinition clone() {
    return TestPodDefinition(
      name: name,
      type: type,
      description: description,
      dependencyCheck: dependencyCheck,
      scope: scope,
      design: design,
      lifecycle: lifecycle,
      dependsOn: List.from(dependsOn),
      propertyValues: propertyValues,
      factoryMethod: factoryMethod,
      autowireCandidate: autowireCandidate,
      constructorArgumentValues: executableArgumentValues,
    );
  }
}

void main() {
  setUpAll(() async {
    await setupRuntime();
    return Future<void>.value();
  });
  
  group('PodDefinition', () {
    test('should create with required parameters', () {
      final pod = TestPodDefinition(
        name: 'testPod',
        type: Class<String>(),
      );

      expect(pod.name, equals('testPod'));
      expect(pod.type, equals(Class<String>()));
    });

    test('should create with all parameters', () {
      final pod = TestPodDefinition(
        name: 'testPod',
        type: Class<String>(),
        description: 'Test description',
        dependencyCheck: DependencyCheck.ALL,
        scope: ScopeDesign(
          type: ScopeType.PROTOTYPE.name,
          isSingleton: false,
          isPrototype: true,
        ),
        design: DesignDescriptor(
          role: DesignRole.INFRASTRUCTURE,
          isPrimary: true,
        ),
        lifecycle: LifecycleDesign(
          isLazy: true,
          initMethods: ['init'],
          destroyMethods: ['destroy'],
          enforceInitMethod: false,
          enforceDestroyMethod: false,
        ),
        dependsOn: [DependencyDesign(name: 'dep1')],
        propertyValues: MutablePropertyValues(),
        factoryMethod: FactoryMethodDesign('factoryPod', 'create'),
        autowireCandidate: AutowireCandidateDescriptor(
          autowireCandidate: true,
          autowireMode: AutowireMode.BY_TYPE,
        ),
        constructorArgumentValues: ConstructorArgumentValues(),
      );

      expect(pod.name, equals('testPod'));
      expect(pod.description, equals('Test description'));
      expect(pod.dependencyCheck, equals(DependencyCheck.ALL));
      expect(pod.scope.type, equals(ScopeType.PROTOTYPE));
      expect(pod.design.role, equals(DesignRole.INFRASTRUCTURE));
      expect(pod.lifecycle.isLazy, isTrue);
      expect(pod.dependsOn, hasLength(1));
      expect(pod.factoryMethod.podName, equals('factoryPod'));
      expect(pod.autowireCandidate.autowireMode, equals(AutowireMode.BY_TYPE));
    });

    test('should provide default values', () {
      final pod = TestPodDefinition(
        name: 'testPod',
        type: Class<String>(),
      );

      expect(pod.dependencyCheck, equals(DependencyCheck.NONE));
      expect(pod.scope.type, equals(ScopeType.SINGLETON));
      expect(pod.design.role, equals(DesignRole.APPLICATION));
      expect(pod.lifecycle.isLazy, isFalse);
      expect(pod.dependsOn, isEmpty);
      expect(pod.propertyValues, isA<MutablePropertyValues>());
      expect(pod.factoryMethod.podName, isEmpty);
      expect(pod.autowireCandidate.autowireMode, equals(AutowireMode.NO));
      expect(pod.executableArgumentValues, isA<ConstructorArgumentValues>());
    });

    test('hasConstructorArgumentValues should return correct value', () {
      final pod = TestPodDefinition(
        name: 'testPod',
        type: Class<String>(),
      );

      expect(pod.hasConstructorArgumentValues(), isFalse);

      pod.executableArgumentValues.add('arg1', 'value1', packageName: "Test");
      expect(pod.hasConstructorArgumentValues(), isTrue);
    });

    test('hasPropertyValues should return correct value', () {
      final pod = TestPodDefinition(
        name: 'testPod',
        type: Class<String>(),
      );

      expect(pod.hasPropertyValues(), isFalse);

      pod.propertyValues.add('prop1', 'value1', packageName: "test");
      expect(pod.hasPropertyValues(), isTrue);
    });

    test('clone should create copy', () {
      final original = TestPodDefinition(
        name: 'testPod',
        type: Class<String>(),
        description: 'Test',
        dependencyCheck: DependencyCheck.OBJECTS,
      );

      final cloned = original.clone();

      expect(cloned.name, equals(original.name));
      expect(cloned.type, equals(original.type));
      expect(cloned.description, equals(original.description));
      expect(cloned.dependencyCheck, equals(original.dependencyCheck));
    });

    test('equalsAndHashCode should work correctly', () {
      final pod1 = TestPodDefinition(
        name: 'testPod',
        type: Class<String>(),
      );
      final pod2 = TestPodDefinition(
        name: 'testPod',
        type: Class<String>(),
      );
      final pod3 = TestPodDefinition(
        name: 'different',
        type: Class<String>(),
      );
      
      expect(pod1.equals(pod2), isTrue);
      expect(pod1.equals(pod3), isFalse);
      expect(pod1.hashCode, equals(pod2.hashCode));
      expect(pod1.hashCode, isNot(equals(pod3.hashCode)));
    });

    test('toString should include class name and properties', () {
      final pod = TestPodDefinition(
        name: 'testPod',
        type: Class<String>(),
      );

      final str = pod.toString();
      expect(str, contains('TestPodDefinition'));
      expect(str, contains('testPod'));
      // expect(str, contains('Class<String>'));
    });

    test('should handle null description', () {
      final pod = TestPodDefinition(
        name: 'testPod',
        type: Class<String>(),
      );

      expect(pod.description, isNull);
    });

    test('should handle empty collections', () {
      final pod = TestPodDefinition(
        name: 'testPod',
        type: Class<String>(),
      );

      expect(pod.dependsOn, isEmpty);
      expect(pod.propertyValues.isEmpty, isTrue);
      expect(pod.executableArgumentValues.isEmpty(), isTrue);
    });

    test('should handle complex types in properties', () {
      final complexType = Class<Map<String, List<int>>>();
      final pod = TestPodDefinition(
        name: 'testPod',
        type: complexType,
      );

      expect(pod.type, equals(complexType));
    });
  });
}