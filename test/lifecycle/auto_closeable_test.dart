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

// test/auto_closeable_test.dart
import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

class TestAutoCloseable implements AutoCloseable {
  bool closed = false;
  
  @override
  void close() {
    closed = true;
  }
}

class TestAsyncAutoCloseable implements AutoCloseable {
  bool closed = false;
  
  @override
  Future<void> close() async {
    await Future.delayed(Duration(milliseconds: 10));
    closed = true;
  }
}

void main() {
  group('AutoCloseable', () {
    test('should be an abstract class', () {
      final closeable = TestAutoCloseable();
      expect(closeable, isA<AutoCloseable>());
    });
    
    test('should have close method', () {
      final closeable = TestAutoCloseable();
      expect(() => closeable.close(), returnsNormally);
    });
    
    test('close method should work synchronously', () {
      final closeable = TestAutoCloseable();
      expect(closeable.closed, isFalse);
      closeable.close();
      expect(closeable.closed, isTrue);
    });
    
    test('close method should work asynchronously', () async {
      final closeable = TestAsyncAutoCloseable();
      expect(closeable.closed, isFalse);
      await closeable.close();
      expect(closeable.closed, isTrue);
    });
    
    test('should be constructible', () {
      expect(() => TestAutoCloseable(), returnsNormally);
    });
  });
}