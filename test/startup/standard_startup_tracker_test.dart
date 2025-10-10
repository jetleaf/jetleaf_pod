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

// test/standard_startup_tracker_test.dart
import 'package:jetleaf_pod/src/startup/startup.dart';
import 'package:test/test.dart';

void main() {
  group('StandardStartupTracker', () {
    test('should create with current time', () {
      final before = DateTime.now().millisecondsSinceEpoch;
      final startup = StandardStartupTracker();
      final after = DateTime.now().millisecondsSinceEpoch;
      
      final startTime = startup.getStartTime();
      expect(startTime, greaterThanOrEqualTo(before));
      expect(startTime, lessThanOrEqualTo(after));
    });

    test('getProcessUptime should return null', () {
      final startup = StandardStartupTracker();
      expect(startup.getProcessUptime(), isNull);
    });

    test('getAction should return "Started"', () {
      final startup = StandardStartupTracker();
      expect(startup.getAction(), equals('Started'));
    });

    test('started should calculate correct duration', () {
      final startup = StandardStartupTracker();
      
      // Wait a bit
      Future.delayed(Duration(milliseconds: 50), () {
        final duration = startup.started();
        
        expect(duration.inMilliseconds, greaterThanOrEqualTo(0));
        expect(duration.inMilliseconds, lessThan(100));
        
        final retrieved = startup.getTimeTakenToStarted();
        expect(retrieved, equals(duration));
      });
    });

    test('getReady should return increasing duration', () {
      final startup = StandardStartupTracker();
      
      final ready1 = startup.getReady();
      expect(ready1.inMilliseconds, greaterThanOrEqualTo(0));
      
      // Wait a bit
      Future.delayed(Duration(milliseconds: 10), () {
        final ready2 = startup.getReady();
        expect(ready2.inMilliseconds, greaterThanOrEqualTo(ready1.inMilliseconds));
      });
    });

    test('should handle multiple started calls', () {
      final startup = StandardStartupTracker();
      
      final duration1 = startup.started();
      final duration2 = startup.started();
      
      expect(duration2.inMilliseconds, greaterThanOrEqualTo(duration1.inMilliseconds));
      expect(startup.getTimeTakenToStarted(), equals(duration2));
    });

    test('should handle time consistency across operations', () {
      final startup = StandardStartupTracker();
      
      final ready = startup.getReady();
      expect(ready.inMilliseconds, greaterThanOrEqualTo(0));
      
      final started = startup.started();
      expect(started.inMilliseconds, greaterThanOrEqualTo(ready.inMilliseconds));
      
      final finalReady = startup.getReady();
      expect(finalReady.inMilliseconds, greaterThanOrEqualTo(started.inMilliseconds));
    });

    test('should work as StartupTracker', () {
      StartupTracker startup = StandardStartupTracker();
      
      expect(startup.getAction(), equals('Started'));
      expect(startup.getProcessUptime(), isNull);
      
      final duration = startup.started();
      expect(duration, isA<Duration>());
      
      final ready = startup.getReady();
      expect(ready, isA<Duration>());
    });

    test('should handle very fast startup', () {
      final startup = StandardStartupTracker();
      final duration = startup.started();
      
      expect(duration.inMilliseconds, greaterThanOrEqualTo(0));
      expect(duration.inMilliseconds, lessThan(10)); // Should be very fast
    });

    test('should handle toString', () {
      final startup = StandardStartupTracker();
      
      expect(startup.toString(), contains('StandardStartupTracker'));
      expect(startup.toString(), contains('Started'));
    });
  });
}