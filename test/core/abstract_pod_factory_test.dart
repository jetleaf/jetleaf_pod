import 'dart:async';

import 'package:test/test.dart';
import 'package:jetleaf_pod/src/core/default_listable_pod_factory.dart';
import 'package:jetleaf_pod/src/scope/scope.dart';
import 'package:jetleaf_pod/src/helpers/object.dart';
import 'package:jetleaf_lang/lang.dart';

import '../_dependencies.dart';

class _PassthroughScope implements PodScope {
  @override
  Future<ObjectHolder<Object>> get(String name, ObjectFactory<Object> factory) async {
    final holder = await factory.get();
    return ObjectHolder<Object>(holder.getValue(), packageName: holder.getPackageName(), qualifiedName: holder.getQualifiedName());
  }

  @override
  ObjectHolder<Object>? remove(String name) => null;

  @override
  void registerDestructionCallback(String name, Runnable callback) {}

  @override
  Object? resolveContextualObject(String key) => null;

  @override
  String? getConversationId() => null;
}

void main() {
  setUpAll(() async {
    await setupRuntime();
  });
  
  group('AbstractPodFactory basic (via DefaultListablePodFactory)', () {
    test('parent factory propagation', () {
      final parent = DefaultListablePodFactory();
      final child = DefaultListablePodFactory();
      child.setParentFactory(parent);
      expect(child.getParentFactory(), equals(parent));
    });

    test('cache metadata toggle and scope registration', () async {
      final f = DefaultListablePodFactory();
      f.setCachePodMetadata(false);
      expect(f.isCachePodMetadata(), isFalse);

      f.registerScope('test', _PassthroughScope());
      final names = f.getRegisteredScopeNames();
      expect(names.map((e) => e.toLowerCase()), contains('test'));

      final scope = f.getRegisteredScope('test');
      expect(scope, isNotNull);
    });
  });
}
