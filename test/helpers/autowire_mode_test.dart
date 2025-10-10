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

// test/autowire_mode_test.dart
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/src/helpers/enums.dart';
import 'package:test/test.dart';

void main() {
  group('AutowireMode', () {
    test('should have correct values', () {
      expect(AutowireMode.NO.value, equals(0));
      expect(AutowireMode.BY_NAME.value, equals(1));
      expect(AutowireMode.BY_TYPE.value, equals(2));
    });

    test('should have correct enum values', () {
      expect(AutowireMode.values, hasLength(3));
      expect(AutowireMode.values, contains(AutowireMode.NO));
      expect(AutowireMode.values, contains(AutowireMode.BY_NAME));
      expect(AutowireMode.values, contains(AutowireMode.BY_TYPE));
    });

    test('should convert from value', () {
      expect(AutowireMode.values.byValue(0), equals(AutowireMode.NO));
      expect(AutowireMode.values.byValue(1), equals(AutowireMode.BY_NAME));
      expect(AutowireMode.values.byValue(2), equals(AutowireMode.BY_TYPE));
    });

    test('should throw for invalid value', () {
      expect(() => AutowireMode.values.byValue(-1), throwsA(isA<ArgumentError>()));
      expect(() => AutowireMode.values.byValue(3), throwsA(isA<ArgumentError>()));
      expect(() => AutowireMode.values.byValue(999), throwsA(isA<ArgumentError>()));
    });

    test('should handle string representation', () {
      expect(AutowireMode.NO.toString(), contains('AutowireMode.NO'));
      expect(AutowireMode.BY_NAME.toString(), contains('AutowireMode.BY_NAME'));
      expect(AutowireMode.BY_TYPE.toString(), contains('AutowireMode.BY_TYPE'));
    });

    test('should be comparable', () {
      expect(AutowireMode.NO == AutowireMode.NO, isTrue);
      expect(AutowireMode.NO == AutowireMode.BY_NAME, isFalse);
      expect(AutowireMode.BY_NAME == AutowireMode.BY_TYPE, isFalse);
    });

    test('should have consistent hashCode', () {
      expect(AutowireMode.NO.hashCode, equals(AutowireMode.NO.hashCode));
      expect(AutowireMode.BY_NAME.hashCode, equals(AutowireMode.BY_NAME.hashCode));
      expect(AutowireMode.BY_TYPE.hashCode, equals(AutowireMode.BY_TYPE.hashCode));
      
      expect(AutowireMode.NO.hashCode, isNot(equals(AutowireMode.BY_NAME.hashCode)));
      expect(AutowireMode.BY_NAME.hashCode, isNot(equals(AutowireMode.BY_TYPE.hashCode)));
    });

    test('should work in switch statements', () {
      String describeMode(AutowireMode mode) {
        switch (mode) {
          case AutowireMode.NO:
            return 'No autowiring';
          case AutowireMode.BY_NAME:
            return 'Autowire by name';
          case AutowireMode.BY_TYPE:
            return 'Autowire by type';
        }
      }

      expect(describeMode(AutowireMode.NO), equals('No autowiring'));
      expect(describeMode(AutowireMode.BY_NAME), equals('Autowire by name'));
      expect(describeMode(AutowireMode.BY_TYPE), equals('Autowire by type'));
    });

    test('should work in collections', () {
      final modes = {AutowireMode.NO, AutowireMode.BY_NAME, AutowireMode.BY_TYPE};
      expect(modes, hasLength(3));
      expect(modes, contains(AutowireMode.NO));
      expect(modes, contains(AutowireMode.BY_NAME));
      expect(modes, contains(AutowireMode.BY_TYPE));
    });

    test('should handle index access', () {
      expect(AutowireMode.values[0], equals(AutowireMode.NO));
      expect(AutowireMode.values[1], equals(AutowireMode.BY_NAME));
      expect(AutowireMode.values[2], equals(AutowireMode.BY_TYPE));
    });

    test('should handle iteration', () {
      final modes = AutowireMode.values;
      int count = 0;
      
      for (final mode in modes) {
        expect(mode, isA<AutowireMode>());
        count++;
      }
      
      expect(count, equals(3));
    });

    test('should handle map operations', () {
      final modeMap = AutowireMode.values.asMap();
      expect(modeMap[0], equals(AutowireMode.NO));
      expect(modeMap[1], equals(AutowireMode.BY_NAME));
      expect(modeMap[2], equals(AutowireMode.BY_TYPE));
    });

    test('should handle where filters', () {
      final nonZeroModes = AutowireMode.values.where((mode) => mode.value > 0);
      expect(nonZeroModes, hasLength(2));
      expect(nonZeroModes, contains(AutowireMode.BY_NAME));
      expect(nonZeroModes, contains(AutowireMode.BY_TYPE));
    });

    test('should handle value comparisons', () {
      expect(AutowireMode.NO.value < AutowireMode.BY_NAME.value, isTrue);
      expect(AutowireMode.BY_NAME.value < AutowireMode.BY_TYPE.value, isTrue);
      expect(AutowireMode.BY_TYPE.value > AutowireMode.NO.value, isTrue);
    });

    test('should handle valueOf', () {
      expect(AutowireMode.valueOf('NO'), equals(AutowireMode.NO));
      expect(AutowireMode.valueOf('BY_NAME'), equals(AutowireMode.BY_NAME));
      expect(AutowireMode.valueOf('BY_TYPE'), equals(AutowireMode.BY_TYPE));
    });

    test('should handle fromValue', () {
      expect(AutowireMode.fromValue(0), equals(AutowireMode.NO));
      expect(AutowireMode.fromValue(1), equals(AutowireMode.BY_NAME));
      expect(AutowireMode.fromValue(2), equals(AutowireMode.BY_TYPE));
    });

    test('should throw for invalid fromValue', () {
      expect(() => AutowireMode.fromValue(-1), throwsA(isA<IllegalArgumentException>()));
      expect(() => AutowireMode.fromValue(3), throwsA(isA<IllegalArgumentException>()));
    });

    test('should throw for invalid valueOf', () {
      expect(() => AutowireMode.valueOf('INVALID'), throwsA(isA<IllegalArgumentException>()));
    });
  });
}

// Extension to get enum by value
extension on List<AutowireMode> {
  AutowireMode byValue(int value) {
    for (final mode in this) {
      if (mode.value == value) {
        return mode;
      }
    }
    throw ArgumentError('No AutowireMode with value $value');
  }
}