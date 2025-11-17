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

// test/nullable_pod_test.dart
import 'package:jetleaf_pod/src/helpers/nullable_pod.dart';
import 'package:test/test.dart';

void main() {
  group('NullablePod', () {
    test('should create instances correctly', () {
      final pod1 = NullablePod();
      final pod2 = NullablePod();
      
      expect(pod1, isA<NullablePod>());
      expect(pod2, isA<NullablePod>());
    });

    test('all instances should be equal', () {
      final pod1 = NullablePod();
      final pod2 = NullablePod();
      final pod3 = NullablePod();
      
      expect(pod1, equals(pod2));
      expect(pod2, equals(pod3));
      expect(pod1, equals(pod3));
      expect(pod1 == pod2, isTrue);
      expect(pod2 == pod3, isTrue);
    });

    test('hashCode should be consistent across instances', () {
      final pod1 = NullablePod();
      final pod2 = NullablePod();
      final pod3 = NullablePod();
      
      expect(pod1.hashCode, equals(pod2.hashCode));
      expect(pod2.hashCode, equals(pod3.hashCode));
      expect(pod1.hashCode, equals(pod3.hashCode));
    });

    test('toString should return correct representation', () {
      final pod = NullablePod();
      expect(pod.toString(), equals('NullablePod()'));
    });

    test('equalizedProperties should return list containing instance', () {
      final pod = NullablePod();
      final properties = pod.equalizedProperties();
      
      expect(properties, hasLength(1));
      expect(properties[0], equals("NullablePod"));
    });

    test('should work in collections', () {
      final pod1 = NullablePod();
      final pod2 = NullablePod();
      final pod3 = NullablePod();
      
      final set = {pod1, pod2, pod3};
      expect(set, hasLength(1)); // All are equal, so only one in set
      
      final map = {pod1: 'value1', pod2: 'value2'};
      expect(map, hasLength(1)); // Only one entry since keys are equal
      expect(map[pod3], equals('value2')); // Last value wins
    });

    test('should handle comparison with other types', () {
      final pod = NullablePod();
      
      expect(pod.toString() == 'string', isFalse);
      expect(pod == Object(), isFalse);
    });

    test('should handle null safety', () {
      final pod = NullablePod();
      
      // Should not throw on any operation
      expect(() => pod.hashCode, returnsNormally);
      expect(() => pod.toString(), returnsNormally);
      expect(() => pod.equalizedProperties(), returnsNormally);
    });

    test('should be immutable', () {
      final pod = NullablePod();
      
      // No methods to modify state, should be immutable
      expect(pod, equals(NullablePod()));
    });
  });
}