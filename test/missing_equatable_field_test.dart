import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:equatable_analyzer/src/rules/missing_equatable_field.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingEquatableFieldRuleTest);
  });
}

@reflectiveTest
class MissingEquatableFieldRuleTest extends AnalysisRuleTest {
  @override
  String get analysisRule => 'missing_equatable_field';

  @override
  void setUp() {
    if (!Registry.ruleRegistry.any((r) => r.name == analysisRule)) {
      Registry.ruleRegistry.registerWarningRule(MissingEquatableFieldRule());
    }
    newPackage('equatable').addFile('lib/equatable.dart', r'''
class Equatable {
  const Equatable();
  List<Object?> get props => [];
}
''');
    super.setUp();
  }

  Future<void> test_missing_property() async {
    await assertDiagnostics(
      r'''
import 'package:equatable/equatable.dart';

class MyState extends Equatable {
  final String id;
  final String name;

  const MyState(this.id, this.name);

  @override
  List<Object> get props => [id];
}
''',
      [lint(112, 4)],
    );
  }

  Future<void> test_ignore_field() async {
    await assertNoDiagnostics(r'''
import 'package:equatable/equatable.dart';

class MyState extends Equatable {
  final String id;
  // ignore: missing_equatable_field
  final String name;

  const MyState(this.id, this.name);

  @override
  List<Object> get props => [id];
}
''');
  }

  Future<void> test_valid_class() async {
    await assertNoDiagnostics(r'''
import 'package:equatable/equatable.dart';

class MyState extends Equatable {
  final String id;
  final String name;

  const MyState(this.id, this.name);

  @override
  List<Object> get props => [id, name];
}
''');
  }

  Future<void> test_function_field_ignored() async {
    await assertNoDiagnostics(r'''
import 'package:equatable/equatable.dart';

class MyState extends Equatable {
  final String id;
  final VoidCallback onTap;

  const MyState(this.id, this.onTap);

  @override
  List<Object> get props => [id];
}

typedef VoidCallback = void Function();
''');
  }

  Future<void> test_raw_function_field_ignored() async {
    await assertNoDiagnostics(r'''
import 'package:equatable/equatable.dart';

class MyState extends Equatable {
  final String id;
  final Function onSomething;

  const MyState(this.id, this.onSomething);

  @override
  List<Object> get props => [id];
}
''');
  }
}
