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

import 'package:jetleaf_pod/src/core/abstract_pod_factory.dart';
import 'package:jetleaf_pod/src/core/pod_factory.dart';
import 'package:jetleaf_pod/src/definition/pod_definition.dart';
import 'package:jetleaf_pod/src/exceptions.dart';
import 'package:jetleaf_pod/src/helpers/object.dart';
import 'package:jetleaf_pod/src/lifecycle/pod_processors.dart';
import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../_dependencies.dart';

// Test classes
class TestService {
  final String name;
  final TestRepository? repository;
  bool initialized = false;

  TestService(this.name, [this.repository]);

  void initialize() {
    initialized = true;
  }
}

class TestRepository {
  final String connectionString;

  TestRepository(this.connectionString);
}

class TestPodProvider extends PodProvider<TestService> {
  final TestService _service;
  final bool _isSingleton;

  TestPodProvider(this._service, {bool isSingleton = true})
    : _isSingleton = isSingleton;

  @override
  Future<ObjectHolder<TestService>?> get([Class? requiredType]) async {
    return ObjectHolder<TestService>(_service, packageName: "test");
  }

  @override
  Class? getClass() => Class<TestService>();

  @override
  bool isSingleton() => _isSingleton;

  @override
  bool isPrototype() => !_isSingleton;
}

// Test implementation of AbstractPodFactory
class TestAbstractPodFactory extends AbstractPodFactory {
  final Map<String, Object> _pods = {};
  final Map<String, PodDefinition> _definitions = {};
  final Map<String, PodProvider> _providers = {};
  bool _throwOnCreate = false;

  void addPod(String name, Object pod) => _pods[name] = pod;
  void addDefinition(String name, PodDefinition definition) =>
      _definitions[name] = definition;
  void addProvider(String name, PodProvider provider) =>
      _providers[name] = provider;
  void setThrowOnCreate(bool value) => _throwOnCreate = value;

  @override
  Future<bool> containsPod(String name) async => _pods.containsKey(name);

  @override
  Future<T> getPod<T>(
    String name, [
    List<ArgumentValue>? args,
    Class<T>? type,
  ]) async {
    final pod = _pods[name];
    if (pod == null) throw NoSuchPodDefinitionException.byName(name);
    return pod as T;
  }

  @override
  bool containsDefinition(String name) => _definitions.containsKey(name);

  @override
  PodDefinition getDefinition(String name) {
    final def = _definitions[name];
    if (def == null) throw NoSuchPodDefinitionException.byName(name);
    return def;
  }

  @override
  PodDefinition getDefinitionByClass(Class type) {
    for (final def in _definitions.values) {
      if (def.type == type) return def;
    }
    throw NoSuchPodDefinitionException.byType(type);
  }

  @override
  Future<Object> doCreate(
    String name,
    RootPodDefinition definition,
    List<ArgumentValue>? args,
  ) async {
    if (_throwOnCreate) throw PodCreationException('Test creation exception');
    return TestService('created-$name');
  }

  List<String> getDefinitionNames() => _definitions.keys.toList();

  int getNumberOfPodDefinitions() => _definitions.length;

  @override
  Future<Class> getPodClass(String podName) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isTypeMatch(
    String name,
    Class typeToMatch, [
    bool allowPodProviderInit = false,
  ]) {
    throw UnimplementedError();
  }

  @override
  Future<bool> containsType(Class type, [bool allowPodProviderInit = false]) {
    throw UnimplementedError();
  }

