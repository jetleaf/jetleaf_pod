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

part of 'object.dart';

// --------------------------------------------------------------------------------------------------------
// PropertyValue
// --------------------------------------------------------------------------------------------------------

/// {@template property_value}
/// Represents a property with a [_name] and its associated [_value].
///
/// Extends [ConvertibleValue] to support property value conversion and
/// can be marked as optional. Used extensively in pod property configuration.
///
/// Example usage:
/// ```dart
/// final pv = PropertyValue('host', 'localhost');
/// pv.optional = true;
/// print(pv.name); // 'host'
/// print(pv.value); // 'localhost'
/// ```
/// {@endtemplate}
class PropertyValue extends ConvertibleValue {
  /// {@template property_value_name}
  /// The name of the property.
  ///
  /// This is the property name that will be used when setting the value
  /// on a pod instance through reflection or code generation.
  ///
  /// Example:
  /// ```dart
  /// final pv = PropertyValue('port', 8080);
  /// print(pv.name); // 'port'
  /// ```
  /// {@endtemplate}
  final String _name;

  /// {@template property_value_optional}
  /// Whether the property is optional. Defaults to `false`.
  ///
  /// When true, the property value may be null or missing without causing
  /// configuration errors. When false, the property is considered required.
  ///
  /// Example:
  /// ```dart
  /// final pv = PropertyValue('debug', true);
  /// pv.optional = true;
  /// print(pv.optional); // true
  /// ```
  /// {@endtemplate}
  bool _optional = false;

  /// {@macro property_value}
  /// 
  /// [name]: The name of the property
  /// [value]: The value of the property (may need conversion)
  /// [qualifiedName]: The qualified name of the property
  PropertyValue(this._name, Object? value, {String? qualifiedName, String? packageName}) : super(
    value,
    qualifiedName: qualifiedName,
    packageName: packageName,
  );

  /// {@macro property_value_copy}
  factory PropertyValue.copy(PropertyValue pv) {
    final res = PropertyValue(pv._name, pv.getValue(), qualifiedName: pv.getQualifiedName(), packageName: pv.getPackageName());
    res._optional = pv._optional;
    if (pv._converted) {
      res.setConvertedValue(pv._convertedValue);
    }
    return res;
  }

  /// {@macro property_value_name}
  String getName() => _name;

  /// {@macro property_value_optional}
  bool isOptional() => _optional;

  /// {@template property_value_copy}
  /// Creates a deep copy of this [PropertyValue].
  ///
  /// The copy includes the original value, converted value (if any),
  /// conversion state, and the optional flag.
  ///
  /// Returns a new [PropertyValue] instance with the same state.
  ///
  /// Example:
  /// ```dart
  /// final pv = PropertyValue('enabled', 'true');
  /// pv.setConvertedValue(true);
  /// final copy = pv.copy();
  /// print(copy.convertedValue); // true
  /// print(copy.optional); // false (default)
  /// ```
  /// {@endtemplate}
  PropertyValue copy() {
    final rawValue = getValue();
    final pv = PropertyValue(
      _name,
      rawValue is MutablePropertyValues ? rawValue : getValue(),
      qualifiedName: getQualifiedName(),
      packageName: getPackageName(),
    );

    pv._optional = _optional;
    if (_converted) {
      pv.setConvertedValue(_convertedValue);
    }

    return pv;
  }

  @override
  List<Object?> equalizedProperties() => [_name, _value, _optional, _converted, _convertedValue, getQualifiedName()];

  @override
  ToStringOptions toStringOptions() => ToStringOptions(
    customParameterNames: ['name', 'value', 'optional', 'converted', 'convertedValue', 'qualifiedName'],
    includeParameterNames: true,
  );
}

// --------------------------------------------------------------------------------------------------------
// ArgumentValue
// --------------------------------------------------------------------------------------------------------

/// {@template value_holder}
/// Holder for a constructor argument value, including its optional type
/// and name metadata.
///
/// Extends [ConvertibleValue] to support constructor argument conversion
/// and provides additional metadata for argument resolution.
///
/// Example usage:
/// ```dart
/// final vh = ArgumentValue('localhost', 'dart.core.String', 'host');
/// print(vh.value); // 'localhost'
/// print(vh.type);  // 'String'
/// ```
/// {@endtemplate}
class ArgumentValue extends ConvertibleValue {
  /// {@template value_holder_name}
  /// The logical name of the constructor argument, if provided.
  ///
  /// Used for named constructor arguments or for better error reporting.
  /// {@endtemplate}
  final String? _name;

