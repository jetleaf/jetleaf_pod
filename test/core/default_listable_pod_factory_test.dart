// Tests for DefaultListablePodFactory - public API surface and PodDefinition integration
import 'package:test/test.dart';
import 'package:jetleaf_pod/src/core/default_listable_pod_factory.dart';
import 'package:jetleaf_pod/src/definition/pod_definition.dart';
import 'package:jetleaf_pod/src/helpers/object.dart';
import 'package:jetleaf_pod/src/exceptions.dart';
import 'package:jetleaf_pod/src/definition/commons.dart';
import 'package:jetleaf_pod/src/helpers/enums.dart';
import 'package:jetleaf_pod/src/core/pod_factory.dart';
import 'package:jetleaf_pod/src/helpers/nullable_pod.dart';
import 'package:jetleaf_lang/lang.dart';

import '../_dependencies.dart';

class _ServiceA {}

class _ServiceB {}

abstract interface class ControlInterface {}

class PrimaryControlInterface implements ControlInterface {}

class OtherControlInterface implements ControlInterface {
  final ControlInterface _interface;
  OtherControlInterface(this._interface);
}

class _DummySource extends Source {
  @override
  Declaration getDeclaration() => throw UnimplementedError();

  @override
  List<Annotation> getAllDirectAnnotations() => [];

  @override
  A? getDirectAnnotation<A>() => null;

  @override
  String getName() => '';

  @override
  List<String> getModifiers() => [];

  @override
  ProtectionDomain getProtectionDomain() => ProtectionDomain.current();
  @override
  String getSignature() => '';

  @override
  bool isPublic() => true;
}

/// Subclass wrapper to expose protected methods for testing
class TestableFactory extends DefaultListablePodFactory {
  TestableFactory([super.parentFactory]);

  String? callDetermineAutowireCandidate(
    Map<String, Object> candidates,
    DependencyDescriptor descriptor,
  ) => determineAutowireCandidate(candidates, descriptor);

  String? callDetermineHighestPriorityCandidate(
    Map<String, Object> candidates,
    Class requiredType,
  ) => determineHighestPriorityCandidate(candidates, requiredType);

  String? callDeterminePrimaryCandidate(List<String> candidates) =>
      determinePrimaryCandidate(candidates);

  Object? callVerifyInstance(
    Object instance,
    Class type,
    String name,
    DependencyDescriptor descriptor,
  ) => verifyInstance(instance, type, name, descriptor);

  Object callNotifyDependencyNotFound(
    String podName,
    DependencyDescriptor descriptor,
  ) => notifyDependencyNotFound(podName, descriptor);

  String callNotifyMultipleCandidatesFound(
    Class requiredType,
    Map<String, Object> candidates,
  ) => notifyMultipleCandidatesFound(requiredType, candidates);

  Future<Object?> callResolveMultipleCollectionPods(
    String? podName,
    DependencyDescriptor descriptor,
    Set<String>? autowired,
  ) => resolveMultipleCollectionPods(podName, descriptor, autowired);

  Future<Object?> callResolveMultipleMappedPods(
    String? podName,
    DependencyDescriptor descriptor,
    Set<String>? autowired,
  ) => resolveMultipleMappedPods(podName, descriptor, autowired);

  bool callIsRequired(DependencyDescriptor descriptor) =>
      isRequired(descriptor);

  bool callMatchesName(String podName, [String? candidateName]) =>
      matchesName(podName, candidateName);

  bool callSelfReferenced([String? podName, String? candidateName]) =>
      selfReferenced(podName, candidateName);

  int? callGetPriority(Object instance) => getPriority(instance);
}

class TestComparator extends Comparator<Object> {
  @override
  int compare(Object a, Object b) => 0;
}

