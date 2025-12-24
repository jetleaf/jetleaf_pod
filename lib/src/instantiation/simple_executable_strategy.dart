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

import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_logging/logging.dart';

import '../core/abstract_autowire_pod_factory.dart';
import '../core/pod_factory.dart';
import '../definition/pod_definition.dart';
import '../exceptions.dart';
import '../helpers/object.dart';
import 'argument_value_holder.dart';
import 'executable_strategy.dart';

/// {@template simple_executable_strategy}
/// A minimal yet powerful implementation of [ExecutableStrategy] used
/// by Jetleaf’s dependency injection container to determine and invoke
/// constructors or factory methods for pod creation.
///
/// This strategy performs **reflective resolution** of constructor and
/// method arguments, merging:
/// - Explicitly provided arguments from user definitions.
/// - Definition-level executable arguments (from [RootPodDefinition]).
/// - Auto-wired dependencies resolved from the [AbstractAutowirePodFactory].
///
/// ### Key Responsibilities
/// - Selects the most appropriate constructor for a given pod type.
/// - Resolves dependencies for constructor and factory method parameters.
/// - Merges explicit arguments with container-managed dependencies.
/// - Provides detailed debug logs for every resolution step.
///
/// ### Typical Usage
/// ```dart
/// final strategy = SimpleExecutableStrategy(factory);
///
/// final holder = await strategy.determineConstructor(
///   rootPodDef,
///   'dataSource',
///   null,
///   [],
/// );
///
/// final executable = holder.executable;
/// final instance = executable.invoke(holder.positionalArgs, holder.namedArgs);
/// ```
/// {@endtemplate}
final class SimpleExecutableStrategy implements ExecutableStrategy {
  /// {@template simple_executable_strategy.factory}
  /// The underlying [AbstractAutowirePodFactory] responsible for:
  /// - Checking the existence of dependency types.
  /// - Resolving dependency candidates during autowiring.
  /// - Looking up pod definitions when factory methods are involved.
  ///
  /// This is the central mechanism through which autowiring occurs.
  /// {@endtemplate}
  final AbstractAutowirePodFactory factory;

  /// Internal logger instance for trace/trace messages related to
  /// constructor and method resolution.
  ///
  /// This is internal to Jetleaf debugging and not part of
  /// the public API contract.
  final Log _logger = LogFactory.getLog(ExecutableStrategy);

  /// {@macro simple_executable_strategy}
  ///
  /// Creates a new [SimpleExecutableStrategy] bound to the given
  /// [factory].
  SimpleExecutableStrategy(this.factory);
  
  @override
  Future<ExecutableHolder> determineConstructor(RootPodDefinition rpd, String podName, List<Constructor>? constructors, List<ArgumentValue>? explicitArgs) async {
    final cls = rpd.type;
    final ctors = constructors ?? cls.getConstructors();

    Constructor? constructor;
    if (ctors.length == 1) {
      constructor = ctors.first;
    } else {
      Constructor? greedyCtor;
      for (final ctor in ctors) {
        bool canResolveAll = true;
        for (final param in ctor.getParameterTypes()) {
          if (param.isPrimitive()) {
            continue; // Primitive types are not resolved
          }

          if (!await factory.containsType(param)) {
            canResolveAll = false;
            break;
          }
        }

        if (canResolveAll) {
          greedyCtor = ctor;
          break;
        }
      }

      if (greedyCtor != null) {
        constructor = greedyCtor;
      } else {
        constructor = cls.getBestConstructor([]) ?? cls.getDefaultConstructor() ?? cls.getNoArgConstructor();
      }
    }

    if (constructor == null) {
      throw PodCreationException.withPodName(
        podName,
        "No suitable constructor found for pod '$podName' of type '${cls.getName()}'. "
        "None of the available constructors could be matched with the provided arguments "
        "or resolved from the container. "
        "Consider annotating the intended constructor with @Autowired or provide explicit arguments.",
      );
    }

    final arguments = List<ArgumentValue>.from(explicitArgs ?? []);

    ArgumentValueHolder resolved;
    if (constructor.getParameterTypes().isEmpty) {
      resolved = ArgumentValueHolder();
    } else {
      final candidateArgs = await factory.determineCandidateArguments(podName, constructor, constructor.getParameters());
      if (candidateArgs != null) {
        arguments.addAll(candidateArgs);
      }

      resolved = await _resolveExecutableArguments(rpd, constructor, arguments);

      if (_logger.getIsTraceEnabled()) {
        _logger.trace("Resolved constructor ${constructor.getName()} arguments for ${constructor.getDeclaringClass().getName()}: ${resolved.arguments}");
      }
    }
    
    return ExecutableHolder(executable: constructor, namedArgs: resolved.namedArgs, positionalArgs: resolved.positionalArgs, arguments: resolved.arguments);
  }
  
