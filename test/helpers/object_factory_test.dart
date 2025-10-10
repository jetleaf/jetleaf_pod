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

// test/object_factory_test.dart
import 'package:jetleaf_pod/src/helpers/object.dart';
import 'package:test/test.dart';

void main() {
  group('ObjectFactory', () {
    test('SimpleObjectFactory should create objects using creator function', () async {
      final factory = SimpleObjectFactory<String>(([args]) => ObjectHolder('test', packageName: 'test', qualifiedName: 'test'));
      final result = await factory.get();
      expect(result.getValue(), equals('test'));
    });

    test('createMultiple should create multiple instances', () async {
      var counter = 0;
      final factory = SimpleObjectFactory<int>(([args]) => ObjectHolder(counter++, packageName: 'test', qualifiedName: 'test'));
      
      final results = await factory.createMultiple(3);
      expect(results, equals([0, 1, 2]));
    });

    test('chain should create chained factories', () async {
      final firstFactory = SimpleObjectFactory<int>(([args]) => ObjectHolder(42, packageName: 'test', qualifiedName: 'test'));
      final chainedFactory = await firstFactory.chain<String>((intValue) => 
        SimpleObjectFactory<String>(([args]) => ObjectHolder('Value: $intValue', packageName: 'test', qualifiedName: 'test'))
      );
      
      final result = await chainedFactory.get();
      expect(result.getValue(), equals('Value: 42'));
    });

    test('withSideEffect should execute side effect', () async {
      var sideEffectCalled = false;
      final factory = SimpleObjectFactory<String>(([args]) => ObjectHolder('test', packageName: 'test', qualifiedName: 'test'));
      final factoryWithSideEffect = await factory.withSideEffect((value) {
        sideEffectCalled = true;
      });
      
      await factoryWithSideEffect.get();
      expect(sideEffectCalled, isTrue);
    });

    test('toString should return correct format', () {
      final factory = SimpleObjectFactory<String>(([args]) => ObjectHolder('test', packageName: 'test', qualifiedName: 'test'));
      expect(factory.toString(), equals('ObjectFactory<String>'));
    });

    test('copyWith should create new factory with different creator', () async {
      final originalFactory = SimpleObjectFactory<String>(([args]) => ObjectHolder('original', packageName: 'test', qualifiedName: 'test'));
      final copiedFactory = originalFactory.copyWith(creator: ([args]) => ObjectHolder('copied', packageName: 'test', qualifiedName: 'test'));
      
      final result = await copiedFactory.get();
      expect(result.getValue(), equals('copied'));
    });

    test('copyWith should use original creator when null', () async {
      final originalFactory = SimpleObjectFactory<String>(([args]) => ObjectHolder('original', packageName: 'test', qualifiedName: 'test'));
      final copiedFactory = originalFactory.copyWith();
      
      final result = await copiedFactory.get();
      expect(result.getValue(), equals('original'));
    });

    test('should handle async creator functions', () async {
      final factory = SimpleObjectFactory<String>(([args]) async {
        await Future.delayed(Duration(milliseconds: 10));
        return ObjectHolder('async_test', packageName: 'test', qualifiedName: 'test');
      });
      
      final result = await factory.get();
      expect(result.getValue(), equals('async_test'));
    });

    test('should handle exceptions in creator function', () async {
      final factory = SimpleObjectFactory<String>(([args]) {
        throw Exception('Creation failed');
      });
      
      expect(() => factory.get(), throwsA(isA<Exception>()));
    });
  });
}