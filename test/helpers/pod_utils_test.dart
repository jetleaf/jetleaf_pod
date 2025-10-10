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

// test/pod_utils_test.dart
import 'package:jetleaf_pod/src/core/pod_factory.dart';
import 'package:jetleaf_pod/src/exceptions.dart';
import 'package:jetleaf_pod/src/helpers/utils.dart';
import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../_dependencies.dart';

class _FakeListablePodFactory implements ListablePodFactory {
  final Map<Class, List<String>> _namesByType;
  final Map<Class, Map<String, Object>> _podsByType;
  final Map<Class, List<String>> _namesByAnnotation;

  _FakeListablePodFactory({
    Map<Class, List<String>>? namesByType,
    Map<Class, Map<String, Object>>? podsByType,
    Map<Class, List<String>>? namesByAnnotation,
  })  : _namesByType = namesByType ?? {},
        _podsByType = podsByType ?? {},
        _namesByAnnotation = namesByAnnotation ?? {};

  // The methods PodUtils calls:

  @override
  Future<List<String>> getPodNames(Class type, {bool? includeNonSingletons, bool? allowEagerInit}) async {
    final list = _namesByType[type];
    return list != null ? List<String>.from(list) : <String>[];
  }

  @override
  Future<List<String>> getPodNamesForAnnotation<A>(Class<A> annotationType) async {
    final list = _namesByAnnotation[annotationType];
    return list != null ? List<String>.from(list) : <String>[];
  }

  @override
  Future<Map<String, T>> getPodsOf<T>(Class<T> type, {bool? includeNonSingletons, bool? allowEagerInit}) async {
    final map = _podsByType[type];
    if (map == null) return <String, T>{};
    return map.map<String, T>((k, v) => MapEntry(k, v as T));
  }

  // These methods are not used by our tests, but required by the interface:
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// A hierarchical factory that wraps a local listable factory and points to a parent
class _FakeHierarchicalPodFactory extends _FakeListablePodFactory implements HierarchicalPodFactory {
  final ListablePodFactory? parent;
  final Set<String> _localNames;

  _FakeHierarchicalPodFactory({
    this.parent,
    Map<Class, List<String>>? namesByType,
    Map<Class, Map<String, Object>>? podsByType,
    Map<Class, List<String>>? namesByAnnotation,
    Set<String>? localNames,
  })  : _localNames = localNames ?? <String>{},
        super(namesByType: namesByType, podsByType: podsByType, namesByAnnotation: namesByAnnotation);

  @override
  PodFactory? getParentFactory() => parent;

