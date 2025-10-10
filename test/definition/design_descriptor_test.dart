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

// test/design_descriptor_test.dart
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/src/definition/commons.dart';
import 'package:jetleaf_pod/src/helpers/enums.dart';
import 'package:test/test.dart';

void main() {
  group('DesignDescriptor', () {
    test('should create with required parameters', () {
      final descriptor = DesignDescriptor(
        role: DesignRole.APPLICATION,
        isPrimary: false,
      );

      expect(descriptor.role, equals(DesignRole.APPLICATION));
      expect(descriptor.isPrimary, isFalse);
      expect(descriptor.isInfrastructure, isFalse);
    });

    test('equalsAndHashCode should work correctly', () {
      final descriptor1 = DesignDescriptor(
        role: DesignRole.APPLICATION,
        isPrimary: false,
      );
      final descriptor2 = DesignDescriptor(
        role: DesignRole.APPLICATION,
        isPrimary: false,
      );
      final descriptor3 = DesignDescriptor(
        role: DesignRole.INFRASTRUCTURE,
        isPrimary: true,
      );

      expect(descriptor1.equals(descriptor2), isTrue);
      expect(descriptor1.equals(descriptor3), isFalse);
      expect(descriptor1.hashCode, equals(descriptor2.hashCode));
    });

    test('toString should include properties', () {
      final descriptor = DesignDescriptor(
        role: DesignRole.APPLICATION,
        isPrimary: true,
      );

      final str = descriptor.toString();
      expect(str, contains('APPLICATION'));
      expect(str, contains('isPrimary: true'));
      expect(str, contains('isInfrastructure: false'));
    });

    test('should handle all design roles', () {
      final application = DesignDescriptor(
        role: DesignRole.APPLICATION,
        isPrimary: false,
      );
      final support = DesignDescriptor(
        role: DesignRole.SUPPORT,
        isPrimary: false,
      );
      final infrastructure = DesignDescriptor(
        role: DesignRole.INFRASTRUCTURE,
        isPrimary: false,
      );

      expect(application.role, equals(DesignRole.APPLICATION));
      expect(support.role, equals(DesignRole.SUPPORT));
      expect(infrastructure.role, equals(DesignRole.INFRASTRUCTURE));
    });
  });
}