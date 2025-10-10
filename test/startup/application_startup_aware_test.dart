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

// test/application_startup_aware_test.dart
import 'package:jetleaf_pod/src/startup/application_startup.dart';
import 'package:jetleaf_pod/src/startup/startup.dart';
import 'package:test/test.dart';

// Test implementation
class TestApplicationStartupAware implements ApplicationStartupAware {
  ApplicationStartup? _startup;

  @override
  ApplicationStartup getApplicationStartup() {
    if (_startup == null) {
      throw StateError('Startup not set');
    }
    return _startup!;
  }

  @override
  void setApplicationStartup(ApplicationStartup applicationStartup) {
    _startup = applicationStartup;
  }
}

void main() {
  group('ApplicationStartupAware', () {
    test('should set and get ApplicationStartup', () {
      final aware = TestApplicationStartupAware();
      final startup = DefaultApplicationStartup();
      
      aware.setApplicationStartup(startup);
      final retrieved = aware.getApplicationStartup();
      
      expect(retrieved, equals(startup));
    });

    test('should throw if startup not set', () {
      final aware = TestApplicationStartupAware();
      
      expect(() => aware.getApplicationStartup(), throwsA(isA<StateError>()));
    });

    test('should allow changing startup', () {
      final aware = TestApplicationStartupAware();
      final startup1 = DefaultApplicationStartup();
      final startup2 = DefaultApplicationStartup();
      
      aware.setApplicationStartup(startup1);
      expect(aware.getApplicationStartup(), equals(startup1));
      
      aware.setApplicationStartup(startup2);
      expect(aware.getApplicationStartup(), equals(startup2));
    });

    test('should work with actual startup operations', () {
      final aware = TestApplicationStartupAware();
      final startup = DefaultApplicationStartup();
      
      aware.setApplicationStartup(startup);
      
      final step = aware.getApplicationStartup().start('test');
      expect(step, equals(DefaultApplicationStartup.DEFAULT_STARTUP_STEP));
      
      step.tag('key', value: 'value');
      step.end();
    });

    test('should handle multiple aware instances', () {
      final aware1 = TestApplicationStartupAware();
      final aware2 = TestApplicationStartupAware();
      final startup1 = DefaultApplicationStartup();
      final startup2 = DefaultApplicationStartup();
      
      aware1.setApplicationStartup(startup1);
      aware2.setApplicationStartup(startup2);
      
      expect(aware1.getApplicationStartup(), equals(startup1));
      expect(aware2.getApplicationStartup(), equals(startup2));
    });

    test('should work with different startup implementations', () {
      final aware = TestApplicationStartupAware();
      final startup = DefaultApplicationStartup();
      
      aware.setApplicationStartup(startup);
      final retrieved = aware.getApplicationStartup();
      
      expect(retrieved, isA<DefaultApplicationStartup>());
      expect(retrieved.start('test'), isA<DefaultStartupStep>());
    });
  });
}