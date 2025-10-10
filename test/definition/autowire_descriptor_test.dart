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

// test/autowire_candidate_descriptor_test.dart
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/src/definition/commons.dart';
import 'package:jetleaf_pod/src/helpers/enums.dart';
import 'package:test/test.dart';

void main() {
  group('AutowireCandidateDescriptor', () {
    test('should create with required parameters', () {
      final descriptor = AutowireCandidateDescriptor(
        autowireCandidate: true,
        autowireMode: AutowireMode.NO,
      );

      expect(descriptor.autowireCandidate, isTrue);
      expect(descriptor.autowireMode, equals(AutowireMode.NO));
    });

    test('equalsAndHashCode should work correctly', () {
      final descriptor1 = AutowireCandidateDescriptor(
        autowireCandidate: true,
        autowireMode: AutowireMode.NO,
      );
      final descriptor2 = AutowireCandidateDescriptor(
        autowireCandidate: true,
        autowireMode: AutowireMode.NO,
      );
      final descriptor3 = AutowireCandidateDescriptor(
        autowireCandidate: false,
        autowireMode: AutowireMode.BY_TYPE,
      );

      expect(descriptor1.equals(descriptor2), isTrue);
      expect(descriptor1.equals(descriptor3), isFalse);
      expect(descriptor1.hashCode, equals(descriptor2.hashCode));
    });

    test('toString should include properties', () {
      final descriptor = AutowireCandidateDescriptor(
        autowireCandidate: true,
        autowireMode: AutowireMode.BY_TYPE,
      );

      final str = descriptor.toString();
      expect(str, contains('autowireCandidate: true'));
      expect(str, contains('BY_TYPE'));
    });

    test('should handle all autowire modes', () {
      final no = AutowireCandidateDescriptor(
        autowireCandidate: true,
        autowireMode: AutowireMode.NO,
      );
      final byName = AutowireCandidateDescriptor(
        autowireCandidate: true,
        autowireMode: AutowireMode.BY_NAME,
      );
      final byType = AutowireCandidateDescriptor(
        autowireCandidate: true,
        autowireMode: AutowireMode.BY_TYPE,
      );

      expect(no.autowireMode, equals(AutowireMode.NO));
      expect(byName.autowireMode, equals(AutowireMode.BY_NAME));
      expect(byType.autowireMode, equals(AutowireMode.BY_TYPE));
    });

    test('should handle disabled autowire candidate', () {
      final disabled = AutowireCandidateDescriptor(
        autowireCandidate: false,
        autowireMode: AutowireMode.NO,
      );

      expect(disabled.autowireCandidate, isFalse);
    });
  });
}