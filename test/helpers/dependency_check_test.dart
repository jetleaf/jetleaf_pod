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

// test/dependency_check_test.dart
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/src/helpers/enums.dart';
import 'package:test/test.dart';

void main() {
  group('DependencyCheck', () {
    test('should have correct values', () {
      expect(DependencyCheck.NONE.value, equals(0));
      expect(DependencyCheck.OBJECTS.value, equals(1));
      expect(DependencyCheck.ALL.value, equals(2));
    });

    test('should have correct enum values', () {
      expect(DependencyCheck.values, hasLength(3));
      expect(DependencyCheck.values, contains(DependencyCheck.NONE));
      expect(DependencyCheck.values, contains(DependencyCheck.OBJECTS));
      expect(DependencyCheck.values, contains(DependencyCheck.ALL));
    });

    test('should convert from value', () {
      expect(DependencyCheck.values.byValue(0), equals(DependencyCheck.NONE));
      expect(DependencyCheck.values.byValue(1), equals(DependencyCheck.OBJECTS));
      expect(DependencyCheck.values.byValue(2), equals(DependencyCheck.ALL));
    });

    test('should throw for invalid value', () {
      expect(() => DependencyCheck.values.byValue(-1), throwsA(isA<ArgumentError>()));
      expect(() => DependencyCheck.values.byValue(3), throwsA(isA<ArgumentError>()));
      expect(() => DependencyCheck.values.byValue(999), throwsA(isA<ArgumentError>()));
    });

    test('should handle string representation', () {
      expect(DependencyCheck.NONE.toString(), contains('DependencyCheck.NONE'));
      expect(DependencyCheck.OBJECTS.toString(), contains('DependencyCheck.OBJECTS'));
      expect(DependencyCheck.ALL.toString(), contains('DependencyCheck.ALL'));
    });

    test('should be comparable', () {
      expect(DependencyCheck.NONE == DependencyCheck.NONE, isTrue);
      expect(DependencyCheck.NONE == DependencyCheck.OBJECTS, isFalse);
      expect(DependencyCheck.OBJECTS == DependencyCheck.ALL, isFalse);
    });

    test('should have consistent hashCode', () {
      expect(DependencyCheck.NONE.hashCode, equals(DependencyCheck.NONE.hashCode));
      expect(DependencyCheck.OBJECTS.hashCode, equals(DependencyCheck.OBJECTS.hashCode));
      expect(DependencyCheck.ALL.hashCode, equals(DependencyCheck.ALL.hashCode));
      
      expect(DependencyCheck.NONE.hashCode, isNot(equals(DependencyCheck.OBJECTS.hashCode)));
      expect(DependencyCheck.OBJECTS.hashCode, isNot(equals(DependencyCheck.ALL.hashCode)));
    });

    test('should work in switch statements', () {
      String describeCheck(DependencyCheck check) {
        switch (check) {
          case DependencyCheck.NONE:
            return 'No validation';
          case DependencyCheck.OBJECTS:
            return 'Object validation only';
          case DependencyCheck.ALL:
            return 'Full validation';
        }
      }

      expect(describeCheck(DependencyCheck.NONE), equals('No validation'));
      expect(describeCheck(DependencyCheck.OBJECTS), equals('Object validation only'));
      expect(describeCheck(DependencyCheck.ALL), equals('Full validation'));
    });

    test('should work in collections', () {
      final checks = {DependencyCheck.NONE, DependencyCheck.OBJECTS, DependencyCheck.ALL};
      expect(checks, hasLength(3));
      expect(checks, contains(DependencyCheck.NONE));
      expect(checks, contains(DependencyCheck.OBJECTS));
      expect(checks, contains(DependencyCheck.ALL));
    });

    test('should handle index access', () {
      expect(DependencyCheck.values[0], equals(DependencyCheck.NONE));
      expect(DependencyCheck.values[1], equals(DependencyCheck.OBJECTS));
      expect(DependencyCheck.values[2], equals(DependencyCheck.ALL));
    });

    test('should handle iteration', () {
      final checks = DependencyCheck.values;
      int count = 0;
      
      for (final check in checks) {
        expect(check, isA<DependencyCheck>());
        count++;
      }
      
      expect(count, equals(3));
    });

    test('should handle map operations', () {
      final checkMap = DependencyCheck.values.asMap();
      expect(checkMap[0], equals(DependencyCheck.NONE));
      expect(checkMap[1], equals(DependencyCheck.OBJECTS));
      expect(checkMap[2], equals(DependencyCheck.ALL));
    });

    test('should handle where filters', () {
      final validationChecks = DependencyCheck.values.where((check) => check.value > 0);
      expect(validationChecks, hasLength(2));
      expect(validationChecks, contains(DependencyCheck.OBJECTS));
      expect(validationChecks, contains(DependencyCheck.ALL));
    });

    test('should handle validation levels', () {
      // Test that checks can be ordered by strictness
      final checksByStrictness = DependencyCheck.values.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      
      expect(checksByStrictness[0], equals(DependencyCheck.NONE));
      expect(checksByStrictness[1], equals(DependencyCheck.OBJECTS));
      expect(checksByStrictness[2], equals(DependencyCheck.ALL));
    });

    test('should handle boundary values', () {
      expect(DependencyCheck.NONE.value, equals(0));
      expect(DependencyCheck.ALL.value, equals(2));
      
      // Test that values are within expected range
      for (final check in DependencyCheck.values) {
        expect(check.value, greaterThanOrEqualTo(0));
        expect(check.value, lessThanOrEqualTo(2));
      }
    });

    test('should handle valueOf', () {
      expect(DependencyCheck.valueOf('NONE'), equals(DependencyCheck.NONE));
      expect(DependencyCheck.valueOf('OBJECTS'), equals(DependencyCheck.OBJECTS));
      expect(DependencyCheck.valueOf('ALL'), equals(DependencyCheck.ALL));
    });

    test('should handle fromValue', () {
      expect(DependencyCheck.fromValue(0), equals(DependencyCheck.NONE));
      expect(DependencyCheck.fromValue(1), equals(DependencyCheck.OBJECTS));
      expect(DependencyCheck.fromValue(2), equals(DependencyCheck.ALL));
    });

    test('should throw for invalid fromValue', () {
      expect(() => DependencyCheck.fromValue(-1), throwsA(isA<IllegalArgumentException>()));
      expect(() => DependencyCheck.fromValue(3), throwsA(isA<IllegalArgumentException>()));
    });

    test('should throw for invalid valueOf', () {
      expect(() => DependencyCheck.valueOf('INVALID'), throwsA(isA<IllegalArgumentException>()));
    });
  });
}

// Extension to get enum by value
extension on List<DependencyCheck> {
  DependencyCheck byValue(int value) {
    for (final check in this) {
      if (check.value == value) {
        return check;
      }
    }
    throw ArgumentError('No DependencyCheck with value $value');
  }
}