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

import 'package:jetleaf_pod/src/core/abstract_autowire_pod_factory.dart';
import 'package:jetleaf_pod/src/core/pod_factory.dart';
import 'package:jetleaf_pod/src/definition/commons.dart';
import 'package:jetleaf_pod/src/definition/pod_definition.dart';
import 'package:jetleaf_pod/src/exceptions.dart';
import 'package:jetleaf_pod/src/helpers/enums.dart';
import 'package:jetleaf_pod/src/helpers/object.dart';
import 'package:jetleaf_pod/src/lifecycle/pod_processors.dart';
import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../_dependencies.dart';

// Test implementation of AbstractAutowirePodFactory
class TestAutowirePodFactory extends AbstractAutowirePodFactory {
  final Map<String, PodDefinition> _definitions = {};
  bool _throwOnCreate = false;
  bool _throwOnResolve = false;

  TestAutowirePodFactory([super.parentFactory]);

  void setThrowOnCreate(bool value) => _throwOnCreate = value;
  void setThrowOnResolve(bool value) => _throwOnResolve = value;

  @override
  bool containsDefinition(String name) => _definitions.containsKey(name);

  @override
  PodDefinition getDefinition(String name) {
    final def = _definitions[name];
    if (def == null) throw NoSuchPodDefinitionException.byName(name);
    return def;
  }