  /// {@macro value_holder}
  /// 
  /// [value]: The argument value
  /// [qualifiedName]: Required qualified name of the class that the argument is for (The return type of the argument)
  /// [name]: Optional name for the argument
  ArgumentValue(Object? value, {String? qualifiedName, String? packageName, String? name}) 
    : _name = name, super(value, qualifiedName: qualifiedName, packageName: packageName);

  /// {@template value_holder_copy}
  /// Creates a deep copy of this [ArgumentValue].
  ///
  /// The copy includes the original value, converted value (if any),
  /// conversion state, type, and name.
  ///
  /// Returns a new [ArgumentValue] instance with the same state.
  ///
  /// Example:
  /// ```dart
  /// final vh = ArgumentValue('8080', 'int');
  /// vh.setConvertedValue(8080);
  /// final copy = vh.copy();
  /// print(copy.convertedValue); // 8080
  /// print(copy.type); // 'int'
  /// ```
  /// {@endtemplate}
  ArgumentValue copy() {
    final vh = ArgumentValue(_value, qualifiedName: _qualifiedName, packageName: _packageName, name: _name);
    if (_converted) {
      vh.setConvertedValue(_convertedValue);
    }
    return vh;
  }

  /// {@macro value_holder_name}
  String? getName() => _name;

  @override
  List<Object?> equalizedProperties() => [_name, _value, _converted, _convertedValue, _qualifiedName];

  @override
  ToStringOptions toStringOptions() => ToStringOptions(
    customParameterNames: ['name', 'value', 'converted', 'convertedValue', 'qualifiedName'],
    includeParameterNames: true,
  );
}

// ---------------------------------------------------------------------------------------------------------
// MutablePropertyValues
// ---------------------------------------------------------------------------------------------------------

/// {@template mutable_property_values}
/// Mutable implementation of PropertyValues interface.
///
/// This class provides a mutable collection of PropertyValue objects that can be
/// modified after creation. It's the standard implementation used by pod definitions
/// to store and manage property injection configuration.
///
/// Key features:
/// - Add, remove, and modify property values
/// - Merge with other PropertyValues instances
/// - Convert to/from various formats
/// - Support for property value validation
/// - Thread-safe operations when needed
/// - Efficient lookup and iteration
///
/// Example usage:
/// ```dart
/// final propertyValues = MutablePropertyValues();
/// 
/// // Add properties
/// propertyValues.add(PropertyValue('host', 'localhost'));
/// propertyValues.add(PropertyValue('port', 8080));
/// propertyValues.add(PropertyValue('timeout', 30));
/// 
/// // Modify existing property
/// propertyValues.addPropertyValue(PropertyValue('port', 9090));
/// 
/// // Remove property
/// propertyValues.removePropertyValue('timeout');
/// 
/// // Check for property
/// if (propertyValues.contains('host')) {
///   final hostValue = propertyValues.getPropertyValue('host');
/// }
/// ```
/// {@endtemplate}
class MutablePropertyValues extends PropertyValues with EqualsAndHashCode, ToString {
  /// {@template mutable_property_values_list}
  /// Internal list storing all property values in insertion order.
  /// {@endtemplate}
  final List<PropertyValue> _values = <PropertyValue>[];

  /// {@template mutable_property_values_processed_properties}
  /// Set of property names that have been processed during pod population.
  /// {@endtemplate}
  final Set<String> _processedProperties = <String>{};

  /// {@template mutable_property_values_logger}
  /// Logger instance for logging messages.
  /// {@endtemplate}
  final Log logger = LogFactory.getLog(MutablePropertyValues);

  /// {@template mutable_property_values_converted}
  /// Flag indicating whether property values have been type-converted.
  /// {@endtemplate}
  bool _converted = false;

  /// {@macro mutable_property_values}
  /// 
  /// [propertyValues]: Optional initial list of property values
  MutablePropertyValues([List<PropertyValue>? propertyValues]) {
    if (propertyValues != null) {
      _values.addAll(propertyValues);
    }
  }

