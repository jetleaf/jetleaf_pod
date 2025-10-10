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

// test/argument_value_test.dart
import 'package:jetleaf_pod/src/helpers/object.dart';
import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

void main() {
  group('ArgumentValue', () {
    test('should create ArgumentValue with value', () {
      final av = ArgumentValue('test_value', qualifiedName: 'test.Qualified', packageName: 'test_package');
      expect(av.getValue(), equals('test_value'));
      expect(av.getName(), isNull);
    });

    test('should create ArgumentValue with name', () {
      final av = ArgumentValue('test_value', name: 'test_name', qualifiedName: 'test.Qualified', packageName: 'test_package');
      expect(av.getValue(), equals('test_value'));
      expect(av.getName(), equals('test_name'));
    });

    test('should handle qualified name and package name', () {
      final av = ArgumentValue('test_value', qualifiedName: 'test.Qualified', packageName: 'test_package', name: 'test_name');
      expect(av.getQualifiedName(), equals('test.Qualified'));
      expect(av.getPackageName(), equals('test_package'));
    });

    test('copy should create identical copy', () {
      final original = ArgumentValue('test_value', qualifiedName: 'test.Qualified', packageName: 'test_package', name: 'test_name');
      original.setConvertedValue('converted_value');
      
      final copy = original.copy();
      expect(copy.getValue(), equals(original.getValue()));
      expect(copy.getName(), equals(original.getName()));
      expect(copy.getQualifiedName(), equals(original.getQualifiedName()));
      expect(copy.getPackageName(), equals(original.getPackageName()));
      expect(copy.isConverted(), equals(original.isConverted()));
      expect(copy.getConvertedValue(), equals(original.getConvertedValue()));
    });

    test('should handle value conversion', () {
      final av = ArgumentValue('42', qualifiedName: 'test.Qualified', packageName: 'test_package', name: 'test_name');
      expect(av.isConverted(), isFalse);
      expect(av.getConvertedValue(), isNull);
      
      av.setConvertedValue(42);
      expect(av.isConverted(), isTrue);
      expect(av.getConvertedValue(), equals(42));
      expect(av.getValue(), equals(42));
    });

    test('equalsAndHashCode should work correctly', () {
      final av1 = ArgumentValue('value', name: 'name', qualifiedName: 'test.Qualified', packageName: 'test_package');
      final av2 = ArgumentValue('value', name: 'name', qualifiedName: 'test.Qualified', packageName: 'test_package');
      final av3 = ArgumentValue('different', name: 'name', qualifiedName: 'test.Qualified', packageName: 'test_package');
      final av4 = ArgumentValue('value', name: 'different', qualifiedName: 'test.Qualified', packageName: 'test_package');
      
      expect(av1.equals(av2), isTrue);
      expect(av1.equals(av3), isFalse);
      expect(av1.equals(av4), isFalse);
      expect(av1.hashCode, equals(av2.hashCode));
    });

    test('toString should include all properties', () {
      final av = ArgumentValue('test_value', qualifiedName: 'test.Qualified', packageName: 'test_package', name: 'test_name');
      av.setConvertedValue('converted_value');
      
      final str = av.toString();
      expect(str, contains('name: test_name'));
      expect(str, contains('value: test_value'));
      expect(str, contains('convertedValue: converted_value'));
      expect(str, contains('qualifiedName: test.Qualified'));
    });

    test('should handle null values', () {
      final av = ArgumentValue(null, name: 'test_name', qualifiedName: 'test.Qualified', packageName: 'test_package');
      expect(av.getValue(), isNull);
    });

    test('should handle complex objects', () {
      final complexValue = {'key': 'value', 'list': [1, 2, 3]};
      final av = ArgumentValue(complexValue, name: 'complex_arg', qualifiedName: 'test.Qualified', packageName: 'test_package');
      expect(av.getValue(), equals(complexValue));
    });
  });
}