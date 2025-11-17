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

// test/object_provider_test.dart
import 'package:jetleaf_pod/src/exceptions.dart';
import 'package:jetleaf_pod/src/helpers/object.dart';
import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../_dependencies.dart';

class TestObjectProvider extends ObjectProvider<String> {
  final List<ObjectHolder<String>> objects;

  TestObjectProvider(this.objects);

  @override
  GenericStream<ObjectHolder<String>> stream() => GenericStream.of(objects);
}

void main() {
  setUpAll(() async {
    await setupRuntime();
    return Future<void>.value();
  });

  group('ObjectProvider', () {
    test('get should return single object', () async {
      final provider = TestObjectProvider([ObjectHolder('test', packageName: 'test')]);
      final result = await provider.get();
      expect(result.getValue(), equals('test'));
    });

    test('get should throw when no objects exist', () async {
      final provider = TestObjectProvider([]);
      expect(() => provider.get(), throwsA(isA<NoSuchPodDefinitionException>()));
    });

    test('get should throw when multiple objects exist', () async {
      final provider = TestObjectProvider([
        ObjectHolder('test1', packageName: 'test1'),
        ObjectHolder('test2', packageName: 'test2'),
      ]);
      expect(() => provider.get(), throwsA(isA<NoUniquePodDefinitionException>()));
    });

    test('getIfAvailable should return object when available', () async {
      final provider = TestObjectProvider([ObjectHolder('test', packageName: 'test')]);
      final result = await provider.getIfAvailable();
      expect(result?.getValue(), equals('test'));
    });

    test('getIfAvailable should return null when not available', () async {
      final provider = TestObjectProvider([]);
      final result = await provider.getIfAvailable();
      expect(result, isNull);
    });

    test('getIfAvailable should use supplier when not available', () async {
      final provider = TestObjectProvider([]);
      final result = await provider.getIfAvailable(() => ObjectHolder('supplied', packageName: 'supplied'));
      expect(result?.getValue(), equals('supplied'));
    });

    test('getIfAvailable should throw when multiple objects exist', () async {
      final provider = TestObjectProvider([
        ObjectHolder('test1', packageName: 'test1'),
        ObjectHolder('test2', packageName: 'test2'),
      ]);
      expect(() => provider.getIfAvailable(), throwsA(isA<NoUniquePodDefinitionException>()));
    });

    test('getIfUnique should return object when exactly one exists', () async {
      final provider = TestObjectProvider([ObjectHolder('test', packageName: 'test')]);
      final result = await provider.getIfUnique();
      expect(result?.getValue(), equals('test'));
    });

    test('getIfUnique should return null when no objects exist', () async {
      final provider = TestObjectProvider([]);
      final result = await provider.getIfUnique();
      expect(result, isNull);
    });

    test('getIfUnique should throw when multiple objects exist', () async {
      final provider = TestObjectProvider([
        ObjectHolder('test1', packageName: 'test1'),
        ObjectHolder('test2', packageName: 'test2'),
      ]);
      expect(() => provider.getIfUnique(), throwsA(isA<NoUniquePodDefinitionException>()));
    });

    test('ifAvailable should execute consumer when available', () async {
      final provider = TestObjectProvider([ObjectHolder('test', packageName: 'test')]);
      var consumerCalled = false;
      await provider.ifAvailable((object) {
        consumerCalled = true;
        expect(object.getValue(), equals('test'));
      });
      expect(consumerCalled, isTrue);
    });

    test('ifAvailable should not execute consumer when not available', () async {
      final provider = TestObjectProvider([]);
      var consumerCalled = false;
      await provider.ifAvailable((object) {
        consumerCalled = true;
      });
      expect(consumerCalled, isFalse);
    });

    test('ifUnique should execute consumer when exactly one exists', () async {
      final provider = TestObjectProvider([ObjectHolder('test', packageName: 'test')]);
      var consumerCalled = false;
      await provider.ifUnique((object) {
        consumerCalled = true;
        expect(object.getValue(), equals('test'));
      });
      expect(consumerCalled, isTrue);
    });

    test('ifUnique should not execute consumer when not available', () async {
      final provider = TestObjectProvider([]);
      var consumerCalled = false;
      await provider.ifUnique((object) {
        consumerCalled = true;
      });
      expect(consumerCalled, isFalse);
    });

    test('stream should return all objects', () async {
      final objects = [
        ObjectHolder('test1', packageName: 'test1'),
        ObjectHolder('test2', packageName: 'test2'),
      ];
      final provider = TestObjectProvider(objects);
      final streamResults = provider.stream().toList();
      expect(streamResults, equals(objects));
    });

    test('iterator should return values from objects', () {
      final objects = [
        ObjectHolder('test1', packageName: 'test1'),
        ObjectHolder('test2', packageName: 'test2'),
      ];
      final provider = TestObjectProvider(objects);
      expect(provider.toList(), equals(['test1', 'test2']));
    });
  });
}