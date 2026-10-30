/// Computational Calculus Engine
library;

import 'dart:math' as math;
import 'ast.dart';
import 'evaluator.dart';
import 'fraction.dart';
import 'parser.dart';

/// Serializes an AST Node back to a clean algebraic string expression
String stringifyAST(ASTNode node) {
  return switch (node) {
    NumberNode(:final value) => () {
        if (value % 1 == 0) return value.toInt().toString();
        return value.toString();
      }(),
    ConstantNode(:final name) => name,
    VariableNode(:final name) => name,
    UnaryOpNode(:final operator, :final operand) => () {
        final inner = stringifyAST(operand);
        final operandStr = operand is BinaryOpNode ? '($inner)' : inner;
        return '$operator$operandStr';
      }(),
    BinaryOpNode(:final operator, :final left, :final right) => () {
        var l = stringifyAST(left);
        var r = stringifyAST(right);

        if (operator == '*' || operator == '/' || operator == '^') {
          if (left is BinaryOpNode &&
              (left.operator == '+' || left.operator == '-')) {
            l = '($l)';
          }
        }
        if (operator == '^') {
          if (right is BinaryOpNode) {
            r = '($r)';
          }
        } else if (operator == '/' || operator == '-') {
          if (right is BinaryOpNode) {
            r = '($r)';
          }
        }

        return '$l $operator $r';
      }(),
    FunctionNode(:final name, :final arguments) =>
      '$name(${arguments.map(stringifyAST).join(', ')})',
  };
}

/// Simplifies basic obvious structures (e.g., 0 * x -> 0, 1 * x -> x, 0 + x -> x)
ASTNode simplifyAST(ASTNode node) {
  if (node is UnaryOpNode) {
    final operand = simplifyAST(node.operand);
    if (operand is NumberNode && operand.value == 0) {
      return const NumberNode(0);
    }
    return UnaryOpNode(operator: node.operator, operand: operand);
  }

  if (node is FunctionNode) {
    final args = node.arguments.map(simplifyAST).toList();
    return FunctionNode(name: node.name, arguments: args);
  }

  if (node is BinaryOpNode) {
    final left = simplifyAST(node.left);
    final right = simplifyAST(node.right);

    // Number constant folding
    if (left is NumberNode && right is NumberNode) {
      final l = left.value;
      final r = right.value;
      return switch (node.operator) {
        '+' => NumberNode(l + r),
        '-' => NumberNode(l - r),
        '*' => NumberNode(l * r),
        '/' => r != 0
            ? NumberNode(l / r)
            : BinaryOpNode(operator: '/', left: left, right: right),
        '^' => NumberNode(math.pow(l, r).toDouble()),
        _ => BinaryOpNode(operator: node.operator, left: left, right: right),
      };
    }

    // Multiplication rules:
    if (node.operator == '*') {
      if (left is NumberNode) {
        if (left.value == 0) return const NumberNode(0);
        if (left.value == 1) return right;
      }
      if (right is NumberNode) {
        if (right.value == 0) return const NumberNode(0);
        if (right.value == 1) return left;
      }
    }

    // Addition / Subtraction rules:
    if (node.operator == '+') {
      if (left is NumberNode && left.value == 0) return right;
      if (right is NumberNode && right.value == 0) return left;
    }
    if (node.operator == '-') {
      if (right is NumberNode && right.value == 0) return left;
      if (left is NumberNode && left.value == 0) {
        return UnaryOpNode(operator: '-', operand: right);
      }
    }

    // Power rules:
    if (node.operator == '^') {
      if (right is NumberNode) {
        if (right.value == 0) return const NumberNode(1);
        if (right.value == 1) return left;
      }
    }

    return BinaryOpNode(operator: node.operator, left: left, right: right);
  }

  return node;
}

