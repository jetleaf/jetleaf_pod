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

// test/startup_step_tag_test.dart
import 'package:jetleaf_pod/src/startup/startup.dart';
import 'package:test/test.dart';

// Test implementation
class TestStartupStepTag extends StartupStepTag {
  @override
  final String key;
  @override
  final String value;

  TestStartupStepTag(this.key, this.value);
}

void main() {
  group('StartupStepTag', () {
    test('should create with key and value', () {
      final tag = TestStartupStepTag('testKey', 'testValue');
      
      expect(tag.key, equals('testKey'));
      expect(tag.value, equals('testValue'));
    });

    test('should handle different key-value pairs', () {
      final testCases = [
        {'key': 'name', 'value': 'John'},
        {'key': 'age', 'value': '30'},
        {'key': 'active', 'value': 'true'},
        {'key': 'score', 'value': '100.5'},
      ];
      
      for (final testCase in testCases) {
        final tag = TestStartupStepTag(testCase['key']!, testCase['value']!);
        expect(tag.key, equals(testCase['key']));
        expect(tag.value, equals(testCase['value']));
      }
    });

    test('should handle empty strings', () {
      final tag = TestStartupStepTag('', '');
      
      expect(tag.key, equals(''));
      expect(tag.value, equals(''));
    });

    test('should handle long strings', () {
      final longKey = 'a' * 1000;
      final longValue = 'b' * 1000;
      final tag = TestStartupStepTag(longKey, longValue);
      
      expect(tag.key, equals(longKey));
      expect(tag.value, equals(longValue));
    });

    test('should handle special characters', () {
      final specialKey = 'key-with-dashes_and_underscores@symbols';
      final specialValue = 'value with spaces and !@#\$%^&*() symbols';
      final tag = TestStartupStepTag(specialKey, specialValue);
      
      expect(tag.key, equals(specialKey));
      expect(tag.value, equals(specialValue));
    });

    test('should handle unicode characters', () {
      final unicodeKey = 'ñame';
      final unicodeValue = '中文测试🚀';
      final tag = TestStartupStepTag(unicodeKey, unicodeValue);
      
      expect(tag.key, equals(unicodeKey));
      expect(tag.value, equals(unicodeValue));
    });

    test('should work in collections', () {
      final tag1 = TestStartupStepTag('key', 'value');
      final tag2 = TestStartupStepTag('key', 'value');
      final tag3 = TestStartupStepTag('different', 'value');
      
      final set = {tag1, tag2, tag3};
      // Since we're using default equality, they should all be different
      expect(set, hasLength(2));
    });

    test('should implement toString', () {
      final tag = TestStartupStepTag('test', 'value');
      
      expect(tag.toString(), contains('test'));
      expect(tag.toString(), contains('value'));
    });
  });
}