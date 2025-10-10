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

// test/pod_provider_test.dart
import 'dart:async';

import 'package:jetleaf_pod/src/helpers/object.dart';
import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../_dependencies.dart';

class TestPodProvider extends PodProvider<String> {
  final String value;
  final Class? objectType;
  final bool isSingletonFlag;
  final bool isPrototypeFlag;
  final bool isEagerInitFlag;

  TestPodProvider({
    this.value = 'default',
    this.objectType,
    this.isSingletonFlag = true,
    this.isPrototypeFlag = false,
    this.isEagerInitFlag = false,
  });

  @override
  Class? getClass() => objectType ?? Class<String>();

  @override
  FutureOr<ObjectHolder<String>?> get([Class? requiredType]) => ObjectHolder(value, packageName: 'test', qualifiedName: 'test');

  @override
  bool isSingleton() => isSingletonFlag;

  @override
  bool isPrototype() => isPrototypeFlag;

  @override
  bool isEagerInit() => isEagerInitFlag;
}

void main() {
  setUpAll(() async {
    await setupRuntime();
    return Future<void>.value();
  });

  group('PodProvider', () {
    test('should create and return object', () async {
      final provider = TestPodProvider(value: 'test_value');
      final result = await provider.get();
      expect(result?.getValue(), equals('test_value'));
    });

    test('isSingleton should return true by default', () {
      final provider = TestPodProvider();
      expect(provider.isSingleton(), isTrue);
    });

    test('should return correct class type', () {
      final provider = TestPodProvider(objectType: Class<int>());
      expect(provider.getClass(), equals(Class<int>()));
    });

    test('supportsType should return true for compatible types', () {
      final provider = TestPodProvider(objectType: Class<String>());
      expect(provider.supportsType(Class<String>()), isTrue);
      expect(provider.supportsType(Class<Object>()), isTrue);
    });

    test('supportsType should return false for incompatible types', () {
      final provider = TestPodProvider(objectType: Class<String>());
      expect(provider.supportsType(Class<int>()), isFalse);
    });

    test('isPrototype should return false by default', () {
      final provider = TestPodProvider();
      expect(provider.isPrototype(), isFalse);
    });

    test('isEagerInit should return false by default', () {
      final provider = TestPodProvider();
      expect(provider.isEagerInit(), isFalse);
    });

    test('should handle null return from get', () async {
      final provider = _NullPodProvider();
      final result = await provider.get();
      expect(result, isNull);
    });

    test('should handle exceptions in get', () async {
      final provider = _ExceptionPodProvider();
      expect(() => provider.get(), throwsA(isA<Exception>()));
    });

    test('isPrototype and isSingleton should be consistent', () {
      final singletonProvider = TestPodProvider(isSingletonFlag: true, isPrototypeFlag: false);
      final prototypeProvider = TestPodProvider(isSingletonFlag: false, isPrototypeFlag: true);
      
      expect(singletonProvider.isSingleton(), isTrue);
      expect(singletonProvider.isPrototype(), isFalse);
      expect(prototypeProvider.isSingleton(), isFalse);
      expect(prototypeProvider.isPrototype(), isTrue);
    });
  });
}

class _NullPodProvider extends PodProvider<String> {
  @override
  FutureOr<ObjectHolder<String>?> get([Class? requiredType]) => null;

  @override
  Class? getClass() => Class<String>();
}

class _ExceptionPodProvider extends PodProvider<String> {
  @override
  FutureOr<ObjectHolder<String>?> get([Class? requiredType]) {
    throw Exception('Failed to create pod');
  }

  @override
  Class? getClass() => Class<String>();
}