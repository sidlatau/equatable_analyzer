import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddMissingEquatableFieldFix extends ResolvedCorrectionProducer {
  static const _addMissingPropertyKind = FixKind(
    'add_missing_equatable_field',
    DartFixKindPriority.standard,
    "Add missing fields to props",
  );

  AddMissingEquatableFieldFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => _addMissingPropertyKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final node = this.node;

    // Find the class declaration whether we start at the field name or declaration
    final classDecl = node.thisOrAncestorOfType<ClassDeclaration>();
    if (classDecl == null) return;

    final element = classDecl.declaredFragment?.element;
    if (element == null) return;

    final fields = element.fields
        .where(
          (f) =>
              !f.isStatic &&
              !f.isSynthetic &&
              f.isFinal &&
              !f.isConst &&
              f.name != null &&
              f.type is! FunctionType &&
              !f.type.isDartCoreFunction,
        )
        .toList();

    // Find the 'props' method
    final method = classDecl.members.whereType<MethodDeclaration>().firstWhere(
      (m) => m.name.lexeme == 'props',
      orElse: () => classDecl.members.whereType<MethodDeclaration>().first,
    );

    // Ensure we actually found 'props'
    if (method.name.lexeme != 'props') return;

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
        .where((f) => f.name != null && !includedNames.contains(f.name))
        .toList();

    if (missingFields.isEmpty) return;

    await builder.addDartFileEdit(file, (builder) {
      final elements = expression.elements;
      if (elements.isNotEmpty) {
        builder.addInsertion(elements.last.end, (builder) {
          for (final field in missingFields) {
            final name = field.name;
            if (name != null) {
              builder.write(', ');
              builder.write(name);
            }
          }
        });
      } else {
        builder.addInsertion(expression.leftBracket.end, (builder) {
          for (var i = 0; i < missingFields.length; i++) {
            final name = missingFields[i].name;
            if (name != null) {
              if (i > 0) {
                builder.write(', ');
              }
              builder.write(name);
            }
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
