import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:equatable_analyzer/src/rules/missing_equatable_property.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingEquatablePropertyRuleTest);
  });
}

@reflectiveTest
class MissingEquatablePropertyRuleTest extends AnalysisRuleTest {
  @override
  String get analysisRule => 'missing_equatable_property';

  @override
  void setUp() {
    if (!Registry.ruleRegistry.any((r) => r.name == analysisRule)) {
      Registry.ruleRegistry.registerWarningRule(MissingEquatablePropertyRule());
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
      [lint(188, 5)],
    );
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
}
