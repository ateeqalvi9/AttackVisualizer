/// High-Performance AST Evaluator with Domain Checks, Angle Modes, and Calculus Operators
library;

import 'dart:math' as math;
import 'ast.dart';

enum AngleMode { radians, degrees }

/// Evaluates an AST Node given a variable scope and angle mode.
double evaluateAST(
  ASTNode node, [
  Map<String, double> variables = const {},
  AngleMode angleMode = AngleMode.radians,
]) {
  return switch (node) {
    NumberNode(:final value) => value,
    ConstantNode(:final value) => value,
    VariableNode(:final name) => () {
        final val = variables[name] ??
            variables[name.toLowerCase()] ??
            variables[name.toUpperCase()];
        if (val == null) {
          throw ArgumentError('Variable "$name" is undefined in current context');
        }
        return val;
      }(),
    UnaryOpNode(:final operator, :final operand) => () {
        final opVal = evaluateAST(operand, variables, angleMode);
        return operator == '-' ? -opVal : opVal;
      }(),
    BinaryOpNode(:final operator, :final left, :final right) => () {
        final l = evaluateAST(left, variables, angleMode);
        final r = evaluateAST(right, variables, angleMode);

        return switch (operator) {
          '+' => l + r,
          '-' => l - r,
          '*' => l * r,
          '/' => () {
              if (r.abs() < 1e-15) {
                throw UnsupportedError('Division by zero detected');
              }
              return l / r;
            }(),
          '^' => math.pow(l, r).toDouble(),
          _ => throw UnsupportedError('Unknown operator "$operator"'),
        };
      }(),
    FunctionNode(:final name, :final arguments) => () {
        final funcName = name.toLowerCase();

        // 1. Calculus: Derivative (diff / d / derivative)
        if (funcName == 'diff' || funcName == 'derivative' || funcName == 'd') {
          return _evaluateDerivative(arguments, variables, angleMode);
        }

        // 2. Calculus: Definite Integral with limits (integrate / integral)
        if (funcName == 'integrate' || funcName == 'integral') {
          return _evaluateIntegral(arguments, variables, angleMode);
        }

        // 3. Calculus: Limit (limit / lim)
        if (funcName == 'limit' || funcName == 'lim') {
          return _evaluateLimit(arguments, variables, angleMode);
        }

        // Standard Single-Argument Math Functions
        final primaryArg = arguments.isNotEmpty ? arguments.first : const NumberNode(0);
        var arg = evaluateAST(primaryArg, variables, angleMode);

        final isTrig = funcName == 'sin' || funcName == 'cos' || funcName == 'tan';
        final isInverseTrig =
            funcName == 'asin' || funcName == 'acos' || funcName == 'atan';

        // Convert angle to radians if in degrees mode
        if (isTrig && angleMode == AngleMode.degrees) {
          arg = (arg * math.pi) / 180.0;
        }

        var res = switch (funcName) {
          'sin' => math.sin(arg),
          'cos' => math.cos(arg),
          'tan' => math.tan(arg),
          'asin' => math.asin(arg),
          'acos' => math.acos(arg),
          'atan' => math.atan(arg),
          'sinh' => _sinh(arg),
          'cosh' => _cosh(arg),
          'tanh' => _tanh(arg),
          'log' => () {
              if (arguments.length > 1) {
                // log(x, base)
                final base = evaluateAST(arguments[1], variables, angleMode);
                if (arg <= 0 || base <= 0 || base == 1) {
                  throw ArgumentError('Logarithm base/domain error');
                }
                return math.log(arg) / math.log(base);
              }
              if (arg <= 0) {
                throw ArgumentError('Logarithm domain error (must be > 0)');
              }
              return math.log(arg) / math.ln10;
            }(),
          'ln' => () {
              if (arg <= 0) {
                throw ArgumentError('Natural logarithm domain error (must be > 0)');
              }
              return math.log(arg);
            }(),
          'sqrt' => () {
              if (arg < 0) {
                throw ArgumentError('Square root of negative number error');
              }
              return math.sqrt(arg);
            }(),
          'abs' => arg.abs(),
          'exp' => math.exp(arg),
          _ => throw UnsupportedError('Unsupported function "$name"'),
        };

        // Convert back to degrees if inverse trig and degrees mode
        if (isInverseTrig && angleMode == AngleMode.degrees) {
          res = (res * 180.0) / math.pi;
        }

        return res;
      }(),
  };
}

