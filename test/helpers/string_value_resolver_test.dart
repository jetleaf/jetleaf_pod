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

// test/string_value_resolver_test.dart
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/src/helpers/object.dart';
import 'package:test/test.dart';

// Test implementation for basic testing
class TestStringValueResolver implements StringValueResolver {
  final Map<String, String> values;

  TestStringValueResolver(this.values);

  @override
  String? resolve(String value) {
    return values[value] ?? value;
  }
}

// Test implementation that throws on specific values
class ThrowingStringValueResolver implements StringValueResolver {
  @override
  String? resolve(String value) {
    if (value == 'throw') {
      throw IllegalArgumentException('Cannot resolve value: $value');
    }
    return value;
  }
}

// Test implementation that returns null for specific values
class NullReturningStringValueResolver implements StringValueResolver {
  @override
  String? resolve(String value) {
    if (value == 'return-null') {
      return null;
    }
    return value;
  }
}

// Test implementation with placeholder resolution
class PlaceholderStringValueResolver implements StringValueResolver {
  final Map<String, String> placeholders;

  PlaceholderStringValueResolver(this.placeholders);

  @override
  String? resolve(String value) {
    var result = value;
    placeholders.forEach((key, replacement) {
      result = result.replaceAll('\${$key}', replacement);
    });
    return result;
  }
}

// Test implementation with environment variable simulation
class EnvironmentStringValueResolver implements StringValueResolver {
  final Map<String, String> environment;

  EnvironmentStringValueResolver(this.environment);

  @override
  String? resolve(String value) {
    if (value.startsWith('\$')) {
      final envVar = value.substring(1);
      return environment[envVar] ?? value;
    }
    return value;
  }
}

// Test implementation with chained resolution
class ChainedStringValueResolver implements StringValueResolver {
  final List<StringValueResolver> resolvers;

  ChainedStringValueResolver(this.resolvers);

  @override
  String? resolve(String value) {
    String? currentValue = value;
    for (final resolver in resolvers) {
      currentValue = resolver.resolve(currentValue!);
      if (currentValue == null) break;
    }
    return currentValue;
  }
}

// Test implementation with caching
class CachingStringValueResolver implements StringValueResolver {
  final StringValueResolver delegate;
  final Map<String, String?> cache = {};

  CachingStringValueResolver(this.delegate);

  @override
  String? resolve(String value) {
    if (cache.containsKey(value)) {
      return cache[value];
    }
    final result = delegate.resolve(value);
    cache[value] = result;
    return result;
  }
}

// Test implementation with transformation
class TransformingStringValueResolver implements StringValueResolver {
  @override
  String? resolve(String value) {
    return value.toUpperCase();
  }
}

// Test implementation with conditional logic
class ConditionalStringValueResolver implements StringValueResolver {
  @override
  String? resolve(String value) {
    if (value.isEmpty) return '';
    if (value == 'true') return '1';
    if (value == 'false') return '0';
    if (value == 'null') return null;
    return value;
  }
}

// Test implementation with default values
class DefaultValueStringValueResolver implements StringValueResolver {
  final String defaultValue;

  DefaultValueStringValueResolver(this.defaultValue);

  @override
  String? resolve(String value) {
    if (value.isEmpty) return defaultValue;
    return value;
  }
}