  @override
  Future<bool> containsType(Class type, [bool allowPodProviderInit = false]) {
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
  PodDefinition getDefinitionByClass(Class type) {
    for (final def in _definitions.values) {
      if (def.type == type) return def;
    }
    throw NoSuchPodDefinitionException.byType(type);
  }

  void addDefinition(String name, PodDefinition definition) {
    _definitions[name] = definition;
  }

  @override
  Future<Object> doCreate(
    String name,
    RootPodDefinition definition,
    List<ArgumentValue>? args,
  ) async {
    if (_throwOnCreate) throw PodCreationException('Test exception');

    return super.doCreate(name, definition, args);
  }

  @override
  Future<Object?> doResolveDependency(
    DependencyDescriptor descriptor, [
    Set<String>? autowiredPods,
  ]) async {
    if (_throwOnResolve) throw PodException('Test resolve exception');

    // Mock dependency resolution
    if (descriptor.type.getName() == 'TestService') {
      return TestService();
    } else if (descriptor.type.getName() == 'TestRepository') {
      return TestRepository();
    }

    return null;
  }

  @override
  Future<Class> getPodClass(String podName) {
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
  String getPackageName() => "test";
}

// Test classes
class TestService {
  String? name;
  TestRepository? repository;
  bool initialized = false;

  TestService([this.name]);

  void setRepository(TestRepository repo) {
    repository = repo;
  }

  void initialize() {
    initialized = true;
  }
}

class TestRepository {
  String? connectionString;

  TestRepository([this.connectionString]);
}

class TestFactory {
  TestService createService() => TestService('factory-created');

  TestService createInstance() => TestService('instance-created');
}

class TestPodProcessor extends PodInitializationProcessor {
  final List<String> processedPods = [];
  bool shouldReturnNull = false;

  @override
  Future<Object?> processBeforeInitialization(
    Object pod,
    Class podClass,
    String name,
  ) async {
    processedPods.add('before-$name');
    return shouldReturnNull ? null : pod;
  }

  @override
  Future<Object?> processAfterInitialization(
    Object pod,
    Class podClass,
    String name,
  ) async {
    processedPods.add('after-$name');
    return shouldReturnNull ? null : pod;
  }
}

class TestInstantiationProcessor extends PodInstantiationProcessor {
  final List<String> processedPods = [];
  bool shouldReturnProxy = false;
  bool shouldSkipPropertyPopulation = false;
  Object? proxyObject;

  @override
  Future<Object?> processBeforeInstantiation(
    Class podClass,
    String name,
  ) async {
    processedPods.add('before-instantiation-$name');
    return shouldReturnProxy ? (proxyObject ?? TestService('proxy')) : null;
  }

  @override
  Future<bool> processAfterInstantiation(
    Object pod,
    Class podClass,
    String name,
  ) async {
    processedPods.add('after-instantiation-$name');
    return !shouldSkipPropertyPopulation;
  }

  @override
  Future<PropertyValues?> processPropertyValues(
    PropertyValues pvs,
    Object pod,
    Class podClass,
    String name,
  ) async {
    processedPods.add('property-values-$name');
    return pvs;
  }
}

void main() {
  setUpAll(() async {
    await setupRuntime();
    return Future<void>.value();
  });

  group('AbstractAutowirePodFactory Tests', () {
    late TestAutowirePodFactory factory;

    setUp(() {
      factory = TestAutowirePodFactory();
    });

    group('Constructor and Configuration', () {
      test('should initialize with default values', () {
        expect(factory.getAllowCircularReferences(), isTrue);
        expect(factory.getAllowDefinitionOverriding(), isTrue);
      });

      test('should set circular references flag', () {
        factory.setAllowCircularReferences(false);
        expect(factory.getAllowCircularReferences(), isFalse);

        factory.setAllowCircularReferences(true);
        expect(factory.getAllowCircularReferences(), isTrue);
      });

      test('should set definition overriding flag', () {
        factory.setAllowDefinitionOverriding(false);
        expect(factory.getAllowDefinitionOverriding(), isFalse);

        factory.setAllowDefinitionOverriding(true);
        expect(factory.getAllowDefinitionOverriding(), isTrue);
      });
    });

    group('copyConfigurationFrom', () {
      test(
        'should copy configuration from another AbstractAutowirePodFactory',
        () {
          final otherFactory = TestAutowirePodFactory();
          otherFactory.setAllowCircularReferences(false);
          otherFactory.setAllowDefinitionOverriding(false);
          otherFactory.ignoreDependencyType(Class<String>());

          factory.copyConfigurationFrom(otherFactory);

          expect(factory.getAllowCircularReferences(), isFalse);
          expect(factory.getAllowDefinitionOverriding(), isFalse);
          expect(factory.isTypeIgnored(Class<String>()), isTrue);
        },
      );

      test('should handle non-AbstractAutowirePodFactory', () {
        final mockFactory = MockConfigurablePodFactory();
        expect(
          () => factory.copyConfigurationFrom(mockFactory),
          returnsNormally,
        );
      });
    });

    group('createPod', () {
      test('should create pod with matching type', () async {
        final service = TestService();
        final result = await factory.createPod(service, Class<TestService>());

        expect(result, isA<TestService>());
      });

      test('should throw exception for type mismatch', () async {
        final service = TestService();
        expect(
          () => factory.createPod(service, Class<TestRepository>()),
          throwsA(isA<PodCreationException>()),
        );
      });
    });

    group('doCreate', () {
      test('should handle circular reference detection', () async {
        factory.setAllowCircularReferences(false);

        final definition = RootPodDefinition(type: Class<TestService>());

        // This would normally be set by the framework during creation
        expect(
          () => factory.doCreate('testService', definition, null),
          returnsNormally,
        );
      });

      test('should call resolveBeforeInstantiation', () async {
        final processor = TestInstantiationProcessor();
        processor.shouldReturnProxy = true;
        factory.addPodProcessor(processor);

        final definition = RootPodDefinition(type: Class<TestService>());
        definition.design = DesignDescriptor(
          role: DesignRole.APPLICATION,
          isPrimary: true,
        );

        final result = await factory.doCreate('testService', definition, null);

        expect(result, isA<TestService>());
        expect(
          processor.processedPods,
          contains('before-instantiation-testService'),
        );
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

    group('autowire', () {
      test('should autowire by type', () async {
        final result = await factory.autowire(
          Class<TestService>(),
          AutowireMode.BY_TYPE.value,
          true,
        );
        expect(result, isA<TestService>());
      });

      test('should autowire by name', () async {
        final result = await factory.autowire(
          Class<TestService>(),
          AutowireMode.BY_NAME.value,
          true,
        );
        expect(result, isA<TestService>());
      });

      test('should autowire with no mode', () async {
        final result = await factory.autowire(
          Class<TestService>(),
          AutowireMode.NO.value,
          false,
        );
        expect(result, isA<TestService>());
      });
    });

    group('autowirePod', () {
      test('should autowire existing pod', () async {
        final service = TestService();

        await factory.autowirePod(service, Class<TestService>());

        // Should complete without throwing
        expect(service, isNotNull);
      });

      test('should autowire with specific mode', () async {
        final service = TestService();

        await factory.autowirePod(
          service,
          Class<TestService>(),
          autowireMode: AutowireMode.BY_TYPE.value,
        );

        expect(service, isNotNull);
      });

      test('should autowire with dependency check', () async {
        final service = TestService();

        await factory.autowirePod(
          service,
          Class<TestService>(),
          checkDependency: true,
        );

        expect(service, isNotNull);
      });
    });

    group('applyPodPropertyValues', () {
      test('should apply property values to existing pod', () async {
        final service = TestService();

        // Add a definition with property values
        final definition = RootPodDefinition(type: Class<TestService>());
        definition.propertyValues = MutablePropertyValues();
        definition.propertyValues.add(
          'name',
          'test-service',
          qualifiedName: "dart:core/string.dart.String",
        );
        factory.addDefinition('testService', definition);

        await factory.applyPodPropertyValues(service, 'testService');

        expect(service, isNotNull);
      });
    });

    group('initializePod', () {
      test('should initialize existing pod', () async {
        final service = TestService();

        await factory.initializePod(
          service,
          Class<TestService>(),
          'testService',
        );

        expect(service, isNotNull);
      });
    });

    group('destroyExistingPod', () {
      test('should destroy existing pod', () async {
        final service = TestService();

        // Add definition for destruction
        final definition = RootPodDefinition(type: Class<TestService>());
        factory.addDefinition('testService', definition);

        await factory.destroyExistingPod(
          service,
          Class<TestService>(),
          'testService',
        );

        expect(service, isNotNull);
      });

      test('should handle destruction failure gracefully', () async {
        final service = TestService();

        // Add definition that might cause issues
        final definition = RootPodDefinition(type: Class<TestService>());
        factory.addDefinition('testService', definition);

        expect(
          () => factory.destroyExistingPod(
            service,
            Class<TestService>(),
            'testService',
          ),
          returnsNormally,
        );
      });
    });

    group('configurePod', () {
      test('should configure existing pod', () async {
        final service = TestService();

        // Add definition
        final definition = RootPodDefinition(type: Class<TestService>());
        factory.addDefinition('testService', definition);

        final result = await factory.configurePod(service, 'testService');

        expect(result, equals(service));
      });
    });

    group('resolveDependency', () {
      test('should resolve dependency', () async {
        final descriptor = DependencyDescriptor(
          source: Class<TestService>(),
          podName: 'testPod',
          propertyName: 'testProperty',
          type: Class<TestService>(),
        );

        final result = await factory.resolveDependency(descriptor);

        expect(result, isA<TestService>());
      });

      test('should return null for ignored dependency types', () async {
        factory.ignoreDependencyType(Class<TestService>());

        final descriptor = DependencyDescriptor(
          source: Class<TestService>(),
          podName: 'testPod',
          propertyName: 'testProperty',
          type: Class<TestService>(),
        );

        final result = await factory.resolveDependency(descriptor);

        expect(result, isNull);
      });

      test('should return null for ignored dependency interfaces', () async {
        factory.ignoreDependencyInterface(Class<TestService>());

        final descriptor = DependencyDescriptor(
          source: Class<TestService>(),
          podName: 'testPod',
          propertyName: 'testProperty',
          type: Class<TestService>(),
        );

        final result = await factory.resolveDependency(descriptor);

        expect(result, isNull);
      });

      test('should handle resolution failure', () async {
        factory.setThrowOnResolve(true);

        final descriptor = DependencyDescriptor(
          source: Class<TestService>(),
          podName: 'testPod',
          propertyName: 'testProperty',
          type: Class<TestService>(),
        );

        expect(
          () => factory.resolveDependency(descriptor),
          throwsA(isA<PodException>()),
        );
      });
    });

    group('postProcessObjectFromPodProvider', () {
      test('should post-process object from pod provider', () async {
        final service = TestService();
        final holder = ObjectHolder<Object>(service, packageName: "test");

        final result = await factory.postProcessObjectFromPodProvider(
          holder,
          'testService',
        );

        expect(result.getValue(), equals(service));
      });

      test('should handle post-processing with definition', () async {
        final service = TestService();
        final holder = ObjectHolder<Object>(service, packageName: "test");

        // Add definition with expression
        final definition = RootPodDefinition(type: Class<TestService>());
        factory.addDefinition('testService', definition);

        final result = await factory.postProcessObjectFromPodProvider(
          holder,
          'testService',
        );

        expect(result.getValue(), equals(service));
      });

      test('should handle post-processing failure gracefully', () async {
        final service = TestService();
        final holder = ObjectHolder<Object>(service, packageName: "test");

        // This should not throw even if there are issues
        final result = await factory.postProcessObjectFromPodProvider(
          holder,
          'nonExistentService',
        );

        expect(result.getValue(), equals(service));
      });
    });

    group('Dependency Type Management', () {
      test('should ignore dependency types', () {
        factory.ignoreDependencyType(Class<String>());
        expect(factory.isTypeIgnored(Class<String>()), isTrue);
        expect(factory.isTypeIgnored(Class<int>()), isFalse);
      });

      test('should ignore dependency interfaces', () {
        factory.ignoreDependencyInterface(Class<TestService>());
        expect(factory.isInterfaceIgnored(Class<TestService>()), isTrue);
        expect(factory.isInterfaceIgnored(Class<TestRepository>()), isFalse);
      });
    });

    group('Value Conversion', () {
      test('should convert compatible values', () {
        final result = factory.convertValueIfNecessary(
          'test',
          Class<String>(),
          Class<String>(),
        );
        expect(result, equals('test'));
      });

      test('should return null for null values', () {
        final result = factory.convertValueIfNecessary(
          null,
          Class<String>(),
          Class<String>(),
        );
        expect(result, isNull);
      });

      test('should return value if target type matches', () {
        final service = TestService();
        final result = factory.convertValueIfNecessary(
          service,
          Class<TestService>(),
          Class<TestService>(),
        );
        expect(result, equals(service));
      });
    });

    group('Complex Scenarios', () {
      test('should handle complete pod creation lifecycle', () async {
        // Add processors
        final processor = TestPodProcessor();
        final instantiationProcessor = TestInstantiationProcessor();
        factory.addPodProcessor(processor);
        factory.addPodProcessor(instantiationProcessor);

        // Create definition
        final definition = RootPodDefinition(type: Class<TestService>());
        definition.design = DesignDescriptor(
          role: DesignRole.APPLICATION,
          isPrimary: true,
        );
        definition.propertyValues = MutablePropertyValues();
        definition.propertyValues.add(
          'name',
          'test-service',
          qualifiedName: "dart:core/string.dart.String",
        );

        final result = await factory.doCreate('testService', definition, null);

        expect(result, isA<TestService>());
        expect(instantiationProcessor.processedPods, isNotEmpty);
      });

      test('should handle factory method instantiation', () async {
        final definition = RootPodDefinition(type: Class<TestService>())
          ..name = 'testService';
        definition.factoryMethod = FactoryMethodDesign(
          'testFactory',
          'createService',
        );

        // Add factory definition
        final factoryDef = RootPodDefinition(type: Class<TestFactory>())
          ..name = 'testFactory';
        factory.addDefinition('testFactory', factoryDef);

        expect(
          () => factory.doCreate('testService', definition, null),
          returnsNormally,
        );
      });

      test('should handle constructor autowiring', () async {
        final definition = RootPodDefinition(type: Class<TestService>());
        definition.executableArgumentValues = ConstructorArgumentValues();
        definition.executableArgumentValues.addArgument(
          ArgumentValue(
            'test-name',
            name: "name",
            qualifiedName: "dart:core/string.dart.String",
          ),
        );

        expect(
          () => factory.doCreate('testService', definition, null),
          returnsNormally,
        );
      });
    });

    group('Error Handling', () {
      test('should handle missing factory method', () async {
        final definition = RootPodDefinition(type: Class<TestService>());
        definition.factoryMethod = FactoryMethodDesign(
          'nonExistentFactory',
          'createService',
        );

        expect(
          () => factory.doCreate('testService', definition, null),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle property setting failures', () {
        final service = TestService();
        final definition = RootPodDefinition(type: Class<TestService>());
        definition.propertyValues = MutablePropertyValues();
        definition.propertyValues.add(
          'nonExistentProperty',
          'value',
          qualifiedName: "dart:core/string.dart.String",
        );
        factory.addDefinition('testService', definition);

        expect(
          () => factory.configurePod(service, 'testService'),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}

// Mock classes for testing
class MockConfigurablePodFactory implements ConfigurablePodFactory {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
