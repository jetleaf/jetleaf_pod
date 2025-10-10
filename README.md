# jetleaf_pod

🫘 A lightweight, modular **dependency injection (DI)** and **inversion-of-control (IoC)** library for the JetLeaf framework ecosystem.

`jetleaf_pod` provides a flexible set of factories, registries, definitions, scopes, and lifecycle hooks to manage object creation, dependency resolution, and application startup in a structured way.

- Homepage: https://jetleaf.hapnium.com
- Repository: https://github.com/jetleaf/jetleaf_pod
- License: See `LICENSE`

## Contents
- **[Features](#features)**
- **[Install](#install)**
- **[Quick Start](#quick-start)**
- **[Core Concepts](#core-concepts)**
  - **[Pod Factory](#pod-factory)**
  - **[Pod Definitions](#pod-definitions)**
  - **[Scopes](#scopes)**
  - **[Lifecycle Hooks](#lifecycle-hooks)**
  - **[Autowiring](#autowiring)**
  - **[Startup Tracking](#startup-tracking)**
- **[Usage](#usage)**
  - **[Basic Pod Registration](#basic-pod-registration)**
  - **[Dependency Injection](#dependency-injection)**
  - **[Scoped Pods](#scoped-pods)**
  - **[Lifecycle Management](#lifecycle-management)**
  - **[Alias Registry](#alias-registry)**
  - **[Application Startup](#application-startup)**
- **[API Reference](#api-reference)**
- **[Testing](#testing)**
- **[Changelog](#changelog)**
- **[Contributing](#contributing)**
- **[Compatibility](#compatibility)**

## Features
- **Pod Factory** – Central container for creating, managing, and retrieving components (pods).
- **Pod Definitions** – Metadata-driven configuration for pods with scopes, lifecycle, and dependencies.
- **Scopes** – Singleton, prototype, and custom scope support for contextual lifetimes.
- **Autowiring** – Automatic dependency injection by type or name.
- **Lifecycle Hooks** – `InitializingPod`, `DisposablePod`, and `SmartInitializingSingleton` interfaces.
- **Alias Registry** – Manage alternative names for pods.
- **Startup Tracking** – Monitor and profile application startup phases.
- **Extensible** – Custom factories, scopes, and processors.

## Install
Add to your `pubspec.yaml`:

```yaml
dependencies:
  jetleaf_pod:
    hosted: https://onepub.dev/api/fahnhnofly/
    version: ^1.0.0
```

Minimum SDK: Dart ^3.9.0

Import:

```dart
import 'package:jetleaf_pod/pod.dart';
```

## Quick Start
```dart
import 'package:jetleaf_pod/pod.dart';

class MyService {
  void doWork() => print('Working...');
}

class MyController {
  final MyService service;
  
  MyController(this.service);
  
  void execute() => service.doWork();
}

void main() async {
  final factory = DefaultListablePodFactory();

  // Register pods
  factory.registerDefinition(
    PodDefinition(
      name: 'myService',
      type: Class<MyService>(),
    ),
  );

  factory.registerDefinition(
    PodDefinition(
      name: 'myController',
      type: Class<MyController>(),
    ),
  );

  // Retrieve and use
  final controller = await factory.getPod<MyController>('myController');
  controller.execute(); // Output: Working...
}
```

## Core Concepts

### Pod Factory
The `PodFactory` is the central container for managing pods (components). It provides:
- **Pod retrieval** by name or type
- **Dependency resolution** and injection
- **Lifecycle management** (initialization, destruction)
- **Scope management** (singleton, prototype, custom)

Key implementations:
- `DefaultListablePodFactory` – Full-featured factory with autowiring and lifecycle support
- `AbstractPodFactory` – Base implementation for custom factories
- `AutowirePodFactory` – Interface for automatic dependency injection

### Pod Definitions
A `PodDefinition` is the blueprint for a pod, containing:
- **Name** and **type** (`Class`)
- **Scope** (singleton, prototype, custom)
- **Lifecycle** (lazy init, init methods, destroy methods)
- **Dependencies** (explicit `dependsOn` relationships)
- **Autowiring** configuration (by type, by name, or disabled)
- **Factory methods** for custom instantiation
- **Constructor arguments** and **property values**

```dart
final podDef = PodDefinition(
  name: 'userService',
  type: Class<UserService>(),
  scope: ScopeDesign(
    type: ScopeType.SINGLETON.name,
    isSingleton: true,
    isPrototype: false,
  ),
  lifecycle: LifecycleDesign(
    isLazy: false,
    initMethods: ['initialize'],
    destroyMethods: ['dispose'],
  ),
  autowireCandidate: AutowireCandidateDescriptor(
    autowireCandidate: true,
    autowireMode: AutowireMode.BY_TYPE,
  ),
);
```

### Scopes
Scopes control the lifecycle and visibility of pods:
- **Singleton** – One instance per container (default)
- **Prototype** – New instance for each request
- **Custom** – Implement `PodScope` for request, session, or application-specific scopes

```dart
abstract class PodScope {
  Future<ObjectHolder<Object>> get(String name, ObjectFactory<Object> factory);
  ObjectHolder<Object>? remove(String name);
  void registerDestructionCallback(String name, Runnable callback);
  Object? resolveContextualObject(String key);
  String? getConversationId();
}
```

### Lifecycle Hooks
Pods can implement lifecycle interfaces:
- **`InitializingPod`** – Called after properties are set (`onReady()`)
- **`DisposablePod`** – Called during shutdown (`onDestroy()`)
- **`SmartInitializingSingleton`** – Called once after all singletons are ready (`onSingletonReady()`)

```dart
class MyRepository implements InitializingPod, DisposablePod {
  late DatabaseClient client;

  @override
  Future<void> onReady() async {
    await client.connect();
  }

  @override
  Future<void> onDestroy() async {
    await client.close();
  }
}
```

### Autowiring
Automatic dependency injection by type or name:
- **`AutowireMode.BY_TYPE`** – Inject by matching type
- **`AutowireMode.BY_NAME`** – Inject by matching property name
- **`AutowireMode.CONSTRUCTOR`** – Inject via constructor parameters
- **`AutowireMode.NO`** – Manual wiring only

```dart
final factory = DefaultListablePodFactory();

// Autowire by type
await factory.autowirePod(myController, Class<MyController>());

// Explicit wiring
final service = await factory.get<MyService>();
```

### Startup Tracking
Monitor and profile application startup:
- **`StartupTracker`** – Track startup time and phases
- **`StartupStep`** – Record metrics for specific startup actions
- **`ApplicationStartup`** – Orchestrate startup steps with tagging

```dart
final startup = StartupTracker.create();
final step = applicationStartup.start('context.refresh');
step.tag('pod.name', value: 'dataSource');
step.end();

final duration = startup.started();
print('Started in ${duration.inMilliseconds}ms');
```

## Usage

### Basic Pod Registration
```dart
final factory = DefaultListablePodFactory();

// Register a pod definition
factory.registerDefinition(
  PodDefinition(
    name: 'emailService',
    type: Class<EmailService>(),
  ),
);

// Retrieve the pod
final emailService = await factory.getPod<EmailService>('emailService');
await emailService.sendWelcomeEmail();
```

### Dependency Injection
```dart
class DatabaseService {
  void connect() => print('Connected to database');
}

class UserRepository {
  final DatabaseService db;
  
  UserRepository(this.db);
  
  void save() => db.connect();
}

// Register both pods
factory.registerDefinition(PodDefinition(
  name: 'databaseService',
  type: Class<DatabaseService>(),
));

factory.registerDefinition(PodDefinition(
  name: 'userRepository',
  type: Class<UserRepository>(),
  autowireCandidate: AutowireCandidateDescriptor(
    autowireCandidate: true,
    autowireMode: AutowireMode.CONSTRUCTOR,
  ),
));

// Retrieve with automatic injection
final repo = await factory.getPod<UserRepository>('userRepository');
repo.save(); // Output: Connected to database
```

### Scoped Pods
```dart
// Singleton (default)
factory.registerDefinition(PodDefinition(
  name: 'appConfig',
  type: Class<AppConfig>(),
  scope: ScopeDesign(
    type: ScopeType.SINGLETON.name,
    isSingleton: true,
    isPrototype: false,
  ),
));

// Prototype (new instance each time)
factory.registerDefinition(PodDefinition(
  name: 'requestContext',
  type: Class<RequestContext>(),
  scope: ScopeDesign(
    type: ScopeType.PROTOTYPE.name,
    isSingleton: false,
    isPrototype: true,
  ),
));

final config1 = await factory.getPod<AppConfig>('appConfig');
final config2 = await factory.getPod<AppConfig>('appConfig');
print(identical(config1, config2)); // true (singleton)

final ctx1 = await factory.getPod<RequestContext>('requestContext');
final ctx2 = await factory.getPod<RequestContext>('requestContext');
print(identical(ctx1, ctx2)); // false (prototype)
```

### Lifecycle Management
```dart
class MyService implements InitializingPod, DisposablePod {
  @override
  Future<void> onReady() async {
    print('Service initialized');
  }

  @override
  Future<void> onDestroy() async {
    print('Service destroyed');
  }
}

factory.registerDefinition(PodDefinition(
  name: 'myService',
  type: Class<MyService>(),
  lifecycle: LifecycleDesign(
    isLazy: false,
    initMethods: ['onReady'],
    destroyMethods: ['onDestroy'],
  ),
));

// Service will be initialized when retrieved
final service = await factory.getPod<MyService>('myService');
// Output: Service initialized

// Destroy the service
await factory.destroySingleton('myService');
// Output: Service destroyed
```

### Alias Registry
```dart
final aliasRegistry = SimpleAliasRegistry();

// Register aliases
aliasRegistry.registerAlias('primaryDataSource', 'dataSource');
aliasRegistry.registerAlias('mainDB', 'dataSource');

// Retrieve by alias
final aliases = aliasRegistry.getAliases('dataSource');
print(aliases); // ['primaryDataSource', 'mainDB']

// Check canonical name
final canonical = aliasRegistry.canonicalName('mainDB');
print(canonical); // 'dataSource'
```

### Application Startup
```dart
final startup = StartupTracker.create();
final appStartup = ApplicationStartup();

// Start tracking a phase
final step = appStartup.start('context.refresh');
step.tag('phase', value: 'initialization');

// Perform initialization work
await initializeContext();

// End the step
step.end();

// Mark application as started
final duration = startup.started();
print('Application started in ${duration.inMilliseconds}ms');
```

## API Reference

### Core Exports (`lib/pod.dart`)
- **Alias**: `AliasRegistry`, `SimpleAliasRegistry`
- **Core**: `PodFactory`, `AutowirePodFactory`, `DefaultListablePodFactory`, `AbstractPodFactory`
- **Definition**: `PodDefinition`, `PodDefinitionRegistry`, `SimplePodDefinitionRegistry`
- **Expression**: `PodExpression`
- **Helpers**: `NullablePod`, `ObjectProvider`, `ObjectHolder`, `ObjectFactory`
- **Instantiation**: `ExecutableStrategy`, `ArgumentValueHolder`
- **Lifecycle**: `InitializingPod`, `DisposablePod`, `SmartInitializingSingleton`, `PodPostProcessor`
- **Name Generator**: `PodNameGenerator`, `SimplePodNameGenerator`
- **Scope**: `PodScope`
- **Singleton**: `SingletonPodRegistry`
- **Startup**: `StartupTracker`, `StartupStep`, `ApplicationStartup`
- **Exceptions**: `PodException`, `PodNotFoundException`, `PodCreationException`

See `lib/pod.dart` for the full export list and `lib/src/` for implementation details.

## Testing
Run tests with:

```bash
dart test
```

See `test/` for coverage of factories, definitions, scopes, lifecycle, and startup tracking.

## Changelog
See `CHANGELOG.md`.

## Contributing
Issues and PRs are welcome at the GitHub repository.

1. Fork and create a feature branch.
2. Add tests for new functionality.
3. Run `dart test` and ensure lints pass.
4. Open a PR with a concise description and examples.

## Compatibility
- Dart SDK: `>=3.9.0 <4.0.0`
- Depends on `jetleaf_lang`, `jetleaf_logging`, `jetleaf_convert`, `jetleaf_utils`, `jetleaf_env` (see `pubspec.yaml`).

---

Built with 🫘 by the JetLeaf team.