  @override
  Future<ExecutableHolder> determineFactoryMethod(RootPodDefinition definition, String podName, List<ArgumentValue>? explicitArgs) async {
    Method? method = definition.factoryMethod.getFactoryMethod();
    String factoryMethodName = definition.factoryMethod.methodName;
    Class? factoryType = definition.factoryMethod.factoryType;

    if (method == null) {
      final factoryPodName = definition.factoryMethod.podName;
      final factoryDefinition = factory.getDefinition(factoryPodName);
      factoryType ??= factoryDefinition.type;
      method = factoryType.getMethod(factoryMethodName);
    }

    if (method == null) {
      throw PodCreationException.withPodName(
        podName,
        "No factory method named '$factoryMethodName' found on type '${factoryType?.getName()}'. "
        "Ensure that the method exists, is visible, and matches the expected signature.",
      );
    }

    final arguments = List<ArgumentValue>.from(explicitArgs ?? []);

    ArgumentValueHolder resolved;
    if (method.getParameterTypes().isEmpty) {
      resolved = ArgumentValueHolder();
    } else {
      final candidateArgs = await factory.determineCandidateArguments(podName, method, method.getParameters());
      if (candidateArgs != null) {
        arguments.addAll(candidateArgs);
      }

      resolved = await _resolveExecutableArguments(definition, method, arguments);

      if (_logger.getIsTraceEnabled()) {
        _logger.trace("Resolved factory method ${method.getName()} for ${method.getDeclaringClass().getName()} arguments: ${resolved.arguments}");
      }
    }
    
    return ExecutableHolder(executable: method, namedArgs: resolved.namedArgs, positionalArgs: resolved.positionalArgs, arguments: resolved.arguments);
  }

