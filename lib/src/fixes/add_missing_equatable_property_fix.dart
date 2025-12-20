import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddMissingEquatablePropertyFix extends ResolvedCorrectionProducer {
  static const _addMissingPropertyKind = FixKind(
    'add_missing_equatable_property',
    DartFixKindPriority.standard,
    "Add missing properties to props",
  );

  AddMissingEquatablePropertyFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => _addMissingPropertyKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final node = this.node;
    if (node is! MethodDeclaration) return;
    final method = node;

    final classDecl = method.parent;
    if (classDecl is! ClassDeclaration) return;

    final element = classDecl.declaredFragment?.element;
    if (element == null) return;

    final fields = element.fields
        .where(
          (f) =>
              !f.isStatic &&
              !f.isSynthetic &&
              f.isFinal &&
              !f.isConst &&
              f.name != null,
        )
        .toList();

    final expression = _getReturnExpression(method);
    if (expression is! ListLiteral) return;

    final includedNames = <String>{};
    for (final element in expression.elements) {
      if (element is SimpleIdentifier) {
        includedNames.add(element.name);
      } else if (element is PropertyAccess) {
        includedNames.add(element.propertyName.name);
      } else if (element is PrefixedIdentifier &&
          element.prefix.name == 'this') {
        includedNames.add(element.identifier.name);
      }
    }

    final missingFields = fields
        .where((f) => !includedNames.contains(f.name!))
        .toList();

    if (missingFields.isEmpty) return;

    await builder.addDartFileEdit(file, (builder) {
      final elements = expression.elements;
      if (elements.isNotEmpty) {
        builder.addInsertion(elements.last.end, (builder) {
          for (final field in missingFields) {
            builder.write(', ');
            builder.write(field.name!);
          }
        });
      } else {
        builder.addInsertion(expression.leftBracket.end, (builder) {
          for (var i = 0; i < missingFields.length; i++) {
            if (i > 0) {
              builder.write(', ');
            }
            builder.write(missingFields[i].name!);
          }
        });
      }
    });
  }

  Expression? _getReturnExpression(MethodDeclaration method) {
    final body = method.body;
    if (body is ExpressionFunctionBody) {
      return body.expression;
    } else if (body is BlockFunctionBody) {
      for (final statement in body.block.statements) {
        if (statement is ReturnStatement) {
          return statement.expression;
        }
      }
    }
    return null;
  }
}
