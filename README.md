# Equatable Analyzer

A Dart analyzer plugin that provides additional lint rules for the [equatable](https://pub.dev/packages/equatable) package.

This plugin ensures that your `Equatable` classes are correctly implemented, preventing common bugs where properties are missing from the `props` list.

## Features

### Rules

#### `missing_equatable_property`
Detects when a `final` field in a class extending `Equatable` is missing from the `props` getter.

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
  final String name;

  const MyState(this.id, this.name);

  @override
  List<Object> get props => [id]; // 'name' is missing!
}
```

## Installation

1. Add `equatable_analyzer` as a dev dependency in your `pubspec.yaml`:

```yaml
dev_dependencies:
  equatable_analyzer: ^0.0.1
```

2. Enable the plugin in your `analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    - equatable_analyzer
```

3. Restart your analysis server (or run `dart analyze`).

## Configuration

Currently, rules are enabled by default when the plugin is active.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

[MIT](https://choosealicense.com/licenses/mit/)