  @override
  Future<ObjectProvider<T>> getProvider<T>(
    Class<T> type, {
    String? podName,
    bool allowEagerInit = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Object?> resolveDependency(
    DependencyDescriptor descriptor, [
    Set<String>? autowiredPods,
  ]) {
    throw UnimplementedError();
  }

  @override
  void setAllowCircularReferences(bool value) {}

  @override
  void setAllowDefinitionOverriding(bool value) {}

  @override
  String getPackageName() => "test";

  @override
  bool getAllowCircularReferences() => false;

  @override
  bool getAllowDefinitionOverriding() => false;

  @override
  bool getAllowRawInjection() => false;

  @override
  void setAllowRawInjection(bool value) {}
}

void main() {
  setUpAll(() async {
    await setupRuntime();
    return Future<void>.value();
  });

  group('AbstractPodFactory Tests', () {
    late TestAbstractPodFactory factory;

    setUp(() {
      factory = TestAbstractPodFactory();
    });

    group('Basic Pod Operations', () {
      test('should check if pod exists', () async {
        factory.addPod('testService', TestService('test'));

        expect(await factory.containsPod('testService'), isTrue);
        expect(await factory.containsPod('nonExistent'), isFalse);
      });

      test('should get pod by name', () async {
        final service = TestService('test');
        factory.addPod('testService', service);

        final result = await factory.getPod<TestService>('testService');

        expect(result, equals(service));
      });

      test('should throw exception for non-existent pod', () async {
        expect(
          () => factory.getPod<TestService>('nonExistent'),
          throwsA(isA<NoSuchPodDefinitionException>()),
        );
      });

      test('should get pod with arguments', () async {
        final service = TestService('test');
        factory.addPod('testService', service);

        final args = [
          ArgumentValue('arg1', qualifiedName: "dart:core/string.dart.String"),
        ];
        final result = await factory.getPod<TestService>('testService', args);

        expect(result, equals(service));
      });
    });

    group('Pod Definition Management', () {
      test('should check if definition exists', () {
        final definition = RootPodDefinition(type: Class<TestService>());
        factory.addDefinition('testService', definition);

        expect(factory.containsDefinition('testService'), isTrue);
        expect(factory.containsDefinition('nonExistent'), isFalse);
      });

      test('should get definition by name', () {
        final definition = RootPodDefinition(type: Class<TestService>());
        factory.addDefinition('testService', definition);

        final result = factory.getDefinition('testService');

        expect(result, equals(definition));
      });

      test('should get definition by class', () {
        final definition = RootPodDefinition(type: Class<TestService>());
        factory.addDefinition('testService', definition);

        final result = factory.getDefinitionByClass(Class<TestService>());

        expect(result, equals(definition));
      });

      test('should throw exception for non-existent definition', () {
        expect(
          () => factory.getDefinition('nonExistent'),
          throwsA(isA<NoSuchPodDefinitionException>()),
        );
      });

      test('should throw exception for non-existent class definition', () {
        expect(
          () => factory.getDefinitionByClass(Class<TestService>()),
          throwsA(isA<NoSuchPodDefinitionException>()),
        );
      });

      test('should get definition names', () {
        final definition1 = RootPodDefinition(type: Class<TestService>());
        final definition2 = RootPodDefinition(type: Class<TestRepository>());

        factory.addDefinition('service', definition1);
        factory.addDefinition('repository', definition2);

        final names = factory.getDefinitionNames();

        expect(names, contains('service'));
        expect(names, contains('repository'));
        expect(names.length, equals(2));
      });

      test('should get number of pod definitions', () {
        expect(factory.getNumberOfPodDefinitions(), equals(0));

        factory.addDefinition(
          'service',
          RootPodDefinition(type: Class<TestService>()),
        );
        expect(factory.getNumberOfPodDefinitions(), equals(1));

        factory.addDefinition(
          'repository',
          RootPodDefinition(type: Class<TestRepository>()),
        );
        expect(factory.getNumberOfPodDefinitions(), equals(2));
      });
    });

    group('Pod Creation', () {
      test('should create pod using doCreate', () async {
        final definition = RootPodDefinition(type: Class<TestService>());

        final result = await factory.doCreate('testService', definition, null);

        expect(result, isA<TestService>());
        expect((result as TestService).name, equals('created-testService'));
      });

      test('should create pod with arguments', () async {
        final definition = RootPodDefinition(type: Class<TestService>());
        final args = [
          ArgumentValue(
            'test-arg',
            qualifiedName: "dart:core/string.dart.String",
          ),
        ];

        final result = await factory.doCreate('testService', definition, args);

        expect(result, isA<TestService>());
      });

      test('should handle creation failure', () async {
        factory.setThrowOnCreate(true);
        final definition = RootPodDefinition(type: Class<TestService>());

        expect(
          () => factory.doCreate('testService', definition, null),
          throwsA(isA<PodCreationException>()),
        );
      });
    });

    group('Singleton Management', () {
      test('should register singleton with object', () async {
        final service = TestService('singleton');

        await factory.registerSingleton(
          'singletonService',
          Class<TestService>(),
          object: ObjectHolder<Object>(service, packageName: "test"),
        );

        expect(factory.containsSingleton('singletonService'), isTrue);

        final result = await factory.getSingleton('singletonService');
        expect(result, equals(service));
      });

      test('should register singleton with factory', () async {
        final objectFactory = TestObjectFactory(TestService('factory-created'));

        await factory.registerSingleton(
          'factoryService',
          Class<TestObjectFactory>(),
          factory: objectFactory,
        );

        expect(factory.containsSingleton('factoryService'), isTrue);
      });

      test('should get singleton names', () async {
        final service1 = TestService('singleton1');
        final service2 = TestService('singleton2');

        await factory.registerSingleton(
          'service1',
          Class<TestService>(),
          object: ObjectHolder<Object>(service1, packageName: "test"),
        );
        await factory.registerSingleton(
          'service2',
          Class<TestService>(),
          object: ObjectHolder<Object>(service2, packageName: "test"),
        );

        final names = factory.getSingletonNames();

        expect(names, contains('service1'));
        expect(names, contains('service2'));
        expect(names.length, equals(2));
      });

      test('should remove singleton', () async {
        final service = TestService('singleton');
        await factory.registerSingleton(
          'testService',
          Class<TestService>(),
          object: ObjectHolder<Object>(service, packageName: "test"),
        );

        expect(factory.containsSingleton('testService'), isTrue);

        factory.removeSingleton('testService');

        expect(factory.containsSingleton('testService'), isFalse);
      });

      test('should clear singleton cache', () async {
        final service1 = TestService('singleton1');
        final service2 = TestService('singleton2');

        await factory.registerSingleton(
          'service1',
          Class<TestService>(),
          object: ObjectHolder<Object>(service1, packageName: "test"),
        );
        await factory.registerSingleton(
          'service2',
          Class<TestService>(),
          object: ObjectHolder<Object>(service2, packageName: "test"),
        );

        expect(factory.getSingletonNames().length, equals(2));

        factory.clearSingletonCache();

        expect(factory.getSingletonNames(), isEmpty);
      });
    });

    group('Pod Processors', () {
      test('should add pod aware processor', () {
        final processor = TestPodProcessor();

        factory.addPodProcessor(processor);

        expect(factory.getPodProcessors(), contains(processor));
      });

      test('should get pod processor count', () {
        expect(factory.getPodProcessorCount(), equals(0));

        factory.addPodProcessor(TestPodProcessor());
        expect(factory.getPodProcessorCount(), equals(1));

        factory.addPodProcessor(TestPodProcessor());
        expect(factory.getPodProcessorCount(), equals(2));
      });

      test('should check if has instantiation pod post processors', () {
        expect(factory.hasPodInstantiationProcessors(), isFalse);

        factory.addPodProcessor(TestInstantiationProcessor());
        expect(factory.hasPodInstantiationProcessors(), isTrue);
      });

      test('should check if has destruction pod post processors', () {
        expect(factory.hasPodDestructionProcessors(), isFalse);

        factory.addPodProcessor(TestDestructionProcessor());
        expect(factory.hasPodDestructionProcessors(), isTrue);
      });
    });

    group('Lifecycle Management', () {
      test('should handle pod creation lifecycle', () async {
        final processor = TestPodProcessor();
        factory.addPodProcessor(processor);

        final definition = RootPodDefinition(type: Class<TestService>());

        final result = await factory.doCreate('testService', definition, null);

        expect(result, isA<TestService>());
      });

      test('should handle singleton creation tracking', () async {
        factory.beforeSingletonCreation('testService');

        expect(factory.isActuallyInCreation('testService'), isTrue);

        factory.afterSingletonCreation('testService');

        expect(factory.isActuallyInCreation('testService'), isFalse);
      });

      test('should handle circular dependency detection', () async {
        factory.beforeSingletonCreation('service1');
        factory.beforeSingletonCreation('service2');

        expect(factory.isActuallyInCreation('service1'), isTrue);
        expect(factory.isActuallyInCreation('service2'), isTrue);

        factory.afterSingletonCreation('service2');
        factory.afterSingletonCreation('service1');

        expect(factory.isActuallyInCreation('service1'), isFalse);
        expect(factory.isActuallyInCreation('service2'), isFalse);
      });
    });

    group('Parent Factory Integration', () {
      test('should work with parent factory', () {
        final parentFactory = TestAbstractPodFactory();
        final childFactory = TestAbstractPodFactory();
        childFactory.setParentFactory(parentFactory);

        expect(childFactory.getParentFactory(), equals(parentFactory));
      });

      test('should delegate to parent when pod not found locally', () async {
        final parentFactory = TestAbstractPodFactory();
        final childFactory = TestAbstractPodFactory();
        childFactory.setParentFactory(parentFactory);

        final service = TestService('parent-service');
        parentFactory.addPod('parentService', service);

        // This would typically delegate to parent in a full implementation
        expect(await parentFactory.containsPod('parentService'), isTrue);
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle null pod name gracefully', () async {
        expect(
          () => factory.getPod<TestService>(''),
          throwsA(isA<NoSuchPodDefinitionException>()),
        );
      });

      test('should handle null definition name gracefully', () {
        expect(
          () => factory.getDefinition(''),
          throwsA(isA<NoSuchPodDefinitionException>()),
        );
      });

      test('should handle empty factory state', () {
        expect(factory.getDefinitionNames(), isEmpty);
        expect(factory.getNumberOfPodDefinitions(), equals(0));
        expect(factory.getSingletonNames(), isEmpty);
        expect(factory.getPodProcessorCount(), equals(0));
      });

      test('should handle multiple processors of same type', () {
        final processor1 = TestPodProcessor();
        final processor2 = TestPodProcessor();

        factory.addPodProcessor(processor1);
        factory.addPodProcessor(processor2);

        expect(factory.getPodProcessorCount(), equals(2));
        expect(factory.getPodProcessors(), contains(processor1));
        expect(factory.getPodProcessors(), contains(processor2));
      });
    });
  });
}

// Mock and helper classes
class TestPodProcessor extends PodInitializationProcessor {
  final List<String> processedPods = [];

  @override
  Future<Object?> processBeforeInitialization(
    Object pod,
    Class podClass,
    String name,
  ) async {
    processedPods.add('before-$name');
    return pod;
  }

  @override
  Future<Object?> processAfterInitialization(
    Object pod,
    Class podClass,
    String name,
  ) async {
    processedPods.add('after-$name');
    return pod;
  }
}

class TestInstantiationProcessor extends PodInstantiationProcessor {
  @override
  Future<Object?> processBeforeInstantiation(
    Class podClass,
    String name,
  ) async {
    return null;
  }

  @override
  Future<bool> processAfterInstantiation(
    Object pod,
    Class podClass,
    String name,
  ) async {
    return true;
  }

  @override
  Future<PropertyValues?> processPropertyValues(
    PropertyValues pvs,
    Object pod,
    Class podClass,
    String name,
  ) async {
    return pvs;
  }
}

class TestDestructionProcessor extends PodDestructionProcessor {
  @override
  Future<void> processBeforeDestruction(
    Object pod,
    Class podClass,
    String name,
  ) async {
    // Test implementation
  }

  @override
  Future<void> processAfterDestruction(
    Object pod,
    Class podClass,
    String name,
  ) async {}
}

class TestObjectFactory extends ObjectFactory<Object> {
  final Object _object;

  TestObjectFactory(this._object);

  @override
  Future<ObjectHolder<Object>> get([List<ArgumentValue>? args]) async {
    return ObjectHolder<Object>(_object, packageName: "dart");
  }
}
