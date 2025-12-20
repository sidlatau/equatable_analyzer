import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'src/fixes/add_missing_equatable_property_fix.dart';
import 'src/rules/missing_equatable_property.dart';

final plugin = EquatableAnalyzerPlugin();

class EquatableAnalyzerPlugin extends Plugin {
  @override
  String get name => 'Equatable Analyzer';

  @override
  Future<void> register(PluginRegistry registry) async {
    registry.registerWarningRule(MissingEquatablePropertyRule());
    registry.registerFixForRule(
      MissingEquatablePropertyRule.code,
      AddMissingEquatablePropertyFix.new,
    );
  }
}