  /// {@template mutable_property_values_from_map}
  /// Create from a Map of property names to values.
  ///
  /// [source]: Map containing property names as keys and values as values
  ///
  /// Example:
  /// ```dart
  /// final map = {'host': 'localhost', 'port': 8080, 'enabled': true};
  /// final propertyValues = MutablePropertyValues.fromMap(map);
  /// print(propertyValues.getPropertyValue('host')?.getValue()); // 'localhost'
  /// ```
  /// {@endtemplate}
  MutablePropertyValues.fromMap(Map<String, Map<String, Object?>> source) {
    source.forEach((name, value) {
      final qn = value['qualifiedName'] as String?;
      final pn = value['packageName'] as String?;
      final object = value['value'];

      _values.add(PropertyValue(name, object, qualifiedName: qn, packageName: pn));
    });
  }

  /// {@template mutable_property_values_copy}
  /// Create a deep copy of another PropertyValues instance.
  ///
  /// [original]: The PropertyValues instance to copy
  ///
  /// Example:
  /// ```dart
  /// final original = MutablePropertyValues()
  ///   ..add('timeout', 30)
  ///   ..add('retries', 3);
  /// 
  /// final copy = MutablePropertyValues.copy(original);
  /// copy.add('maxConnections', 100);
  /// // original remains unchanged
  /// ```
  /// {@endtemplate}
  MutablePropertyValues.copy(PropertyValues original) {
    for (final pv in original.getPropertyValues()) {
      _values.add(PropertyValue.copy(pv));
    }
  }

  /// {@template mutable_property_values_from}
  /// Create from a PropertyValues instance.
  ///
  /// [pvs]: The PropertyValues instance to create from
  ///
  /// Example:
  /// ```dart
  /// final pvs = PropertyValues()
  ///   ..add('timeout', 30)
  ///   ..add('retries', 3);
  /// 
  /// final propertyValues = MutablePropertyValues.from(pvs);
  /// print(propertyValues.getPropertyValue('timeout')?.getValue()); // 30
  /// ```
  /// {@endtemplate}
  factory MutablePropertyValues.from(PropertyValues pvs) => MutablePropertyValues(pvs.getPropertyValues());

  @override
  List<PropertyValue> getPropertyValues() => List.unmodifiable(_values);

  @override
  PropertyValue? getPropertyValue(String propertyName) {
    for (final pv in _values) {
      if (pv.getName() == propertyName) {
        return pv;
      }
    }
    return null;
  }

  @override
  PropertyValues changesSince(PropertyValues old) {
    final changes = MutablePropertyValues();
    if (identical(this, old)) {
      return changes;
    }

    // Add new or changed properties
    for (final newPv in _values) {
      final oldPv = old.getPropertyValue(newPv.getName());
      if (oldPv == null || !oldPv.equals(newPv)) {
        changes.addPropertyValue(newPv);
      }
    }

    return changes;
  }

  @override
  bool containsProperty(String propertyName) => getPropertyValue(propertyName) != null;

  @override
  bool get isEmpty => _values.isEmpty;

  @override
  int get length => _values.length;

  /// {@template mutable_property_values_add_property_value}
  /// Add a PropertyValue object, replacing any existing one for the same property.
  ///
  /// [pv]: The PropertyValue to add
  /// Returns this instance for method chaining
  ///
  /// Example:
  /// ```dart
  /// final pv = PropertyValue('timeout', 30);
  /// propertyValues.addPropertyValue(pv);
  /// ```
  /// {@endtemplate}
  MutablePropertyValues addPropertyValue(PropertyValue pv) {
    for (int i = 0; i < _values.length; i++) {
      final currentPv = _values[i];
      if (currentPv.getName() == pv.getName()) {
        _values[i] = _mergeIfRequired(pv, currentPv);
        return this;
      }
    }
    _values.add(pv);
    return this;
  }

  /// {@template mutable_property_values_add}
  /// Add a PropertyValue object by name and value.
  ///
  /// [propertyName]: The name of the property
  /// [propertyValue]: The value of the property
  ///
  /// Example:
  /// ```dart
  /// propertyValues.add('host', 'localhost');
  /// propertyValues.add('port', 8080);
  /// ```
  /// {@endtemplate}
  void add(String propertyName, Object? propertyValue, {String? qualifiedName, String? packageName}) {
    addPropertyValue(PropertyValue(propertyName, propertyValue, qualifiedName: qualifiedName, packageName: packageName));
  }

