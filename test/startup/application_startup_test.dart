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

// test/application_startup_test.dart
import 'package:jetleaf_pod/src/startup/application_startup.dart';
import 'package:test/test.dart';

void main() {
  group('ApplicationStartup', () {
    test('DefaultApplicationStartup should return DEFAULT_STARTUP_STEP', () {
      final startup = DefaultApplicationStartup();
      final step = startup.start('test');
      
      expect(step, equals(DefaultApplicationStartup.DEFAULT_STARTUP_STEP));
    });

    test('DefaultApplicationStartup should return same instance for all calls', () {
      final startup = DefaultApplicationStartup();
      
      final step1 = startup.start('test1');
      final step2 = startup.start('test2');
      final step3 = startup.start('test3');
      
      expect(step1, equals(DefaultApplicationStartup.DEFAULT_STARTUP_STEP));
      expect(step2, equals(DefaultApplicationStartup.DEFAULT_STARTUP_STEP));
      expect(step3, equals(DefaultApplicationStartup.DEFAULT_STARTUP_STEP));
      expect(step1, equals(step2));
      expect(step2, equals(step3));
    });

    test('DefaultApplicationStartup should handle different step names', () {
      final startup = DefaultApplicationStartup();
      
      final names = ['context.load', 'pods.init', 'database.connect', 'service.start'];
      for (final name in names) {
        final step = startup.start(name);
        expect(step, equals(DefaultApplicationStartup.DEFAULT_STARTUP_STEP));
      }
    });

    test('DefaultApplicationStartup should handle empty step name', () {
      final startup = DefaultApplicationStartup();
      final step = startup.start('');
      
      expect(step, equals(DefaultApplicationStartup.DEFAULT_STARTUP_STEP));
    });

    test('DefaultApplicationStartup should handle very long step name', () {
      final startup = DefaultApplicationStartup();
      final longName = 'a' * 1000;
      final step = startup.start(longName);
      
      expect(step, equals(DefaultApplicationStartup.DEFAULT_STARTUP_STEP));
    });

    test('DefaultApplicationStartup.DEFAULT_STARTUP_STEP should be singleton', () {
      final step1 = DefaultApplicationStartup.DEFAULT_STARTUP_STEP;
      final step2 = DefaultApplicationStartup.DEFAULT_STARTUP_STEP;
      
      expect(step1, equals(step2));
      expect(identical(step1, step2), isTrue);
    });

    test('should work with multiple ApplicationStartup instances', () {
      final startup1 = DefaultApplicationStartup();
      final startup2 = DefaultApplicationStartup();
      
      final step1 = startup1.start('test');
      final step2 = startup2.start('test');
      
      expect(step1, equals(step2)); // Both return the same DEFAULT_STARTUP_STEP
    });
  });
}