/// Differentiates an AST symbolically wrt a variable (e.g. x)
ASTNode differentiateSymbolic(ASTNode node, [String variable = 'x']) {
  return switch (node) {
    NumberNode() || ConstantNode() => const NumberNode(0),
    VariableNode(:final name) =>
      name.toLowerCase() == variable.toLowerCase()
          ? const NumberNode(1)
          : const NumberNode(0),
    UnaryOpNode(:final operator, :final operand) => UnaryOpNode(
        operator: operator,
        operand: differentiateSymbolic(operand, variable),
      ),
    BinaryOpNode(:final operator, :final left, :final right) => () {
        final u = left;
        final v = right;
        final du = differentiateSymbolic(u, variable);
        final dv = differentiateSymbolic(v, variable);

        return switch (operator) {
          '+' => BinaryOpNode(operator: '+', left: du, right: dv),
          '-' => BinaryOpNode(operator: '-', left: du, right: dv),
          '*' => BinaryOpNode(
              operator: '+',
              left: BinaryOpNode(operator: '*', left: du, right: v),
              right: BinaryOpNode(operator: '*', left: u, right: dv),
            ),
          '/' => BinaryOpNode(
              operator: '/',
              left: BinaryOpNode(
                operator: '-',
                left: BinaryOpNode(operator: '*', left: du, right: v),
                right: BinaryOpNode(operator: '*', left: u, right: dv),
              ),
              right: BinaryOpNode(
                operator: '^',
                left: v,
                right: const NumberNode(2),
              ),
            ),
          '^' => () {
              if (v is NumberNode) {
                final n = v.value;
                return BinaryOpNode(
                  operator: '*',
                  left: BinaryOpNode(
                    operator: '*',
                    left: NumberNode(n),
                    right: BinaryOpNode(
                      operator: '^',
                      left: u,
                      right: NumberNode(n - 1),
                    ),
                  ),
                  right: du,
                );
              }
              if (u is ConstantNode && u.name.toLowerCase() == 'e') {
                return BinaryOpNode(
                  operator: '*',
                  left: BinaryOpNode(operator: '^', left: u, right: v),
                  right: dv,
                );
              }
              throw UnsupportedError(
                'Symbolic derivative for variable base & exponent is not supported',
              );
            }(),
          _ => throw UnsupportedError('Unsupported operator: $operator'),
        };
      }(),
    FunctionNode(:final name, :final arguments) => () {
        final u = arguments.isNotEmpty ? arguments.first : const VariableNode('x');
        final du = differentiateSymbolic(u, variable);
        final funcName = name.toLowerCase();

        final ASTNode dFunc = switch (funcName) {
          'sin' => FunctionNode(name: 'cos', arguments: [u]),
          'cos' => UnaryOpNode(
              operator: '-',
              operand: FunctionNode(name: 'sin', arguments: [u]),
            ),
          'tan' => BinaryOpNode(
              operator: '/',
              left: const NumberNode(1),
              right: BinaryOpNode(
                operator: '^',
                left: FunctionNode(name: 'cos', arguments: [u]),
                right: const NumberNode(2),
              ),
            ),
          'ln' => BinaryOpNode(
              operator: '/',
              left: const NumberNode(1),
              right: u,
            ),
          'sqrt' => BinaryOpNode(
              operator: '/',
              left: const NumberNode(1),
              right: BinaryOpNode(
                operator: '*',
                left: const NumberNode(2),
                right: FunctionNode(name: 'sqrt', arguments: [u]),
              ),
            ),
          'exp' => FunctionNode(name: 'exp', arguments: [u]),
          _ => throw UnsupportedError(
              'Symbolic derivative for function "$name" is not implemented',
            ),
        };

        return BinaryOpNode(operator: '*', left: dFunc, right: du);
      }(),
  };
}

