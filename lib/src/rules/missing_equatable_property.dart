import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

class MissingEquatablePropertyRule extends AnalysisRule {
  MissingEquatablePropertyRule()
    : super(
        name: 'missing_equatable_property',
        description: 'Equatable props should include all final fields.',
      );

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = MissingEquatablePropertyVisitor(this, context);
    registry.addClassDeclaration(this, visitor);
  }

  @override
  DiagnosticCode get diagnosticCode => const LintCode(
    'missing_equatable_property',
    'The field {0} is missing from props.',
    correctionMessage: 'Add the field to props.',
  );
}

class MissingEquatablePropertyVisitor extends SimpleAstVisitor<void> {
  final MissingEquatablePropertyRule rule;
  final RuleContext context;

  MissingEquatablePropertyVisitor(this.rule, this.context);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null) return;

    if (!_extendsEquatable(element)) return;

    final propsGetter = _expectedpropsGetter(element);
    if (propsGetter == null) return;

    final missingFields = _findMissingFields(element, propsGetter, node);

    for (final field in missingFields) {
      final propsNode = node.members.whereType<MethodDeclaration>().firstWhere(
        (m) => m.name.lexeme == 'props',
        orElse: () => node.members.whereType<MethodDeclaration>().first,
      );

      rule.reportAtToken(propsNode.name, arguments: [field.name!]);
    }
  }

  bool _extendsEquatable(InterfaceElement? element) {
    if (element == null) return false;
    for (final type in element.allSupertypes) {
      if (type.element.name == 'Equatable') {
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
      // Find return statement
      for (final statement in body.block.statements) {
        if (statement is ReturnStatement) {
          return statement.expression;
        }
      }
    }
    return null;
  }
}
