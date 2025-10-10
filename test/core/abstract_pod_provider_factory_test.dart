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

// ignore_for_file: invalid_use_of_protected_member

import 'package:jetleaf_pod/src/core/abstract_pod_provider_factory.dart';
import 'package:jetleaf_pod/src/exceptions.dart';
import 'package:jetleaf_pod/src/helpers/nullable_pod.dart';
import 'package:jetleaf_pod/src/helpers/object.dart';
import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../_dependencies.dart';

// Test classes
class TestService {
  final String name;
  bool initialized = false;
  
  TestService(this.name);
  
  void initialize() {
    initialized = true;
  }
}

class TestRepository {
  final String connectionString;
  
  TestRepository(this.connectionString);
}

// Test PodProvider implementations
class TestPodProvider extends PodProvider<TestService> {
  final TestService _service;
  final bool _isSingleton;
  bool _shouldThrow = false;
  bool _shouldReturnNull = false;
  int _callCount = 0;
  
  TestPodProvider(this._service, {bool isSingleton = true}) : _isSingleton = isSingleton;
  
  void setShouldThrow(bool value) => _shouldThrow = value;
  void setShouldReturnNull(bool value) => _shouldReturnNull = value;
  
  int get callCount => _callCount;
  
  @override
  Future<ObjectHolder<TestService>?> get([Class? requiredType]) async {
    _callCount++;
    
    if (_shouldThrow) {
      throw PodCreationException('Test provider exception');
    }
    
    if (_shouldReturnNull) {
      return null;
    }
    
    return ObjectHolder<TestService>(_service, packageName: "test");
  }
  
  @override
  Class? getClass() => Class<TestService>();
  
  @override
  bool isSingleton() => _isSingleton;
  
  @override
  bool isPrototype() => !_isSingleton;
}

class ThrowingPodProvider extends PodProvider<TestService> {
  final Exception _exception;
  
  ThrowingPodProvider(this._exception);
  
  @override
  Future<ObjectHolder<TestService>?> get([Class? requiredType]) async {
    throw _exception;
  }
  
  @override
  Class? getClass() => Class<TestService>();
  
  @override
  bool isSingleton() => true;
  
  @override
  bool isPrototype() => false;
}

class NotInitializedPodProvider extends PodProvider<TestService> {
  @override
  Future<ObjectHolder<TestService>?> get([Class? requiredType]) async {
    throw PodProviderNotInitializedException.withMessage('Provider not initialized');
  }
  
  @override
  Class? getClass() => Class<TestService>();
  
  @override
  bool isSingleton() => true;
  
  @override
  bool isPrototype() => false;
}

// Test implementation of AbstractPodProviderFactory
class TestPodProviderFactory extends AbstractPodProviderFactory {
  bool _shouldThrowInPostProcess = false;
  Object? _postProcessResult;
  final List<String> _postProcessedPods = [];
  
  void setShouldThrowInPostProcess(bool value) => _shouldThrowInPostProcess = value;
  void setPostProcessResult(Object? result) => _postProcessResult = result;
  
  List<String> get postProcessedPods => _postProcessedPods;
  
  @override
  Future<ObjectHolder<Object>> postProcessObjectFromPodProvider(ObjectHolder<Object> object, String name) async {
    _postProcessedPods.add(name);
    
    if (_shouldThrowInPostProcess) {
      throw Exception('Post-processing failed');
    }
    
    if (_postProcessResult != null) {
      return ObjectHolder<Object>(_postProcessResult!, packageName: "test");
    }
    
    return super.postProcessObjectFromPodProvider(object, name);
  }
}

class SimpleTestPodProviderFactory extends AbstractPodProviderFactory {
  @override
  Future<ObjectHolder<Object>> postProcessObjectFromPodProvider(ObjectHolder<Object> object, String name) async {
    return object;
  }
}

class MockSingletonPodProvider extends PodProvider {
  final Object value;
  int callCount = 0;

  MockSingletonPodProvider(this.value);

