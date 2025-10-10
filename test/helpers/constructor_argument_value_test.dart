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

// test/constructor_argument_values_test.dart
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/src/helpers/object.dart';
import 'package:test/test.dart';

void main() {
  group('ConstructorArgumentValues', () {
    test('should create empty ConstructorArgumentValues', () {
      final cav = ConstructorArgumentValues();
      expect(cav.isEmpty(), isTrue);
      expect(cav.getCount(), equals(0));
    });

    test('add should add generic argument', () {
      final cav = ConstructorArgumentValues();
      cav.add('arg_name', 'arg_value', qualifiedName: 'test.Qualified', packageName: 'test_package');
      
      expect(cav.getCount(), equals(1));
      final arg = cav.get(name: 'arg_name');
      expect(arg?.getValue(), equals('arg_value'));
      expect(arg?.getQualifiedName(), equals('test.Qualified'));
    });

    test('addArgument should add generic argument', () {
      final cav = ConstructorArgumentValues();
      cav.addArgument(ArgumentValue('arg_value', name: 'arg_name', qualifiedName: 'test.Qualified', packageName: 'test_package'));
      
      expect(cav.getCount(), equals(1));
      final arg = cav.get(name: 'arg_name');
      expect(arg?.getValue(), equals('arg_value'));
      expect(arg?.getQualifiedName(), equals('test.Qualified'));
    });

    test('addArgument should throw when adding argument without name', () {
      final cav = ConstructorArgumentValues();
      expect(() => cav.addArgument(ArgumentValue('arg_value', qualifiedName: 'test.Qualified', packageName: 'test_package')),
          throwsA(isA<IllegalArgumentException>()));
    });

    test('get should find argument by name', () {
      final cav = ConstructorArgumentValues();
      cav.add('test_arg', 'test_value', qualifiedName: 'test.Qualified');
      
      final arg = cav.get(name: 'test_arg');
      expect(arg?.getValue(), equals('test_value'));
      expect(arg?.getQualifiedName(), equals('test.Qualified'));
    });

    test('get should find argument by name', () {
      final cav = ConstructorArgumentValues();
      cav.add('test_arg', 'test_value', qualifiedName: 'test.Qualified');
      
      final arg = cav.get(name: 'test_arg');
      expect(arg?.getValue(), equals('test_value'));
    });

    test('get should find argument by qualified name', () {
      final cav = ConstructorArgumentValues();
      cav.add('test_arg', 'test_value', qualifiedName: 'test.Qualified');
      
      final arg = cav.get(qualifiedName: 'test.Qualified');
      expect(arg?.getValue(), equals('test_value'));
    });

    test('get should find argument by package name', () {
      final cav = ConstructorArgumentValues();
      cav.add('test_arg', 'test_value', packageName: 'test_package');
      
      final arg = cav.get(packageName: 'test_package');
      expect(arg?.getValue(), equals('test_value'));
    });

    test('get should return null when not found', () {
      final cav = ConstructorArgumentValues();
      final arg = cav.get(name: 'nonexistent');
      expect(arg, isNull);
    });

    test('clear should remove all arguments', () {
      final cav = ConstructorArgumentValues();
      cav.add('test_arg', 'test_value', qualifiedName: 'test.Qualified');
      cav.clear();
      
      expect(cav.isEmpty(), isTrue);
    });

    test('toMap should convert to map', () {
      final cav = ConstructorArgumentValues();
      cav.add('arg1', 'value1', qualifiedName: 'test.Qualified');
      cav.add('arg2', 'value2', qualifiedName: 'test.Qualified');
      
      final map = cav.toMap();
      expect(map.length, equals(2));
      expect(map['arg1']?.getValue(), equals('value1'));
    });

    test('toList should convert to list', () {
      final cav = ConstructorArgumentValues();
      cav.add('arg1', 'value1', qualifiedName: 'test.Qualified');
      cav.add('arg2', 'value2', qualifiedName: 'test.Qualified');
      
      final list = cav.toList();
      expect(list.length, equals(2));
      expect(list[0].getName(), equals('arg1'));
    });

    test('copy should create deep copy', () {
      final original = ConstructorArgumentValues();
      original.add('test_arg', 'test_value', qualifiedName: 'test.Qualified');
      
      final copy = original.copy();
      expect(copy.getCount(), equals(1));
      final arg = copy.get(name: 'test_arg');
      expect(arg?.getValue(), equals('test_value'));
      expect(arg?.getQualifiedName(), equals('test.Qualified'));
    });

    test('should handle multiple arguments with same name (last wins)', () {
      final cav = ConstructorArgumentValues();
      cav.add('same_name', 'first_value', qualifiedName: 'test.Qualified');
      cav.add('same_name', 'second_value', qualifiedName: 'test.Qualified');
      
      final arg = cav.get(name: 'same_name');
      expect(arg?.getValue(), equals('second_value'));
    });

    test('should handle null values', () {
      final cav = ConstructorArgumentValues();
      cav.add('null_arg', null, qualifiedName: 'test.Qualified');
      
      final arg = cav.get(name: 'null_arg');
      expect(arg?.getValue(), isNull);
    });

    test('should handle complex objects', () {
      final complexValue = {'key': 'value', 'list': [1, 2, 3]};
      final cav = ConstructorArgumentValues();
      cav.add('complex_arg', complexValue, qualifiedName: 'test.Qualified');
      
      final arg = cav.get(name: 'complex_arg');
      expect(arg?.getValue(), equals(complexValue));
    });
  });
}