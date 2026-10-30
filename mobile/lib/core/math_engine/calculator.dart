/// Scientific Calculator Service Engine with Fraction & Radical Output
library;

import 'ast.dart';
import 'evaluator.dart';
import 'fraction.dart';
import 'parser.dart';

class ScientificResult {
  final double result;
  final ASTNode ast;
  final List<String> steps;
  final String display;
  final String? fraction;
  final String decimal;

  ScientificResult({
    required this.result,
    required this.ast,
    required this.steps,
    required this.display,
    this.fraction,
    required this.decimal,
  });
}

/// Rounds floating point numbers to clean tiny binary arithmetic inaccuracies.
/// e.g. 0.1 + 0.2 = 0.30000000000000004 -> 0.3
double stripPrecision(double num) {
  if (num.isNaN || num.isInfinite) return num;
  // If close to a clean integer
  if ((num - num.round()).abs() < 1e-11) {
    return num.roundToDouble();
  }
  // Format with 12 significant digits to clear IEEE-754 mantissa noise
  final s = num.toStringAsPrecision(12);
  return double.parse(s);
}

/// Computes factorial of a non-negative integer.
int factorial(int n) {
  if (n < 0) {
    throw ArgumentError('Factorial is defined for non-negative integers only');
  }
  if (n == 0 || n == 1) return 1;
  var res = 1;
  for (var i = 2; i <= n; i++) {
    res *= i;
  }
  return res;
}

/// Evaluates a scientific expression.
ScientificResult evaluateScientific(
  String expression, {
  Map<String, double> variables = const {},
  AngleMode angleMode = AngleMode.radians,
}) {
  final ast = parseExpression(expression);
  final raw = evaluateAST(ast, variables, angleMode);
  final cleaned = stripPrecision(raw);
  final formatted = Fraction.format(cleaned);

  final steps = <String>[
    'Parsed Input: $expression',
    'Angle Mode: ${angleMode.name}',
  ];
  if (variables.isNotEmpty) {
    steps.add('Variables: $variables');
  }
  if (formatted.fraction != null && formatted.fraction != formatted.decimal) {
    steps.add('Exact Form: ${formatted.fraction}');
  }
  steps.add('Decimal Value: ${formatted.decimal}');

  return ScientificResult(
    result: cleaned,
    ast: ast,
    steps: steps,
    display: formatted.display,
    fraction: formatted.fraction,
    decimal: formatted.decimal ?? cleaned.toString(),
  );
}
