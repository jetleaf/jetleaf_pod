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

import 'package:jetleaf_pod/src/core/default_listable_pod_factory.dart';
import 'package:jetleaf_pod/src/core/pod_factory.dart';
import 'package:jetleaf_pod/src/definition/commons.dart';
import 'package:jetleaf_pod/src/definition/pod_definition.dart';
import 'package:jetleaf_pod/src/exceptions.dart';
import 'package:jetleaf_pod/src/expression/pod_expression.dart';
import 'package:jetleaf_pod/src/helpers/enums.dart';
import 'package:jetleaf_pod/src/helpers/object.dart';
import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../_dependencies.dart';

// Test classes
class TestService {
  final String? name;
  final TestRepository? repository;
  bool initialized = false;
  
  TestService([this.name, this.repository]);
  
  void initialize() {
    initialized = true;
  }
}

class TestRepository {
  final String? connectionString;
  
  TestRepository([this.connectionString]);
}

@TestAnnotation('service')
class AnnotatedService {
  final String value;
  
  AnnotatedService(this.value);
}

@TestAnnotation('repository')
class AnnotatedRepository {
  final String name;
  
  AnnotatedRepository(this.name);
}

class TestAnnotation {
  final String value;
  
  const TestAnnotation(this.value);
}

abstract interface class AbstractClassTest {}

class TestPodExpression implements PodExpression<Object> {
  final Object value;
  
  TestPodExpression(this.value);
  
  @override
  Future<ObjectHolder<Object>> evaluate(PodExpressionContext context) async {
    return ObjectHolder<Object>(value, packageName: "test");
  }
}