/// Integrates an AST symbolically wrt a variable (e.g. x)
ASTNode integrateSymbolic(ASTNode node, [String variable = 'x']) {
  final vLower = variable.toLowerCase();
  return switch (node) {
    NumberNode(:final value) => value == 0
        ? const NumberNode(0)
        : BinaryOpNode(
            operator: '*',
            left: NumberNode(value),
            right: VariableNode(variable),
          ),
    ConstantNode(:final name) => BinaryOpNode(
        operator: '*',
        left: ConstantNode(name, node.value),
        right: VariableNode(variable),
      ),
    VariableNode(:final name) => name.toLowerCase() == vLower
        ? BinaryOpNode(
            operator: '/',
            left: BinaryOpNode(
              operator: '^',
              left: VariableNode(variable),
              right: const NumberNode(2),
            ),
            right: const NumberNode(2),
          )
        : BinaryOpNode(
            operator: '*',
            left: VariableNode(name),
            right: VariableNode(variable),
          ),
    UnaryOpNode(:final operator, :final operand) => UnaryOpNode(
        operator: operator,
        operand: integrateSymbolic(operand, variable),
      ),
    BinaryOpNode(:final operator, :final left, :final right) => () {
        if (operator == '+' || operator == '-') {
          return BinaryOpNode(
            operator: operator,
            left: integrateSymbolic(left, variable),
            right: integrateSymbolic(right, variable),
          );
        }
        // Constant * f(x)
        if (operator == '*') {
          if (left is NumberNode) {
            return BinaryOpNode(
              operator: '*',
              left: left,
              right: integrateSymbolic(right, variable),
            );
          }
          if (right is NumberNode) {
            return BinaryOpNode(
              operator: '*',
              left: right,
              right: integrateSymbolic(left, variable),
            );
          }
        }
        // Power rule: x^n
        if (operator == '^' && left is VariableNode && left.name.toLowerCase() == vLower) {
          if (right is NumberNode) {
            final n = right.value;
            if (n == -1) {
              return FunctionNode(name: 'ln', arguments: [VariableNode(variable)]);
            }
            final newPow = n + 1;
            return BinaryOpNode(
              operator: '/',
              left: BinaryOpNode(
                operator: '^',
                left: VariableNode(variable),
                right: NumberNode(newPow),
              ),
              right: NumberNode(newPow),
            );
          }
        }
        // 1 / x
        if (operator == '/' && left is NumberNode && left.value == 1 && right is VariableNode && right.name.toLowerCase() == vLower) {
          return FunctionNode(name: 'ln', arguments: [VariableNode(variable)]);
        }
        throw UnsupportedError('Symbolic integral not supported for this form');
      }(),
    FunctionNode(:final name, :final arguments) => () {
        final arg = arguments.isNotEmpty ? arguments.first : VariableNode(variable);
        final isLinearX = arg is VariableNode && arg.name.toLowerCase() == vLower;
        if (!isLinearX) {
          throw UnsupportedError('Symbolic integral for composite function argument not supported');
        }
        return switch (name.toLowerCase()) {
          'sin' => UnaryOpNode(
              operator: '-',
              operand: FunctionNode(name: 'cos', arguments: [VariableNode(variable)]),
            ),
          'cos' => FunctionNode(name: 'sin', arguments: [VariableNode(variable)]),
          'exp' => FunctionNode(name: 'exp', arguments: [VariableNode(variable)]),
          _ => throw UnsupportedError('Symbolic integral for function $name not supported'),
        };
      }(),
  };
}

/// Returns symbolic derivative as a clean mathematical string
String getSymbolicDerivative(String expression, [String variable = 'x']) {
  final ast = parseExpression(expression);
  final deriv = differentiateSymbolic(ast, variable);
  final simplified = simplifyAST(deriv);
  return stringifyAST(simplified);
}

/// Returns symbolic antiderivative / indefinite integral as a string
String getSymbolicIntegral(String expression, [String variable = 'x']) {
  final ast = parseExpression(expression);
  try {
    final integrated = integrateSymbolic(ast, variable);
    final simplified = simplifyAST(integrated);
    return '${stringifyAST(simplified)} + C';
  } catch (_) {
    return '∫($expression) d$variable';
  }
}

