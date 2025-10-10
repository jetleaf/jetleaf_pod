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

// test/property_values_test.dart
import 'package:jetleaf_pod/src/helpers/object.dart';
import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

class TestPropertyValues extends PropertyValues {
  final List<PropertyValue> values;

  TestPropertyValues(this.values);

  @override
  List<PropertyValue> getPropertyValues() => values;

  @override
  PropertyValue? getPropertyValue(String propertyName) =>
      values.firstWhereOrNull((pv) => pv.getName() == propertyName);

  @override
  PropertyValues changesSince(PropertyValues old) => this;

  @override
  bool containsProperty(String propertyName) =>
      getPropertyValue(propertyName) != null;

  @override
  bool get isEmpty => values.isEmpty;

  @override
  Iterator<PropertyValue> get iterator => values.iterator;
}

void main() {
  group('PropertyValues', () {
    test('should iterate over properties', () {
      final properties = [
        PropertyValue('prop1', 'value1', qualifiedName: 'test.Qualified'),
        PropertyValue('prop2', 'value2', qualifiedName: 'test.Qualified'),
      ];
      final pvs = TestPropertyValues(properties);
      
      expect(pvs.toList(), equals(properties));
    });

    test('getPropertyValue should return correct property', () {
      final properties = [
        PropertyValue('prop1', 'value1', qualifiedName: 'test.Qualified'),
        PropertyValue('prop2', 'value2', qualifiedName: 'test.Qualified'),
      ];
      final pvs = TestPropertyValues(properties);
      
      expect(pvs.getPropertyValue('prop1')?.getValue(), equals('value1'));
      expect(pvs.getPropertyValue('nonexistent'), isNull);
    });

    test('containsProperty should check existence', () {
      final properties = [
        PropertyValue('prop1', 'value1', qualifiedName: 'test.Qualified'),
      ];
      final pvs = TestPropertyValues(properties);
      
      expect(pvs.containsProperty('prop1'), isTrue);
      expect(pvs.containsProperty('nonexistent'), isFalse);
    });

    test('contains should check existence by string value', () {
      final properties = [
        PropertyValue('prop1', 'value1', qualifiedName: 'test.Qualified'),
      ];
      final pvs = TestPropertyValues(properties);
      
      expect(pvs.contains('prop1'), isTrue);
      expect(pvs.contains('nonexistent'), isFalse);
      expect(pvs.contains(123), isFalse); // Non-string values
    });

    test('isEmpty should reflect empty state', () {
      final emptyPvs = TestPropertyValues([]);
      final nonEmptyPvs = TestPropertyValues([PropertyValue('prop', 'value', qualifiedName: 'test.Qualified')]);
      
      expect(emptyPvs.isEmpty, isTrue);
      expect(nonEmptyPvs.isEmpty, isFalse);
    });

    test('changesSince should return differences (default implementation)', () {
      final pvs = TestPropertyValues([]);
      final changes = pvs.changesSince(TestPropertyValues([]));
      
      expect(changes, equals(pvs));
    });

    test('should handle empty property lists', () {
      final emptyPvs = TestPropertyValues([]);
      expect(emptyPvs.getPropertyValues(), isEmpty);
      expect(emptyPvs.iterator.moveNext(), isFalse);
    });

    test('should handle large property lists', () {
      final properties = List.generate(100, (i) => PropertyValue('prop$i', 'value$i', qualifiedName: 'test.Qualified'));
      final pvs = TestPropertyValues(properties);
      
      expect(pvs.length, equals(100));
      expect(pvs.getPropertyValue('prop50')?.getValue(), equals('value50'));
    });
  });
}