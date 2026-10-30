import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_cas/core/math_engine/tokens.dart';
import 'package:scientific_cas/core/math_engine/parser.dart';
import 'package:scientific_cas/core/math_engine/evaluator.dart';
import 'package:scientific_cas/core/math_engine/calculator.dart';
import 'package:scientific_cas/core/math_engine/matrix.dart';
import 'package:scientific_cas/core/math_engine/calculus.dart';
import 'package:scientific_cas/core/math_engine/solver.dart';

void main() {
  group('Tokenizer & Implicit Multiplication', () {
    test('Tokenizes basic expression', () {
      final tokens = tokenize('2 + 3 * 4');
      expect(tokens.length, 6); // 2, +, 3, *, 4, EOF
    });

    test('Injects implicit multiplication for 2x and 2(x+1)', () {
      final t1 = injectImplicitMultiplication(tokenize('2x'));
      expect(t1.any((t) => t.type == TokenType.multiply), isTrue);

      final t2 = injectImplicitMultiplication(tokenize('2(x+1)'));
      expect(t2.any((t) => t.type == TokenType.multiply), isTrue);
    });
  });

  group('Parser & Evaluator', () {
    test('Evaluates arithmetic correctly', () {
      final ast = parseExpression('2 + 3 * 4');
      expect(evaluateAST(ast), 14.0);
    });

    test('Evaluates powers right-associative', () {
      final ast = parseExpression('2^3^2'); // 2^(3^2) = 2^9 = 512
      expect(evaluateAST(ast), 512.0);
    });

    test('Evaluates trigonometric and constants', () {
      final ast = parseExpression('sin(pi / 2)');
      final val = evaluateAST(ast);
      expect(val, closeTo(1.0, 1e-9));
    });

    test('Evaluates degrees mode', () {
      final ast = parseExpression('sin(90)');
      final val = evaluateAST(ast, {}, AngleMode.degrees);
      expect(val, closeTo(1.0, 1e-9));
    });

    test('Evaluates variables scope', () {
      final ast = parseExpression('x^2 + 2x + 1');
      expect(evaluateAST(ast, {'x': 3}), 16.0);
    });
  });

  group('Scientific Calculator Engine', () {
    test('Cleans precision noise', () {
      final res = evaluateScientific('0.1 + 0.2');
      expect(res.result, 0.3);
    });

    test('Computes factorials', () {
      expect(factorial(5), 120);
      expect(factorial(0), 1);
    });
  });

  group('Matrix Engine', () {
    test('Addition & Multiplication', () {
      final a = [
        [1.0, 2.0],
        [3.0, 4.0],
      ];
      final b = [
        [2.0, 0.0],
        [1.0, 2.0],
      ];

      final sum = add(a, b);
      expect(sum[0][0], 3.0);
      expect(sum[1][1], 6.0);

      final prod = multiply(a, b);
      // [1*2 + 2*1, 1*0 + 2*2] = [4, 4]
      // [3*2 + 4*1, 3*0 + 4*2] = [10, 8]
      expect(prod[0][0], 4.0);
      expect(prod[0][1], 4.0);
      expect(prod[1][0], 10.0);
      expect(prod[1][1], 8.0);
    });

    test('Determinant and Inverse', () {
      final a = [
        [4.0, 7.0],
        [2.0, 6.0],
      ];
      expect(determinant(a), closeTo(10.0, 1e-9));

      final inv = inverse(a);
      final check = multiply(a, inv);
      expect(check[0][0], closeTo(1.0, 1e-6));
      expect(check[1][1], closeTo(1.0, 1e-6));
      expect(check[0][1], closeTo(0.0, 1e-6));
    });

    test('RREF computation', () {
      final a = [
        [1.0, 2.0, -1.0, -4.0],
        [2.0, 3.0, -1.0, -11.0],
        [-2.0, 0.0, -3.0, 22.0],
      ];
      final res = rref(a);
      expect(res.rref.length, 3);
      expect(res.steps.isNotEmpty, isTrue);
    });

    test('Eigenvalues computation', () {
      final a = [
        [2.0, 1.0],
        [1.0, 2.0],
      ];
      final evals = eigenvalues(a);
      expect(evals.length, 2);
      expect(evals[0], closeTo(3.0, 1e-2));
      expect(evals[1], closeTo(1.0, 1e-2));
    });
  });

  group('Calculus Engine', () {
    test('Symbolic Derivative', () {
      final deriv = getSymbolicDerivative('x^3 + 5x');
      expect(deriv.contains('x^2') || deriv.contains('x ^ 2'), isTrue);
    });

    test('Numerical Derivative', () {
      // d/dx(x^2) at x=3 is 6
      final df = numericDerivative('x^2', 3.0);
      expect(df, closeTo(6.0, 1e-4));
    });

    test('Numerical Integration (Simpson)', () {
      // Integral of x^2 from 0 to 3 is 9
      final val = numericalIntegration('x^2', 0, 3, intervals: 100);
      expect(val, closeTo(9.0, 1e-4));
    });

    test('Limit Solver', () {
      // lim(x->0) sin(x)/x = 1
      final lim = approximateLimit('sin(x) / x', 0.0);
      expect(lim.converges, isTrue);
      expect(lim.limit, closeTo(1.0, 1e-4));
    });
  });

  group('Equation Solver', () {
    test('Solves Quadratic roots', () {
      // x^2 - 5x + 6 = 0 -> roots 2 and 3
      final res = solvePolynomial('x^2 - 5x + 6');
      expect(res.degree, 2);
      expect(res.roots.length, 2);
      final rootVals = res.roots.map((r) => r.real).toList();
      expect(rootVals.contains(2.0) || rootVals.contains(3.0), isTrue);
    });

    test('Solves Linear System Ax = B', () {
      final a = [
        [2.0, 1.0],
        [1.0, -1.0],
      ];
      final b = [5.0, 1.0];
      // 2x + y = 5, x - y = 1 -> 3x = 6 -> x = 2, y = 1
      final res = solveLinearSystem(a, b);
      expect(res.result[0], closeTo(2.0, 1e-6));
      expect(res.result[1], closeTo(1.0, 1e-6));
    });
  });

  group('Unclosed Parentheses & Auto-Balancing (Calculator Behavior)', () {
    test('Evaluates sin(30 without closing parenthesis in degrees mode', () {
      final res = evaluateScientific('sin(30', angleMode: AngleMode.degrees);
      expect(res.result, 0.5);
      expect(res.fraction, '1/2');
    });

    test('Evaluates nested unclosed parentheses', () {
      final res = evaluateScientific('2 * (3 + (4 * 2');
      expect(res.result, 22.0);
    });

    test('Evaluates cos(45 without closing paren to exact radical √2/2 in degrees mode', () {
      final res = evaluateScientific('cos(45', angleMode: AngleMode.degrees);
      expect(res.fraction, '√2/2');
    });
  });

  group('Fractions & Radicals Formatter', () {
    test('Formats rational fractions correctly', () {
      final res1 = evaluateScientific('3 / 6');
      expect(res1.fraction, '1/2');

      final res2 = evaluateScientific('7 / 4');
      expect(res2.fraction, '7/4');

      final res3 = evaluateScientific('0.75');
      expect(res3.fraction, '3/4');
    });

    test('Detects trigonometric radicals in degrees mode', () {
      final sin30 = evaluateScientific('sin(30)', angleMode: AngleMode.degrees);
      expect(sin30.fraction, '1/2');

      final cos30 = evaluateScientific('cos(30)', angleMode: AngleMode.degrees);
      expect(cos30.fraction, '√3/2');

      final sin45 = evaluateScientific('sin(45)', angleMode: AngleMode.degrees);
      expect(sin45.fraction, '√2/2');

      final tan60 = evaluateScientific('tan(60)', angleMode: AngleMode.degrees);
      expect(tan60.fraction, '√3');
    });
  });

  group('Inline Calculus Expressions & Limits', () {
    test('Evaluates diff(x^3, 2) inline', () {
      final res = evaluateScientific('diff(x^3, 2)');
      expect(res.result, closeTo(12.0, 1e-3));
    });

    test('Evaluates d/dx(x^2, 3) inline using d/dx prefix', () {
      final res = evaluateScientific('d/dx(x^2, 3)');
      expect(res.result, closeTo(6.0, 1e-3));
    });

    test('Evaluates integrate(x^2, 0, 3) inline', () {
      final res = evaluateScientific('integrate(x^2, 0, 3)');
      expect(res.result, closeTo(9.0, 1e-3));
    });

    test('Evaluates ∫(x^2, 0, 3) using integral symbol', () {
      final res = evaluateScientific('∫(x^2, 0, 3)');
      expect(res.result, closeTo(9.0, 1e-3));
    });

    test('Evaluates integrate with default limits (0 to 1)', () {
      final res = evaluateScientific('integrate(x^2)');
      expect(res.result, closeTo(1.0 / 3.0, 1e-3));
      expect(res.fraction, '1/3');
    });

    test('Evaluates limit(sin(x) / x, 0) inline', () {
      final res = evaluateScientific('limit(sin(x) / x, 0)');
      expect(res.result, closeTo(1.0, 1e-3));
    });

    test('Evaluates limit with default target 0', () {
      final res = evaluateScientific('limit(sin(x) / x)');
      expect(res.result, closeTo(1.0, 1e-3));
    });

    test('Computes symbolic antiderivatives', () {
      final anti1 = getSymbolicIntegral('x^2');
      expect(anti1.contains('x ^ 3 / 3') || anti1.contains('x^3 / 3') || anti1.contains('x^3/3'), isTrue);

      final anti2 = getSymbolicIntegral('sin(x)');
      expect(anti2.contains('-cos(x)'), isTrue);
    });
  });
}