  /// {@template mutable_property_values_add_property_values}
  /// Add all property values from another PropertyValues object.
  ///
  /// [other]: The PropertyValues instance to add properties from
  /// Returns this instance for method chaining
  ///
  /// Example:
  /// ```dart
  /// final additionalValues = MutablePropertyValues()
  ///   ..add('timeout', 30)
  ///   ..add('retries', 3);
  /// 
  /// propertyValues.addPropertyValues(additionalValues);
  /// ```
  /// {@endtemplate}
  MutablePropertyValues addPropertyValues(PropertyValues? other) {
    if (other != null) {
      for (final pv in other.getPropertyValues()) {
        addPropertyValue(PropertyValue.copy(pv));
      }
    }
    return this;
  }

  /// {@template mutable_property_values_add_property_values_from_map}
  /// Add all properties from a Map.
  ///
  /// [other]: Map containing properties to add
  /// Returns this instance for method chaining
  ///
  /// Example:
  /// ```dart
  /// final configMap = {'timeout': 30, 'maxConnections': 100};
  /// propertyValues.addPropertyValuesFromMap(configMap);
  /// ```
  /// {@endtemplate}
  MutablePropertyValues addPropertyValuesFromMap(Map<String, Map<String, Object?>> other) {
    other.forEach((key, value) {
      final qn = value['qualifiedName'] as String?;
      final pn = value['packageName'] as String?;
      final object = value['value'];

      addPropertyValue(PropertyValue(key, object, qualifiedName: qn, packageName: pn));
    });
    return this;
  }

  /// {@template mutable_property_values_set_property_value_at}
  /// Set a property value at a specific index, replacing any existing one.
  ///
  /// [pv]: The PropertyValue to set
  /// [i]: The index to set the property value at
  /// Returns this instance for method chaining
  ///
  /// Example:
  /// ```dart
  /// final newPv = PropertyValue('port', 9090);
  /// propertyValues.setPropertyValueAt(newPv, 1);
  /// ```
  /// {@endtemplate}
  MutablePropertyValues setPropertyValueAt(PropertyValue pv, int i) {
    _values[i] = pv;
    return this;
  }

  /// {@template mutable_property_values_remove_property_value}
  /// Remove the given PropertyValue, if contained.
  ///
  /// [pv]: The PropertyValue to remove
  ///
  /// Example:
  /// ```dart
  /// final pvToRemove = propertyValues.getPropertyValue('timeout');
  /// if (pvToRemove != null) {
  ///   propertyValues.removePropertyValue(pvToRemove);
  /// }
  /// ```
  /// {@endtemplate}
  void removePropertyValue(PropertyValue pv) {
    _values.remove(pv);
  }

  /// {@template mutable_property_values_remove_property_value_by_name}
  /// Remove a PropertyValue by name.
  ///
  /// [propertyName]: The name of the property to remove
  ///
  /// Example:
  /// ```dart
  /// propertyValues.removePropertyValueByName('timeout');
  /// ```
  /// {@endtemplate}
  void removePropertyValueByName(String propertyName) {
    _values.removeWhere((pv) => pv.getName() == propertyName);
  }

  /// {@template mutable_property_values_get_property_value_at}
  /// Get PropertyValue at the given index.
  ///
  /// [i]: The index of the property value to retrieve
  /// Returns the PropertyValue at the specified index
  ///
  /// Example:
  /// ```dart
  /// final firstProperty = propertyValues.getPropertyValueAt(0);
  /// print(firstProperty.getName());
  /// ```
  /// {@endtemplate}
  PropertyValue getPropertyValueAt(int i) {
    if(_values.length <= i) {
      throw IllegalArgumentException('Index out of range');
    }
    return _values[i];
  }

  /// {@template mutable_property_values_clear}
  /// Clear all property values.
  ///
  /// Example:
  /// ```dart
  /// propertyValues.clear();
  /// print(propertyValues.isEmpty); // true
  /// ```
  /// {@endtemplate}
  void clear() {
    _values.clear();
  }

