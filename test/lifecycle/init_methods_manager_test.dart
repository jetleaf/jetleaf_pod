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

import 'package:jetleaf_pod/src/definition/commons.dart';
import 'package:jetleaf_pod/src/definition/pod_definition.dart';
import 'package:jetleaf_pod/src/exceptions.dart';
import 'package:jetleaf_pod/src/lifecycle/init_methods_manager.dart';
import 'package:jetleaf_pod/src/lifecycle/lifecycle.dart';
import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../_dependencies.dart';

// Test classes
class TestInitializingPod implements InitializingPod {
  bool onReadyCalled = false;
  bool shouldThrow = false;

  @override
  Future<void> onReady() async {
    if (shouldThrow) {
      throw PodException('Init failed');
    }
    onReadyCalled = true;
  }

  @override
  String getPackageName() => "test";
}

class TestCustomInitPod {
  bool customInitCalled = false;
  bool customInit2Called = false;

  void customInit() {
    customInitCalled = true;
  }

  Future<void> customInit2() async {
    customInit2Called = true;
  }

  void invalidInit(String param) {
    // This should not be called due to parameter
  }
}

class TestPodWithoutInit {
  // No init methods
}

void main() {
  setUpAll(() async {
    await setupRuntime();
    return Future<void>.value();
  });

  group('InitMethodsManager', () {
    late InitMethodsManager manager;

    setUp(() {
      manager = InitMethodsManager();
    });

    test('should invoke InitializingPod.onReady()', () async {
      // Arrange
      final pod = TestInitializingPod();
      
      // Act
      await manager.invokeInitMethods('testPod', pod, null);
      
      // Assert
      expect(pod.onReadyCalled, isTrue);
    });

    test('should invoke both lifecycle interfaces', () async {
      // Arrange
      final pod = TestBothLifecyclePod();
      
      // Act
      await manager.invokeInitMethods('testPod', pod, null);
      
      // Assert
      expect(pod.onReadyCalled, isTrue);
      expect(pod.onSingletonReadyCalled, isTrue);
    });

    test('should invoke custom init methods', () async {
      // Arrange
      final pod = TestCustomInitPod();
      final definition = RootPodDefinition(type: Class<TestCustomInitPod>())
        ..lifecycle = LifecycleDesign(
          initMethods: ['customInit', 'customInit2'],
          enforceInitMethod: true
        );
      
      // Act
      await manager.invokeInitMethods('testPod', pod, definition);
      
      // Assert
      expect(pod.customInitCalled, isTrue);
      expect(pod.customInit2Called, isTrue);
    });

    test('should handle InitializingPod exception', () async {
      // Arrange
      final pod = TestInitializingPod()..shouldThrow = true;
      
      // Act & Assert
      expect(
        () => manager.invokeInitMethods('testPod', pod, null),
        throwsA(isA<PodException>())
      );
    });

    test('should handle missing init method when enforcement disabled', () async {
      // Arrange
      final pod = TestPodWithoutInit();
      final definition = RootPodDefinition(type: Class<TestPodWithoutInit>())
        ..lifecycle = LifecycleDesign(
          initMethods: ['nonExistentMethod'],
          enforceInitMethod: false
        );
      
      // Act & Assert - should not throw
      await manager.invokeInitMethods('testPod', pod, definition);
    });

    test('should throw when init method missing and enforcement enabled', () async {
      // Arrange
      final pod = TestPodWithoutInit();
      final definition = RootPodDefinition(type: Class<TestPodWithoutInit>())
        ..lifecycle = LifecycleDesign(
          initMethods: ['nonExistentMethod'],
          enforceInitMethod: true
        );
      
      // Act & Assert
      expect(
        () => manager.invokeInitMethods('testPod', pod, definition),
        throwsA(isA<PodCreationException>())
      );
    });

    test('hasInitMethods should return true for InitializingPod', () {
      // Arrange
      final pod = TestInitializingPod();
      
      // Act
      final result = manager.hasInitMethods(pod, null);
      
      // Assert
      expect(result, isTrue);
    });

    test('hasInitMethods should return true for custom init methods', () {
      // Arrange
      final pod = TestPodWithoutInit();
      final definition = RootPodDefinition(type: Class<TestPodWithoutInit>())
        ..lifecycle = LifecycleDesign(initMethods: ['customInit']);
      
      // Act
      final result = manager.hasInitMethods(pod, definition);
      
      // Assert
      expect(result, isTrue);
    });

    test('hasInitMethods should return false for pod without init methods', () {
      // Arrange
      final pod = TestPodWithoutInit();
      final definition = RootPodDefinition(type: Class<TestPodWithoutInit>());
      
      // Act
      final result = manager.hasInitMethods(pod, definition);
      
      // Assert
      expect(result, isFalse);
    });

    test('validateInitMethods should pass for valid methods', () {
      // Arrange
      final podClass = Class<TestCustomInitPod>();
      final definition = RootPodDefinition(type: podClass)
        ..lifecycle = LifecycleDesign(
          initMethods: ['customInit'],
          enforceInitMethod: true
        );
      
      // Act & Assert - should not throw
      manager.validateInitMethods(podClass, definition);
    });

    test('validateInitMethods should throw for invalid methods', () {
      // Arrange
      final podClass = Class<TestCustomInitPod>();
      final definition = RootPodDefinition(type: podClass)
        ..lifecycle = LifecycleDesign(
          initMethods: ['invalidInit'], // has parameters
          enforceInitMethod: true
        );
      
      // Act & Assert
      expect(
        () => manager.validateInitMethods(podClass, definition),
        throwsA(isA<PodDefinitionValidationException>())
      );
    });
  });
}

class TestBothLifecyclePod implements InitializingPod, SmartInitializingSingleton {
  bool onReadyCalled = false;
  bool onSingletonReadyCalled = false;

  @override
  Future<void> onReady() async {
    onReadyCalled = true;
  }

  @override
  Future<void> onSingletonReady() async {
    onSingletonReadyCalled = true;
  }
  
  @override
  String getPackageName() => "test";
}