  @override
  Future<ObjectHolder<Object>> get([Class? type]) async {
    callCount++;
    return ObjectHolder<Object>(value, packageName: "test");
  }

  @override
  bool isSingleton() => true;

  @override
  Class? getClass() => null;
}

// Custom post-processing implementation
class CustomPostProcessFactory extends AbstractPodProviderFactory {
  final Map<String, int> postProcessCount = {};

  @override
  Future<ObjectHolder<Object>> postProcessObjectFromPodProvider(ObjectHolder<Object> object, String name) async {
    postProcessCount[name] = (postProcessCount[name] ?? 0) + 1;
    return ObjectHolder<Object>('processed_${object.getValue()}', packageName: object.getPackageName(), qualifiedName: object.getQualifiedName());
  }
}

class SimpleMockPodProvider extends PodProvider {
  final Object value;
  final bool? single;

  SimpleMockPodProvider(this.value, {this.single});

  @override
  Future<ObjectHolder<Object>> get([Class? type]) async {
    return ObjectHolder<Object>(value, packageName: "test");
  }

  @override
  bool isSingleton() => single ?? true;

  @override
  Class? getClass() => null;
}

class MockNonSingletonPodProvider extends PodProvider {
  final Object value;
  int callCount = 0;

  MockNonSingletonPodProvider(this.value);

  @override
  Future<ObjectHolder<Object>> get([Class? type]) async {
    callCount++;
    return ObjectHolder<Object>(value, packageName: "test");
  }

  @override
  bool isSingleton() => false;

  @override
  Class? getClass() => null;
}

class NullReturningPodProvider extends PodProvider {
  @override
  Future<ObjectHolder<Object>> get([Class? type]) async {
    return ObjectHolder<Object>(NullablePod(), packageName: "test");
  }

  @override
  bool isSingleton() => false;

  @override
  Class? getClass() => null;
}

