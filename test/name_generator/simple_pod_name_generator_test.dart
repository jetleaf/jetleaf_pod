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

// test/simple_pod_name_generator_test.dart
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/src/name_generator/simple_pod_name_generator.dart';
import 'package:test/test.dart';
import 'package:jetleaf_pod/src/definition/pod_definition.dart';
import 'package:jetleaf_pod/src/definition/pod_definition_registry.dart';

import '../_dependencies.dart';

// Real classes for testing
class UserService {}
class URLService {}
class XMLParser {}
class MyService {}
class ABTest {}
class Test {}
class A {}
class Service {}
class HTTPClient {}
class JSONParser {}
class CSSLoader {}
class APIClient {}
class HTMLParser {}
class URLbuilder {}
class Class123 {}
class User_Service {}
class _123Service {}
class U {}
class UU {}
class Uu {}
class uU {}
class U1 {}
class A1 {}
class A_B {}
class VeryLongClassNameWithManyCharactersThatExceedsNormalLength {}

class MockPodDefinition implements PodDefinition {
  @override
  final String name;
  @override
  final Class type;

  MockPodDefinition({required this.name, required this.type});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockPodDefinitionRegistry implements PodDefinitionRegistry {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    await setupRuntime();
    return Future<void>.value();
  });

  group('SimplePodNameGenerator - generate method', () {
    late SimplePodNameGenerator generator;
    late PodDefinitionRegistry registry;

    setUp(() {
      generator = const SimplePodNameGenerator();
      registry = MockPodDefinitionRegistry();
    });

    test('should generate name from simple class name', () {
      final definition = MockPodDefinition(
        name: 'ignored',
        type: Class<UserService>(),
      );

      final result = generator.generate(definition, registry);
      expect(result, equals('userService'));
    });

    test('should preserve acronyms and uppercase prefixes', () {
      final definition1 = MockPodDefinition(
        name: 'ignored',
        type: Class<URLService>(),
      );
      final definition2 = MockPodDefinition(
        name: 'ignored',
        type: Class<XMLParser>(),
      );

      expect(generator.generate(definition1, registry), equals('URLService'));
      expect(generator.generate(definition2, registry), equals('XMLParser'));
    });

    test('should handle single character class names', () {
      final definition = MockPodDefinition(
        name: 'ignored',
        type: Class<A>(),
      );

      final result = generator.generate(definition, registry);
      expect(result, equals('a'));
    });

    test('should handle regular class names with various patterns', () {
      final testCases = [
        (Class<MyService>(), 'myService'),
        (Class<Test>(), 'test'),
        (Class<Service>(), 'service'),
        (Class<HTTPClient>(), 'HTTPClient'),
        (Class<JSONParser>(), 'JSONParser'),
      ];

      for (final (type, expected) in testCases) {
        final definition = MockPodDefinition(
          name: 'ignored',
          type: type,
        );

        final result = generator.generate(definition, registry);
        expect(result, equals(expected), reason: 'Failed for ${type.getQualifiedName()}');
      }
    });

    test('should handle acronyms with mixed case scenarios', () {
      final testCases = [
        (Class<CSSLoader>(), 'CSSLoader'),
        (Class<APIClient>(), 'APIClient'),
        (Class<HTMLParser>(), 'HTMLParser'),
        (Class<URLbuilder>(), 'URLbuilder'),
      ];

      for (final (type, expected) in testCases) {
        final definition = MockPodDefinition(
          name: 'ignored',
          type: type,
        );

        final result = generator.generate(definition, registry);
        expect(result, equals(expected));
      }
    });

    test('should handle numeric class names', () {
      final definition = MockPodDefinition(
        name: 'ignored',
        type: Class<Class123>(),
      );

      final result = generator.generate(definition, registry);
      expect(result, equals('class123'));
    });

    test('should handle class names with underscores', () {
      final definition = MockPodDefinition(
        name: 'ignored',
        type: Class<User_Service>(),
      );

      final result = generator.generate(definition, registry);
      expect(result, equals('user_Service'));
    });

    test('should handle class names starting with underscore and numbers', () {
      final definition = MockPodDefinition(
        name: 'ignored',
        type: Class<_123Service>(),
      );

      final result = generator.generate(definition, registry);
      expect(result, equals('_123Service'));
    });

    test('should handle very long class names', () {
      final definition = MockPodDefinition(
        name: 'ignored',
        type: Class<VeryLongClassNameWithManyCharactersThatExceedsNormalLength>(),
      );

      final result = generator.generate(definition, registry);
      expect(result, equals('veryLongClassNameWithManyCharactersThatExceedsNormalLength'));
    });

    test('should handle ABTest pattern (two uppercase at start)', () {
      final definition = MockPodDefinition(
        name: 'ignored',
        type: Class<ABTest>(),
      );

      final result = generator.generate(definition, registry);
      expect(result, equals('ABTest'));
    });

    test('should ignore the provided name field and use class name', () {
      final definition = MockPodDefinition(
        name: 'customNameShouldBeIgnored',
        type: Class<UserService>(),
      );

      final result = generator.generate(definition, registry);
      expect(result, equals('userService'));
    });

    test('should work with different registry implementations', () {
      final definition = MockPodDefinition(
        name: 'ignored',
        type: Class<UserService>(),
      );

      // Test with different registry mock
      final emptyRegistry = _EmptyPodDefinitionRegistry();
      final result = generator.generate(definition, emptyRegistry);
      expect(result, equals('userService'));
    });

    test('should be consistent across multiple calls', () {
      final definition = MockPodDefinition(
        name: 'ignored',
        type: Class<UserService>(),
      );

      // Multiple calls should return the same result
      final result1 = generator.generate(definition, registry);
      final result2 = generator.generate(definition, registry);
      final result3 = generator.generate(definition, registry);

      expect(result1, equals('userService'));
      expect(result2, equals('userService'));
      expect(result3, equals('userService'));
      expect(result1, equals(result2));
      expect(result2, equals(result3));
    });

    test('should handle single uppercase character classes', () {
      final definition = MockPodDefinition(
        name: 'ignored',
        type: Class<U>(),
      );

      final result = generator.generate(definition, registry);
      expect(result, equals('u'));
    });

    test('should handle two uppercase characters (acronym pattern)', () {
      final definition = MockPodDefinition(
        name: 'ignored',
        type: Class<UU>(),
      );

      final result = generator.generate(definition, registry);
      expect(result, equals('UU'));
    });

    test('should handle first uppercase, second lowercase', () {
      final definition = MockPodDefinition(
        name: 'ignored',
        type: Class<Uu>(),
      );

      final result = generator.generate(definition, registry);
      expect(result, equals('uu'));
    });

    test('should handle first lowercase, second uppercase', () {
      final definition = MockPodDefinition(
        name: 'ignored',
        type: Class<uU>(),
      );

      final result = generator.generate(definition, registry);
      expect(result, equals('uU'));
    });

    test('should handle uppercase followed by number', () {
      final definition = MockPodDefinition(
        name: 'ignored',
        type: Class<U1>(),
      );

      final result = generator.generate(definition, registry);
      expect(result, equals('u1'));
    });

    test('should handle uppercase followed by number (A1)', () {
      final definition = MockPodDefinition(
        name: 'ignored',
        type: Class<A1>(),
      );

      final result = generator.generate(definition, registry);
      expect(result, equals('a1'));
    });

    test('should handle class names with underscore in middle', () {
      final definition = MockPodDefinition(
        name: 'ignored',
        type: Class<A_B>(),
      );

      final result = generator.generate(definition, registry);
      expect(result, equals('a_B'));
    });

    test('should handle the registry being unused in generation', () {
      final definition = MockPodDefinition(
        name: 'ignored',
        type: Class<UserService>(),
      );

      // The result should be the same regardless of registry content
      final result1 = generator.generate(definition, registry);
      final result2 = generator.generate(definition, _DifferentRegistry());

      expect(result1, equals('userService'));
      expect(result2, equals('userService'));
      expect(result1, equals(result2));
    });

    test('should handle definition with different name values', () {
      final testNames = ['', 'test', 'customName', '123', '_private'];

      for (final name in testNames) {
        final definition = MockPodDefinition(
          name: name,
          type: Class<UserService>(),
        );

        final result = generator.generate(definition, registry);
        // All should produce the same result regardless of definition.name
        expect(result, equals('userService'));
      }
    });
  });
}

// Mock registry for testing
class _EmptyPodDefinitionRegistry implements PodDefinitionRegistry {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DifferentRegistry implements PodDefinitionRegistry {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}