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

// test/property_value_test.dart
import 'package:jetleaf_pod/src/helpers/object.dart';
import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

void main() {
  group('PropertyValue', () {
    test('should create PropertyValue with name and value', () {
      final pv = PropertyValue('test_name', 'test_value', qualifiedName: 'test.Qualified', packageName: 'test_package');
      expect(pv.getName(), equals('test_name'));
      expect(pv.getValue(), equals('test_value'));
      expect(pv.isOptional(), isFalse);
    });

    test('should handle optional flag', () {
      final pv = PropertyValue('test_name', 'test_value', qualifiedName: 'test.Qualified', packageName: 'test_package');
      expect(pv.isOptional(), isFalse);
    });

    test('should handle qualified name and package name', () {
      final pv = PropertyValue('test_name', 'test_value', qualifiedName: 'test.Qualified', packageName: 'test_package');
      expect(pv.getQualifiedName(), equals('test.Qualified'));
      expect(pv.getPackageName(), equals('test_package'));
    });

    test('copy should create identical copy', () {
      final original = PropertyValue('test_name', 'test_value', qualifiedName: 'test.Qualified', packageName: 'test_package');
      original.setConvertedValue('converted_value');
      
      final copy = original.copy();
      expect(copy.getName(), equals(original.getName()));
      expect(copy.getValue(), equals(original.getValue()));
      expect(copy.getQualifiedName(), equals(original.getQualifiedName()));
      expect(copy.getPackageName(), equals(original.getPackageName()));
      expect(copy.isConverted(), equals(original.isConverted()));
      expect(copy.getConvertedValue(), equals(original.getConvertedValue()));
    });

    test('should handle value conversion', () {
      final pv = PropertyValue('test_name', '42', qualifiedName: 'test.Qualified', packageName: 'test_package');
      expect(pv.isConverted(), isFalse);
      expect(pv.getConvertedValue(), isNull);
      
      pv.setConvertedValue(42);
      expect(pv.isConverted(), isTrue);
      expect(pv.getConvertedValue(), equals(42));
      expect(pv.getValue(), equals(42));
    });

    test('equalsAndHashCode should work correctly', () {
      final pv1 = PropertyValue('name', 'value', qualifiedName: 'test.Qualified', packageName: 'test_package');
      final pv2 = PropertyValue('name', 'value', qualifiedName: 'test.Qualified', packageName: 'test_package');
      final pv3 = PropertyValue('different', 'value', qualifiedName: 'test.Qualified', packageName: 'test_package');
      final pv4 = PropertyValue('name', 'different', qualifiedName: 'test.Qualified', packageName: 'test_package');
      
      expect(pv1.equals(pv2), isTrue);
      expect(pv1.equals(pv3), isFalse);
      expect(pv1.equals(pv4), isFalse);
      expect(pv1.hashCode, equals(pv2.hashCode));
    });

    test('toString should include all properties', () {
      final pv = PropertyValue('test_name', 'test_value', qualifiedName: 'test.Qualified', packageName: 'test_package');
      pv.setConvertedValue('converted_value');
      
      final str = pv.toString();
      expect(str, contains('name: test_name'));
      expect(str, contains('value: test_value'));
      expect(str, contains('convertedValue: converted_value'));
      expect(str, contains('qualifiedName: test.Qualified'));
    });

    test('should handle null values', () {
      final pv = PropertyValue('test_name', null, qualifiedName: 'test.Qualified', packageName: 'test_package');
      expect(pv.getValue(), isNull);
    });

    test('should handle complex objects', () {
      final complexValue = {'key': 'value', 'list': [1, 2, 3]};
      final pv = PropertyValue('complex', complexValue, qualifiedName: 'test.Qualified', packageName: 'test_package');
      expect(pv.getValue(), equals(complexValue));
    });
  });
}