void main() {
  setUpAll(() async {
    await setupRuntime();
    return Future<void>.value();
  });

  group('DefaultListablePodFactory Tests', () {
    late DefaultListablePodFactory factory;
    
    setUp(() {
      factory = DefaultListablePodFactory();
    });
    
    group('Constructor and Initialization', () {
      test('should initialize with default values', () {
        expect(factory.getNumberOfPodDefinitions(), equals(0));
        expect(factory.getDefinitionNames(), isEmpty);
      });
      
      test('should initialize with parent factory', () {
        final parentFactory = DefaultListablePodFactory();
        final childFactory = DefaultListablePodFactory(parentFactory);
        
        expect(childFactory.getParentFactory(), equals(parentFactory));
      });
    });
    
    group('Pod Definition Management', () {
      test('should register pod definition', () async {
        final definition = RootPodDefinition(type: Class<TestService>());
        
        await factory.registerDefinition('testService', definition);
        
        expect(factory.containsDefinition('testService'), isTrue);
        expect(factory.getNumberOfPodDefinitions(), equals(1));
        expect(factory.getDefinitionNames(), contains('testService'));
      });
      
      test('should get pod definition', () async {
        final definition = RootPodDefinition(type: Class<TestService>());
        await factory.registerDefinition('testService', definition);
        
        final retrieved = factory.getDefinition('testService');
        
        expect(retrieved, isNotNull);
        expect(retrieved.type, equals(Class<TestService>()));
      });
      
      test('should get pod definition by class', () async {
        final definition = RootPodDefinition(type: Class<TestService>());
        await factory.registerDefinition('testService', definition);
        
        final retrieved = factory.getDefinitionByClass(Class<TestService>());
        
        expect(retrieved, isNotNull);
        expect(retrieved.type, equals(Class<TestService>()));
      });
      
      test('should throw exception for non-existent definition', () {
        expect(
          () => factory.getDefinition('nonExistent'),
          throwsA(isA<PodDefinitionStoreException>())
        );
      });
      
      test('should throw exception for non-existent class definition', () {
        expect(
          () => factory.getDefinitionByClass(Class<TestService>()),
          throwsA(isA<PodDefinitionStoreException>())
        );
      });
      
      test('should remove pod definition', () async {
        final definition = RootPodDefinition(type: Class<TestService>());
        await factory.registerDefinition('testService', definition);
        
        expect(factory.containsDefinition('testService'), isTrue);
        
        await factory.removeDefinition('testService');
        
        expect(factory.containsDefinition('testService'), isFalse);
      });
      
      test('should handle definition overriding when allowed', () async {
        final definition1 = RootPodDefinition(type: Class<TestService>());
        final definition2 = RootPodDefinition(type: Class<TestRepository>());
        
        await factory.registerDefinition('testPod', definition1);
        await factory.registerDefinition('testPod', definition2);
        
        final retrieved = factory.getDefinition('testPod');
        expect(retrieved.type, equals(Class<TestRepository>()));
      });
      
      test('should throw exception when definition overriding not allowed', () async {
        factory.setAllowDefinitionOverriding(false);
        
        final definition1 = RootPodDefinition(type: Class<TestService>());
        final definition2 = RootPodDefinition(type: Class<TestRepository>());
        
        await factory.registerDefinition('testPod', definition1);
        
        expect(
          () => factory.registerDefinition('testPod', definition2),
          throwsA(isA<PodDefinitionValidationException>())
        );
      });
      
      test('should handle frozen configuration', () async {
        final definition = RootPodDefinition(type: Class<TestService>());
        
        // Simulate frozen configuration
        factory.freezeConfiguration();
        
        expect(
          () => factory.registerDefinition('testService', definition),
          throwsA(isA<PodDefinitionStoreException>())
        );
      });
    });
    
    group('Pod Class Resolution', () {
      test('should get pod class from definition', () async {
        final definition = RootPodDefinition(type: Class<TestService>());
        await factory.registerDefinition('testService', definition);
        
        final podClass = await factory.getPodClass('testService');
        
        expect(podClass, equals(Class<TestService>()));
      });
      
      test('should resolve pod class from expression', () async {
        final definition = RootPodDefinition(type: Class<TestService>());
        definition.setPodExpression(TestPodExpression(Class<TestRepository>()));
        await factory.registerDefinition('testService', definition);
        
        final podClass = await factory.getPodClass('testService');
        
        expect(podClass, equals(Class<TestRepository>()));
      });
    });
    
    group('Pod Names and Iteration', () {
      test('should get pod names by type', () async {
        final serviceDefinition = RootPodDefinition(type: Class<TestService>());
        final repositoryDefinition = RootPodDefinition(type: Class<TestRepository>());
        
        await factory.registerDefinition('testService', serviceDefinition);
        await factory.registerDefinition('testRepository', repositoryDefinition);
        
        final serviceNames = await factory.getPodNames(Class<TestService>(), includeNonSingletons: true);
        
        expect(serviceNames, contains('testService'));
        expect(serviceNames, isNot(contains('testRepository')));
      });
      
      test('should get pod names for annotation', () async {
        final serviceDefinition = RootPodDefinition(type: Class<AnnotatedService>());
        final repositoryDefinition = RootPodDefinition(type: Class<AnnotatedRepository>());
        
        await factory.registerDefinition('annotatedService', serviceDefinition);
        await factory.registerDefinition('annotatedRepository', repositoryDefinition);
        
        final annotatedNames = await factory.getPodNamesForAnnotation(Class<TestAnnotation>());
        
        expect(annotatedNames, contains('annotatedService'));
        expect(annotatedNames, contains('annotatedRepository'));
      });
      
      test('should get pod names iterator', () async {
        final definition1 = RootPodDefinition(type: Class<TestService>());
        final definition2 = RootPodDefinition(type: Class<TestRepository>());
        
        await factory.registerDefinition('service', definition1);
        await factory.registerDefinition('repository', definition2);
        
        final iterator = factory.getPodNamesIterator();
        final names = <String>[];
        
        while (iterator.moveNext()) {
          names.add(iterator.current);
        }
        
        expect(names, contains('service'));
        expect(names, contains('repository'));
      });
      
      test('should include singleton names in iterator', () async {
        final definition = RootPodDefinition(type: Class<TestService>());
        await factory.registerDefinition('definedService', definition);
        
        // Register a singleton directly
        await factory.registerSingleton(
          'singletonService',
          Class<TestService>(), 
          object: ObjectHolder<Object>(TestService(), packageName: "Test")
        );
        
        final iterator = factory.getPodNamesIterator();
        final names = <String>[];
        
        while (iterator.moveNext()) {
          names.add(iterator.current);
        }
        
        expect(names, contains('definedService'));
        expect(names, contains('singletonService'));
      });
    });
    
    group('Annotation Handling', () {
      test('should find annotation on pod', () async {
        final definition = RootPodDefinition(type: Class<AnnotatedService>());
        await factory.registerDefinition('annotatedService', definition);
        
        final annotation = await factory.findAnnotationOnPod('annotatedService', Class<TestAnnotation>());
        
        expect(annotation, isNotNull);
        expect(annotation!.value, equals('service'));
      });
      
      test('should return null for missing annotation', () async {
        final definition = RootPodDefinition(type: Class<TestService>());
        await factory.registerDefinition('testService', definition);
        
        final annotation = await factory.findAnnotationOnPod('testService', Class<TestAnnotation>());
        
        expect(annotation, isNull);
      });
      
      test('should find all annotations on pod', () async {
        final definition = RootPodDefinition(type: Class<AnnotatedService>());
        await factory.registerDefinition('annotatedService', definition);
        
        final annotations = await factory.findAllAnnotationsOnPod('annotatedService', Class<TestAnnotation>());
        
        expect(annotations, isNotEmpty);
        expect(annotations.first.value, equals('service'));
      });
      
      test('should handle annotation search failure gracefully', () async {
        final annotation = await factory.findAnnotationOnPod('nonExistent', Class<TestAnnotation>());
        
        expect(annotation, isNull);
      });
    });
    
    group('Pod Retrieval', () {
      test('should get pods of type', () async {
        final serviceDefinition = RootPodDefinition(type: Class<TestService>());
        await factory.registerDefinition('testService', serviceDefinition);
        
        final pods = await factory.getPodsOf(Class<TestService>(), includeNonSingletons: true, allowEagerInit: true);
        
        expect(pods, isNotEmpty);
        expect(pods['testService'], isA<TestService>());
      });
      
      test('should get pods with annotation', () async {
        final serviceDefinition = RootPodDefinition(type: Class<AnnotatedService>())
          ..executableArgumentValues = ConstructorArgumentValues();

        serviceDefinition.executableArgumentValues.add("value", "Hello", qualifiedName: "dart:core/string.dart.String");
        await factory.registerDefinition('annotatedService', serviceDefinition);
        
        final pods = await factory.getPodsWithAnnotation(Class<TestAnnotation>());
        
        expect(pods, isNotEmpty);
        expect(pods['annotatedService'], isA<AnnotatedService>());
      });
      
      test('should handle pod retrieval failure gracefully', () async {
        final definition = RootPodDefinition(type: Class<TestService>());
        await factory.registerDefinition('failingService', definition);
        
        final pods = await factory.getPodsWithAnnotation(Class<TestAnnotation>());
        
        expect(pods, isEmpty);
      });
      
      test('should get object provider', () async {
        final definition = RootPodDefinition(type: Class<TestService>());
        await factory.registerDefinition('testService', definition);
        
        final provider = await factory.getProvider(Class<TestService>(), podName: 'testService');
        
        expect(provider, isNotNull);
      });
    });
    
    group('Autowire Candidate Checking', () {
      test('should identify autowire candidate', () async {
        final definition = RootPodDefinition(type: Class<TestService>());
        definition.autowireCandidate = AutowireCandidateDescriptor(autowireCandidate: true, autowireMode: AutowireMode.BY_NAME);
        await factory.registerDefinition('testService', definition);
        
        final descriptor = DependencyDescriptor(
          source: Class<TestService>(),
          podName: 'testPod',
          propertyName: 'service',
          type: Class<TestService>()
        );
        
        final isCandidate = factory.isAutowireCandidate('testService', descriptor);
        
        expect(isCandidate, isTrue);
      });
      
      test('should reject non-autowire candidate', () async {
        final definition = RootPodDefinition(type: Class<TestService>());
        definition.autowireCandidate = AutowireCandidateDescriptor(autowireCandidate: false, autowireMode: AutowireMode.NO );
        await factory.registerDefinition('testService', definition);
        
        final descriptor = DependencyDescriptor(
          source: Class<TestService>(),
          podName: 'testPod',
          propertyName: 'service',
          type:Class<TestService>()
        );
        
        final isCandidate = factory.isAutowireCandidate('testService', descriptor);
        
        expect(isCandidate, isFalse);
      });
      
      test('should reject abstract pod types', () async {
        final definition = RootPodDefinition(type: Class<AbstractClassTest>());
        await factory.registerDefinition('abstractService', definition);
        
        final descriptor = DependencyDescriptor(
          source: Class<AbstractClassTest>(),
          podName: 'testPod',
          propertyName: 'service',
          type:Class<AbstractClassTest>()
        );
        
        final isCandidate = factory.isAutowireCandidate('abstractService', descriptor);
        
        expect(isCandidate, isFalse);
      });
      
      test('should reject ignored dependency types', () async {
        factory.registerIgnoredDependency(Class<TestService>());
        
        final definition = RootPodDefinition(type: Class<TestService>());
        await factory.registerDefinition('testService', definition);
        
        final descriptor = DependencyDescriptor(
          source: Class<TestService>(),
          podName: 'testPod',
          propertyName: 'service',
          type: Class<TestService>()
        );
        
        final isCandidate = factory.isAutowireCandidate('testService', descriptor);
        
        expect(isCandidate, isFalse);
      });
      
      test('should delegate to parent factory when appropriate', () async {
        final parentFactory = DefaultListablePodFactory();
        final childFactory = DefaultListablePodFactory(parentFactory);
        
        final definition = RootPodDefinition(type: Class<TestService>())
          ..autowireCandidate = AutowireCandidateDescriptor(autowireCandidate: true, autowireMode: AutowireMode.NO);
        await parentFactory.registerDefinition('parentService', definition);
        
        final descriptor = DependencyDescriptor(
          source: Class<TestService>(),
          podName: 'testPod',
          propertyName: 'service',
          type: Class<TestService>()
        );
        
        final isCandidate = childFactory.isAutowireCandidate('parentService', descriptor);
        
        expect(isCandidate, isTrue);
      });
    });
    
    group('Singleton Pre-instantiation', () {
      test('should pre-instantiate singletons', () async {
        final definition = RootPodDefinition(type: Class<TestService>());
        definition.scope = ScopeDesign.type(ScopeType.SINGLETON.name);
        definition.lifecycle = LifecycleDesign(isLazy: false);
        await factory.registerDefinition('eagerService', definition);
        
        await factory.preInstantiateSingletons();
        
        // Verify singleton was created
        expect(factory.containsSingleton('eagerService'), isTrue);
      });
      
      test('should skip lazy singletons during pre-instantiation', () async {
        final definition = RootPodDefinition(type: Class<TestService>());
        definition.scope = ScopeDesign.type(ScopeType.SINGLETON.name);
        definition.lifecycle = LifecycleDesign(isLazy: true);
        await factory.registerDefinition('lazyService', definition);
        
        await factory.preInstantiateSingletons();
        
        // Lazy singleton should not be created
        expect(factory.containsSingleton('lazyService'), isFalse);
      });
      
      test('should skip abstract classes during pre-instantiation', () async {
        final definition = RootPodDefinition(type: Class<AbstractClassTest>());
        definition.scope = ScopeDesign.type(ScopeType.SINGLETON.name);
        definition.lifecycle = LifecycleDesign(isLazy: false);
        await factory.registerDefinition('abstractService', definition);
        
        await factory.preInstantiateSingletons();
        
        // Abstract class should not be instantiated
        expect(factory.containsSingleton('abstractService'), isFalse);
      });
    });
    
    group('Dependency Resolution', () {
      test('should resolve dependency from resolvable dependencies', () async {
        final testService = TestService('resolvable');
        factory.registerResolvableDependency(Class<TestService>(), testService);
        
        final descriptor = DependencyDescriptor(
          source: Class<TestService>(),
          podName: 'testPod',
          propertyName: 'service',
          type: Class<TestService>()
        );
        
        final result = await factory.doResolveDependency(descriptor);
        
        expect(result, equals(testService));
      });
      
      test('should resolve dependency from object factory', () async {
        final objectFactory = TestObjectFactory(TestService('factory-created'));
        factory.registerResolvableDependency(Class<TestService>(), objectFactory);
        
        final descriptor = DependencyDescriptor(
          source: Class<TestService>(),
          podName: 'testPod',
          propertyName: 'service',
          type: Class<TestService>()
        );
        
        final result = await factory.doResolveDependency(descriptor);
        
        expect(result, isA<TestService>());
        expect((result as TestService).name, equals('factory-created'));
      });
      
      test('should resolve single pod of type', () async {
        final definition = RootPodDefinition(type: Class<TestService>());
        await factory.registerDefinition('singleService', definition);
        
        final descriptor = DependencyDescriptor(
          source: Class<TestService>(),
          podName: 'testPod',
          propertyName: 'service',
          type: Class<TestService>()
        );
        
        final result = await factory.doResolveDependency(descriptor);
        
        expect(result, isA<TestService>());
      });
      
      test('should resolve pod by name when multiple exist', () async {
        final definition1 = RootPodDefinition(type: Class<TestService>());
        final definition2 = RootPodDefinition(type: Class<TestService>());
        
        await factory.registerDefinition('service1', definition1);
        await factory.registerDefinition('service2', definition2);
        
        final descriptor = DependencyDescriptor(
          source: Class<TestService>(),
          podName: 'testPod',
          propertyName: 'service1', // Specific name
          type: Class<TestService>()
        );
        
        final result = await factory.doResolveDependency(descriptor);
        
        expect(result, isA<TestService>());
      });
      
      test('should resolve primary pod when multiple exist', () async {
        final definition1 = RootPodDefinition(type: Class<TestService>());
        final definition2 = RootPodDefinition(type: Class<TestService>());
        definition2.design = DesignDescriptor(role: DesignRole.APPLICATION, isPrimary: true);
        
        await factory.registerDefinition('service1', definition1);
        await factory.registerDefinition('primaryService', definition2);
        
        final descriptor = DependencyDescriptor(
          source: Class<TestService>(),
          podName: 'testPod',
          propertyName: 'service',
          type: Class<TestService>()
        );
        
        final result = await factory.doResolveDependency(descriptor);
        
        expect(result, isA<TestService>());
      });
      
      test('should return null for unresolvable dependency', () async {
        final descriptor = DependencyDescriptor(
          source: Class<TestService>(),
          podName: 'testPod',
          propertyName: 'nonExistentService',
          type: Class<TestService>()
        );
        
        final result = await factory.doResolveDependency(descriptor);
        
        expect(result, isNull);
      });
      
      test('should handle dependency resolution failure gracefully', () async {
        final descriptor = DependencyDescriptor(
          source: Class<TestService>(),
          podName: 'testPod',
          propertyName: 'service',
          type: Class<TestService>()
        );
        
        final result = await factory.doResolveDependency(descriptor);
        
        expect(result, isNull);
      });
    });
    
    group('Metadata Cache Management', () {
      test('should clear metadata cache', () async {
        final definition = RootPodDefinition(type: Class<TestService>());
        await factory.registerDefinition('testService', definition);
        
        // Access to populate cache
        factory.getMergedPodDefinition('testService');
        
        factory.clearMetadataCache();
        
        // Should not throw and should work normally after cache clear
        expect(() => factory.getMergedPodDefinition('testService'), returnsNormally);
      });
    });
    
    group('Ignored Dependencies', () {
      test('should register ignored dependency type', () {
        factory.registerIgnoredDependency(Class<String>());
        
        expect(factory.isTypeIgnored(Class<String>()), isTrue);
      });
      
      test('should register ignored dependency interface', () {
        factory.registerIgnoredDependency(Class<AbstractClassTest>());
        
        expect(factory.isInterfaceIgnored(Class<AbstractClassTest>()), isTrue);
      });
    });
    
    group('Custom Post Processing', () {
      test('should apply custom post processing', () {
        final service = TestService('original');
        
        final result = factory.applyCustomPostProcessing(service, 'testService');
        
        expect(result, equals(service));
      });
    });
    
    group('Edge Cases and Error Handling', () {
      test('should handle empty factory', () {
        expect(factory.getDefinitionNames(), isEmpty);
        expect(factory.getNumberOfPodDefinitions(), equals(0));
      });
      
      test('should handle missing pod definition gracefully', () {
        expect(
          () => factory.getDefinition('nonExistent'),
          throwsA(isA<PodDefinitionStoreException>())
        );
      });
      
      test('should handle complex dependency scenarios', () async {
        // Create a complex dependency graph
        final serviceDefinition = RootPodDefinition(type: Class<TestService>());
        final repositoryDefinition = RootPodDefinition(type: Class<TestRepository>());
        
        await factory.registerDefinition('testService', serviceDefinition);
        await factory.registerDefinition('testRepository', repositoryDefinition);
        
        // Test various resolution scenarios
        final serviceDescriptor = DependencyDescriptor(
          source: Class<TestService>(),
          podName: 'testPod',
          propertyName: 'testService',
          type: Class<TestService>()
        );
        
        final repositoryDescriptor = DependencyDescriptor(
          source: Class<TestRepository>(),
          podName: 'testPod',
          propertyName: 'testRepository',
          type: Class<TestRepository>()
        );
        
        final serviceResult = await factory.doResolveDependency(serviceDescriptor);
        final repositoryResult = await factory.doResolveDependency(repositoryDescriptor);
        
        expect(serviceResult, isA<TestService>());
        expect(repositoryResult, isA<TestRepository>());
      });
    });
  });
}

class TestObjectFactory extends ObjectFactory<Object> {
  final Object object;
  
  TestObjectFactory(this.object);
  
  @override
  Future<ObjectHolder<Object>> get([List<ArgumentValue>? args]) async {
    return ObjectHolder<Object>(object, qualifiedName: "dart:core/object.dart.Object");
  }
}