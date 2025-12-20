import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

class MissingEquatableFieldRule extends AnalysisRule {
  MissingEquatableFieldRule()
    : super(
        name: 'missing_equatable_field',
        description: 'Equatable props should include all final fields.',
      );

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = MissingEquatableFieldVisitor(this, context);
    registry.addClassDeclaration(this, visitor);
  }

  static const code = LintCode(
    'missing_equatable_field',
    'The field \'{0}\' is missing from props.',
    correctionMessage: 'Add the field to props.',
  );

  @override
  DiagnosticCode get diagnosticCode => code;
}

class MissingEquatableFieldVisitor extends SimpleAstVisitor<void> {
  final MissingEquatableFieldRule rule;
  final RuleContext context;

  MissingEquatableFieldVisitor(this.rule, this.context);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null) return;

    if (!_extendsEquatable(element)) return;

    final propsGetter = _expectedpropsGetter(element);
    if (propsGetter == null) return;

    final missingFields = _findMissingFields(element, propsGetter, node);

    for (final field in missingFields) {
      final fieldName = field.name;
      if (fieldName == null) continue;

      final fieldDeclaration = node.members
          .whereType<FieldDeclaration>()
          .expand((f) => f.fields.variables)
          .cast<VariableDeclaration?>()
          .firstWhere((v) => v?.name.lexeme == fieldName, orElse: () => null);

      if (fieldDeclaration != null) {
        rule.reportAtToken(fieldDeclaration.name, arguments: [fieldName]);
      }
    }
  }

  bool _extendsEquatable(InterfaceElement? element) {
    if (element == null) return false;
    for (final type in element.allSupertypes) {
      if (type.element.name == 'Equatable' ||
          type.element.name == 'EquatableMixin') {
        return true;
      }
    }
    return false;
  }

  PropertyAccessorElement? _expectedpropsGetter(InterfaceElement element) {
    final getter = element.getGetter('props');
    if (getter == null || getter.isStatic) return null;
    if (getter.enclosingElement != element) return null;
    return getter;
  }

  List<FieldElement> _findMissingFields(
    InterfaceElement classElement,
    PropertyAccessorElement propsGetter,
    ClassDeclaration classNode,
  ) {
    final fields = classElement.fields
        .where((f) => !f.isStatic && !f.isSynthetic && f.isFinal && !f.isConst)
        .where((f) => f.name != null)
        .where((f) => f.type is! FunctionType && !f.type.isDartCoreFunction)
        .toList();

    final propsMethod = classNode.members
        .whereType<MethodDeclaration>()
        .firstWhere(
          (m) => m.declaredFragment?.element == propsGetter,
          orElse: () => throw StateError('Props method not found in AST'),
        );

    final expression = _getReturnExpression(propsMethod);
    if (expression is ListLiteral) {
      final includedNames = <String>{};
      for (final element in expression.elements) {
        if (element is SimpleIdentifier) {
          includedNames.add(element.name);
        }
      }

      return fields.where((f) => !includedNames.contains(f.name)).toList();
    }

    return [];
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