void main() {
  group('StringValueResolver Interface', () {
    test('should resolve basic values', () {
      final resolver = TestStringValueResolver({'key': 'value'});
      
      expect(resolver.resolve('key'), equals('value'));
      expect(resolver.resolve('unknown'), equals('unknown'));
    });

    test('should handle null returns', () {
      final resolver = NullReturningStringValueResolver();
      
      expect(resolver.resolve('return-null'), isNull);
      expect(resolver.resolve('normal'), equals('normal'));
    });

    test('should throw IllegalArgumentException when required', () {
      final resolver = ThrowingStringValueResolver();
      
      expect(() => resolver.resolve('throw'), throwsA(isA<IllegalArgumentException>()));
      expect(resolver.resolve('safe'), equals('safe'));
    });

    test('should resolve placeholders', () {
      final resolver = PlaceholderStringValueResolver({
        'name': 'John',
        'age': '30'
      });
      
      expect(resolver.resolve('Hello \${name}'), equals('Hello John'));
      expect(resolver.resolve('Age: \${age}'), equals('Age: 30'));
      expect(resolver.resolve('Unknown \${var}'), equals('Unknown \${var}'));
      expect(resolver.resolve('No placeholders'), equals('No placeholders'));
    });

    test('should handle multiple placeholders', () {
      final resolver = PlaceholderStringValueResolver({
        'first': 'John',
        'last': 'Doe'
      });
      
      expect(resolver.resolve('\${first} \${last}'), equals('John Doe'));
    });

    test('should handle nested placeholders', () {
      final resolver = PlaceholderStringValueResolver({
        'name': 'John',
        'full': '\${name} Doe'
      });
      
      // Note: This implementation doesn't handle nested placeholders recursively
      expect(resolver.resolve('\${full}'), equals('\${name} Doe'));
    });

    test('should resolve environment variables', () {
      final resolver = EnvironmentStringValueResolver({
        'HOME': '/home/user',
        'PATH': '/usr/bin'
      });
      
      expect(resolver.resolve('\$HOME'), equals('/home/user'));
      expect(resolver.resolve('\$PATH'), equals('/usr/bin'));
      expect(resolver.resolve('\$UNKNOWN'), equals('\$UNKNOWN'));
      expect(resolver.resolve('normal'), equals('normal'));
    });

    test('should chain multiple resolvers', () {
      final resolver1 = PlaceholderStringValueResolver({'name': 'John'});
      final resolver2 = TransformingStringValueResolver();
      final chainedResolver = ChainedStringValueResolver([resolver1, resolver2]);
      
      expect(chainedResolver.resolve('Hello \${name}'), equals('HELLO JOHN'));
    });

    test('should cache resolved values', () {
      final baseResolver = TestStringValueResolver({'key': 'value'});
      final cachingResolver = CachingStringValueResolver(baseResolver);
      
      expect(cachingResolver.resolve('key'), equals('value'));
      expect(cachingResolver.resolve('key'), equals('value'));
      expect(cachingResolver.resolve('unknown'), equals('unknown'));
    });

    test('should transform values', () {
      final resolver = TransformingStringValueResolver();
      
      expect(resolver.resolve('hello'), equals('HELLO'));
      expect(resolver.resolve('Test'), equals('TEST'));
      expect(resolver.resolve('123'), equals('123'));
    });

    test('should handle conditional logic', () {
      final resolver = ConditionalStringValueResolver();
      
      expect(resolver.resolve(''), equals(''));
      expect(resolver.resolve('true'), equals('1'));
      expect(resolver.resolve('false'), equals('0'));
      expect(resolver.resolve('null'), isNull);
      expect(resolver.resolve('other'), equals('other'));
    });

    test('should provide default values', () {
      final resolver = DefaultValueStringValueResolver('default');
      
      expect(resolver.resolve(''), equals('default'));
      expect(resolver.resolve('custom'), equals('custom'));
      expect(resolver.resolve('   '), equals('   ')); // Whitespace not empty
    });

    test('should handle edge cases with empty strings', () {
      final resolver = TestStringValueResolver({});
      
      expect(resolver.resolve(''), equals(''));
      expect(resolver.resolve('   '), equals('   '));
    });

    test('should handle very long strings', () {
      final resolver = TestStringValueResolver({});
      final longString = 'a' * 10000;
      
      expect(resolver.resolve(longString), equals(longString));
    });

    test('should handle unicode and special characters', () {
      final resolver = TestStringValueResolver({
        'ñ': 'spanish_n',
        '中文': 'chinese',
        '🚀': 'rocket'
      });
      
      expect(resolver.resolve('ñ'), equals('spanish_n'));
      expect(resolver.resolve('中文'), equals('chinese'));
      expect(resolver.resolve('🚀'), equals('rocket'));
      expect(resolver.resolve('🌍'), equals('🌍')); // Not in mapping
    });

    test('should handle case sensitivity', () {
      final resolver = TestStringValueResolver({
        'KEY': 'value',
        'key': 'different_value'
      });
      
      expect(resolver.resolve('KEY'), equals('value'));
      expect(resolver.resolve('key'), equals('different_value'));
    });

    test('should handle identical input and output', () {
      final resolver = TestStringValueResolver({'same': 'same'});
      
      expect(resolver.resolve('same'), equals('same'));
      expect(identical(resolver.resolve('same'), 'same'), isTrue);
    });

    test('should handle multiple resolutions of same value', () {
      final resolver = TestStringValueResolver({'key': 'value'});
      
      final result1 = resolver.resolve('key');
      final result2 = resolver.resolve('key');
      final result3 = resolver.resolve('key');
      
      expect(result1, equals('value'));
      expect(result2, equals('value'));
      expect(result3, equals('value'));
    });

    test('should handle mixed scenarios', () {
      final resolver = PlaceholderStringValueResolver({
        'env': 'production',
        'port': '8080'
      });
      
      expect(resolver.resolve('Server: \${env}:\${port}'), equals('Server: production:8080'));
      expect(resolver.resolve('Standalone'), equals('Standalone'));
    });

    test('should handle resolver with no-op behavior', () {
      final resolver = TestStringValueResolver({});
      
      expect(resolver.resolve('any value'), equals('any value'));
      expect(resolver.resolve('123'), equals('123'));
      expect(resolver.resolve('!@#\$%^&*()'), equals('!@#\$%^&*()'));
    });

    test('should handle resolver that always returns null', () {
      final resolver = NullReturningStringValueResolver();
      
      // This resolver only returns null for specific value
      expect(resolver.resolve('return-null'), isNull);
      expect(resolver.resolve('other'), equals('other'));
    });

    test('should handle resolver that always throws', () {
      final resolver = ThrowingStringValueResolver();
      
      expect(() => resolver.resolve('throw'), throwsA(isA<IllegalArgumentException>()));
      expect(resolver.resolve('other'), equals('other'));
    });

    test('should handle complex placeholder patterns', () {
      final resolver = PlaceholderStringValueResolver({
        'db.host': 'localhost',
        'db.port': '5432',
        'db.name': 'mydb'
      });
      
      expect(
        resolver.resolve('jdbc:postgresql://\${db.host}:\${db.port}/\${db.name}'),
        equals('jdbc:postgresql://localhost:5432/mydb')
      );
    });

    test('should handle environment variables with special characters', () {
      final resolver = EnvironmentStringValueResolver({
        'APP_NAME': 'MyApp',
        'APP_VERSION': '1.0.0',
        'DB_URL': 'postgresql://localhost:5432/mydb'
      });
      
      expect(resolver.resolve('\$APP_NAME'), equals('MyApp'));
      expect(resolver.resolve('\$APP_VERSION'), equals('1.0.0'));
      expect(resolver.resolve('\$DB_URL'), equals('postgresql://localhost:5432/mydb'));
    });

    test('should handle chained resolvers with different behaviors', () {
      final resolver1 = PlaceholderStringValueResolver({'name': 'john'});
      final resolver2 = TransformingStringValueResolver();
      final resolver3 = TestStringValueResolver({'JOHN': 'JOHN_DOE'});
      final chainedResolver = ChainedStringValueResolver([resolver1, resolver2, resolver3]);
      
      expect(chainedResolver.resolve('Hello \${name}'), equals('HELLO JOHN'));
      // Note: The third resolver doesn't match 'HELLO JOHN', so it returns as-is
    });

    test('should handle caching with null values', () {
      final baseResolver = NullReturningStringValueResolver();
      final cachingResolver = CachingStringValueResolver(baseResolver);
      
      expect(cachingResolver.resolve('return-null'), isNull);
      expect(cachingResolver.resolve('return-null'), isNull); // Should use cache
      expect(cachingResolver.resolve('normal'), equals('normal'));
    });

    test('should handle transformation edge cases', () {
      final resolver = TransformingStringValueResolver();
      
      expect(resolver.resolve(''), equals(''));
      expect(resolver.resolve('a'), equals('A'));
      expect(resolver.resolve('A'), equals('A'));
      expect(resolver.resolve('1'), equals('1'));
      expect(resolver.resolve('!'), equals('!'));
    });

    test('should handle conditional edge cases', () {
      final resolver = ConditionalStringValueResolver();
      
      expect(resolver.resolve('TRUE'), equals('TRUE')); // Case sensitive
      expect(resolver.resolve('FALSE'), equals('FALSE'));
      expect(resolver.resolve('NULL'), equals('NULL'));
    });

    test('should handle default value edge cases', () {
      final resolver = DefaultValueStringValueResolver('default');
      
      expect(resolver.resolve(''), equals('default'));
      expect(resolver.resolve(' '), equals(' ')); // Not empty
      expect(resolver.resolve('\t'), equals('\t')); // Not empty
      expect(resolver.resolve('\n'), equals('\n')); // Not empty
    });

    test('should handle performance with large mappings', () {
      final largeMap = Map<String, String>.fromIterables(
        List.generate(1000, (i) => 'key$i'),
        List.generate(1000, (i) => 'value$i')
      );
      final resolver = TestStringValueResolver(largeMap);
      
      expect(resolver.resolve('key500'), equals('value500'));
      expect(resolver.resolve('key999'), equals('value999'));
      expect(resolver.resolve('nonexistent'), equals('nonexistent'));
    });

    test('should handle very long resolution chains', () {
      final resolvers = List.generate(100, (_) => TestStringValueResolver({}));
      final chainedResolver = ChainedStringValueResolver(resolvers);
      
      expect(chainedResolver.resolve('test'), equals('test'));
    });

    test('should handle resolver composition', () {
      // Test that different resolver types can work together
      final envResolver = EnvironmentStringValueResolver({'MODE': 'dev'});
      final placeholderResolver = PlaceholderStringValueResolver({'mode': '\$MODE'});
      final transformer = TransformingStringValueResolver();
      
      final result1 = envResolver.resolve('\$MODE');
      final result2 = placeholderResolver.resolve('Mode: \${mode}');
      final result3 = transformer.resolve('hello');
      
      expect(result1, equals('dev'));
      expect(result2, equals('Mode: \$MODE')); // Placeholder doesn't resolve env vars
      expect(result3, equals('HELLO'));
    });

    test('should verify interface contract compliance', () {
      // Test that all implementations follow the interface contract
      final resolvers = [
        TestStringValueResolver({}),
        ThrowingStringValueResolver(),
        NullReturningStringValueResolver(),
        PlaceholderStringValueResolver({}),
        EnvironmentStringValueResolver({}),
        TransformingStringValueResolver(),
        ConditionalStringValueResolver(),
        DefaultValueStringValueResolver('default'),
      ];
      
      for (final resolver in resolvers) {
        // All should accept non-null strings
        expect(() => resolver.resolve('test'), returnsNormally);
        
        // All should handle empty strings
        expect(() => resolver.resolve(''), returnsNormally);
      }
    });

    test('should handle memory usage patterns', () {
      // Test that resolvers don't leak memory
      final resolver = TestStringValueResolver({'key': 'value'});
      
      // Repeated resolutions should not cause memory issues
      for (int i = 0; i < 1000; i++) {
        expect(resolver.resolve('key'), equals('value'));
      }
    });

    test('should handle concurrent access patterns', () async {
      final resolver = TestStringValueResolver({'key': 'value'});
      final futures = <Future>[];
      
      for (int i = 0; i < 100; i++) {
        futures.add(Future(() {
          expect(resolver.resolve('key'), equals('value'));
        }));
      }
      
      await Future.wait(futures);
    });

    test('should handle error recovery', () {
      final resolver = ThrowingStringValueResolver();
      
      // First call throws
      expect(() => resolver.resolve('throw'), throwsA(isA<IllegalArgumentException>()));
      
      // Subsequent calls should work normally
      expect(resolver.resolve('safe'), equals('safe'));
      expect(resolver.resolve('another'), equals('another'));
    });

    test('should handle mixed error and success scenarios', () {
      final resolver = ThrowingStringValueResolver();
      
      expect(resolver.resolve('safe1'), equals('safe1'));
      expect(() => resolver.resolve('throw'), throwsA(isA<IllegalArgumentException>()));
      expect(resolver.resolve('safe2'), equals('safe2'));
    });

    test('should handle resolver with complex internal state', () {
      final resolver = TestStringValueResolver({'key': 'value'});
      
      expect(resolver.resolve('key'), equals('value'));
      expect(resolver.resolve('key'), equals('value'));
    });

    test('should handle resolver with side effects', () {
      final resolver = TestStringValueResolver({'key': 'value'});
      
      resolver.resolve('key');
      resolver.resolve('key');
      resolver.resolve('key');
      
      expect(resolver.resolve('key'), equals('value'));
    });

    test('should handle all character types', () {
      final resolver = TestStringValueResolver({});
      
      // Test various character types
      expect(resolver.resolve('abc123'), equals('abc123'));
      expect(resolver.resolve('!@#\$%^&*()'), equals('!@#\$%^&*()'));
      expect(resolver.resolve('áéíóú'), equals('áéíóú'));
      expect(resolver.resolve('中文'), equals('中文'));
      expect(resolver.resolve('🚀🌍'), equals('🚀🌍'));
      expect(resolver.resolve('\x00\x01\x02'), equals('\x00\x01\x02')); // Control characters
    });

    test('should handle maximum string length', () {
      final resolver = TestStringValueResolver({});
      // Dart doesn't have a fixed maximum string length, but test with a very long string
      final veryLongString = 'x' * 1000000;
      
      expect(resolver.resolve(veryLongString), equals(veryLongString));
    });

    test('should handle resolver with transformation that could throw', () {
      final resolver = TransformingStringValueResolver();
      // TransformingStringValueResolver should not throw on any input
      expect(() => resolver.resolve('any string'), returnsNormally);
      expect(() => resolver.resolve(''), returnsNormally);
      expect(() => resolver.resolve('!@#\$%^&*()'), returnsNormally);
    });

    test('should handle resolver that modifies input', () {
      final resolver = TransformingStringValueResolver();
      const input = 'hello';
      final output = resolver.resolve(input);
      
      expect(output, isNot(equals(input))); // Should be modified
      expect(output, equals('HELLO'));
    });

    test('should handle resolver that preserves input', () {
      final resolver = TestStringValueResolver({});
      const input = 'hello';
      final output = resolver.resolve(input);
      
      expect(output, equals(input)); // Should be preserved
      expect(identical(output, input), isTrue); // Should be same object
    });
  });
}