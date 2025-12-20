import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'src/rules/missing_equatable_property.dart';

final plugin = EquatableAnalyzerPlugin();

class EquatableAnalyzerPlugin extends Plugin {
  @override
  String get name => 'Equatable Analyzer';

  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(MissingEquatablePropertyRule());
  }
}
