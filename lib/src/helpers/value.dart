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
// ConvertibleValue
// --------------------------------------------------------------------------------------------------------

/// {@template convertible_value}
/// Abstraction for holding a raw value and its converted state.
///
/// A [ConvertibleValue] stores an original [_value], an optional [_convertedValue],
/// and whether it has been marked as [_converted]. Subclasses can extend this
/// to provide richer semantics such as pod property values or constructor
/// arguments.
///
/// This class is used throughout the framework to track values that may need
/// type conversion during pod instantiation and property population.
///
/// Example usage:
/// ```dart
/// final cv = PropertyValue('host', 'localhost');
/// print(cv.value); // 'localhost'
/// cv.setConvertedValue('127.0.0.1');
/// print(cv.convertedValue); // '127.0.0.1'
/// ```
/// {@endtemplate}
abstract class ConvertibleValue extends ObjectHolder<Object?> {
  /// {@macro convertible_value}
  /// 
  /// [value]: The original raw value to be stored and potentially converted
  /// [qualifiedName]: The qualified name of the property
  ConvertibleValue(super.value, {super.packageName, super.qualifiedName});

  /// {@template convertible_value_converted_value}
  /// The converted value after type transformation has been applied.
  ///
  /// This field holds the value after it has been converted to the appropriate
  /// target type. It remains null until [setConvertedValue] is called.
  ///
  /// Example:
  /// ```dart
  /// final cv = ConvertibleValue('true');
  /// cv.setConvertedValue(true);
  /// print(cv.convertedValue); // true
  /// ```
  /// {@endtemplate}
  Object? _convertedValue;

  /// {@template convertible_value_converted_flag}
  /// Whether this value has been successfully converted.
  ///
  /// Defaults to `false` and is set to `true` when [setConvertedValue] is called.
  /// This flag helps track which values still need conversion processing.
  ///
  /// Example:
  /// ```dart
  /// final cv = ConvertibleValue('42');
  /// print(cv.converted); // false
  /// cv.setConvertedValue(42);
  /// print(cv.converted); // true
  /// ```
  /// {@endtemplate}
  bool _converted = false;

  /// {@template convertible_value_set_converted_value}
  /// Sets the converted value and marks the value as converted.
  ///
  /// This method updates the [convertedValue] field and sets the [_converted]
  /// flag to true. It should be called after successful type conversion.
  ///
  /// [convertedValue]: The converted value in its target type
  ///
  /// Example:
  /// ```dart
  /// final cv = ConvertibleValue('3.14');
  /// cv.setConvertedValue(3.14);
  /// print(cv.convertedValue); // 3.14
  /// print(cv.converted); // true
  /// ```
  /// {@endtemplate}
  void setConvertedValue(Object? convertedValue) {
    _converted = true;
    _convertedValue = convertedValue;
  }

  @override
  Object? getValue() => _converted ? _convertedValue : _value;

  /// {@template convertible_value_is_converted}
  /// Returns whether the value has been successfully converted.
  ///
  /// Returns:
  /// - `true` if the value has been converted
  /// - `false` if the value has not been converted
  ///
  /// Example:
  /// ```dart
  /// final cv = ConvertibleValue('true');
  /// print(cv.isConverted()); // false
  /// cv.setConvertedValue(true);
  /// print(cv.isConverted()); // true
  /// ```
  /// {@endtemplate}
  bool isConverted() => _converted;

  /// {@template convertible_value_get_converted_value}
  /// Returns the converted value after type transformation has been applied.
  ///
  /// Returns:
  /// - The converted value if [_converted] is true
  /// - null if the value has not been converted
  ///
  /// Example:
  /// ```dart
  /// final cv = ConvertibleValue('true');
  /// print(cv.getConvertedValue()); // null
  /// cv.setConvertedValue(true);
  /// print(cv.getConvertedValue()); // true
  /// ```
  /// {@endtemplate}
  Object? getConvertedValue() => _convertedValue;
}

// --------------------------------------------------------------------------------------------------------
// PropertyValues
// --------------------------------------------------------------------------------------------------------

/// {@template property_values}
/// Interface for accessing a collection of [PropertyValue] objects.
///
/// This interface provides a uniform way to access property values regardless
/// of the underlying storage implementation. It extends [Iterable] to allow
/// easy iteration over all property values.
///
/// Example usage:
/// ```dart
/// class MyProps extends PropertyValues {
///   final list = [PropertyValue('key', 'value')];
///   @override
///   List<PropertyValue> getPropertyValues() => list;
///   @override
///   PropertyValue? getPropertyValue(String name) =>
///       list.firstWhereOrNull((pv) => pv.name == name);
///   @override
///   PropertyValues changesSince(PropertyValues old) => this;
///   @override
///   bool containsProperty(String propertyName) =>
///       getPropertyValue(propertyName) != null;
///   @override
///   bool get isEmpty => list.isEmpty;
///   @override
///   Iterator<PropertyValue> get iterator => list.iterator;
/// }
/// ```
/// {@endtemplate}
abstract class PropertyValues extends Iterable<PropertyValue> {
  /// {@template property_values_get_property_values}
  /// Returns all property values as an unmodifiable list.
  ///
  /// Returns a list containing all [PropertyValue] objects in this collection.
  /// The returned list should not be modified.
  ///
  /// Example:
  /// ```dart
  /// final props = MutablePropertyValues()
  ///   ..addPropertyValueByName('host', 'localhost')
  ///   ..addPropertyValueByName('port', 8080);
  /// 
  /// final allValues = props.getPropertyValues();
  /// for (final pv in allValues) {
  ///   print('${pv.name}: ${pv.value}');
  /// }
  /// ```
  /// {@endtemplate}
  List<PropertyValue> getPropertyValues();

