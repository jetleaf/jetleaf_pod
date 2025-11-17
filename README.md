# 🫘 JetLeaf Pod — Dependency Injection & IoC Container

[![pub package](https://img.shields.io/badge/version-1.0.0-blue)](https://pub.dev/packages/jetleaf_pod)
[![License](https://img.shields.io/badge/license-JetLeaf-green)](#license)
[![Dart SDK](https://img.shields.io/badge/sdk-%3E%3D3.9.0-blue)](https://dart.dev)

A lightweight, modular dependency injection (DI) and inversion-of-control (IoC) container for managing object creation, dependency resolution, and application lifecycle in JetLeaf applications.

## 📋 Overview

`jetleaf_pod` provides a flexible DI/IoC framework with:

- **Pod Factories** — Define and resolve object creation strategies
- **Pod Definitions** — Register metadata and configuration for pods
- **Lifecycle Hooks** — Control object initialization and destruction
- **Scopes** — Manage pod lifetimes (singleton, prototype, request-scoped)
- **Alias Registry** — Map multiple names to the same pod
- **Pod Expressions** — Evaluate and transform pod references
- **Startup Orchestration** — Coordinate application initialization

## 🚀 Quick Start

### Installation

```yaml
dependencies:
  jetleaf_pod:
    path: ./jetleaf_pod
```

### Basic Usage

```dart
import 'package:jetleaf_pod/jetleaf_pod.dart';

class UserService {
  String getUser(String id) => 'User: $id';
}

void main() {
  // Create a pod factory
  final factory = DefaultListablePodFactory();

  // Register a pod definition
  factory.registerDefinition(
    PodDefinition(
      name: 'userService',
      create: () => UserService(),
      scope: Scope.singleton,
    ),
  );

  // Retrieve and use the pod
  final userService = factory.getPod<UserService>('userService');
  print(userService.getUser('123'));  // Output: User: 123
}
```

## 📚 Key Components

### 1. Pod Factories

**DefaultListablePodFactory** — The main factory for pod creation and management:

```dart
import 'package:jetleaf_pod/jetleaf_pod.dart';

void main() {
  final factory = DefaultListablePodFactory();

  // Register pods
  factory.registerDefinition(
    PodDefinition(
      name: 'database',
      create: () => Database('localhost', 5432),
      scope: Scope.singleton,
    ),
  );

  // Get pod by name
  final db = factory.getPod<Database>('database');

  // Get pod by type (requires only one pod of that type)
  final db2 = factory.getPod<Database>();

  // Check if pod exists
  final exists = factory.containsPod('database');

  // Get all pods of a type
  final allDatabases = factory.getPodsOfType<Database>();
}

class Database {
  final String host;
  final int port;
  Database(this.host, this.port);
}
```

### 2. Pod Definitions

**PodDefinition** — Register objects and their creation strategy:

```dart
// Factory function definition
final def1 = PodDefinition(
  name: 'service',
  create: () => MyService(),
  scope: Scope.singleton,
  description: 'Main application service',
);

// Factory class instance (lazy instantiation)
final def2 = PodDefinition(
  name: 'logger',
  create: () => Logger(),
  scope: Scope.prototype,  // New instance each time
  lazyInit: true,  // Don't create until requested
);

// Pod with initialization callback
final def3 = PodDefinition(
  name: 'repository',
  create: () {
    final repo = UserRepository();
    repo.initialize();  // Initialize after creation
    return repo;
  },
  scope: Scope.singleton,
);
```

### 3. Scopes

**Pod Lifetimes** — Control when pods are created and destroyed:

```dart
import 'package:jetleaf_pod/jetleaf_pod.dart';

void main() {
  final factory = DefaultListablePodFactory();

  // Singleton: one instance for entire application
  factory.registerDefinition(
    PodDefinition(
      name: 'config',
      create: () => AppConfig(),
      scope: Scope.singleton,
    ),
  );

  // Prototype: new instance each time
  factory.registerDefinition(
    PodDefinition(
      name: 'request',
      create: () => RequestContext(),
      scope: Scope.prototype,
    ),
  );

  // Multiple singletons return same instance
  final config1 = factory.getPod<AppConfig>('config');
  final config2 = factory.getPod<AppConfig>('config');
  assert(identical(config1, config2));  // true

  // Multiple prototypes return different instances
  final req1 = factory.getPod<RequestContext>('request');
  final req2 = factory.getPod<RequestContext>('request');
  assert(identical(req1, req2));  // false
}

class AppConfig {
  final String version = '1.0.0';
}

class RequestContext {
  final String id = DateTime.now().toString();
}
```

### 4. Lifecycle Hooks

**Control object initialization and destruction**:

```dart
import 'package:jetleaf_pod/jetleaf_pod.dart';

class DatabaseConnection {
  late SqliteConnection _connection;

  // Called after pod is created
  Future<void> initialize() async {
    print('Initializing database...');
    _connection = await SqliteConnection.connect(':memory:');
  }

  // Called before pod is destroyed
  Future<void> destroy() async {
    print('Closing database...');
    await _connection.close();
  }
}

void main() {
  final factory = DefaultListablePodFactory();

  factory.registerDefinition(
    PodDefinition(
      name: 'database',
      create: () => DatabaseConnection(),
      scope: Scope.singleton,
      initMethod: 'initialize',  // Lifecycle method names
      destroyMethod: 'destroy',
    ),
  );

  // Initialization happens automatically
  final db = factory.getPod<DatabaseConnection>('database');
  
  // Later, when shutting down
  factory.destroy();  // Calls destroy() on all pods
}
```

### 5. Alias Registry

**Register multiple names for the same pod**:

```dart
import 'package:jetleaf_pod/jetleaf_pod.dart';

class EmailService {
  void send(String to, String body) {
    print('Sending email to $to');
  }
}

void main() {
  final factory = DefaultListablePodFactory();
  final aliasRegistry = SimpleAliasRegistry();

  // Register the pod
  factory.registerDefinition(
    PodDefinition(
      name: 'emailService',
      create: () => EmailService(),
      scope: Scope.singleton,
    ),
  );

  // Register aliases
  aliasRegistry.registerAlias('sendEmail', 'emailService');
  aliasRegistry.registerAlias('notificationService', 'emailService');

  // All names point to the same pod
  final service1 = factory.getPod<EmailService>('emailService');
  final service2 = factory.getPod<EmailService>('sendEmail');
  final service3 = factory.getPod<EmailService>('notificationService');
  
  assert(identical(service1, service2));  // true
  assert(identical(service2, service3));  // true
}
```

### 6. Pod Expressions

**Evaluate and reference pods dynamically**:

```dart
import 'package:jetleaf_pod/jetleaf_pod.dart';

void main() {
  final factory = DefaultListablePodFactory();

  // Register a configuration pod
  factory.registerDefinition(
    PodDefinition(
      name: 'config',
      create: () => AppConfig(databaseUrl: 'postgres://localhost'),
      scope: Scope.singleton,
    ),
  );

  // Reference pod properties in expressions
  factory.registerDefinition(
    PodDefinition(
      name: 'database',
      create: () {
        final config = factory.getPod<AppConfig>('config');
        return Database(config.databaseUrl);
      },
      scope: Scope.singleton,
    ),
  );
}

class AppConfig {
  final String databaseUrl;
  AppConfig({required this.databaseUrl});
}

class Database {
  final String url;
  Database(this.url);
}
```

## 🎯 Common Patterns

### Pattern 1: Service Layering

```dart
import 'package:jetleaf_pod/jetleaf_pod.dart';

// Data layer
class UserRepository {
  List<String> getUsers() => ['Alice', 'Bob'];
}

// Business logic layer
class UserService {
  final UserRepository repository;
  
  UserService(this.repository);
  
  List<String> fetchAllUsers() => repository.getUsers();
}

// Presentation layer
class UserController {
  final UserService service;
  
  UserController(this.service);
  
  void displayUsers() {
    final users = service.fetchAllUsers();
    print('Users: $users');
  }
}

void main() {
  final factory = DefaultListablePodFactory();

  // Register repository
  factory.registerDefinition(
    PodDefinition(
      name: 'userRepository',
      create: () => UserRepository(),
      scope: Scope.singleton,
    ),
  );

  // Register service (depends on repository)
  factory.registerDefinition(
    PodDefinition(
      name: 'userService',
      create: () => UserService(factory.getPod('userRepository')),
      scope: Scope.singleton,
    ),
  );

  // Register controller (depends on service)
  factory.registerDefinition(
    PodDefinition(
      name: 'userController',
      create: () => UserController(factory.getPod('userService')),
      scope: Scope.singleton,
    ),
  );

  final controller = factory.getPod<UserController>('userController');
  controller.displayUsers();  // Output: Users: [Alice, Bob]
}
```

### Pattern 2: Configuration-based Pod Registration

```dart
import 'package:jetleaf_pod/jetleaf_pod.dart';

void registerApplicationPods(DefaultListablePodFactory factory) {
  // Register all application pods
  factory.registerDefinition(
    PodDefinition(
      name: 'config',
      create: () => AppConfig.load(),
      scope: Scope.singleton,
    ),
  );

  factory.registerDefinition(
    PodDefinition(
      name: 'logger',
      create: () => Logger(),
      scope: Scope.singleton,
    ),
  );

  factory.registerDefinition(
    PodDefinition(
      name: 'database',
      create: () {
        final config = factory.getPod<AppConfig>('config');
        return Database(config.databaseUrl);
      },
      scope: Scope.singleton,
      initMethod: 'connect',
      destroyMethod: 'disconnect',
    ),
  );
}

void main() {
  final factory = DefaultListablePodFactory();
  registerApplicationPods(factory);

  // Application is now ready to use
  final db = factory.getPod<Database>('database');
  print('Database connected');
}

class AppConfig {
  final String databaseUrl;
  
  AppConfig({required this.databaseUrl});
  
  static AppConfig load() {
    return AppConfig(databaseUrl: 'postgres://localhost:5432/myapp');
  }
}

class Database {
  final String url;
  Database(this.url);
  
  Future<void> connect() async {
    print('Connecting to $url');
  }
  
  Future<void> disconnect() async {
    print('Disconnecting from $url');
  }
}

class Logger {
  void log(String message) => print('[LOG] $message');
}
```

### Pattern 3: Factory Method Pods

```dart
import 'package:jetleaf_pod/jetleaf_pod.dart';

class DataSourceFactory {
  static DataSource createDataSource(String databaseUrl) {
    return DataSource(databaseUrl);
  }
}

void main() {
  final factory = DefaultListablePodFactory();

  // Register pod created by factory method
  factory.registerDefinition(
    PodDefinition(
      name: 'dataSource',
      create: () => DataSourceFactory.createDataSource('postgres://localhost'),
      scope: Scope.singleton,
    ),
  );

  final dataSource = factory.getPod<DataSource>('dataSource');
  print('DataSource: $dataSource');
}

class DataSource {
  final String url;
  DataSource(this.url);
}
```

## ⚠️ Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Pod not found | Name mismatch or not registered | Verify pod name matches registration |
| Circular dependency | Pod A depends on B, B depends on A | Restructure to avoid cycles |
| Wrong type retrieved | Generic type mismatch | Ensure registered and retrieved types match |
| Initialization not called | No initMethod specified | Set `initMethod` in PodDefinition |
| Memory leak | Singleton not destroyed | Call `factory.destroy()` on shutdown |

## 📋 Best Practices

### ✅ DO

- Use singleton scope for stateless services
- Use prototype scope for request-specific objects
- Register pods during application startup
- Use meaningful pod names
- Implement lifecycle methods for resources
- Call `factory.destroy()` on application shutdown
- Register pods centrally in configuration methods
- Use type-safe `getPod<T>()` when possible

### ❌ DON'T

- Create manual singletons instead of using pod factory
- Hold strong references to factory in pods (use dependency injection)
- Register too many prototype-scoped pods
- Forget to call destroy methods
- Create circular dependencies
- Change pod definitions after startup
- Use positional parameters without names

## 📦 Dependencies

- **`jetleaf_lang`** — Language utilities
- **`jetleaf_logging`** — Logging support
- **`jetleaf_convert`** — Type conversion
- **`jetleaf_utils`** — Utility functions
- **`jetleaf_env`** — Configuration support

## 🔗 Related Packages

- **`jetleaf_core`** — Uses pods for DI
- **`jetleaf_web`** — Pod-based HTTP handling
- **`jetleaf_resource`** — Pod-managed resources

## 📄 License

This package is part of the JetLeaf Framework. See LICENSE in the root directory.

## 📞 Support

For issues, questions, or contributions, visit:
- [GitHub Issues](https://github.com/jetleaf/jetleaf_pod/issues)
- [Documentation](https://jetleaf.hapnium.com/docs/pod)
- [Community Forum](https://forum.jetleaf.hapnium.com)

---

**Created with ❤️ by [Hapnium](https://hapnium.com)**