void main() {
  setUpAll(() async {
    await setupRuntime();
    return Future<void>.value();
  });

  group('AbstractPodProviderFactory Tests', () {
    late TestPodProviderFactory factory;

    setUp(() {
      factory = TestPodProviderFactory();
    });

    group('Constructor and Initialization', () {
      test('should initialize with empty cache', () {
        expect(factory.getSingletonNames(), isEmpty);
      });

      test('should have POD_PROVIDER_CLASS constant', () {
        expect(factory.POD_PROVIDER_CLASS, isNotNull);
        expect(factory.POD_PROVIDER_CLASS.getName(), equals('PodProvider'));
      });
    });

    group('Singleton Management Override', () {
      test('should remove singleton and clear cache', () async {
        final service = TestService('test');
        await factory.registerSingleton('testService', Class<TestService>(), object: ObjectHolder<Object>(service, packageName: "test"));

        expect(factory.containsSingleton('testService'), isTrue);

        factory.removeSingleton('testService');

        expect(factory.containsSingleton('testService'), isFalse);
      });

      test('should clear singleton cache', () async {
        final service1 = TestService('service1');
        final service2 = TestService('service2');

        await factory.registerSingleton('service1', Class<TestService>(), object: ObjectHolder<Object>(service1, packageName: "test"));
        await factory.registerSingleton('service2', Class<TestService>(), object: ObjectHolder<Object>(service2, packageName: "test"));

        expect(factory.getSingletonNames().length, equals(2));

        factory.clearSingletonCache();

        expect(factory.getSingletonNames(), isEmpty);
      });

      test('should register singleton with object', () async {
        final service = TestService('test');

        await factory.registerSingleton('testService', Class<TestService>(), object: ObjectHolder<Object>(service, packageName: "test"));

        expect(factory.containsSingleton('testService'), isTrue);
      });

      test('should register singleton with factory', () async {
        final objectFactory = TestObjectFactory(TestService('factory-created'));

        await factory.registerSingleton('testService', Class<TestObjectFactory>(), factory: objectFactory);

        expect(factory.containsSingleton('testService'), isTrue);
      });
    });

    group('getNullableProviderObject', () {
      test('should return cached object when exists', () async {
        final service = TestService('cached');
        await factory.registerSingleton('testService', Class<TestService>(), object: ObjectHolder<Object>(service, packageName: "test"));

        final result = factory.getNullableProviderObject('testService');

        expect(result, isNotNull);
        expect(result!.getValue(), equals(service));
      });

      test('should return null when object does not exist', () {
        final result = factory.getNullableProviderObject('nonExistent');

        expect(result, isNull);
      });
    });

    group('getProviderObject', () {
      test('should return cached object for singleton provider (no provider call)', () async {
        final service = TestService('cached');
        final provider = TestPodProvider(service, isSingleton: true);

        // Pre-cache the object (provider should NOT be called)
        await factory.registerSingleton('testService', Class<TestService>(), object: ObjectHolder<Object>(service, packageName: "test"));

        final result = await factory.getProviderObject(provider, Class<TestService>(), 'testService', false);

        expect(result.getValue(), equals(service));
        expect(provider.callCount, equals(0)); // Should not call provider
      });

      test('should call provider when not registered as singleton (no cache)', () async {
        final service = TestService('from-provider');
        final provider = TestPodProvider(service, isSingleton: true);

        // DO NOT register the singleton name: this ensures "containsSingleton" is false
        final result = await factory.getProviderObject(provider, Class<TestService>(), 'testService', false);

        expect(result.getValue(), equals(service));
        expect(provider.callCount, equals(1));
      });

      test('should apply post-processing when requested (cached present)', () async {
        final service = TestService('original');
        final processedService = TestService('processed');
        final provider = TestPodProvider(service, isSingleton: true);

        // Pre-cache the raw object
        await factory.registerSingleton('testService', Class<TestService>(), object: ObjectHolder<Object>(service, packageName: "test"));

        factory.setPostProcessResult(processedService);

        final result = await factory.getProviderObject(provider, Class<TestService>(), 'testService', true);

        expect(result.getValue(), equals(processedService));
        expect(factory.postProcessedPods, contains('testService'));
        expect(provider.callCount, equals(0)); // provider never called because cache used
      });

      test('should skip post-processing when currently creating singleton (cached present)', () async {
        final service = TestService('creating');
        final provider = TestPodProvider(service, isSingleton: true);

        // Pre-cache object so cached path is used
        await factory.registerSingleton('testService', Class<TestService>(), object: ObjectHolder<Object>(service, packageName: "test"));

        // Simulate currently creating
        factory.beforeSingletonCreation('testService');

        try {
          final result = await factory.getProviderObject(provider, Class<TestService>(), 'testService', true);

          expect(result.getValue(), equals(service));
          expect(factory.postProcessedPods, isEmpty); // Should skip post-processing when creating
        } finally {
          factory.afterSingletonCreation('testService');
        }
      });

      test('should handle non-singleton providers', () async {
        final service = TestService('prototype');
        final provider = TestPodProvider(service, isSingleton: false);

        final result = await factory.getProviderObject(provider, Class<TestService>(), 'testService', false);

        expect(result.getValue(), equals(service));
        expect(provider.callCount, equals(1));
      });

      test('should handle concurrent access to cached objects', () async {
        final service = TestService('concurrent');
        final provider = TestPodProvider(service, isSingleton: true);

        // Pre-cache the object
        await factory.registerSingleton('testService', Class<TestService>(), object: ObjectHolder<Object>(service, packageName: "test"));

        // Simulate concurrent access
        final futures = List.generate(5, (_) => factory.getProviderObject(provider, Class<TestService>(), 'testService', false));

        final results = await Future.wait(futures);

        for (final result in results) {
          expect(result.getValue(), equals(service));
        }
        expect(provider.callCount, equals(0)); // Should use cached version
      });

      test('should handle post-processing failure', () async {
        final service = TestService('test');
        final provider = TestPodProvider(service, isSingleton: true);

        // Pre-cache to hit the cached branch
        await factory.registerSingleton('testService', Class<TestService>(), object: ObjectHolder<Object>(service, packageName: "test"));

        factory.setShouldThrowInPostProcess(true);

        await expectLater(
          factory.getProviderObject(provider, Class<TestService>(), 'testService', true),
          throwsA(isA<PodCreationException>()),
        );
      });
    });

    group('_doGet', () {
      test('should get object from provider successfully', () async {
        final service = TestService('success');
        final provider = TestPodProvider(service);

        final result = await factory.getProviderObject(provider, Class<TestService>(), 'testService', false);

        expect(result.getValue(), equals(service));
      });

      test('should handle PodProviderNotInitializedException', () async {
        final provider = NotInitializedPodProvider();

        await expectLater(
          factory.getProviderObject(provider, Class<TestService>(), 'testService', false),
          throwsA(isA<PodCurrentlyInCreationException>()),
        );
      });

      test('should handle general provider exceptions', () async {
        final provider = ThrowingPodProvider(Exception('General error'));

        await expectLater(
          factory.getProviderObject(provider, Class<TestService>(), 'testService', false),
          throwsA(isA<PodCreationException>()),
        );
      });

      test('should handle null return from provider (non-singleton)', () async {
        final provider = TestPodProvider(TestService('test'), isSingleton: false);
        provider.setShouldReturnNull(true);

        final result = await factory.getProviderObject(provider, Class<TestService>(), 'testService', false);

        expect(result.getValue(), isA<NullablePod>());
      });

      test('should handle null return during singleton creation', () async {
        final provider = TestPodProvider(TestService('test'));
        provider.setShouldReturnNull(true);

        // Simulate currently creating singleton
        factory.beforeSingletonCreation('testService');

        try {
          await expectLater(
            factory.getProviderObject(provider, Class<TestService>(), 'testService', false),
            throwsA(isA<PodCurrentlyInCreationException>()),
          );
        } finally {
          factory.afterSingletonCreation('testService');
        }
      });
    });

    group('postProcessObjectFromPodProvider', () {
      test('should return object unchanged by default', () async {
        final service = TestService('unchanged');
        final holder = ObjectHolder<Object>(service, packageName: "test");

        final result = await factory.postProcessObjectFromPodProvider(holder, 'testService');

        expect(result.getValue(), equals(service));
        expect(result.getPackageName(), equals(holder.getPackageName()));
        expect(result.getQualifiedName(), equals(holder.getQualifiedName()));
      });

      test('should be overridable by subclasses', () async {
        final service = TestService('original');
        final processedService = TestService('processed');
        final holder = ObjectHolder<Object>(service, packageName: "test");

        factory.setPostProcessResult(processedService);

        final result = await factory.postProcessObjectFromPodProvider(holder, 'testService');

        expect(result.getValue(), equals(processedService));
      });
    });

    group('Complex Scenarios', () {
      test('should handle multiple providers with different lifecycle', () async {
        final singletonService = TestService('singleton');
        final prototypeService = TestService('prototype');

        final singletonProvider = TestPodProvider(singletonService, isSingleton: true);
        final prototypeProvider = TestPodProvider(prototypeService, isSingleton: false);

        // Pre-cache the singleton (provider should not be called)
        await factory.registerSingleton('singletonService', Class<TestService>(), object: ObjectHolder<Object>(singletonService, packageName: "test"));

        // Get singleton multiple times
        final singleton1 = await factory.getProviderObject(singletonProvider, Class<TestService>(), 'singletonService', false);
        final singleton2 = await factory.getProviderObject(singletonProvider, Class<TestService>(), 'singletonService', false);

        // Get prototype multiple times (no caching)
        final prototype1 = await factory.getProviderObject(prototypeProvider, Class<TestService>(), 'prototypeService', false);
        final prototype2 = await factory.getProviderObject(prototypeProvider, Class<TestService>(), 'prototypeService', false);

        expect(singleton1.getValue(), equals(singleton2.getValue()));
        expect(singletonProvider.callCount, equals(0)); // Called 0 times because instance was pre-cached

        expect(prototype1.getValue(), equals(prototype2.getValue()));
        expect(prototypeProvider.callCount, equals(2)); // Called twice for prototype
      });

      test('should handle post-processing with caching correctly (adjusted semantics)', () async {
        final service = TestService('original');
        final processedService = TestService('processed');
        final provider = TestPodProvider(service, isSingleton: true);

        // Pre-cache the raw object (this means provider is not invoked during get)
        await factory.registerSingleton('testService', Class<TestService>(), object: ObjectHolder<Object>(service, packageName: "test"));
        factory.setPostProcessResult(processedService);

        // First call with post-processing should return processed view
        final result1 = await factory.getProviderObject(provider, Class<TestService>(), 'testService', true);
        expect(result1.getValue(), equals(processedService));

        // Second call without post-processing returns the raw cached object
        final result2 = await factory.getProviderObject(provider, Class<TestService>(), 'testService', false);
        expect(result2.getValue(), equals(service));

        // Third call with post-processing returns processed view again
        final result3 = await factory.getProviderObject(provider, Class<TestService>(), 'testService', true);
        expect(result3.getValue(), equals(processedService));

        // Provider not called because the object was pre-cached
        expect(provider.callCount, equals(0));
      });

      test('should handle edge case with null provider result and post-processing (non-singleton)', () async {
        final provider = TestPodProvider(TestService('test'), isSingleton: false);
        provider.setShouldReturnNull(true);

        final result = await factory.getProviderObject(provider, Class<TestService>(), 'testService', true);

        expect(result.getValue(), isA<NullablePod>());
      });

      test('should maintain thread safety during concurrent operations (cached singleton)', () async {
        final service = TestService('concurrent');
        final provider = TestPodProvider(service, isSingleton: true);

        // Pre-cache the singleton so provider is not called during concurrent gets
        await factory.registerSingleton('testService', Class<TestService>(), object: ObjectHolder<Object>(service, packageName: "test"));

        // Simulate concurrent access with different post-processing requirements
        final futures = <Future<ObjectHolder<Object>>>[];

        for (int i = 0; i < 10; i++) {
          futures.add(factory.getProviderObject(provider, Class<TestService>(), 'testService', i % 2 == 0));
        }

        final results = await Future.wait(futures);

        // All results should be valid
        for (final result in results) {
          expect(result.getValue(), isNotNull);
        }

        // Provider should be called only 0 times because we pre-cached
        expect(provider.callCount, equals(0));
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle provider that throws PodException', () async {
        final provider = ThrowingPodProvider(PodException('Test pod exception'));

        await expectLater(
          factory.getProviderObject(provider, Class<TestService>(), 'testService', false),
          throwsA(isA<PodCreationException>()),
        );
      });

      test('should handle provider that throws RuntimeException', () async {
        final provider = ThrowingPodProvider(RuntimeException('Test runtime exception'));

        await expectLater(
          factory.getProviderObject(provider, Class<TestService>(), 'testService', false),
          throwsA(isA<PodCreationException>()),
        );
      });

      test('should handle provider that throws general Exception', () async {
        final provider = ThrowingPodProvider(Exception('Test general exception'));

        await expectLater(
          factory.getProviderObject(provider, Class<TestService>(), 'testService', false),
          throwsA(isA<PodCreationException>()),
        );
      });

      test('should handle empty provider name', () async {
        final service = TestService('test');
        final provider = TestPodProvider(service);

        final result = await factory.getProviderObject(provider, Class<TestService>(), '', false);

        expect(result.getValue(), equals(service));
      });

      test('should handle null type parameter', () async {
        final service = TestService('test');
        final provider = TestPodProvider(service);

        final result = await factory.getProviderObject(provider, null, 'testService', false);

        expect(result.getValue(), equals(service));
      });
    });
  });

  group('AbstractPodProviderFactory Basic Tests - SimpleTestPodProviderFactory', () {
    late SimpleTestPodProviderFactory factory;

    setUp(() {
      factory = SimpleTestPodProviderFactory();
    });

    tearDown(() {
      factory.clearSingletonCache();
    });

    test('should initialize with empty cache', () {
      expect(factory.getNullableProviderObject('test'), isNull);
    });

    test('removeSingleton should remove from both registry and cache', () {
      factory.registerSingleton('test', Class<Object>(), object: ObjectHolder<Object>(Object(), packageName: "test"));
      factory.removeSingleton('test');
      
      expect(factory.containsSingleton('test'), isFalse);
      expect(factory.getNullableProviderObject('test'), isNull);
    });

    test('clearSingletonCache should clear both registry and cache', () {
      factory.registerSingleton('test1', Class<Object>(), object: ObjectHolder<Object>(Object(), packageName: "test"));
      factory.registerSingleton('test2', Class<Object>(), object: ObjectHolder<Object>(Object(), packageName: "test"));
      
      factory.clearSingletonCache();
      
      expect(factory.containsSingleton('test1'), isFalse);
      expect(factory.containsSingleton('test2'), isFalse);
    });

    test('getNullableCachedProviderObject returns cached object', () async {
      final testObject = ObjectHolder<Object>('test_value', packageName: "test");
      await factory.registerSingleton('test', Class<String>(), object: testObject);
      
      expect(factory.getNullableProviderObject('test'), testObject);
    });

    test('getNullableCachedProviderObject returns null for non-existent object', () {
      expect(factory.getNullableProviderObject('non_existent'), isNull);
    });
  });

  group('AbstractPodProviderFactory Singleton Tests', () {
    late SimpleTestPodProviderFactory factory;
    late MockSingletonPodProvider singletonProvider;

    setUp(() {
      factory = SimpleTestPodProviderFactory();
      singletonProvider = MockSingletonPodProvider('singleton_value');
    });

    tearDown(() {
      factory.clearSingletonCache();
    });

    test('should cache singleton provider objects', () async {
      factory.registerSingleton('test_singleton', Class<String>(), object: ObjectHolder<Object>('singleton_value', packageName: "test"));
      
      final result1 = await factory.getProviderObject(
        singletonProvider, null, 'test_singleton', true
      );
      
      final result2 = await factory.getProviderObject(
        singletonProvider, null, 'test_singleton', true
      );
      
      expect(result1.getValue(), 'singleton_value');
      expect(result2.getValue(), 'singleton_value');
      expect(singletonProvider.callCount, 1); // Should be called only once
    });

    test('should return cached object for singleton provider', () async {
      await factory.registerSingleton('test_singleton', Class<String>(), object: ObjectHolder<Object>('cached_value', packageName: "test"));
      
      final result = await factory.getProviderObject(
        singletonProvider, null, 'test_singleton', true
      );
      
      expect(result.getValue(), 'cached_value');
      expect(singletonProvider.callCount, 0); // Should not call provider
    });

    test('should handle singleton not in registry', () async {
      // Provider claims to be singleton but not registered as one
      final result = await factory.getProviderObject(
        singletonProvider, null, 'not_registered', true
      );
      
      expect(result.getValue(), 'singleton_value');
      expect(singletonProvider.callCount, 1);
    });
  });

  group('AbstractPodProviderFactory Post-Processing Tests', () {
    late CustomPostProcessFactory factory;
    late SimpleMockPodProvider provider;

    setUp(() {
      factory = CustomPostProcessFactory();
      provider = SimpleMockPodProvider('original_value');
    });

    tearDown(() {
      factory.clearSingletonCache();
    });

    test('should apply post-processing to singleton objects', () async {
      await factory.registerSingleton('test', Class<String>(), object: ObjectHolder<Object>('original_value', packageName: "test"));
      
      final result = await factory.getProviderObject(provider, null, 'test', true);
      
      expect(result.getValue(), 'processed_original_value');
      expect(factory.postProcessCount['test'], 1);
    });

    test('should apply post-processing to non-singleton objects', () async {
      final nonSingletonProvider = SimpleMockPodProvider('non_singleton_value', single: false);
      
      final result = await factory.getProviderObject(
        nonSingletonProvider, null, 'test_non_singleton', true
      );
      
      expect(result.getValue(), 'processed_non_singleton_value');
      expect(factory.postProcessCount['test_non_singleton'], 1);
    });

    test('should skip post-processing when shouldPostProcess is false', () async {
      await factory.registerSingleton('test', Class<String>(), object: ObjectHolder<Object>('original_value', packageName: "test"));
      
      final result = await factory.getProviderObject(provider, null, 'test', false);
      
      expect(result.getValue(), 'original_value');
      expect(factory.postProcessCount['test'], isNull);
    });

    test('should handle post-processing exceptions', () async {
      final throwingFactory = _ThrowingPostProcessFactory();
      await throwingFactory.registerSingleton('test', Class<String>(), object: ObjectHolder<Object>('original_value', packageName: "test"));
      
      expect(
        () => throwingFactory.getProviderObject(provider, null, 'test', true),
        throwsA(isA<PodCreationException>())
      );
    });
  });

  group('AbstractPodProviderFactory Non-Singleton Tests', () {
    late SimpleTestPodProviderFactory factory;
    late MockNonSingletonPodProvider nonSingletonProvider;

    setUp(() {
      factory = SimpleTestPodProviderFactory();
      nonSingletonProvider = MockNonSingletonPodProvider('non_singleton_value');
    });

    test('should not cache non-singleton provider objects', () async {
      final result1 = await factory.getProviderObject(
        nonSingletonProvider, null, 'test_non_singleton', true
      );
      
      final result2 = await factory.getProviderObject(
        nonSingletonProvider, null, 'test_non_singleton', true
      );
      
      expect(result1.getValue(), 'non_singleton_value');
      expect(result2.getValue(), 'non_singleton_value');
      expect(nonSingletonProvider.callCount, 2); // Should be called each time
    });

    test('should handle non-singleton with post-processing', () async {
      final result = await factory.getProviderObject(
        nonSingletonProvider, null, 'test_non_singleton', true
      );
      
      expect(result.getValue(), 'non_singleton_value');
      expect(nonSingletonProvider.callCount, 1);
    });

    test('should handle non-singleton without post-processing', () async {
      final result = await factory.getProviderObject(
        nonSingletonProvider, null, 'test_non_singleton', false
      );
      
      expect(result.getValue(), 'non_singleton_value');
      expect(nonSingletonProvider.callCount, 1);
    });
  });

  group('AbstractPodProviderFactory Error Handling Tests', () {
    late SimpleTestPodProviderFactory factory;

    setUp(() {
      factory = SimpleTestPodProviderFactory();
    });

    test('should handle PodProviderNotInitializedException', () async {
      final provider = ThrowingPodProvider(PodProviderNotInitializedException());
      
      expect(
        () => factory.getProviderObject(provider, null, 'test', true),
        throwsA(isA<PodCurrentlyInCreationException>())
      );
    });

    test('should handle generic exceptions from provider', () async {
      final provider = ThrowingPodProvider(Exception('Test exception'));
      
      expect(
        () => factory.getProviderObject(provider, null, 'test', true),
        throwsA(isA<PodCreationException>())
      );
    });

    test('should handle null returns from provider', () async {
      final provider = NullReturningPodProvider();
      
      final result = await factory.getProviderObject(provider, null, 'test', true);
      
      expect(result.getValue(), isA<NullablePod>());
    });

    test('should handle required type parameter', () async {
      final provider = ThrowingPodProvider(Exception('Test'));
      
      expect(
        () => factory.getProviderObject(provider, Class<Object>(null, 'test'), 'test', true),
        throwsA(isA<PodCreationException>())
      );
    });
  });
}

/// Helper classes for testing
class TestObjectFactory extends ObjectFactory<Object> {
  final Object _object;

  TestObjectFactory(this._object);

  @override
  Future<ObjectHolder<Object>> get([List<ArgumentValue>? args]) async {
    return ObjectHolder<Object>(_object, packageName: "dart");
  }
}

class _ThrowingPostProcessFactory extends AbstractPodProviderFactory {
  @override
  Future<ObjectHolder<Object>> postProcessObjectFromPodProvider(ObjectHolder<Object> object, String name) async {
    throw Exception('Post-processing failed');
  }
}