  /// {@template property_values_get_property_value}
  /// Retrieves a property by its [propertyName], or `null` if not found.
  ///
  /// [propertyName]: The name of the property to retrieve
  /// Returns the [PropertyValue] with the given name, or null if not found.
  ///
  /// Example:
  /// ```dart
  /// final props = MutablePropertyValues()
  ///   ..addPropertyValueByName('timeout', 5000);
  /// 
  /// final timeout = props.getPropertyValue('timeout');
  /// print(timeout?.value); // 5000
  /// ```
  /// {@endtemplate}
  PropertyValue? getPropertyValue(String propertyName);

  /// {@template property_values_changes_since}
  /// Computes the set of properties that differ compared to another [old]
  /// [PropertyValues].
  ///
  /// This method is useful for detecting changes between two property sets,
  /// such as during configuration updates or hot reload.
  ///
  /// [old]: The previous property values to compare against
  /// Returns a new [PropertyValues] containing only the changed properties
  ///
  /// Example:
  /// ```dart
  /// final old = MutablePropertyValues()
  ///   ..addPropertyValueByName('host', '127.0.0.1');
  /// final current = MutablePropertyValues()
  ///   ..addPropertyValueByName('host', 'localhost');
  ///
  /// final diff = current.changesSince(old);
  /// print(diff.getPropertyValue('host')?.value); // 'localhost'
  /// ```
  /// {@endtemplate}
  PropertyValues changesSince(PropertyValues old);

  /// {@template property_values_contains_property}
  /// Returns `true` if a property with the given [propertyName] exists.
  ///
  /// [propertyName]: The name of the property to check
  /// Returns true if the property exists, false otherwise
  ///
  /// Example:
  /// ```dart
  /// final props = MutablePropertyValues()
  ///   ..addPropertyValueByName('enabled', true);
  /// 
  /// print(props.containsProperty('enabled')); // true
  /// print(props.containsProperty('missing')); // false
  /// ```
  /// {@endtemplate}
  bool containsProperty(String propertyName);

  /// {@template property_values_contains}
  /// Returns `true` if a property with the given [value] exists.
  ///
  /// [value]: The value of the property to check
  /// Returns true if the property exists, false otherwise
  ///
  /// Example:
  /// ```dart
  /// final props = MutablePropertyValues()
  ///   ..addPropertyValueByName('enabled', true);
  /// 
  /// print(props.contains('enabled')); // true
  /// print(props.contains('missing')); // false
  /// ```
  /// {@endtemplate}
  @override
  bool contains(Object? value) {
    if(value is! String) {
      return false;
    }
    return getPropertyValue(value.toString()) != null;
  }

  /// {@template property_values_is_empty}
  /// Whether the collection has no properties.
  ///
  /// Returns true if there are no property values in this collection.
  ///
  /// Example:
  /// ```dart
  /// final emptyProps = MutablePropertyValues();
  /// final populatedProps = MutablePropertyValues()
  ///   ..addPropertyValueByName('test', 'value');
  /// 
  /// print(emptyProps.isEmpty); // true
  /// print(populatedProps.isEmpty); // false
  /// ```
  /// {@endtemplate}
  @override
  bool get isEmpty;
}

// --------------------------------------------------------------------------------------------------------
// Mergeable
// --------------------------------------------------------------------------------------------------------