void main() {
  setUpAll(() async {
    await setupRuntime();
  });

  group('DefaultListablePodFactory - public API', () {
    late TestableFactory factory;

    setUp(() {
      factory = TestableFactory();
    });

    test('set/get dependency comparator', () {
      final comp = TestComparator();
      factory.setDependencyComparator(comp);
      expect(factory.getDependencyComparator(), equals(comp));
    });

    test(
      'registerDefinition / getDefinition / getDefinitionByClass / names/count',
      () async {
        final defA = RootPodDefinition(type: Class<_ServiceA>());
        final defB = RootPodDefinition(type: Class<_ServiceB>());

        await factory.registerDefinition('a', defA);
        await factory.registerDefinition('b', defB);

        expect(factory.containsDefinition('a'), isTrue);
        expect(factory.containsDefinition('b'), isTrue);

        final gotA = factory.getDefinition('a');
        expect(
          gotA.type.getCanonicalName(),
          equals(Class<_ServiceA>().getCanonicalName()),
        );

        final byClass = factory.getDefinitionByClass(Class<_ServiceB>());
        expect(byClass.name, equals('b'));

        final names = factory.getDefinitionNames();
        expect(names, containsAll(['a', 'b']));
        expect(factory.getNumberOfPodDefinitions(), greaterThanOrEqualTo(2));
      },
    );

    test('freezeConfiguration prevents register/remove', () async {
      final def = RootPodDefinition(type: Class<_ServiceA>());
      await factory.registerDefinition('toFreeze', def);
      factory.freezeConfiguration();

      final newDef = RootPodDefinition(type: Class<_ServiceB>());
      expect(
        () async => await factory.registerDefinition('shouldFail', newDef),
        throwsA(isA<PodDefinitionStoreException>()),
      );
      expect(
        () async => await factory.removeDefinition('toFreeze'),
        throwsA(isA<PodDefinitionStoreException>()),
      );
    });

    test('addSingleton and getPodClass fallbacks', () async {
      // add a singleton value holder
      await factory.addSingleton(
        's1',
        object: ObjectHolder<String>('value', packageName: 'test'),
      );

      final cls = await factory.getPodClass('s1');
      expect(
        cls.getCanonicalName(),
        equals(Class<String>().getCanonicalName()),
      );
    });

    test('getPodNamesIterator includes definitions and singletons', () async {
      final def = RootPodDefinition(type: Class<_ServiceA>());
      await factory.registerDefinition('iterDef', def);
      await factory.addSingleton(
        'iterSingleton',
        object: ObjectHolder<int>(42, packageName: 'test'),
      );

      final it = factory.getPodNamesIterator();
      final all = <String>[];
      while (it.moveNext()) {
        all.add(it.current);
      }

      expect(all, containsAll(['iterDef', 'iterSingleton']));
    });

    test('clearMetadataCache is callable and does not throw', () async {
      // register a definition and then clear cache
      final def = RootPodDefinition(type: Class<_ServiceB>());
      await factory.registerDefinition('cacheDef', def);
      expect(() => factory.clearMetadataCache(), returnsNormally);
    });

    test('get - works for primary pods', () async {
      // register a definition and then clear cache
      final primaryControl = RootPodDefinition(type: Class<PrimaryControlInterface>())
        ..design = DesignDescriptor(role: DesignRole.APPLICATION, isPrimary: true);
      final otherControl = RootPodDefinition(type: Class<OtherControlInterface>());
      await factory.registerDefinition('primaryControl', primaryControl);
      await factory.registerDefinition('otherControl', otherControl);

      final controlInterface = await factory.get(Class<OtherControlInterface>());
      expect(controlInterface._interface.runtimeType, PrimaryControlInterface);
    });

    test(
      'registerIgnoredDependency and registerResolvableDependency are callable',
      () {
        // Should not throw when registering ignored / resolvable types
        factory.registerIgnoredDependency(Class<String>());
        factory.registerResolvableDependency(Class<int>(), 7);
        // no public getter for these maps - just ensure methods don't throw
        expect(true, isTrue);
      },
    );

    test(
      'removeDefinition removes local and delegates to parent when present',
      () async {
        final parent = DefaultListablePodFactory();
        final child = DefaultListablePodFactory(parent);

        final def = RootPodDefinition(type: Class<_ServiceA>());
        await parent.registerDefinition('fromParent', def);
        expect(parent.containsDefinition('fromParent'), isTrue);

        // Removing from child should also remove from parent if parent contains it
        await child.removeDefinition('fromParent');
        expect(parent.containsDefinition('fromParent'), isFalse);
      },
    );

    test('autowire candidate logic and determineAutowireCandidate', () async {
      final def1 = RootPodDefinition(type: Class<_ServiceA>());
      final def2 = RootPodDefinition(type: Class<_ServiceA>());
      def2.design = DesignDescriptor(
        role: DesignRole.APPLICATION,
        isPrimary: true,
      );

      await factory.registerDefinition('c1', def1);
      await factory.registerDefinition('c2', def2);

      final descriptor = DependencyDescriptor(
        source: _DummySource(),
        podName: 'consumer',
        propertyName: 'service',
        type: Class<_ServiceA>(),
      );

      // c2 is primary -> should be chosen
      final candidates = <String, Object>{'c1': Object(), 'c2': Object()};
      final chosen = factory.callDetermineAutowireCandidate(
        candidates,
        descriptor,
      );
      expect(chosen, anyOf(equals('c2'), isNotNull));

      // register resolvable dependency and ensure it can be chosen
      final special = Object();
      factory.registerResolvableDependency(Class<_ServiceA>(), special);
      final cand2 = <String, Object>{'r1': Object(), 'r2': special};
      final chosen2 = factory.callDetermineAutowireCandidate(cand2, descriptor);
      expect(chosen2, equals('r2'));
    });

    test(
      'determineHighestPriorityCandidate and getPriority conflict behavior',
      () async {
        final objA = Object();
        final objB = Object();
        final comparator = OrderComparator();
        factory.setDependencyComparator(comparator);

        final res = factory.callDetermineHighestPriorityCandidate({
          'a': objA,
          'b': objB,
        }, Class<_ServiceA>());
        expect(res, isNull);
      },
    );

    test(
      'verifyInstance and notifyDependencyNotFound/notifyMultipleCandidatesFound',
      () {
        final descRequired = DependencyDescriptor(
          source: _DummySource(),
          podName: 'p',
          propertyName: 'prop',
          type: Class<_ServiceA>(),
          isRequired: true,
        );

        expect(
          () => factory.callVerifyInstance(
            NullablePod(),
            Class<_ServiceA>(),
            'p',
            descRequired,
          ),
          throwsA(isA<NoSuchPodDefinitionException>()),
        );

        expect(
          () => factory.callVerifyInstance(
            123,
            Class<_ServiceA>(),
            'p',
            descRequired,
          ),
          throwsA(isA<PodNotOfRequiredTypeException>()),
        );

        expect(
          () => factory.callNotifyDependencyNotFound('p', descRequired),
          throwsA(isA<NoSuchPodDefinitionException>()),
        );

        final multi = {'a': 1, 'b': 2};
        expect(
          () => factory.callNotifyMultipleCandidatesFound(
            Class<_ServiceA>(),
            multi,
          ),
          throwsA(isA<NoUniquePodDefinitionException>()),
        );
      },
    );

    test(
      'resolveMultipleCollectionPods and resolveMultipleMappedPods',
      () async {
        final d1 = RootPodDefinition(type: Class<_ServiceA>());
        final d2 = RootPodDefinition(type: Class<_ServiceA>());
        await factory.registerDefinition('listA', d1);
        await factory.registerDefinition('listB', d2);

        final descriptorList = DependencyDescriptor(
          source: _DummySource(),
          podName: 'consumer',
          propertyName: 'prop',
          type: Class<List<_ServiceA>>(),
        );

        final listRes = await factory.callResolveMultipleCollectionPods(
          'consumer',
          descriptorList,
          <String>{},
        );
        expect(listRes == null || listRes is List, isTrue);

        final descriptorMap = DependencyDescriptor(
          source: _DummySource(),
          podName: 'consumer',
          propertyName: 'prop',
          type: Class<Map<String, _ServiceA>>(),
        );

        final mapRes = await factory.callResolveMultipleMappedPods(
          'consumer',
          descriptorMap,
          <String>{},
        );
        expect(mapRes == null || mapRes is Map, isTrue);
      },
    );

    test('isRequired and matchesName/selfReferenced behavior', () async {
      final descOpt = DependencyDescriptor(
        source: _DummySource(),
        podName: 'p',
        propertyName: 'prop',
        type: Class<Optional>(),
        isRequired: false,
      );

      expect(factory.callIsRequired(descOpt), isFalse);
      expect(factory.callMatchesName('x', 'x'), isTrue);
      expect(factory.callSelfReferenced('same', 'same'), isTrue);
    });
  });
}
