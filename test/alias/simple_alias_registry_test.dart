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

// test/simple_alias_registry_test.dart
// ignore_for_file: invalid_use_of_protected_member

import 'package:jetleaf_pod/src/alias/simple_alias_registry.dart';
import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

void main() {
  group('SimpleAliasRegistry', () {
    late SimpleAliasRegistry registry;

    setUp(() {
      registry = SimpleAliasRegistry();
    });

    test('should initialize with empty storage', () {
      expect(registry.isAlias('test'), isFalse);
      expect(registry.getAliases('test'), isEmpty);
      expect(registry.getAlias('test'), isNull);
    });

    test('registerAlias should register valid alias', () {
      registry.registerAlias('service', 'alias');
      
      expect(registry.isAlias('alias'), isTrue);
      expect(registry.getAlias('alias'), equals('service'));
      expect(registry.getAliases('service'), contains('alias'));
    });

    test('registerAlias should throw for empty name', () {
      expect(() => registry.registerAlias('', 'alias'), 
          throwsA(isA<IllegalArgumentException>()));
    });

    test('registerAlias should throw for empty alias', () {
      expect(() => registry.registerAlias('service', ''), 
          throwsA(isA<IllegalArgumentException>()));
    });

    test('registerAlias should ignore alias pointing to same name', () {
      registry.registerAlias('service', 'service');
      
      expect(registry.isAlias('service'), isFalse);
      expect(registry.getAliases('service'), isEmpty);
    });

    test('registerAlias should allow re-registering same alias for same name', () {
      registry.registerAlias('service', 'alias');
      registry.registerAlias('service', 'alias'); // Should not throw
      
      expect(registry.getAlias('alias'), equals('service'));
    });

    test('registerAlias should detect circular references', () {
      registry.registerAlias('serviceA', 'serviceB');
      
      expect(() => registry.registerAlias('serviceB', 'serviceA'),
          throwsA(isA<IllegalStateException>()));
    });

    test('registerAlias should detect indirect circular references', () {
      registry.registerAlias('serviceA', 'serviceB');
      registry.registerAlias('serviceB', 'serviceC');
      
      expect(() => registry.registerAlias('serviceC', 'serviceA'),
          throwsA(isA<IllegalStateException>()));
    });

    test('removeAlias should remove existing alias', () {
      registry.registerAlias('service', 'alias');
      registry.removeAlias('alias');
      
      expect(registry.isAlias('alias'), isFalse);
      expect(registry.getAlias('alias'), isNull);
    });

    test('removeAlias should throw for non-existent alias', () {
      expect(() => registry.removeAlias('nonexistent'),
          throwsA(isA<IllegalStateException>()));
    });

    test('isAlias should return correct values', () {
      registry.registerAlias('service', 'alias');
      
      expect(registry.isAlias('alias'), isTrue);
      expect(registry.isAlias('service'), isFalse);
      expect(registry.isAlias('nonexistent'), isFalse);
    });

    test('getAliases should return all aliases for name', () {
      registry.registerAlias('service', 'alias1');
      registry.registerAlias('service', 'alias2');
      registry.registerAlias('service', 'alias3');
      
      final aliases = registry.getAliases('service');
      expect(aliases, containsAll(['alias1', 'alias2', 'alias3']));
    });

    test('getAliases should return transitive aliases', () {
      registry.registerAlias('service', 'alias1');
      registry.registerAlias('alias1', 'alias2');
      registry.registerAlias('alias2', 'alias3');
      
      final aliases = registry.getAliases('service');
      expect(aliases, containsAll(['alias1', 'alias2', 'alias3']));
    });

    test('getAliases should return empty list for non-aliased name', () {
      expect(registry.getAliases('service'), isEmpty);
    });

    test('getAlias should return direct alias target', () {
      registry.registerAlias('service', 'alias');
      
      expect(registry.getAlias('alias'), equals('service'));
      expect(registry.getAlias('service'), isNull);
    });

    test('targetName should resolve alias chains', () {
      registry.registerAlias('ultimate', 'alias1');
      registry.registerAlias('alias1', 'alias2');
      registry.registerAlias('alias2', 'alias3');
      
      // Test protected method through extension or reflection
      // For this test, we'll assume targetName is made available for testing
      expect(registry.targetName('alias3'), equals('ultimate'));
      expect(registry.targetName('alias1'), equals('ultimate'));
      expect(registry.targetName('ultimate'), equals('ultimate'));
    });

    test('hasAlias should detect direct and transitive aliases', () {
      registry.registerAlias('service', 'alias1');
      registry.registerAlias('alias1', 'alias2');
      
      // Test protected method
      expect(registry.hasAlias('service', 'alias1'), isTrue);
      expect(registry.hasAlias('service', 'alias2'), isTrue);
      expect(registry.hasAlias('service', 'nonexistent'), isFalse);
    });

    test('resolveAliases should process aliases with value resolver', () {
      registry.registerAlias('service', 'alias');
      
      registry.resolveAliases((value) {
        if (value == 'service') return 'resolvedService';
        if (value == 'alias') return 'resolvedAlias';
        return value;
      });
      
      expect(registry.getAlias('resolvedAlias'), equals('resolvedService'));
      expect(registry.isAlias('alias'), isFalse);
    });

    test('resolveAliases should handle empty resolved values', () {
      registry.registerAlias('service', 'alias');
      
      registry.resolveAliases((value) => '');
      
      expect(registry.isAlias('alias'), isFalse);
      expect(registry.getAliases('service'), isEmpty);
    });

    test('resolveAliases should handle identical resolved values', () {
      registry.registerAlias('service', 'alias');
      
      registry.resolveAliases((value) => 'same');
      
      expect(registry.isAlias('alias'), isFalse);
      expect(registry.getAliases('service'), isEmpty);
    });

    test('getAliasNames should return all alias names in order', () {
      registry.registerAlias('service1', 'alias1');
      registry.registerAlias('service2', 'alias2');
      registry.registerAlias('service3', 'alias3');
      
      final aliasNames = registry.getAliasNames();
      expect(aliasNames, equals(['alias1', 'alias2', 'alias3']));
    });

    test('getUltimateNames should return all target names', () {
      registry.registerAlias('service1', 'alias1');
      registry.registerAlias('alias1', 'alias2');
      registry.registerAlias('service2', 'alias3');
      
      final names = registry.getUltimateNames();
      expect(names, containsAll(['service1', 'service2']));
    });

    test('clear should remove all aliases', () {
      registry.registerAlias('service1', 'alias1');
      registry.registerAlias('service2', 'alias2');
      
      registry.clear();
      
      expect(registry.aliasCount, equals(0));
      expect(registry.isEmpty, isTrue);
      expect(registry.isNotEmpty, isFalse);
    });

    test('aliasCount should return correct count', () {
      expect(registry.aliasCount, equals(0));
      
      registry.registerAlias('service1', 'alias1');
      expect(registry.aliasCount, equals(1));
      
      registry.registerAlias('service2', 'alias2');
      expect(registry.aliasCount, equals(2));
      
      registry.removeAlias('alias1');
      expect(registry.aliasCount, equals(1));
    });

    test('isEmpty and isNotEmpty should work correctly', () {
      expect(registry.isEmpty, isTrue);
      expect(registry.isNotEmpty, isFalse);
      
      registry.registerAlias('service', 'alias');
      
      expect(registry.isEmpty, isFalse);
      expect(registry.isNotEmpty, isTrue);
    });

    test('should handle concurrent access safely', () async {
      // Test that synchronized blocks work correctly
      final futures = <Future>[];
      
      for (int i = 0; i < 10; i++) {
        futures.add(Future(() {
          registry.registerAlias('service$i', 'alias$i');
        }));
      }
      
      await Future.wait(futures);
      
      expect(registry.aliasCount, equals(10));
      for (int i = 0; i < 10; i++) {
        expect(registry.getAlias('alias$i'), equals('service$i'));
      }
    });

    test('should handle complex alias chains', () {
      registry.registerAlias('ultimate', 'level1');
      registry.registerAlias('level1', 'level2');
      registry.registerAlias('level2', 'level3');
      registry.registerAlias('level3', 'level4');
      
      expect(registry.targetName('level4'), equals('ultimate'));
      expect(registry.getAliases('ultimate'), 
          containsAll(['level1', 'level2', 'level3', 'level4']));
    });

    test('should handle multiple aliases for same target', () {
      registry.registerAlias('service', 'alias1');
      registry.registerAlias('service', 'alias2');
      registry.registerAlias('service', 'alias3');
      
      expect(registry.getAliases('service'), 
          containsAll(['alias1', 'alias2', 'alias3']));
      expect(registry.getAlias('alias1'), equals('service'));
      expect(registry.getAlias('alias2'), equals('service'));
      expect(registry.getAlias('alias3'), equals('service'));
    });

    test('should handle mixed direct and indirect aliases', () {
      registry.registerAlias('service', 'direct1');
      registry.registerAlias('direct1', 'indirect1');
      registry.registerAlias('service', 'direct2');
      registry.registerAlias('direct2', 'indirect2');
      
      final aliases = registry.getAliases('service');
      expect(aliases, containsAll([
        'direct1', 'indirect1', 'direct2', 'indirect2'
      ]));
    });

    test('should handle edge case with self-referential alias', () {
      // This should be caught by the same-name check
      registry.registerAlias('service', 'service');
      expect(registry.isAlias('service'), isFalse);
    });

    test('should handle edge case with very long alias chains', () {
      const chainLength = 100;
      for (int i = 0; i < chainLength; i++) {
        if (i == 0) {
          registry.registerAlias('target', 'alias0');
        } else {
          registry.registerAlias('alias${i-1}', 'alias$i');
        }
      }
      
      expect(registry.targetName('alias${chainLength-1}'), equals('target'));
    });

    test('should handle unicode and special characters in names', () {
      registry.registerAlias('sérvîçé', 'ålïàs');
      registry.registerAlias('服务', '别名');
      registry.registerAlias('service with spaces', 'alias with spaces');
      registry.registerAlias('service-with-dashes', 'alias-with-dashes');
      
      expect(registry.getAlias('ålïàs'), equals('sérvîçé'));
      expect(registry.getAlias('别名'), equals('服务'));
      expect(registry.getAlias('alias with spaces'), equals('service with spaces'));
      expect(registry.getAlias('alias-with-dashes'), equals('service-with-dashes'));
    });

    test('should handle very long names and aliases', () {
      final longName = 'a' * 1000;
      final longAlias = 'b' * 1000;
      
      registry.registerAlias(longName, longAlias);
      
      expect(registry.getAlias(longAlias), equals(longName));
      expect(registry.isAlias(longAlias), isTrue);
    });

    test('should maintain registration order in getAliasNames', () {
      final aliases = ['z', 'a', 'm', '1', '9'];
      for (final alias in aliases) {
        registry.registerAlias('service', alias);
      }
      
      expect(registry.getAliasNames(), equals(aliases));
    });

    test('should handle remove and re-register scenarios', () {
      registry.registerAlias('service', 'alias');
      registry.removeAlias('alias');
      registry.registerAlias('service', 'alias');
      
      expect(registry.getAlias('alias'), equals('service'));
    });

    test('should handle multiple removes', () {
      registry.registerAlias('service1', 'alias1');
      registry.registerAlias('service2', 'alias2');
      registry.registerAlias('service3', 'alias3');
      
      registry.removeAlias('alias1');
      registry.removeAlias('alias2');
      registry.removeAlias('alias3');
      
      expect(registry.isEmpty, isTrue);
    });

    test('should handle interleaved registration and removal', () {
      registry.registerAlias('service1', 'alias1');
      registry.registerAlias('service2', 'alias2');
      registry.removeAlias('alias1');
      registry.registerAlias('service3', 'alias3');
      registry.registerAlias('service4', 'alias4');
      registry.removeAlias('alias2');
      
      expect(registry.getAliasNames(), equals(['alias3', 'alias4']));
    });
  });

  group('SimpleAliasRegistry - allowAliasOverriding', () {
    test('should allow alias overriding by default', () {
      final registry = SimpleAliasRegistry();
      registry.registerAlias('service1', 'alias');
      registry.registerAlias('service2', 'alias'); // Should not throw
      
      expect(registry.getAlias('alias'), equals('service2'));
    });

    test('should respect overridden allowAliasOverriding', () {
      final strictRegistry = _StrictAliasRegistry();
      strictRegistry.registerAlias('service1', 'alias');
      
      expect(() => strictRegistry.registerAlias('service2', 'alias'),
          throwsA(isA<IllegalStateException>()));
    });
  });
}

// Test subclass that disallows alias overriding
class _StrictAliasRegistry extends SimpleAliasRegistry {
  @override
  bool allowAliasOverriding() => false;
}