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

// test/startup_step_tags_test.dart
import 'package:jetleaf_pod/src/startup/startup.dart';
import 'package:test/test.dart';

void main() {
  group('StartupStepTags', () {
    test('DefaultStartupStepTags should be empty', () {
      final tags = DefaultStartupStepTags();
      
      expect(tags.isEmpty, isTrue);
      expect(tags.isNotEmpty, isFalse);
    });

    test('DefaultStartupStepTags iterator should have no elements', () {
      final tags = DefaultStartupStepTags();
      final iterator = tags.iterator;
      
      expect(iterator.moveNext(), isFalse);
    });

    test('DefaultStartupStepTags should work with for-in loop', () {
      final tags = DefaultStartupStepTags();
      int count = 0;
      
      for (final _ in tags) {
        count++;
      }
      
      expect(count, equals(0));
    });

    test('DefaultStartupStepTags should work with toList', () {
      final tags = DefaultStartupStepTags();
      final list = tags.toList();
      
      expect(list, isEmpty);
    });

    test('DefaultStartupStepTags should work with any', () {
      final tags = DefaultStartupStepTags();
      
      expect(tags.any((tag) => true), isFalse);
      expect(tags.any((tag) => false), isFalse);
    });

    test('DefaultStartupStepTags should work with firstOrNull', () {
      final tags = DefaultStartupStepTags();
      
      expect(tags.firstOrNull, isNull);
    });

    test('DefaultStartupStepTags should work with length', () {
      final tags = DefaultStartupStepTags();
      
      expect(tags.length, equals(0));
    });

    test('DefaultStartupStepTags should work with contains', () {
      final tags = DefaultStartupStepTags();
      
      expect(tags.contains('anything'), isFalse);
    });

    test('DefaultStartupStepTags should work with elementAt', () {
      final tags = DefaultStartupStepTags();
      
      expect(() => tags.elementAt(0), throwsRangeError);
    });

    test('DefaultStartupStepTags should implement Iterable correctly', () {
      final tags = DefaultStartupStepTags();
      
      expect(tags.fold<int>(0, (sum, tag) => sum + 1), equals(0));
      expect(tags.where((tag) => true).isEmpty, isTrue);
      expect(tags.map((tag) => tag).isEmpty, isTrue);
    });
  });
}