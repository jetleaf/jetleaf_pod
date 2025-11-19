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

// test/lifecycle_design_test.dart
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/src/definition/commons.dart';
import 'package:test/test.dart';

void main() {
  group('LifecycleDesign', () {
    test('should create with default values', () {
      final design = LifecycleDesign();

      expect(design.isLazy, isNull);
      expect(design.initMethods, isEmpty);
      expect(design.destroyMethods, isEmpty);
      expect(design.enforceInitMethod, isTrue);
      expect(design.enforceDestroyMethod, isTrue);
    });

    test('should create with custom values', () {
      final design = LifecycleDesign(
        isLazy: true,
        initMethods: ['init1', 'init2'],
        destroyMethods: ['destroy1'],
        enforceInitMethod: false,
        enforceDestroyMethod: false,
      );

      expect(design.isLazy, isTrue);
      expect(design.initMethods, equals(['init1', 'init2']));
      expect(design.destroyMethods, equals(['destroy1']));
      expect(design.enforceInitMethod, isFalse);
      expect(design.enforceDestroyMethod, isFalse);
    });

    test('equalsAndHashCode should work correctly', () {
      final design1 = LifecycleDesign(
        isLazy: true,
        initMethods: ['init'],
        destroyMethods: ['destroy'],
      );
      final design2 = LifecycleDesign(
        isLazy: true,
        initMethods: ['init'],
        destroyMethods: ['destroy'],
      );
      final design3 = LifecycleDesign(
        isLazy: false,
        initMethods: ['init'],
        destroyMethods: ['destroy'],
      );

      expect(design1.equals(design2), isTrue);
      expect(design1.equals(design3), isFalse);
      expect(design1.hashCode, equals(design2.hashCode));
    });

    test('toString should include properties', () {
      final design = LifecycleDesign(
        isLazy: true,
        initMethods: ['init'],
        destroyMethods: ['destroy'],
      );

      final str = design.toString();
      expect(str, contains('isLazy: true'));
      expect(str, contains('initMethods: [init]'));
      expect(str, contains('destroyMethods: [destroy]'));
    });

    test('should handle empty method lists', () {
      final design = LifecycleDesign(
        initMethods: [],
        destroyMethods: [],
      );

      expect(design.initMethods, isEmpty);
      expect(design.destroyMethods, isEmpty);
    });

    test('should handle multiple methods', () {
      final design = LifecycleDesign(
        initMethods: ['init1', 'init2', 'init3'],
        destroyMethods: ['destroy1', 'destroy2'],
      );

      expect(design.initMethods, hasLength(3));
      expect(design.destroyMethods, hasLength(2));
    });
  });
}