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

// test/scope_descriptor_test.dart
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/src/definition/commons.dart';
import 'package:jetleaf_pod/src/helpers/enums.dart';
import 'package:test/test.dart';

void main() {
  group('ScopeDescriptor', () {
    test('should create with required parameters', () {
      final descriptor = ScopeDesign(
        type: ScopeType.SINGLETON.name,
        isSingleton: true,
        isPrototype: false,
      );

      expect(descriptor.type, equals(ScopeType.SINGLETON.name));
      expect(descriptor.isSingleton, isTrue);
      expect(descriptor.isPrototype, isFalse);
    });

    test('equalsAndHashCode should work correctly', () {
      final descriptor1 = ScopeDesign(
        type: ScopeType.SINGLETON.name,
        isSingleton: true,
        isPrototype: false,
      );
      final descriptor2 = ScopeDesign(
        type: ScopeType.SINGLETON.name,
        isSingleton: true,
        isPrototype: false,
      );
      final descriptor3 = ScopeDesign(
        type: ScopeType.PROTOTYPE.name,
        isSingleton: false,
        isPrototype: true,
      );

      expect(descriptor1.equals(descriptor2), isTrue);
      expect(descriptor1.equals(descriptor3), isFalse);
      expect(descriptor1.hashCode, equals(descriptor2.hashCode));
    });

    test('toString should include properties', () {
      final descriptor = ScopeDesign(
        type: ScopeType.SINGLETON.name,
        isSingleton: true,
        isPrototype: false,
      );

      final str = descriptor.toString();
      expect(str, contains('SINGLETON'));
      expect(str, contains('isSingleton: true'));
      expect(str, contains('isPrototype: false'));
    });

    test('should handle all scope types', () {
      final singleton = ScopeDesign(
        type: ScopeType.SINGLETON.name,
        isSingleton: true,
        isPrototype: false,
      );
      final prototype = ScopeDesign(
        type: ScopeType.PROTOTYPE.name,
        isSingleton: false,
        isPrototype: true,
      );

      expect(singleton.type, equals(ScopeType.SINGLETON.name));
      expect(prototype.type, equals(ScopeType.PROTOTYPE.name));
    });
  });
}