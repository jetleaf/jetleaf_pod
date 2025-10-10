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

// test/mergeable_test.dart
import 'package:jetleaf_pod/src/helpers/object.dart';
import 'package:test/test.dart';

class TestMergeable implements Mergeable {
  final Map<String, dynamic> data;
  final bool mergeEnabled;

  TestMergeable(this.data, {this.mergeEnabled = true});

  @override
  bool isMergeEnabled() => mergeEnabled;

  @override
  Object merge(Object parent) {
    if (!mergeEnabled) return this;
    if (parent is TestMergeable) {
      return TestMergeable({...parent.data, ...data});
    }
    return this;
  }
}

class TestListMergeable implements Mergeable {
  final List<dynamic> items;
  final bool mergeEnabled;

  TestListMergeable(this.items, {this.mergeEnabled = true});

  @override
  bool isMergeEnabled() => mergeEnabled;

  @override
  Object merge(Object parent) {
    if (!mergeEnabled) return this;
    if (parent is TestListMergeable) {
      return TestListMergeable([...parent.items, ...items]);
    }
    return this;
  }
}

void main() {
  group('Mergeable', () {
    test('should merge maps with child overriding parent', () {
      final parent = TestMergeable({'common': 'parent', 'parentOnly': true});
      final child = TestMergeable({'common': 'child', 'childOnly': 42});
      
      final result = child.merge(parent) as TestMergeable;
      expect(result.data, equals({
        'common': 'child',
        'parentOnly': true,
        'childOnly': 42,
      }));
    });

    test('should merge lists by appending', () {
      final parent = TestListMergeable([1, 2, 3]);
      final child = TestListMergeable([4, 5]);
      
      final result = child.merge(parent) as TestListMergeable;
      expect(result.items, equals([1, 2, 3, 4, 5]));
    });

    test('should return current object when merge not enabled', () {
      final parent = TestMergeable({'key': 'parent'});
      final child = TestMergeable({'key': 'child'}, mergeEnabled: false);
      
      final result = child.merge(parent);
      expect(result, equals(child));
    });

    test('should return current object when parent type mismatch', () {
      final parent = {'key': 'parent'}; // Regular map, not TestMergeable
      final child = TestMergeable({'key': 'child'});
      
      final result = child.merge(parent);
      expect(result, equals(child));
    });

    test('isMergeEnabled should reflect merge state', () {
      final enabled = TestMergeable({}, mergeEnabled: true);
      final disabled = TestMergeable({}, mergeEnabled: false);
      
      expect(enabled.isMergeEnabled(), isTrue);
      expect(disabled.isMergeEnabled(), isFalse);
    });

    test('should handle empty collections', () {
      final parent = TestMergeable({});
      final child = TestMergeable({'key': 'value'});
      
      final result = child.merge(parent) as TestMergeable;
      expect(result.data, equals({'key': 'value'}));
    });

    test('should handle nested merging scenarios', () {
      final parent = TestMergeable({
        'level1': {'parent': 'value'},
        'common': 'parent',
      });
      final child = TestMergeable({
        'level1': {'child': 'value'},
        'common': 'child',
      });
      
      final result = child.merge(parent) as TestMergeable;
      expect(result.data, equals({
        'level1': {'child': 'value'}, // Child overrides entire nested map
        'common': 'child',
      }));
    });

    test('should handle null values in merge', () {
      final parent = TestMergeable({'key': null});
      final child = TestMergeable({'key': 'not_null'});
      
      final result = child.merge(parent) as TestMergeable;
      expect(result.data, equals({'key': 'not_null'}));
    });

    test('should handle complex nested structures', () {
      final parent = TestMergeable({
        'nested': {
          'list': [1, 2],
          'map': {'a': 'parent'},
        },
      });
      final child = TestMergeable({
        'nested': {
          'list': [3, 4], // This will override the entire list
          'map': {'b': 'child'},
        },
      });
      
      final result = child.merge(parent) as TestMergeable;
      expect(result.data, equals({
        'nested': {
          'list': [3, 4],
          'map': {'b': 'child'}, // Child map overrides parent map entirely
        },
      }));
    });
  });
}