  /// {@template simple_executable_strategy.resolve_executable_arguments}
  /// Resolves and merges argument values for a given [Executable]
  /// (constructor or method), honoring multiple precedence levels:
  ///
  /// 1. **Definition-level arguments** (lowest precedence)  
  ///    From [RootPodDefinition.executableArgumentValues].
  /// 2. **Explicit or candidate arguments** (medium precedence)  
  ///    Provided during invocation or determined by dependency candidates.
  /// 3. **Autowired dependencies** (high precedence)  
  ///    Automatically resolved from the [AbstractAutowirePodFactory].
  /// 4. **Default or nullable arguments** (fallback)  
  ///    Uses declared default values or `null` for optional parameters.
  ///
  /// ### Behavior Summary
  /// - Logs every resolution attempt in debug mode.
  /// - Ensures required parameters are resolvable; throws [PodException] otherwise.
  /// - Produces a consistent [ArgumentValueHolder] with named/positional arguments.
  ///
  /// ### Example
  /// ```dart
  /// final holder = await _resolveExecutableArguments(
  ///   definition,
  ///   constructor,
  ///   explicitArgs,
  /// );
  /// ```
  ///
  /// The returned [ArgumentValueHolder] is immutable and ready for
  /// execution via reflection.
  /// {@endtemplate}
  Future<ArgumentValueHolder> _resolveExecutableArguments(RootPodDefinition definition, Executable executable, List<ArgumentValue>? explicitArgs) async {
    if (_logger.getIsTraceEnabled()) {
      _logger.trace("Resolving args for executable ${executable is Method ? "factory method" : "constructor"} named '${executable.getName()}' of pod '${definition.name}'");
    }

    final List<ArgumentValue> merged = [];

    // copy definition-level executable args first (lowest precedence)
    final eav = definition.executableArgumentValues;
    if (!eav.isEmpty()) {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace("Merging ${eav.toList().length} definition-level executable args");
      }

      for (final defArg in eav.toList()) {
        merged.add(defArg);

        if (_logger.getIsTraceEnabled()) {
          _logger.trace("  definition arg: '${defArg.getName()}' => ${defArg.getValue()} (type=${defArg.getQualifiedName()})");
        }
      }
    } else {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace("No definition-level executable args to merge");
      }
    }

    // overlay explicit/candidate args (higher precedence) — copy them so we don't mutate originals
    if (explicitArgs != null && explicitArgs.isNotEmpty) {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace("Applying ${explicitArgs.length} explicit/candidate args (higher precedence)");
      }

      for (final ex in explicitArgs) {
        final existing = merged.find((a) => _argumentMatches(a, ex));
        if (existing != null) {
          merged.remove(existing);
        }

        merged.add(ex);
        if (_logger.getIsTraceEnabled()) {
          _logger.trace("  explicit named arg: '${ex.getName()}' => ${ex.getValue()} (replaced=${existing != null})");
        }
      }
    } else {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace("No explicit/candidate args provided");
      }
    }

    // 2) Prepare containers for final resolved values in parameter order -----------
    final parameters = executable.getParameters();
    if (_logger.getIsTraceEnabled()) {
      _logger.trace("Executable '${executable.getName()}' has ${parameters.length} parameters");
    }

    final resolvedArgs = <ArgumentValue>[];
    final namedArgs = <String, Object?>{};
    final positionalArgs = <Object?>[];

    for (final param in parameters) {
      final paramClass = param.getReturnClass();
      final paramName = param.getName();

      final existing = merged.find((a) => _paramMatchesArgument(param, a));
      if (existing != null && existing.getValue() != null) {
        if (_logger.getIsTraceEnabled()) {
          _logger.trace(
            "Resolved ${param.isRequired() ? 'required' : 'optional'} "
            "${param.isNamed() ? 'named' : 'positional'} parameter '$paramName' of type "
            "'${paramClass.getQualifiedName().split('.').last}' (${paramClass.getQualifiedName()}) "
            "${param.hasDefaultValue() ? ' with a default value' : ''}.",
          );
        }

        final resolvedArg = ArgumentValue(
          existing.getValue(),
          qualifiedName: paramClass.getQualifiedName(),
          packageName: paramClass.getPackage().getName(),
          name: paramName,
        );

        resolvedArgs.add(resolvedArg);

        if (param.isNamed()) {
          namedArgs[paramName] = resolvedArg.getValue();
        } else {
          positionalArgs.add(resolvedArg.getValue());
        }

        if (_logger.getIsTraceEnabled()) {
          _logger.trace("Registered resolved value for '$paramName' => ${resolvedArg.getValue()}");
        }

        continue;
      } else {
        if (_logger.getIsTraceEnabled()) {
          _logger.trace(
            "Resolving ${param.isRequired() ? 'required' : 'optional'} "
            "${param.isNamed() ? 'named' : 'positional'} parameter '$paramName' of type "
            "'${paramClass.getQualifiedName().split('.').last}' (${paramClass.getQualifiedName()}) "
            "${param.hasDefaultValue() ? ' with a default value' : ''}.",
          );
        }

        Object? resolvedValue;
        Object? lastException;
        StackTrace? lastStackTrace;
        if (!paramClass.isPrimitive()) {
          if (_logger.getIsTraceEnabled()) {
            _logger.trace("  Attempting autowire-by-type for parameter '$paramName' (type=${paramClass.getQualifiedName()})");
          }

          try {
            resolvedValue = await factory.resolveDependency(DependencyDescriptor(
              source: paramClass,
              podName: definition.name,
              propertyName: param.getName(),
              type: paramClass,
              args: null,
              component: paramClass.componentType(),
              key: paramClass.keyType(),
              isEager: true,
              isRequired: param.isRequired()
            ));
          } on NoUniquePodDefinitionException catch (e) {
            if (_logger.getIsTraceEnabled()) {
              _logger.trace("  Autowire attempt for '$paramName' failed: ${e.runtimeType}", error: e);
            }
            
            rethrow;
          } catch (e, st) {
            if (_logger.getIsTraceEnabled()) {
              _logger.trace("  Autowire attempt for '$paramName' failed: ${e.runtimeType}", error: e, stacktrace: st);
            }
            // resolution failure will be handled by defaults/optional/exception below
            resolvedValue = null;
            lastException = e;
            lastStackTrace = st;
          }

          if (resolvedValue != null) {
            if (_logger.getIsTraceEnabled()) {
              _logger.trace("  Autowired parameter '$paramName' => resolved instance type=${resolvedValue.runtimeType}");
            }

            final resolvedArg = ArgumentValue(
              resolvedValue,
              qualifiedName: paramClass.getQualifiedName(),
              packageName: paramClass.getPackage().getName(),
              name: paramName,
            );

            resolvedArgs.add(resolvedArg);

            if (param.isNamed()) {
              namedArgs[paramName] = resolvedValue;
            } else {
              positionalArgs.add(resolvedValue);
            }

            if (_logger.getIsTraceEnabled()) {
              _logger.trace("  Registered autowired value for '$paramName'");
            }

            continue;
          } else {
            if (_logger.getIsTraceEnabled()) {
              _logger.trace("  Autowire-by-type did not resolve a value for '$paramName'");
            }
          }
        } else {
          if (_logger.getIsTraceEnabled()) {
            _logger.trace("  Skipping autowire for primitive parameter '$paramName'");
          }
        }

        ArgumentValue? existing = merged.find((a) => _paramMatchesArgument(param, a));
        if ((existing == null || existing.getValue() == null) && param.hasDefaultValue()) {
          resolvedValue = existing?.getValue() ?? param.getDefaultValue();
          if (_logger.getIsTraceEnabled()) {
            _logger.trace("  Using default value for parameter '$paramName' => $resolvedValue");
          }

          final resolvedArg = ArgumentValue(
            resolvedValue,
            qualifiedName: paramClass.getQualifiedName(),
            packageName: paramClass.getPackage().getName(),
            name: paramName,
          );

          resolvedArgs.add(resolvedArg);

          if (param.isNamed()) {
            namedArgs[paramName] = resolvedValue;
          } else {
            positionalArgs.add(resolvedValue);
          }

          if (_logger.getIsTraceEnabled()) {
            _logger.trace("  Registered default value for '$paramName'");
          }

          continue;
        }

        existing = merged.find((a) => _paramMatchesArgument(param, a));
        if ((existing == null || existing.getValue() == null) && param.mustBeResolved()) {
          _logger.warn(
            "Failed to resolve required parameter '$paramName' (type=${paramClass.getQualifiedName()}) "
            "for executable '${executable.getName()}' of pod '${definition.name}'",
          );

          if (lastException != null && (lastException is Error || lastException is Exception)) Error.throwWithStackTrace(lastException, lastStackTrace!); 

          throw PodException(
            "Cannot resolve required ${param.isNamed() ? 'named' : 'positional'} executable parameter "
            "'$paramName' of type '${paramClass.getQualifiedName()}' for executable '${executable.getName()}'. "
            "Provide an explicit argument, a factory, or ensure the container can autowire a matching pod.",
          );
        }

        if (!param.isRequired() && existing == null) {
          if (_logger.getIsTraceEnabled()) {
            _logger.trace("  Parameter '$paramName' is optional/nullable - assigning null");
          }

          final resolvedArg = ArgumentValue(
            resolvedValue,
            qualifiedName: paramClass.getQualifiedName(),
            packageName: paramClass.getPackage().getName(),
            name: paramName,
          );

          resolvedArgs.add(resolvedArg);

          if (param.isNamed()) {
            namedArgs[paramName] = resolvedValue;
          } else {
            positionalArgs.add(resolvedValue);
          }

          if (_logger.getIsTraceEnabled()) {
            _logger.trace("  Registered null value for '$paramName'");
          }

          continue;
        }
      }
    }

    return ArgumentValueHolder(
      namedArgs: Map<String, Object?>.unmodifiable(namedArgs),
      positionalArgs: List<Object?>.unmodifiable(positionalArgs),
      arguments: List<ArgumentValue>.unmodifiable(resolvedArgs),
    );
  }

  /// {@template simple_executable_strategy.argument_matches}
  /// Determines whether two [ArgumentValue] instances are equivalent
  /// for merge comparison.
  ///
  /// Equality is determined by:
  /// - Matching argument names (`getName()`).
  /// - Matching fully qualified type names (`getQualifiedName()`).
  /// - Type assignability comparison via [_typeMatches].
  /// {@endtemplate}
  bool _argumentMatches(ArgumentValue first, ArgumentValue second) {
    if (second.getName().equals(first.getName())) {
      return true;
    }

    if (second.getQualifiedName().equals(first.getQualifiedName())) {
      return true;
    }

    if (first.getType() != null && second.getType() != null) {
      return _typeMatches(first.getType()!, second.getType());
    }

    return false;
  }

  /// {@template simple_executable_strategy.param_matches_argument}
  /// Determines whether a given [Parameter] corresponds to a provided
  /// [ArgumentValue] based on name, qualified type name, or assignability.
  /// {@endtemplate}
  bool _paramMatchesArgument(Parameter parameter, ArgumentValue argument) {
    if (argument.getName().equals(parameter.getName())) {
      return true;
    }

    if (argument.getQualifiedName().equals(parameter.getReturnClass().getQualifiedName())) {
      return true;
    }

    return _typeMatches(parameter.getReturnClass(), argument.getType());
  }

  /// {@template simple_executable_strategy.type_matches}
  /// Checks whether [argType] is assignable to [paramClass],
  /// using class equality, reflection-based assignability checks,
  /// or qualified name comparison.
  ///
  /// This method supports Jetleaf’s reflective type model,
  /// which allows for flexible dependency matching across
  /// class hierarchies and interface implementations.
  /// {@endtemplate}
  bool _typeMatches(Class paramClass, Class? argType) {
    if (argType == null) return false;
    // try exact equality first
    if (argType == paramClass) return true;

    // try assignability helpers - adapt to your Class API if different
    if (paramClass.isAssignableFrom(argType)) return true;
    if (argType.isAssignableTo(paramClass)) return true;

    // fallback: compare qualified names (string match)
    final aqn = argType.getQualifiedName();
    final pqn = paramClass.getQualifiedName();
    if (aqn == pqn) return true;

    return false;
  }
}