  /// {@template mutable_property_values_set_converted}
  /// Mark this PropertyValues as converted.
  ///
  /// This method should be called after all property values have been
  /// type-converted to their target types.
  ///
  /// Example:
  /// ```dart
  /// propertyValues.setConverted();
  /// ```
  /// {@endtemplate}
  void setConverted() {
    _converted = true;
  }

  /// {@template mutable_property_values_is_converted}
  /// Check if this PropertyValues has been converted.
  ///
  /// Returns true if property values have been type-converted, false otherwise
  ///
  /// Example:
  /// ```dart
  /// if (!propertyValues.isConverted()) {
  ///   convertPropertyValues(propertyValues);
  ///   propertyValues.setConverted();
  /// }
  /// ```
  /// {@endtemplate}
  bool isConverted() {
    return _converted;
  }

  /// {@template mutable_property_values_register_processed_property}
  /// Register the specified property as processed.
  ///
  /// [propertyName]: The name of the property that has been processed
  ///
  /// Example:
  /// ```dart
  /// propertyValues.registerProcessedProperty('host');
  /// ```
  /// {@endtemplate}
  void registerProcessedProperty(String propertyName) {
    _processedProperties.add(propertyName);
  }

  /// {@template mutable_property_values_clear_processed_property}
  /// Clear the processed properties set.
  ///
  /// [propertyName]: The name of the property to remove from processed set
  ///
  /// Example:
  /// ```dart
  /// propertyValues.clearProcessedProperty('host');
  /// ```
  /// {@endtemplate}
  void clearProcessedProperty(String propertyName) {
    _processedProperties.remove(propertyName);
  }

  /// {@template mutable_property_values_set_processed_properties}
  /// Mark the specified properties as processed.
  ///
  /// [processedProperties]: Set of property names to mark as processed
  ///
  /// Example:
  /// ```dart
  /// propertyValues.setProcessedProperties({'host', 'port', 'timeout'});
  /// ```
  /// {@endtemplate}
  void setProcessedProperties(Set<String> processedProperties) {
    _processedProperties.clear();
    _processedProperties.addAll(processedProperties);
  }

  /// {@template mutable_property_values_get_processed_properties}
  /// Get the set of processed properties.
  ///
  /// Returns an unmodifiable set of property names that have been processed
  ///
  /// Example:
  /// ```dart
  /// final processed = propertyValues.getProcessedProperties();
  /// print('Processed properties: $processed');
  /// ```
  /// {@endtemplate}
  Set<String> getProcessedProperties() {
    return Set.unmodifiable(_processedProperties);
  }

  /// {@template mutable_property_values_merge_if_required}
  /// Merge the given PropertyValue with the current one, if applicable.
  ///
  /// This method handles merging of [Mergeable] values when a property
  /// with the same name already exists.
  ///
  /// [newPv]: The new PropertyValue to merge
  /// [currentPv]: The current PropertyValue to merge with
  /// Returns the merged PropertyValue or the new PropertyValue if no merging occurred
  /// {@endtemplate}
  PropertyValue _mergeIfRequired(PropertyValue newPv, PropertyValue currentPv) {
    final newValue = newPv.getValue();
    if (newValue is Mergeable) {
      final currentValue = currentPv.getValue();
      if (newValue.isMergeEnabled() && currentValue != null) {
        final mergedValue = newValue.merge(currentValue);

        return PropertyValue(
          newPv.getName(),
          mergedValue,
          packageName: newPv.getPackageName(),
          qualifiedName: newPv.getQualifiedName(),
        );
      }
    }
    return newPv;
  }

  /// {@template mutable_property_values_copy}
  /// Creates a deep copy of this [MutablePropertyValues], preserving
  /// [PropertyValue]s and their states.
  ///
  /// The copy includes all property values with their conversion states
  /// and optional flags preserved.
  ///
  /// Returns a new [MutablePropertyValues] instance with the same properties.
  ///
  /// Example:
  /// ```dart
  /// final original = MutablePropertyValues()
  ///   ..addPropertyValueByName('enabled', 'true');
  /// 
  /// final copy = original.copy();
  /// copy.addPropertyValueByName('debug', false);
  /// // original is unchanged
  /// ```
  /// {@endtemplate}
  MutablePropertyValues copy() {
    final copy = MutablePropertyValues();
    copy._values.addAll(
      _values.map((pv) => pv.copy()),
    );

    copy._processedProperties.addAll(_processedProperties);
    copy._converted = _converted;

    return copy;
  }