  // PodUtils calls containsLocalPod(parentName) asynchronously; implement it:
  @override
  Future<bool> containsLocalPod(String name) async => _localNames.contains(name);
}

void main() {
  setUpAll(() async {
    await setupRuntime();
    return Future<void>.value();
  });

  group('PodUtils', () {
    test('constants should have correct values', () {
      expect(PodUtils.SCOPE_DEFAULT.name, equals('SINGLETON'));
      expect(PodUtils.GENERATED_POD_NAME_SEPARATOR, equals('^'));
      expect(PodUtils.POD_PROVIDER_PREFIX, equals('*'));
      expect(PodUtils.ORIGINAL_INSTANCE_SUFFIX, equals('.ORIGINAL_INSTANCE'));
      expect(PodUtils.DEFAULT_METHOD_NAME, equals('(#inferred_method#)'));
      expect(PodUtils.OBJECT_TYPE_ATTRIBUTE, equals('factoryPodObjectType'));
    });

    test('isFactoryDereference should detect factory prefixes', () {
      expect(PodUtils.isFactoryDereference('*myPod'), isTrue);
      expect(PodUtils.isFactoryDereference('**myPod'), isTrue);
      expect(PodUtils.isFactoryDereference('myPod'), isFalse);
      expect(PodUtils.isFactoryDereference(''), isFalse);
      expect(PodUtils.isFactoryDereference(null), isFalse);
    });

    test('transformedName should remove factory prefixes', () {
      expect(PodUtils.transformedName('*myPod'), equals('myPod'));
      expect(PodUtils.transformedName('**myPod'), equals('myPod'));
      expect(PodUtils.transformedName('***myPod'), equals('myPod'));
      expect(PodUtils.transformedName('myPod'), equals('myPod'));
      expect(PodUtils.transformedName(''), equals(''));
      
      // Test caching
      final result1 = PodUtils.transformedName('*cached');
      final result2 = PodUtils.transformedName('*cached');
      expect(result1, equals('cached'));
      expect(result2, equals('cached'));
    });

    test('isGeneratedName should detect generated names', () {
      expect(PodUtils.isGeneratedName('myPod^0'), isTrue);
      expect(PodUtils.isGeneratedName('myPod^instance'), isTrue);
      expect(PodUtils.isGeneratedName('myPod'), isFalse);
      expect(PodUtils.isGeneratedName(''), isFalse);
      expect(PodUtils.isGeneratedName(null), isFalse);
    });

    test('originalName should extract base name from generated names', () {
      expect(PodUtils.originalName('myPod^0'), equals('myPod'));
      expect(PodUtils.originalName('myPod^instance'), equals('myPod'));
      expect(PodUtils.originalName('myPod^123^sub'), equals('myPod'));
      expect(PodUtils.originalName('myPod'), equals('myPod'));
      expect(PodUtils.originalName(''), equals(''));
    });

    test('validateName should validate pod names', () {
      expect(() => PodUtils.validateName('validName'), returnsNormally);
      expect(() => PodUtils.validateName(''), throwsA(isA<IllegalArgumentException>()));
      expect(() => PodUtils.validateName('  trimmed  '), throwsA(isA<IllegalArgumentException>()));
      expect(() => PodUtils.validateName('with\nnewline'), throwsA(isA<IllegalArgumentException>()));
      expect(() => PodUtils.validateName('with\ttab'), throwsA(isA<IllegalArgumentException>()));
      expect(() => PodUtils.validateName('with\rcarriage'), throwsA(isA<IllegalArgumentException>()));
    });

    test('isValidName should check pod name validity', () {
      expect(PodUtils.isValidName('validName'), isTrue);
      expect(PodUtils.isValidName(''), isFalse);
      expect(PodUtils.isValidName('  trimmed  '), isFalse);
      expect(PodUtils.isValidName('with\nnewline'), isFalse);
    });

    test('uniquePod should return single pod or throw', () {
      final type = Class<String>();
      final singlePod = {'name': 'value'};
      final multiplePods = {'name1': 'value1', 'name2': 'value2'};
      final emptyPods = <String, String>{};

      expect(PodUtils.uniquePod(type, singlePod), equals('value'));
      expect(() => PodUtils.uniquePod(type, multiplePods), throwsA(isA<NoUniquePodDefinitionException>()));
      expect(() => PodUtils.uniquePod(type, emptyPods), throwsA(isA<NoSuchPodDefinitionException>()));
    });

    test('should handle edge cases with transformedName', () {
      expect(PodUtils.transformedName('*'), equals(''));
      expect(PodUtils.transformedName('**'), equals(''));
      expect(PodUtils.transformedName('***'), equals(''));
    });

    test('should handle edge cases with originalName', () {
      expect(PodUtils.originalName('^onlySuffix'), equals(''));
      expect(PodUtils.originalName('multiple^separators^here'), equals('multiple'));
      expect(PodUtils.originalName('^'), equals(''));
    });

    test('should handle unicode and special characters in names', () {
      expect(PodUtils.isValidName('ñame'), isTrue);
      expect(PodUtils.isValidName('中文'), isTrue);
      expect(PodUtils.isValidName('🚀pod'), isTrue);
      expect(PodUtils.isValidName('!@#\$pod'), isTrue);
    });

    test('should handle very long names', () {
      final longName = 'a' * 1000;
      expect(PodUtils.isValidName(longName), isTrue);
      expect(PodUtils.transformedName('*$longName'), equals(longName));
    });

    test('should handle concurrent access to transformedName cache', () async {
      final futures = <Future>[];
      
      for (int i = 0; i < 100; i++) {
        futures.add(Future(() {
          expect(PodUtils.transformedName('*concurrent'), equals('concurrent'));
        }));
      }
      
      await Future.wait(futures);
    });
  });

  group('PodUtils - hierarchical helpers', () {
    test('podNamesForTypeIncludingAncestors merges child and parent names and avoids overrides', () async {
      // child has "a" and overrides "shared", parent has "b" and "shared"
      final childNames = {Class<Object>(): ['a', 'shared']};
      final parentNames = {Class<Object>(): ['b', 'shared']};

      final parent = _FakeListablePodFactory(namesByType: parentNames);
      final child = _FakeHierarchicalPodFactory(
        parent: parent,
        namesByType: childNames,
        localNames: {'a', 'shared'},
      );

      final result = await PodUtils.podNamesForTypeIncludingAncestors(child, Class<Object>());
      // 'a' and 'shared' from child must remain; 'b' from parent should be added
      expect(result, containsAll(['a', 'shared', 'b']));
      expect(result.indexOf('a') < result.indexOf('b'), isTrue);
      // ensure 'shared' is only once
      expect(result.where((n) => n == 'shared').length, equals(1));
    });

    test('podNamesForAnnotationIncludingAncestors merges and avoids local override', () async {
      final parentAnn = {Class.forObject(String): ['p1', 'shared']};
      final childAnn = {Class.forObject(String): ['c1', 'shared']};

      final parent = _FakeListablePodFactory(namesByAnnotation: parentAnn);
      final child = _FakeHierarchicalPodFactory(
        parent: parent,
        namesByAnnotation: childAnn,
        localNames: {'c1', 'shared'},
      );

      final result = await PodUtils.podNamesForAnnotationIncludingAncestors(child, Class.forObject(String));
      expect(result, containsAll(['c1', 'shared', 'p1']));
      expect(result.where((n) => n == 'shared').length, equals(1));
    });

    test('podsOfTypeIncludingAncestors merges maps and prefers local entries', () async {
      final parentPods = <String, Object>{
        'p1': 'parentValue1',
        'shared': 'parentShared',
      };
      final childPods = <String, Object>{
        'c1': 'childValue1',
        'shared': 'childShared',
      };

      final parent = _FakeListablePodFactory(podsByType: {Class<String>(): parentPods});
      final child = _FakeHierarchicalPodFactory(
        parent: parent,
        podsByType: {Class<String>(): childPods},
        localNames: {'c1', 'shared'},
      );

      final result = await PodUtils.podsOfTypeIncludingAncestors<String>(child, Class<String>());
      // child entries should be present and prefer local 'shared'
      expect(result['c1'], equals('childValue1'));
      expect(result['p1'], equals('parentValue1'));
      expect(result['shared'], equals('childShared'));
      // size should be 3 (c1, shared, p1)
      expect(result.length, equals(3));
    });

    test('podOfTypeIncludingAncestors throws when zero or multiple matches', () async {
      final emptyFactory = _FakeListablePodFactory(podsByType: {});
      // zero -> NoSuchPodDefinitionException
      await expectLater(
        PodUtils.podOfTypeIncludingAncestors<String>(emptyFactory, Class<String>()),
        throwsA(isA<NoSuchPodDefinitionException>()),
      );

      final multiFactory = _FakeListablePodFactory(podsByType: {
        Class<String>(): {'a': 'v1', 'b': 'v2'}
      });

      await expectLater(
        PodUtils.podOfTypeIncludingAncestors<String>(multiFactory, Class<String>()),
        throwsA(isA<NoUniquePodDefinitionException>()),
      );
    });

    test('podOfType returns the single local pod', () async {
      final map = {Class<String>(): {'only': 'theValue'}};
      final factory = _FakeListablePodFactory(podsByType: map);

      final result = await PodUtils.podOfType<String>(factory, Class<String>());
      expect(result, equals('theValue'));
    });

    test('countPodsIncludingAncestors returns combined length', () async {
      final parentNames = {Class<Object>(): ['bp', 'shared']};
      final childNames = {Class<Object>(): ['c1', 'shared']};

      final parent = _FakeListablePodFactory(namesByType: parentNames);
      final child = _FakeHierarchicalPodFactory(
        parent: parent,
        namesByType: childNames,
        localNames: {'c1', 'shared'},
      );

      final count = await PodUtils.countPodsIncludingAncestors(child);
      // distinct names should be ['c1','shared','bp'] => 3
      expect(count, equals(3));
    });
  });
}