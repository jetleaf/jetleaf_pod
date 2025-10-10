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

// test/scoped_object_factory_test.dart
import 'package:jetleaf_pod/src/scope/scope.dart';
import 'package:jetleaf_pod/src/helpers/object.dart';
import 'package:test/test.dart';

class MockScope extends PodScope {
  final Map<String, ObjectHolder<Object>> objects = {};
  final Map<String, ObjectFactory<Object>> fallbackFactories = {};

  @override
  Future<ObjectHolder<Object>> get(String name, ObjectFactory<Object> fallbackFactory) async {
    if (objects.containsKey(name)) {
      return objects[name]!;
    }
    return fallbackFactory.get();
  }

  @override
  ObjectHolder<Object>? remove(String name) {
    fallbackFactories.remove(name);
    return objects.remove(name);
  }
}

void main() {
  group('ScopedObjectFactory', () {
    test('should create object from scope', () async {
      final scope = MockScope();
      final fallbackFactory = SimpleObjectFactory<String>(([args]) => ObjectHolder('test_value', qualifiedName: 'test.Qualified'));
      final factory = ScopedObjectFactory<String>('test_name', scope, fallbackFactory);
      
      final result = await factory.get();
      expect(result.getValue(), equals('test_value'));
    });

    test('should return existing object from scope', () async {
      final scope = MockScope();
      scope.objects['test_name'] = ObjectHolder('cached_value', qualifiedName: 'test.Qualified');
      
      final fallbackFactory = SimpleObjectFactory<String>(([args]) => ObjectHolder('test_value', qualifiedName: 'test.Qualified'));
      final factory = ScopedObjectFactory<String>('test_name', scope, fallbackFactory);
      
      final result = await factory.get();
      expect(result.getValue(), equals('cached_value'));
    });

    test('getPodName should return correct name', () {
      final scope = MockScope();
      final factory = ScopedObjectFactory<String>('test_pod', scope, SimpleObjectFactory(([args]) => ObjectHolder('test', qualifiedName: 'test.Qualified')));
      expect(factory.getPodName(), equals('test_pod'));
    });

    test('removeFromScope should remove object', () {
      final scope = MockScope();
      scope.objects['test_name'] = ObjectHolder('test_value', qualifiedName: 'test.Qualified');
      
      final factory = ScopedObjectFactory<String>('test_name', scope, SimpleObjectFactory(([args]) => ObjectHolder('test', qualifiedName: 'test.Qualified')));
      final removed = factory.removeFromScope();
      
      expect(removed, equals('test_value'));
      expect(scope.objects.containsKey('test_name'), isFalse);
    });

    test('removeFromScope should return null when not found', () {
      final scope = MockScope();
      final factory = ScopedObjectFactory<String>('nonexistent', scope, SimpleObjectFactory(([args]) => ObjectHolder('test', qualifiedName: 'test.Qualified')));
      final removed = factory.removeFromScope();
      
      expect(removed, isNull);
    });

    test('toString should include name and scope type', () {
      final scope = MockScope();
      final factory = ScopedObjectFactory<String>('test_name', scope, SimpleObjectFactory(([args]) => ObjectHolder('test', qualifiedName: 'test.Qualified')));
      final str = factory.toString();
      
      expect(str, contains('test_name'));
      expect(str, contains('MockScope'));
    });

    test('copyWithScope should create new factory with different parameters', () {
      final originalScope = MockScope();
      final newScope = MockScope();
      final originalFactory = SimpleObjectFactory<String>(([args]) => ObjectHolder('original', qualifiedName: 'test.Qualified'));
      final newFactory = SimpleObjectFactory<String>(([args]) => ObjectHolder('new', qualifiedName: 'test.Qualified'));
      
      final original = ScopedObjectFactory<String>('original_name', originalScope, originalFactory);
      final copied = original.copyWithScope(
        name: 'new_name',
        scope: newScope,
        fallbackFactory: newFactory,
      );
      
      expect(copied.getPodName(), equals('new_name'));
    });

    test('copyWithScope should use original values when null', () {
      final originalScope = MockScope();
      final originalFactory = SimpleObjectFactory<String>(([args]) => ObjectHolder('original', qualifiedName: 'test.Qualified'));
      
      final original = ScopedObjectFactory<String>('original_name', originalScope, originalFactory);
      final copied = original.copyWithScope();
      
      expect(copied.getPodName(), equals('original_name'));
    });

    test('should handle async scope operations', () async {
      final scope = MockScope();
      final fallbackFactory = SimpleObjectFactory<String>(([args]) async {
        await Future.delayed(Duration(milliseconds: 10));
        return ObjectHolder('async_value', qualifiedName: 'test.Qualified');
      });
      
      final factory = ScopedObjectFactory<String>('async_name', scope, fallbackFactory);
      final result = await factory.get();
      
      expect(result.getValue(), equals('async_value'));
    });

    test('should handle exceptions in scope operations', () async {
      final scope = MockScope();
      final fallbackFactory = SimpleObjectFactory<String>(([args]) {
        throw Exception('Creation failed');
      });
      
      final factory = ScopedObjectFactory<String>('failing_name', scope, fallbackFactory);
      expect(() => factory.get(), throwsA(isA<Exception>()));
    });
  });
}