  @override
  Iterator<PropertyValue> get iterator => _values.iterator;

  @override
  List<Object?> equalizedProperties() => _values;

  @override
  ToStringOptions toStringOptions() => ToStringOptions(
    customParameterNameGenerator: (value, index) {
      if(value is PropertyValue) {
        return value.getName();
      }
      return 'property_$index';
    },
  );
}

// --------------------------------------------------------------------------------------------------------
// ConstructorArgumentValues
// --------------------------------------------------------------------------------------------------------

/// {@template constructor_argument_values}
/// Holder for constructor argument values used when instantiating a pod.
///
/// Supports both **indexed arguments** (explicit parameter positions) and
/// **generic arguments** (matched by type). This class is essential for
/// constructor injection in the dependency injection framework.
///
/// Example usage:
/// ```dart
/// final cav = ConstructorArgumentValues();
/// cav.add(0, 'localhost', 'dart.core.String');
/// cav.add(8080, 'dart.core.int');
///
/// print(cav.getCount()); // 2
/// ```
/// {@endtemplate}
class ConstructorArgumentValues with EqualsAndHashCode, ToString {
  /// {@template constructor_argument_values_generic}
  /// Map of generic argument values not tied to a specific parameter index.
  ///
  /// Generic arguments are matched by type during constructor resolution
  /// when the exact parameter position is not specified.
  /// {@endtemplate}
  final Map<String, ArgumentValue> _values = {};

  /// {@template constructor_argument_values_add_generic_argument_value}
  /// Adds a generic argument value with an optional [type].
  ///
  /// Generic arguments are matched by type during constructor resolution.
  /// They are used when the parameter position is not explicitly specified.
  ///
  /// [value]: The argument value
  /// [type]: Optional type hint for the argument
  ///
  /// Example:
  /// ```dart
  /// final args = ConstructorArgumentValues();
  /// args.add('localhost', 'dart.core.String');
  /// args.add(8080, 'dart.core.int');
  /// ```
  /// {@endtemplate}
  void add(String name, Object? value, {String? packageName, String? qualifiedName}) {
    _values[name] = ArgumentValue(value, name: name, qualifiedName: qualifiedName, packageName: packageName);
  }

  /// {@template constructor_argument_values_add_argument_value}
  /// Adds a generic argument value.
  ///
  /// [argument]: The argument value to add
  ///
  /// Example:
  /// ```dart
  /// final args = ConstructorArgumentValues();
  /// args.addArgument(ArgumentValue('localhost', 'dart.core.String'));
  /// args.addArgument(ArgumentValue(8080, 'dart.core.int'));
  /// ```
  /// {@endtemplate}
  void addArgument(ArgumentValue argument) {
    if(argument._name != null) {
      _values.add(argument._name, argument);
    } else {
      throw IllegalArgumentException('Argument value must have a name');
    }
  }

  /// {@template constructor_argument_values_get_generic_argument_value}
  /// Retrieves the first generic argument value matching the [requiredType],
  /// or returns `null` if none match.
  ///
  /// [requiredType]: The type to match against (null matches any type)
  /// Returns the first matching [ArgumentValue] or null
  ///
  /// Example:
  /// ```dart
  /// final args = ConstructorArgumentValues();
  /// args.add('localhost', 'dart.core.String');
  /// args.add(8080, 'dart.core.int');
  /// 
  /// final portArg = args.get(name: 'port');
  /// print(portArg?.value); // 8080
  /// 
  /// final portArg = args.get(qualifiedName: 'dart.core.int');
  /// print(portArg?.value); // 8080
  /// 
  /// final portArg = args.get(packageName: 'dart.core');
  /// print(portArg?.value); // 8080
  /// ```
  /// {@endtemplate}
  ArgumentValue? get({String? qualifiedName, String? name, String? packageName}) {
    if(name != null) {
      return _values[name];
    }

    if(qualifiedName != null) {
      return _values.values.firstWhereOrNull((vh) => vh.getQualifiedName() == qualifiedName);
    }

    return _values.values.firstWhereOrNull((vh) => packageName == null || vh.getPackageName() == packageName);
  }

