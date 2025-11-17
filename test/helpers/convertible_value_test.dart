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

// test/convertible_value_test.dart
import 'package:jetleaf_pod/src/helpers/object.dart';
import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

void main() {
  group('ConvertibleValue', () {
    test('should create ConvertibleValue with value', () {
      final cv = _TestConvertibleValue('test_value', qualifiedName: 'test.Qualified');
      expect(cv.getValue(), equals('test_value'));
      expect(cv.isConverted(), isFalse);
      expect(cv.getConvertedValue(), isNull);
    });

    test('should handle qualified name and package name', () {
      final cv = _TestConvertibleValue('test_value', qualifiedName: 'test.Qualified', packageName: 'test_package');
      expect(cv.getQualifiedName(), equals('test.Qualified'));
      expect(cv.getPackageName(), equals('test_package'));
    });

    test('setConvertedValue should mark as converted', () {
      final cv = _TestConvertibleValue('42', qualifiedName: 'test.Qualified');
      cv.setConvertedValue(42);
      
      expect(cv.isConverted(), isTrue);
      expect(cv.getConvertedValue(), equals(42));
      expect(cv.getValue(), equals(42));
    });

    test('getValue should return original value when not converted', () {
      final cv = _TestConvertibleValue('original_value', qualifiedName: 'test.Qualified');
      expect(cv.getValue(), equals('original_value'));
    });

    test('getValue should return converted value when converted', () {
      final cv = _TestConvertibleValue('original_value', qualifiedName: 'test.Qualified');
      cv.setConvertedValue('converted_value');
      expect(cv.getValue(), equals('converted_value'));
    });

    test('should handle null values', () {
      final cv = _TestConvertibleValue(null, qualifiedName: 'test.Qualified');
      expect(cv.getValue(), isNull);
      
      cv.setConvertedValue('not_null');
      expect(cv.getValue(), equals('not_null'));
    });

    test('should handle complex object conversion', () {
      final original = {'key': 'string_value'};
      final converted = {'key': 'converted_value'};
      
      final cv = _TestConvertibleValue(original, qualifiedName: 'test.Qualified');
      cv.setConvertedValue(converted);
      
      expect(cv.getValue(), equals(converted));
    });

    test('should inherit from ObjectHolder functionality', () {
      final cv = _TestConvertibleValue('test_value', packageName: 'test_package', qualifiedName: 'test.Qualified');
      
      expect(cv.getPackageName(), equals('test_package'));
      expect(cv.getQualifiedName(), equals('test.Qualified'));
    });

    test('should handle multiple conversion calls', () {
      final cv = _TestConvertibleValue('first', qualifiedName: 'test.Qualified');
      cv.setConvertedValue('second');
      cv.setConvertedValue('third');
      
      expect(cv.getConvertedValue(), equals('third'));
      expect(cv.getValue(), equals('third'));
    });
  });
}

class _TestConvertibleValue extends ConvertibleValue {
  _TestConvertibleValue(super.value, {super.packageName, super.qualifiedName});

  @override
  List<Object?> equalizedProperties() => [getValue(), getPackageName(), getQualifiedName()];

  @override
  ToStringOptions toStringOptions() => ToStringOptions(
    customParameterNames: ['value', 'packageName', 'qualifiedName'],
    includeParameterNames: true,
  );
}