/// Evaluates numerical derivative from AST:
/// diff(expr) -> at variables['x'] or 0
/// diff(expr, point) -> at point
/// diff(expr, var, point) -> wrt var at point
double _evaluateDerivative(
  List<ASTNode> args,
  Map<String, double> variables,
  AngleMode angleMode,
) {
  if (args.isEmpty) {
    throw ArgumentError('Derivative requires an expression: diff(f, [point])');
  }
  final expr = args[0];

  String varName = 'x';
  double point = variables['x'] ?? 0.0;

  if (args.length == 1) {
    point = variables[varName] ?? 0.0;
  } else if (args.length == 2) {
    if (args[1] is VariableNode) {
      varName = (args[1] as VariableNode).name;
      point = variables[varName] ?? 0.0;
    } else {
      point = evaluateAST(args[1], variables, angleMode);
    }
  } else if (args.length >= 3) {
    if (args[1] is VariableNode) {
      varName = (args[1] as VariableNode).name;
    }
    point = evaluateAST(args[2], variables, angleMode);
  }

  const h = 1e-5;
  double evalAt(double t) {
    final scope = Map<String, double>.from(variables);
    scope[varName] = t;
    return evaluateAST(expr, scope, angleMode);
  }

  // 5-point stencil central difference
  final f2hPos = evalAt(point + 2 * h);
  final fhPos = evalAt(point + h);
  final fhNeg = evalAt(point - h);
  final f2hNeg = evalAt(point - 2 * h);

  final df = (-f2hPos + 8 * fhPos - 8 * fhNeg + f2hNeg) / (12 * h);
  return df;
}

/// Evaluates numerical definite integral with limits:
/// integrate(expr) -> integral from 0 to 1 wrt 'x'
/// integrate(expr, b) -> integral from 0 to b wrt 'x'
/// integrate(expr, a, b) -> integral from a to b wrt 'x'
/// integrate(expr, var, a, b) -> integral from a to b wrt var
double _evaluateIntegral(
  List<ASTNode> args,
  Map<String, double> variables,
  AngleMode angleMode,
) {
  if (args.isEmpty) {
    throw ArgumentError('Definite integral requires an expression: integrate(expression, [a], b)');
  }

  final expr = args[0];
  String varName = 'x';
  double a = 0.0;
  double b = 1.0;

  if (args.length == 1) {
    a = 0.0;
    b = 1.0;
  } else if (args.length == 2) {
    a = 0.0;
    b = evaluateAST(args[1], variables, angleMode);
  } else if (args.length == 3) {
    a = evaluateAST(args[1], variables, angleMode);
    b = evaluateAST(args[2], variables, angleMode);
  } else {
    if (args[1] is VariableNode) {
      varName = (args[1] as VariableNode).name;
    }
    a = evaluateAST(args[2], variables, angleMode);
    b = evaluateAST(args[3], variables, angleMode);
  }

  // Simpson's 1/3 compound rule
  const n = 200;
  final h = (b - a) / n;

  double evalAt(double t) {
    final scope = Map<String, double>.from(variables);
    scope[varName] = t;
    return evaluateAST(expr, scope, angleMode);
  }

  var sum = evalAt(a) + evalAt(b);
  for (var i = 1; i < n; i++) {
    final x = a + i * h;
    if (i.isOdd) {
      sum += 4 * evalAt(x);
    } else {
      sum += 2 * evalAt(x);
    }
  }

  return (sum * h) / 3.0;
}

/// Evaluates numerical limit:
/// limit(expr) -> limit as x -> 0
/// limit(expr, target) -> limit as x -> target
/// limit(expr, var, target) -> limit as var -> target
double _evaluateLimit(
  List<ASTNode> args,
  Map<String, double> variables,
  AngleMode angleMode,
) {
  if (args.isEmpty) {
    throw ArgumentError('Limit requires an expression: limit(expression, [target])');
  }

  final expr = args[0];
  String varName = 'x';
  double target = 0.0;

  if (args.length == 1) {
    target = 0.0;
  } else if (args.length == 2) {
    target = evaluateAST(args[1], variables, angleMode);
  } else {
    if (args[1] is VariableNode) {
      varName = (args[1] as VariableNode).name;
    }
    target = evaluateAST(args[2], variables, angleMode);
  }

  double evalAt(double t) {
    final scope = Map<String, double>.from(variables);
    scope[varName] = t;
    return evaluateAST(expr, scope, angleMode);
  }

  final hs = [1e-3, 1e-5, 1e-7, 1e-9];
  var leftVal = 0.0;
  var rightVal = 0.0;

  for (final h in hs) {
    try {
      leftVal = evalAt(target - h);
    } catch (_) {}
    try {
      rightVal = evalAt(target + h);
    } catch (_) {}
  }

  final diff = (leftVal - rightVal).abs();
  if (diff < 1e-4 && leftVal.isFinite && rightVal.isFinite && !leftVal.isNaN) {
    return (leftVal + rightVal) / 2.0;
  }

  if (leftVal.isFinite && !leftVal.isNaN) return leftVal;
  if (rightVal.isFinite && !rightVal.isNaN) return rightVal;
  return double.nan;
}

double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2.0;
double _cosh(double x) => (math.exp(x) + math.exp(-x)) / 2.0;
double _tanh(double x) => _sinh(x) / _cosh(x);