  /// {@template constructor_argument_values_get_argument_count}
  /// Returns the total number of argument values (both indexed and generic).
  ///
  /// Returns the sum of indexed and generic argument counts.
  ///
  /// Example:
  /// ```dart
  /// final args = ConstructorArgumentValues();
  /// args.add('first', 'dart.core.String');
  /// args.add('second', 'dart.core.String');
  /// 
  /// print(args.getCount()); // 2
  /// ```
  /// {@endtemplate}
  int getCount() => _values.length;

  /// {@template constructor_argument_values_is_empty}
  /// Returns `true` if there are no argument values defined.
  ///
  /// Returns true if both indexed and generic argument collections are empty.
  ///
  /// Example:
  /// ```dart
  /// final emptyArgs = ConstructorArgumentValues();
  /// final populatedArgs = ConstructorArgumentValues()
  ///   ..add('test');
  /// 
  /// print(emptyArgs.isEmpty()); // true
  /// print(populatedArgs.isEmpty()); // false
  /// ```
  /// {@endtemplate}
  bool isEmpty() => _values.isEmpty;

  /// {@template constructor_argument_values_clear}
  /// Clears all argument values (both indexed and generic).
  ///
  /// Removes all configured arguments from both collections.
  ///
  /// Example:
  /// ```dart
  /// final args = ConstructorArgumentValues();
  /// args.add('test');
  /// args.clear();
  /// print(args.isEmpty()); // true
  /// ```
  /// {@endtemplate}
  void clear() => _values.clear();

  /// {@template constructor_argument_values_to_map}
  /// Returns a map of argument values, where keys are parameter names and values are [ArgumentValue]s.
  ///
  /// Example:
  /// ```dart
  /// final args = ConstructorArgumentValues()
  ///   ..add('localhost', 'dart.core.String')
  ///   ..add(8080, 'dart.core.int');
  /// 
  /// final map = args.toMap();
  /// print(map); // { 'localhost': ArgumentValue('localhost', 'dart.core.String'), 'port': ArgumentValue(8080, 'dart.core.int') }
  /// ```
  /// {@endtemplate}
  Map<String, ArgumentValue> toMap() {
    final map = <String, ArgumentValue>{};
    _values.forEach((key, value) {
      if(value.getName() != null) {
        map[value.getName()!] = value;
      } else {
        throw IllegalArgumentException('Argument value must have a name');
      }
    });
    return map;
  }

  /// {@template constructor_argument_values_to_list}
  /// Returns a list of argument values.
  ///
  /// Example:
  /// ```dart
  /// final args = ConstructorArgumentValues()
  ///   ..add('localhost', 'dart.core.String')
  ///   ..add(8080, 'dart.core.int');
  /// 
  /// final list = args.toList();
  /// print(list); // [ArgumentValue('localhost', 'dart.core.String'), ArgumentValue(8080, 'dart.core.int')]
  /// ```
  /// {@endtemplate}
  List<ArgumentValue> toList() {
    if(_values.values.any((a) => a.getName() == null)) {
      throw IllegalArgumentException('Argument value must have a name');
    }

    return _values.values.toList();
  }

  /// {@template constructor_argument_values_copy}
  /// Creates a deep copy of this [ConstructorArgumentValues], preserving
  /// all [ArgumentValue]s and their states.
  ///
  /// The copy includes all indexed and generic arguments with their
  /// conversion states preserved.
  ///
  /// Returns a new [ConstructorArgumentValues] instance with the same arguments.
  ///
  /// Example:
  /// ```dart
  /// final original = ConstructorArgumentValues();
  /// original.add(0, '8080', 'dart.core.int');
  /// 
  /// final copy = original.copy();
  /// copy.add('additional', 'dart.core.String');
  /// // original is unchanged
  /// ```
  /// {@endtemplate}
  ConstructorArgumentValues copy() {
    final copy = ConstructorArgumentValues();
    copy._values.addAll(_values.map((key, value) => MapEntry(key, value.copy())));
    return copy;
  }

  @override
  List<Object?> equalizedProperties() => _values.values.toList();

  @override
  ToStringOptions toStringOptions() => ToStringOptions()
    ..customParameterNames = _values.values.map((pv) => pv.getName() ?? "").toList();
}