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

// test/scope_type_test.dart
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/src/helpers/enums.dart';
import 'package:test/test.dart';

void main() {
  group('ScopeType', () {
    test('should have correct values', () {
      expect(ScopeType.SINGLETON.value, equals(0));
      expect(ScopeType.PROTOTYPE.value, equals(1));
    });

    test('should have correct enum values', () {
      expect(ScopeType.values, hasLength(2));
      expect(ScopeType.values, contains(ScopeType.SINGLETON));
      expect(ScopeType.values, contains(ScopeType.PROTOTYPE));
    });

    test('should convert from value', () {
      expect(ScopeType.values.byValue(0), equals(ScopeType.SINGLETON));
      expect(ScopeType.values.byValue(1), equals(ScopeType.PROTOTYPE));
    });

    test('should throw for invalid value', () {
      expect(() => ScopeType.values.byValue(-1), throwsA(isA<ArgumentError>()));
      expect(() => ScopeType.values.byValue(2), throwsA(isA<ArgumentError>()));
      expect(() => ScopeType.values.byValue(999), throwsA(isA<ArgumentError>()));
    });

    test('should handle string representation', () {
      expect(ScopeType.SINGLETON.toString(), contains('ScopeType.SINGLETON'));
      expect(ScopeType.PROTOTYPE.toString(), contains('ScopeType.PROTOTYPE'));
    });

    test('should be comparable', () {
      expect(ScopeType.SINGLETON == ScopeType.SINGLETON, isTrue);
      expect(ScopeType.SINGLETON == ScopeType.PROTOTYPE, isFalse);
      expect(ScopeType.PROTOTYPE == ScopeType.PROTOTYPE, isTrue);
    });

    test('should have consistent hashCode', () {
      expect(ScopeType.SINGLETON.hashCode, equals(ScopeType.SINGLETON.hashCode));
      expect(ScopeType.PROTOTYPE.hashCode, equals(ScopeType.PROTOTYPE.hashCode));
      expect(ScopeType.SINGLETON.hashCode, isNot(equals(ScopeType.PROTOTYPE.hashCode)));
    });

    test('should work in switch statements', () {
      String describeScope(ScopeType scope) {
        switch (scope) {
          case ScopeType.SINGLETON:
            return 'Single shared instance';
          case ScopeType.PROTOTYPE:
            return 'New instance each time';
        }
      }

      expect(describeScope(ScopeType.SINGLETON), equals('Single shared instance'));
      expect(describeScope(ScopeType.PROTOTYPE), equals('New instance each time'));
    });

    test('should work in collections', () {
      final scopes = {ScopeType.SINGLETON, ScopeType.PROTOTYPE};
      expect(scopes, hasLength(2));
      expect(scopes, contains(ScopeType.SINGLETON));
      expect(scopes, contains(ScopeType.PROTOTYPE));
    });

    test('should handle index access', () {
      expect(ScopeType.values[0], equals(ScopeType.SINGLETON));
      expect(ScopeType.values[1], equals(ScopeType.PROTOTYPE));
    });

    test('should handle iteration', () {
      final scopes = ScopeType.values;
      int count = 0;
      
      for (final scope in scopes) {
        expect(scope, isA<ScopeType>());
        count++;
      }
      
      expect(count, equals(2));
    });

    test('should handle map operations', () {
      final scopeMap = ScopeType.values.asMap();
      expect(scopeMap[0], equals(ScopeType.SINGLETON));
      expect(scopeMap[1], equals(ScopeType.PROTOTYPE));
    });

    test('should handle where filters', () {
      final nonSingletonScopes = ScopeType.values.where((scope) => scope.value > 0);
      expect(nonSingletonScopes, hasLength(1));
      expect(nonSingletonScopes, contains(ScopeType.PROTOTYPE));
    });

    test('should handle scope comparisons', () {
      expect(ScopeType.SINGLETON.value < ScopeType.PROTOTYPE.value, isTrue);
      expect(ScopeType.PROTOTYPE.value > ScopeType.SINGLETON.value, isTrue);
    });

    test('should handle lifecycle implications', () {
      // Test that scopes can be compared based on lifecycle characteristics
      final sharedScopes = ScopeType.values.where((scope) => scope.value == 0);
      final nonSharedScopes = ScopeType.values.where((scope) => scope.value == 1);
      
      expect(sharedScopes, hasLength(1));
      expect(sharedScopes, contains(ScopeType.SINGLETON));
      
      expect(nonSharedScopes, hasLength(1));
      expect(nonSharedScopes, contains(ScopeType.PROTOTYPE));
    });

    test('should handle boundary values', () {
      expect(ScopeType.SINGLETON.value, equals(0));
      expect(ScopeType.PROTOTYPE.value, equals(1));
      
      // Test that values are within expected range
      for (final scope in ScopeType.values) {
        expect(scope.value, greaterThanOrEqualTo(0));
        expect(scope.value, lessThanOrEqualTo(1));
      }
    });

    test('should handle enum properties', () {
      expect(ScopeType.SINGLETON.index, equals(0));
      expect(ScopeType.PROTOTYPE.index, equals(1));
      
      expect(ScopeType.SINGLETON.name, equals('SINGLETON'));
      expect(ScopeType.PROTOTYPE.name, equals('PROTOTYPE'));
    });

    test('should handle valueOf', () {
      expect(ScopeType.valueOf('SINGLETON'), equals(ScopeType.SINGLETON));
      expect(ScopeType.valueOf('PROTOTYPE'), equals(ScopeType.PROTOTYPE));
    });

    test('should handle fromValue', () {
      expect(ScopeType.fromValue(0), equals(ScopeType.SINGLETON));
      expect(ScopeType.fromValue(1), equals(ScopeType.PROTOTYPE));
    });

    test('should throw for invalid fromValue', () {
      expect(() => ScopeType.fromValue(-1), throwsA(isA<IllegalArgumentException>()));
      expect(() => ScopeType.fromValue(2), throwsA(isA<IllegalArgumentException>()));
    });

    test('should throw for invalid valueOf', () {
      expect(() => ScopeType.valueOf('INVALID'), throwsA(isA<IllegalArgumentException>()));
    });
  });
}

// Extension to get enum by value
extension on List<ScopeType> {
  ScopeType byValue(int value) {
    for (final scope in this) {
      if (scope.value == value) {
        return scope;
      }
    }
    throw ArgumentError('No ScopeType with value $value');
  }
}