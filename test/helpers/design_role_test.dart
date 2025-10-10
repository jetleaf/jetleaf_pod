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

// test/design_role_test.dart
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/src/helpers/enums.dart';
import 'package:test/test.dart';

void main() {
  group('DesignRole', () {
    test('should have correct values', () {
      expect(DesignRole.APPLICATION.value, equals(0));
      expect(DesignRole.SUPPORT.value, equals(1));
      expect(DesignRole.INFRASTRUCTURE.value, equals(2));
    });

    test('should have correct enum values', () {
      expect(DesignRole.values, hasLength(3));
      expect(DesignRole.values, contains(DesignRole.APPLICATION));
      expect(DesignRole.values, contains(DesignRole.SUPPORT));
      expect(DesignRole.values, contains(DesignRole.INFRASTRUCTURE));
    });

    test('should convert from value', () {
      expect(DesignRole.values.byValue(0), equals(DesignRole.APPLICATION));
      expect(DesignRole.values.byValue(1), equals(DesignRole.SUPPORT));
      expect(DesignRole.values.byValue(2), equals(DesignRole.INFRASTRUCTURE));
    });

    test('should throw for invalid value', () {
      expect(() => DesignRole.values.byValue(-1), throwsA(isA<ArgumentError>()));
      expect(() => DesignRole.values.byValue(3), throwsA(isA<ArgumentError>()));
      expect(() => DesignRole.values.byValue(999), throwsA(isA<ArgumentError>()));
    });

    test('should handle string representation', () {
      expect(DesignRole.APPLICATION.toString(), contains('DesignRole.APPLICATION'));
      expect(DesignRole.SUPPORT.toString(), contains('DesignRole.SUPPORT'));
      expect(DesignRole.INFRASTRUCTURE.toString(), contains('DesignRole.INFRASTRUCTURE'));
    });

    test('should be comparable', () {
      expect(DesignRole.APPLICATION == DesignRole.APPLICATION, isTrue);
      expect(DesignRole.APPLICATION == DesignRole.SUPPORT, isFalse);
      expect(DesignRole.SUPPORT == DesignRole.INFRASTRUCTURE, isFalse);
    });

    test('should have consistent hashCode', () {
      expect(DesignRole.APPLICATION.hashCode, equals(DesignRole.APPLICATION.hashCode));
      expect(DesignRole.SUPPORT.hashCode, equals(DesignRole.SUPPORT.hashCode));
      expect(DesignRole.INFRASTRUCTURE.hashCode, equals(DesignRole.INFRASTRUCTURE.hashCode));
      
      expect(DesignRole.APPLICATION.hashCode, isNot(equals(DesignRole.SUPPORT.hashCode)));
      expect(DesignRole.SUPPORT.hashCode, isNot(equals(DesignRole.INFRASTRUCTURE.hashCode)));
    });

    test('should work in switch statements', () {
      String describeRole(DesignRole role) {
        switch (role) {
          case DesignRole.APPLICATION:
            return 'Application logic';
          case DesignRole.SUPPORT:
            return 'Support component';
          case DesignRole.INFRASTRUCTURE:
            return 'Infrastructure component';
        }
      }

      expect(describeRole(DesignRole.APPLICATION), equals('Application logic'));
      expect(describeRole(DesignRole.SUPPORT), equals('Support component'));
      expect(describeRole(DesignRole.INFRASTRUCTURE), equals('Infrastructure component'));
    });

    test('should work in collections', () {
      final roles = {DesignRole.APPLICATION, DesignRole.SUPPORT, DesignRole.INFRASTRUCTURE};
      expect(roles, hasLength(3));
      expect(roles, contains(DesignRole.APPLICATION));
      expect(roles, contains(DesignRole.SUPPORT));
      expect(roles, contains(DesignRole.INFRASTRUCTURE));
    });

    test('should handle index access', () {
      expect(DesignRole.values[0], equals(DesignRole.APPLICATION));
      expect(DesignRole.values[1], equals(DesignRole.SUPPORT));
      expect(DesignRole.values[2], equals(DesignRole.INFRASTRUCTURE));
    });

    test('should handle iteration', () {
      final roles = DesignRole.values;
      int count = 0;
      
      for (final role in roles) {
        expect(role, isA<DesignRole>());
        count++;
      }
      
      expect(count, equals(3));
    });

    test('should handle map operations', () {
      final roleMap = DesignRole.values.asMap();
      expect(roleMap[0], equals(DesignRole.APPLICATION));
      expect(roleMap[1], equals(DesignRole.SUPPORT));
      expect(roleMap[2], equals(DesignRole.INFRASTRUCTURE));
    });

    test('should handle where filters', () {
      final nonApplicationRoles = DesignRole.values.where((role) => role.value > 0);
      expect(nonApplicationRoles, hasLength(2));
      expect(nonApplicationRoles, contains(DesignRole.SUPPORT));
      expect(nonApplicationRoles, contains(DesignRole.INFRASTRUCTURE));
    });

    test('should handle value comparisons', () {
      expect(DesignRole.APPLICATION.value < DesignRole.SUPPORT.value, isTrue);
      expect(DesignRole.SUPPORT.value < DesignRole.INFRASTRUCTURE.value, isTrue);
      expect(DesignRole.INFRASTRUCTURE.value > DesignRole.APPLICATION.value, isTrue);
    });

    test('should handle role hierarchy', () {
      // Test that roles can be ordered by importance or level
      final rolesByImportance = DesignRole.values.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      
      expect(rolesByImportance[0], equals(DesignRole.APPLICATION));
      expect(rolesByImportance[1], equals(DesignRole.SUPPORT));
      expect(rolesByImportance[2], equals(DesignRole.INFRASTRUCTURE));
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
extension on List<DesignRole> {
  DesignRole byValue(int value) {
    for (final role in this) {
      if (role.value == value) {
        return role;
      }
    }
    throw ArgumentError('No DesignRole with value $value');
  }
}