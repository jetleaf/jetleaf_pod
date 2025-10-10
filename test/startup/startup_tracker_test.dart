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

// test/startup_tracker_test.dart
import 'package:jetleaf_pod/src/startup/startup.dart';
import 'package:test/test.dart';

void main() {
  group('StartupTracker', () {
    test('should create StandardStartupTracker instance', () {
      final startup = StartupTracker.create();
      expect(startup, isA<StandardStartupTracker>());
    });

    test('should get start time', () {
      final startup = StandardStartupTracker();
      final startTime = startup.getStartTime();
      
      expect(startTime, greaterThan(0));
      expect(startTime, lessThanOrEqualTo(DateTime.now().millisecondsSinceEpoch));
    });

    test('should return null for process uptime', () {
      final startup = StandardStartupTracker();
      expect(startup.getProcessUptime(), isNull);
    });

    test('should return correct action string', () {
      final startup = StandardStartupTracker();
      expect(startup.getAction(), equals('Started'));
    });

    test('started() should calculate time taken', () {
      final startup = StandardStartupTracker();
      
      // Wait a bit to ensure measurable time
      Future.delayed(Duration(milliseconds: 10), () {
        final duration = startup.started();
        
        expect(duration, isA<Duration>());
        expect(duration.inMilliseconds, greaterThanOrEqualTo(0));
      });
    });

    test('getTimeTakenToStarted() should return correct duration after started()', () {
      final startup = StandardStartupTracker();
      
      // Call started() first
      final startedDuration = startup.started();
      final retrievedDuration = startup.getTimeTakenToStarted();
      
      expect(retrievedDuration, equals(startedDuration));
    });

    test('getTimeTakenToStarted() should throw if started() not called', () {
      final startup = StandardStartupTracker();
      
      expect(() => startup.getTimeTakenToStarted(), throwsA(isA<Error>()));
    });

    test('getReady() should return current duration', () {
      final startup = StandardStartupTracker();
      final readyDuration = startup.getReady();
      
      expect(readyDuration, isA<Duration>());
      expect(readyDuration.inMilliseconds, greaterThanOrEqualTo(0));
      
      // Verify it increases over time
      final laterDuration = startup.getReady();
      expect(laterDuration.inMilliseconds, greaterThanOrEqualTo(readyDuration.inMilliseconds));
    });

    test('should handle multiple started() calls', () {
      final startup = StandardStartupTracker();
      
      final firstCall = startup.started();
      final secondCall = startup.started();
      
      expect(secondCall.inMilliseconds, greaterThanOrEqualTo(firstCall.inMilliseconds));
      expect(startup.getTimeTakenToStarted(), equals(secondCall));
    });

    test('should handle very short startup times', () {
      final startup = StandardStartupTracker();
      final duration = startup.started();
      
      expect(duration.inMilliseconds, greaterThanOrEqualTo(0));
      expect(duration.inMilliseconds, lessThan(100)); // Should be very fast
    });

    test('should handle time consistency', () {
      final startup = StandardStartupTracker();
      final startTime = startup.getStartTime();
      
      // Verify start time is reasonable (not in future, not too far in past)
      final now = DateTime.now().millisecondsSinceEpoch;
      expect(startTime, lessThanOrEqualTo(now));
      expect(now - startTime, lessThan(1000)); // Should be recent
    });

    test('should work with factory method', () {
      final startup = StartupTracker.create();
      
      expect(startup, isA<StandardStartupTracker>());
      expect(startup.getAction(), equals('Started'));
      expect(startup.getProcessUptime(), isNull);
      
      final duration = startup.started();
      expect(duration, isA<Duration>());
    });
  });
}