/// High-accuracy 5-point central difference numerical derivative
double numericDerivative(
  String expression,
  double xVal, [
  String variable = 'x',
  double h = 1e-5,
]) {
  final ast = parseExpression(expression);
  double f(double x) {
    return evaluateAST(ast, {variable: x});
  }

  final f2hPos = f(xVal + 2 * h);
  final fhPos = f(xVal + h);
  final fhNeg = f(xVal - h);
  final f2hNeg = f(xVal - 2 * h);

  final df = (-f2hPos + 8 * fhPos - 8 * fhNeg + f2hNeg) / (12 * h);
  return double.parse(df.toStringAsFixed(8));
}

/// Computes numerical partial derivative
double partialDerivative(
  String expression,
  String variableName,
  Map<String, double> variablesScope, [
  double h = 1e-5,
]) {
  final ast = parseExpression(expression);
  final xVal = variablesScope[variableName];
  if (xVal == null) {
    throw ArgumentError('Variable "$variableName" missing from scope');
  }

  double f(double val) {
    final scope = Map<String, double>.from(variablesScope);
    scope[variableName] = val;
    return evaluateAST(ast, scope);
  }

  final f2hPos = f(xVal + 2 * h);
  final fhPos = f(xVal + h);
  final fhNeg = f(xVal - h);
  final f2hNeg = f(xVal - 2 * h);

  final df = (-f2hPos + 8 * fhPos - 8 * fhNeg + f2hNeg) / (12 * h);
  return double.parse(df.toStringAsFixed(8));
}

/// Numerical Integration using Simpson's Rule or Trapezoidal Rule
double numericalIntegration(
  String expression,
  double a,
  double b, {
  String variable = 'x',
  int intervals = 1000,
  String method = 'simpson',
}) {
  final ast = parseExpression(expression);
  double f(double x) {
    return evaluateAST(ast, {variable: x});
  }

  if (method == 'trapezoid') {
    final h = (b - a) / intervals;
    var sum = 0.5 * (f(a) + f(b));
    for (var i = 1; i < intervals; i++) {
      sum += f(a + i * h);
    }
    return double.parse((sum * h).toStringAsFixed(10));
  } else {
    // Simpson's 1/3 compound rule
    final n = intervals.isEven ? intervals : intervals + 1;
    final h = (b - a) / n;
    var sum = f(a) + f(b);
    for (var i = 1; i < n; i++) {
      final x = a + i * h;
      if (i.isOdd) {
        sum += 4 * f(x);
      } else {
        sum += 2 * f(x);
      }
    }
    return double.parse(((sum * h) / 3.0).toStringAsFixed(10));
  }
}

class LimitResult {
  final double limit;
  final double directionLeft;
  final double directionRight;
  final bool converges;
  final String formatted;

  LimitResult({
    required this.limit,
    required this.directionLeft,
    required this.directionRight,
    required this.converges,
    required this.formatted,
  });
}

/// Numerical limit approximation as x -> target
LimitResult approximateLimit(
  String expression,
  double target, {
  String variable = 'x',
}) {
  final ast = parseExpression(expression);
  double f(double x) {
    return evaluateAST(ast, {variable: x});
  }

  final hs = [1e-3, 1e-5, 1e-7, 1e-9];
  var leftVal = 0.0;
  var rightVal = 0.0;

  for (final h in hs) {
    try {
      leftVal = f(target - h);
    } catch (_) {}
    try {
      rightVal = f(target + h);
    } catch (_) {}
  }

  final diff = (leftVal - rightVal).abs();
  final converges =
      diff < 1e-4 && leftVal.isFinite && rightVal.isFinite && !leftVal.isNaN;
  final limitValue =
      converges ? double.parse(((leftVal + rightVal) / 2).toStringAsFixed(6)) : double.nan;

  final formattedStr = converges
      ? Fraction.format(limitValue).display
      : 'Diverges / Undefined';

  return LimitResult(
    limit: limitValue,
    directionLeft: double.parse(leftVal.toStringAsFixed(6)),
    directionRight: double.parse(rightVal.toStringAsFixed(6)),
    converges: converges,
    formatted: formattedStr,
  );
}