/// {@template mergeable}
/// Interface for objects that can merge with other objects of the same type.
///
/// This interface defines a contract for objects that support intelligent
/// merging operations, where properties from a parent object are combined
/// with the current object's properties in a non-destructive way.
///
/// Merging is used extensively in configuration scenarios where:
/// - Child configurations inherit from parent configurations
/// - Default values are combined with override values
/// - Multiple configuration sources need to be combined
///
/// Example usage:
/// ```dart
/// class Config implements Mergeable {
///   final Map<String, dynamic> values;
///
///   Config(this.values);
///
///   @override
///   bool isMergeEnabled() => true;
///
///   @override
///   Object merge(Object parent) {
///     if (parent is Config) {
///       return Config({...parent.values, ...values});
///     }
///     return this;
///   }
/// }
///
/// final parentConfig = Config({'timeout': 5000, 'host': 'localhost'});
/// final childConfig = Config({'timeout': 10000, 'port': 8080});
/// final merged = childConfig.merge(parentConfig) as Config;
/// print(merged.values); // {'timeout': 10000, 'host': 'localhost', 'port': 8080}
/// ```
/// {@endtemplate}
abstract class Mergeable {
  /// {@template mergeable_is_merge_enabled}
  /// Returns whether merging is enabled for this particular instance.
  ///
  /// This method allows objects to dynamically control whether they
  /// participate in merging operations. When false, the merge operation
  /// may return the current object unchanged or follow different merging
  /// semantics.
  ///
  /// Returns true if this instance supports and allows merging,
  /// false otherwise.
  ///
  /// Example:
  /// ```dart
  /// class OptionalMergeConfig implements Mergeable {
  ///   final bool enableMerging;
  ///   final Map<String, dynamic> values;
  ///
  ///   OptionalMergeConfig(this.values, {this.enableMerging = true});
  ///
  ///   @override
  ///   bool isMergeEnabled() => enableMerging;
  ///
  ///   @override
  ///   Object merge(Object parent) {
  ///     if (!enableMerging) return this;
  ///     if (parent is OptionalMergeConfig) {
  ///       return OptionalMergeConfig({...parent.values, ...values});
  ///     }
  ///     return this;
  ///   }
  /// }
  ///
  /// final config = OptionalMergeConfig({'key': 'value'}, enableMerging: false);
  /// print(config.isMergeEnabled()); // false
  /// ```
  /// {@endtemplate}
  bool isMergeEnabled();

  /// {@template mergeable_merge}
  /// Merge the current value set with that of the supplied object.
  ///
  /// This method performs an intelligent combination of the current object's
  /// state with the parent object's state. The merging strategy should be:
  /// - Non-destructive (parent values are not modified)
  /// - Preferential (child values typically override parent values)
  /// - Type-aware (handles different data structures appropriately)
  ///
  /// [parent]: The parent object to merge with. This should be of the same
  ///           type as the current object, but implementations may handle
  ///           type mismatches gracefully.
  ///
  /// Returns a new object containing the merged state, or the current object
  /// if merging is not possible or not enabled.
  ///
  /// Example with map merging:
  /// ```dart
  /// class MergeableMap implements Mergeable {
  ///   final Map<String, dynamic> data;
  ///
  ///   MergeableMap(this.data);
  ///
  ///   @override
  ///   bool isMergeEnabled() => true;
  ///
  ///   @override
  ///   Object merge(Object parent) {
  ///     if (parent is MergeableMap) {
  ///       // Child values override parent values
  ///       return MergeableMap({...parent.data, ...data});
  ///     }
  ///     return this;
  ///   }
  /// }
  ///
  /// final parent = MergeableMap({'common': 'parent', 'parentOnly': true});
  /// final child = MergeableMap({'common': 'child', 'childOnly': 42});
  /// final result = child.merge(parent) as MergeableMap;
  /// print(result.data); 
  /// // {'common': 'child', 'parentOnly': true, 'childOnly': 42}
  /// ```
  ///
  /// Example with list merging (append strategy):
  /// ```dart
  /// class MergeableList implements Mergeable {
  ///   final List<dynamic> items;
  ///
  ///   MergeableList(this.items);
  ///
  ///   @override
  ///   bool isMergeEnabled() => true;
  ///
  ///   @override
  ///   Object merge(Object parent) {
  ///     if (parent is MergeableList) {
  ///       // Append child items to parent items
  ///       return MergeableList([...parent.items, ...items]);
  ///     }
  ///     return this;
  ///   }
  /// }
  ///
  /// final parent = MergeableList([1, 2, 3]);
  /// final child = MergeableList([4, 5]);
  /// final result = child.merge(parent) as MergeableList;
  /// print(result.items); // [1, 2, 3, 4, 5]
  /// ```
  /// {@endtemplate}
  Object merge(Object parent);
}

// --------------------------------------------------------------------------------------------------------
// StringValueResolver
// --------------------------------------------------------------------------------------------------------

/// {@template string_value_resolver}
/// Interface for resolving string values to their actual values.
///
/// This interface is used to resolve string values to their actual values,
/// typically for configuration properties. Implementations may perform
/// various operations such as environment variable lookups, property
/// expansion, or custom value resolution logic.
///
/// Example usage:
/// ```dart
/// class MyStringValueResolver implements StringValueResolver {
///   @override
///   String? resolve(String value) {
///     // Custom resolution logic
///     return value;
///   }
/// }
/// ```
/// {@endtemplate}
abstract interface class StringValueResolver {
  /// {@template string_value_resolver_resolve_string_value}
  /// Resolve the given String value, for example resolving placeholders.
  /// 
  /// [value] the original String value (never `null`)
  /// Returns the resolved String value (may be `null` when resolved to a null
  /// value), possibly the original String value itself (in case of no placeholders
  /// to resolve or when ignoring unresolvable placeholders)
  /// 
  /// Throws [IllegalArgumentException] if the given String value cannot be resolved
  /// {@endtemplate}
  String? resolve(String value);
}