import 'dart:async';

import 'package:test/test.dart';
import 'package:jetleaf_pod/src/core/abstract_pod_provider_factory.dart';
import 'package:jetleaf_pod/src/helpers/object.dart';
import 'package:jetleaf_pod/src/helpers/nullable_pod.dart';
import 'package:jetleaf_lang/lang.dart';

import '../_dependencies.dart';

class _DummyProvider implements PodProvider<String> {
  final ObjectHolder<String>? _result;

  _DummyProvider(this._result);

  @override
  FutureOr<ObjectHolder<String>?> get([Class? requiredType]) async => _result;

  @override
  Class? getClass() => null;

  @override
  bool isEagerInit() => false;

  @override
  bool isPrototype() => true;

  @override
  bool isSingleton() => false;

  @override
  bool supportsType(Class type) => false;
}

class _TestProviderFactory extends AbstractPodProviderFactory {
  Future<ObjectHolder<Object>> callGetProviderObject(PodProvider provider, Class? type, String name, bool shouldPostProcess) {
    return getProviderObject(provider, type, name, shouldPostProcess);
  }
}

void main() {
  setUpAll(() async {
    await setupRuntime();
  });
  
  group('AbstractPodProviderFactory', () {
    test('returns object from non-singleton provider', () async {
      final factory = _TestProviderFactory();
      final provider = _DummyProvider(ObjectHolder<String>('hello', packageName: 'test', qualifiedName: 'q'));

      final holder = await factory.callGetProviderObject(provider, null, 'p', true);
      expect(holder.getValue(), equals('hello'));
    });

    test('wraps null provider result as NullablePod', () async {
      final factory = _TestProviderFactory();
      final provider = _DummyProvider(null);

      final holder = await factory.callGetProviderObject(provider, null, 'p', true);
      final value = holder.getValue();
      expect(value, isA<NullablePod>());
    });
  });
}
