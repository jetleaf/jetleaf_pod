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

// test/object_holder_test.dart
import 'package:jetleaf_pod/src/helpers/object.dart';
import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

void main() {
  group('ObjectHolder', () {
    test('should create ObjectHolder with valid parameters', () {
      final holder = ObjectHolder<String>('test', packageName: 'test_package');
      expect(holder.getValue(), equals('test'));
      expect(holder.getPackageName(), equals('test_package'));
      expect(holder.getQualifiedName(), isNull);
    });

    test('should create ObjectHolder with qualified name', () {
      final holder = ObjectHolder<int>(42, qualifiedName: 'package:test/core.dart.TestClass');
      expect(holder.getValue(), equals(42));
      expect(holder.getPackageName(), isNull);
      expect(holder.getQualifiedName(), equals('package:test/core.dart.TestClass'));
    });

    test('should throw when both packageName and qualifiedName are null', () {
      expect(() => ObjectHolder<String>('test'), throwsA(isA<IllegalArgumentException>()));
    });

    test('should throw when packageName is empty', () {
      expect(() => ObjectHolder<String>('test', packageName: ''), throwsA(isA<IllegalArgumentException>()));
    });

    test('should throw when qualifiedName is empty', () {
      expect(() => ObjectHolder<String>('test', qualifiedName: ''), throwsA(isA<IllegalArgumentException>()));
    });

    test('should implement equalsAndHashCode correctly', () {
      final holder1 = ObjectHolder<String>('test', packageName: 'test_package');
      final holder2 = ObjectHolder<String>('test', packageName: 'test_package');
      final holder3 = ObjectHolder<String>('different', packageName: 'test_package');
      
      expect(holder1.equals(holder2), isTrue);
      expect(holder1.equals(holder3), isFalse);
      expect(holder1.hashCode, equals(holder2.hashCode));
    });

    test('should handle null values correctly', () {
      final holder = ObjectHolder<String?>(null, packageName: 'test_package');
      expect(holder.getValue(), isNull);
    });

    test('should handle complex objects', () {
      final complexObject = {'key': 'value', 'number': 42};
      final holder = ObjectHolder<Map<String, dynamic>>(complexObject, packageName: 'test_package');
      expect(holder.getValue(), equals(complexObject));
    });

    test('toString should include parameter names', () {
      final holder = ObjectHolder<String>('test', packageName: 'test_package', qualifiedName: 'test.Class');
      final str = holder.toString();
      expect(str, contains('value: test'));
      expect(str, contains('packageName: test_package'));
      expect(str, contains('qualifiedName: test.Class'));
    });
  });
}