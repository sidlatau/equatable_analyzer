# Equatable Analyzer

A Dart analyzer plugin that provides additional lint rules for the [equatable](https://pub.dev/packages/equatable) package.

This plugin ensures that your `Equatable` classes are correctly implemented, preventing common bugs where properties are missing from the `props` list.

## Features

### Rules

#### `missing_equatable_field`
Detects when a `final` field in a class extending `Equatable` or using `EquatableMixin` is missing from the `props` getter.

**Good:**
```dart
class MyState extends Equatable {
  final String id;
  final String name;

  const MyState(this.id, this.name);

  @override
  List<Object> get props => [id, name];
}
```

**Bad:**
```dart
class MyState extends Equatable {
  final String id;
  final String name; // Lint: The field 'name' is missing from props.

  const MyState(this.id, this.name);

  @override
  List<Object> get props => [id];
}
```

**Ignoring the rule:**

To ignore the rule for a specific field, add an ignore comment above the field.
Note: The rule ID must be prefixed with the package name.

```dart
class MyState extends Equatable {
  final String id;
  
  // ignore: equatable_analyzer/missing_equatable_field
  final String temporaryValue;

  const MyState(this.id, this.temporaryValue);

  @override
  List<Object> get props => [id];
}
```

## Requirements

- Dart SDK: >=3.10.4

## Installation

Please refer to the [official documentation](https://dart.dev/tools/analyzer-plugins) for how to add and enable analyzer plugins.

Example `analysis_options.yaml`:
```yaml
plugins:
  equatable_analyzer: ^1.0.0
```

## Configuration

Currently, rules are enabled by default when the plugin is active.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

[MIT](LICENSE)
