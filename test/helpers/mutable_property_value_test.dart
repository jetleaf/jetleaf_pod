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

// test/mutable_property_values_test.dart
import 'package:jetleaf_pod/src/helpers/object.dart';
import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

void main() {
  group('MutablePropertyValues', () {
    test('should create empty MutablePropertyValues', () {
      final mpv = MutablePropertyValues();
      expect(mpv.isEmpty, isTrue);
      expect(mpv.length, equals(0));
    });

    test('should create from initial list', () {
      final properties = [
        PropertyValue('prop1', 'value1', qualifiedName: 'test.Qualified', packageName: 'test_package'),
        PropertyValue('prop2', 'value2', qualifiedName: 'test.Qualified', packageName: 'test_package'),
      ];
      final mpv = MutablePropertyValues(properties);
      expect(mpv.length, equals(2));
      expect(mpv.getPropertyValue('prop1')?.getValue(), equals('value1'));
    });

    test('should create from map', () {
      final map = {
        'prop1': {'value': 'value1', 'qualifiedName': 'test.Qualified1'},
        'prop2': {'value': 'value2', 'packageName': 'test_package'},
      };
      final mpv = MutablePropertyValues.fromMap(map);
      expect(mpv.length, equals(2));
      expect(mpv.getPropertyValue('prop1')?.getValue(), equals('value1'));
      expect(mpv.getPropertyValue('prop2')?.getPackageName(), equals('test_package'));
    });

    test('should create copy from another PropertyValues', () {
      final original = MutablePropertyValues()
        ..add('prop1', 'value1', qualifiedName: 'test.Qualified', packageName: 'test_package')
        ..add('prop2', 'value2', qualifiedName: 'test.Qualified', packageName: 'test_package');
      
      final copy = MutablePropertyValues.copy(original);
      expect(copy.length, equals(2));
      expect(copy.getPropertyValue('prop1')?.getValue(), equals('value1'));
    });

    test('addPropertyValue should add new property', () {
      final mpv = MutablePropertyValues();
      final pv = PropertyValue('test_prop', 'test_value', qualifiedName: 'test.Qualified', packageName: 'test_package');
      mpv.addPropertyValue(pv);
      
      expect(mpv.length, equals(1));
      expect(mpv.getPropertyValue('test_prop'), equals(pv));
    });

    test('addPropertyValue should replace existing property', () {
      final mpv = MutablePropertyValues();
      mpv.add('test_prop', 'old_value', qualifiedName: 'test.Qualified', packageName: 'test_package');
      mpv.addPropertyValue(PropertyValue('test_prop', 'new_value', qualifiedName: 'test.Qualified', packageName: 'test_package'));
      
      expect(mpv.length, equals(1));
      expect(mpv.getPropertyValue('test_prop')?.getValue(), equals('new_value'));
    });

    test('add should add property by name and value', () {
      final mpv = MutablePropertyValues();
      mpv.add('test_prop', 'test_value', qualifiedName: 'test.Qualified', packageName: 'test_package');
      
      final pv = mpv.getPropertyValue('test_prop');
      expect(pv?.getValue(), equals('test_value'));
      expect(pv?.getQualifiedName(), equals('test.Qualified'));
      expect(pv?.getPackageName(), equals('test_package'));
    });

    test('addPropertyValues should add multiple properties', () {
      final mpv1 = MutablePropertyValues()..add('prop1', 'value1', qualifiedName: 'test.Qualified', packageName: 'test_package');
      final mpv2 = MutablePropertyValues()..add('prop2', 'value2', qualifiedName: 'test.Qualified', packageName: 'test_package');
      
      mpv1.addPropertyValues(mpv2);
      expect(mpv1.length, equals(2));
      expect(mpv1.getPropertyValue('prop2')?.getValue(), equals('value2'));
    });

    test('addPropertyValuesFromMap should add from map', () {
      final mpv = MutablePropertyValues();
      final map = {
        'new_prop': {'value': 'new_value', 'qualifiedName': 'test.New'}
      };
      
      mpv.addPropertyValuesFromMap(map);
      expect(mpv.getPropertyValue('new_prop')?.getValue(), equals('new_value'));
    });

    test('removePropertyValue should remove property', () {
      final mpv = MutablePropertyValues()..add('test_prop', 'test_value', qualifiedName: 'test.Qualified', packageName: 'test_package');
      final pv = mpv.getPropertyValue('test_prop')!;
      
      mpv.removePropertyValue(pv);
      expect(mpv.containsProperty('test_prop'), isFalse);
    });

    test('removePropertyValueByName should remove by name', () {
      final mpv = MutablePropertyValues()..add('test_prop', 'test_value', qualifiedName: 'test.Qualified', packageName: 'test_package');
      mpv.removePropertyValueByName('test_prop');
      expect(mpv.containsProperty('test_prop'), isFalse);
    });

    test('clear should remove all properties', () {
      final mpv = MutablePropertyValues()
        ..add('prop1', 'value1', qualifiedName: 'test.Qualified', packageName: 'test_package')
        ..add('prop2', 'value2', qualifiedName: 'test.Qualified', packageName: 'test_package');
      
      mpv.clear();
      expect(mpv.isEmpty, isTrue);
    });

    test('should handle conversion state', () {
      final mpv = MutablePropertyValues()..add('prop', 'value', qualifiedName: 'test.Qualified', packageName: 'test_package');
      expect(mpv.isConverted(), isFalse);
      
      mpv.setConverted();
      expect(mpv.isConverted(), isTrue);
    });

    test('should handle processed properties', () {
      final mpv = MutablePropertyValues();
      mpv.registerProcessedProperty('processed_prop');
      expect(mpv.getProcessedProperties(), contains('processed_prop'));
      
      mpv.clearProcessedProperty('processed_prop');
      expect(mpv.getProcessedProperties(), isNot(contains('processed_prop')));
      
      mpv.setProcessedProperties({'prop1', 'prop2'});
      expect(mpv.getProcessedProperties(), containsAll(['prop1', 'prop2']));
    });

    test('changesSince should return differences', () {
      final old = MutablePropertyValues()..add('prop1', 'old_value', qualifiedName: 'test.Qualified', packageName: 'test_package');
      final current = MutablePropertyValues()..add('prop1', 'new_value', qualifiedName: 'test.Qualified', packageName: 'test_package');
      
      final changes = current.changesSince(old);
      expect(changes.getPropertyValue('prop1')?.getValue(), equals('new_value'));
    });

    test('iterator should iterate over properties', () {
      final mpv = MutablePropertyValues()
        ..add('prop1', 'value1', qualifiedName: 'test.Qualified', packageName: 'test_package')
        ..add('prop2', 'value2', qualifiedName: 'test.Qualified', packageName: 'test_package');
      
      final values = mpv.map((pv) => pv.getName()).toList();
      expect(values, containsAll(['prop1', 'prop2']));
    });

    test('equalsAndHashCode should work correctly', () {
      final mpv1 = MutablePropertyValues()..add('prop', 'value', qualifiedName: 'test.Qualified', packageName: 'test_package');
      final mpv2 = MutablePropertyValues()..add('prop', 'value', qualifiedName: 'test.Qualified', packageName: 'test_package');
      final mpv3 = MutablePropertyValues()..add('different', 'value', qualifiedName: 'test.Qualified', packageName: 'test_package');
      
      expect(mpv1.equals(mpv2), isTrue);
      expect(mpv1.equals(mpv3), isFalse);
      expect(mpv1.hashCode, equals(mpv2.hashCode));
    });

    test('copy should create deep copy', () {
      final original = MutablePropertyValues()..add('prop', 'value', qualifiedName: 'test.Qualified', packageName: 'test_package');
      original.registerProcessedProperty('processed');
      original.setConverted();
      
      final copy = original.copy();
      expect(copy.getPropertyValue('prop')?.getValue(), equals('value'));
      expect(copy.getProcessedProperties(), contains('processed'));
      expect(copy.isConverted(), isTrue);
    });
  });
}