/// Polynomial and Equation Solver for CAS Engine
library;

import 'dart:math' as math;
import 'evaluator.dart';
import 'matrix.dart';
import 'parser.dart';

class RootItem {
  final double real;
  final double imag;
  String display;

  RootItem({
    required this.real,
    required this.imag,
    required this.display,
  });
}

class PolynomialResult {
  final int degree;
  final List<double> coefficients;
  final List<RootItem> roots;
  final List<String> steps;

  PolynomialResult({
    required this.degree,
    required this.coefficients,
    required this.roots,
    required this.steps,
  });
}

class SystemResult {
  final List<double> result;
  final List<String> steps;

  SystemResult({required this.result, required this.steps});
}

class PolynomialReconstruction {
  final List<double> coefficients;
  final int degree;

  PolynomialReconstruction({
    required this.coefficients,
    required this.degree,
  });
}

/// Reconstructs polynomial coefficients c_n * x^n + ... + c_1 * x + c_0
/// using Vandermonde matrix interpolation. Assumes max degree of 5.
PolynomialReconstruction reconstructPolynomial(
  String expression, [
  String variable = 'x',
]) {
  final ast = parseExpression(expression);
  final xVals = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0];
  final yVals = <double>[];

  try {
    for (final x in xVals) {
      yVals.add(evaluateAST(ast, {variable: x}));
    }
  } catch (_) {
    throw ArgumentError(
      "Expression evaluation failed. Ensure only '$variable' is used as variable.",
    );
  }

  // Find lowest-degree polynomial that fits perfectly (d from 0 to 5)
  for (var d = 0; d <= 5; d++) {
    final pointsCount = d + 1;
    final subX = xVals.sublist(0, pointsCount);
    final subY = yVals.sublist(0, pointsCount);

    // Build sub Vandermonde matrix of size (d+1) x (d+1)
    final v = List.generate(pointsCount, (i) {
      return List.generate(d + 1, (j) => math.pow(subX[i], j).toDouble());
    });

    try {
      final vInv = inverse(v);
      final yCol = subY.map((y) => [y]).toList();
      final cVec = multiply(vInv, yCol);
      final coeffs = cVec.map((row) => double.parse(row[0].toStringAsPrecision(12))).toList();

      // Validate on remaining test points
      var fitsAll = true;
      for (var testIdx = d + 1; testIdx < xVals.length; testIdx++) {
        final testX = xVals[testIdx];
        var predictedY = 0.0;
        for (var j = 0; j <= d; j++) {
          predictedY += coeffs[j] * math.pow(testX, j);
        }
        if ((predictedY - yVals[testIdx]).abs() > 1e-4) {
          fitsAll = false;
          break;
        }
      }

      if (fitsAll) {
        var degree = d;
        while (degree > 0 && coeffs[degree].abs() < 1e-9) {
          degree--;
        }
        final finalCoeffs = coeffs.sublist(0, degree + 1);
        return PolynomialReconstruction(
          coefficients: finalCoeffs,
          degree: degree,
        );
      }
    } catch (_) {
      // Continue search
    }
  }

  throw UnsupportedError(
    'Expression does not represent a polynomial of degree <= 5',
  );
}

/// Solves a polynomial equation c_n x^n + ... + c_1 x + c_0 = 0
PolynomialResult solvePolynomial(String expression, [String variable = 'x']) {
  final recon = reconstructPolynomial(expression, variable);
  final coefficients = recon.coefficients;
  final degree = recon.degree;

  final steps = <String>[];
  final roots = <RootItem>[];

  steps.add("Detected expression profile as Polynomial in '$variable'");
  steps.add('Calculated degree: $degree');

  // Standard form string
  final coeffTerms = <String>[];
  for (var i = coefficients.length - 1; i >= 0; i--) {
    final c = coefficients[i];
    if (c.abs() < 1e-9) continue;
    final sign = c > 0 ? (coeffTerms.isEmpty ? '' : '+ ') : '- ';
    final absC = c.abs();
    final cStr = (absC == 1 && i > 0) ? '' : (absC % 1 == 0 ? absC.toInt().toString() : absC.toString());
    final varStr = i == 0 ? (absC % 1 == 0 ? absC.toInt().toString() : absC.toString()) : i == 1 ? variable : '$variable^$i';
    coeffTerms.add('$sign$cStr${i == 0 ? '' : varStr}');
  }
  steps.add('Standard Form: ${coeffTerms.join(' ')} = 0');

  if (degree == 0) {
    final c0 = coefficients[0];
    if (c0.abs() < 1e-9) {
      steps.add('Infinite solutions (identity equation 0 = 0).');
      roots.add(RootItem(real: 0, imag: 0, display: 'All real numbers'));
    } else {
      steps.add('No solution (contradictory equation c_0 = 0).');
    }
  } else if (degree == 1) {
    final c0 = coefficients[0];
    final c1 = coefficients[1];
    final rootVal = -c0 / c1;
    steps.add('Linear Equation formula: x = -c0 / c1');
    steps.add('x = -($c0) / $c1 = $rootVal');
    roots.add(RootItem(
      real: rootVal,
      imag: 0,
      display: '$variable = ${_fmt(rootVal)}',
    ));
  } else if (degree == 2) {
    final c0 = coefficients[0];
    final c1 = coefficients[1];
    final c2 = coefficients[2];

    steps.add('Quadratic equation coefficients: a = $c2, b = $c1, c = $c0');
    final discriminant = c1 * c1 - 4 * c2 * c0;
    steps.add('Discriminant (b^2 - 4ac) = ${_fmt(discriminant)}');

    if (discriminant >= 0) {
      final r1 = (-c1 + math.sqrt(discriminant)) / (2 * c2);
      final r2 = (-c1 - math.sqrt(discriminant)) / (2 * c2);
      steps.add('Real roots: x = (-b ± sqrt(D)) / 2a');
      steps.add('x1 = (-$c1 + ${_fmt(math.sqrt(discriminant))}) / ${2 * c2} = ${_fmt(r1)}');
      steps.add('x2 = (-$c1 - ${_fmt(math.sqrt(discriminant))}) / ${2 * c2} = ${_fmt(r2)}');

      roots.add(RootItem(real: r1, imag: 0, display: '$variable = ${_fmt(r1)}'));
      if ((r1 - r2).abs() > 1e-9) {
        roots.add(RootItem(real: r2, imag: 0, display: '$variable = ${_fmt(r2)}'));
      }
    } else {
      final realPart = -c1 / (2 * c2);
      final imagPart = math.sqrt(-discriminant) / (2 * c2);
      steps.add('Complex roots detected (D < 0):');
      steps.add('x = -b / 2a ± i * sqrt(-D) / 2a');
      final d1 = '${_fmt(realPart)} + ${_fmt(imagPart)}i';
      final d2 = '${_fmt(realPart)} - ${_fmt(imagPart)}i';
      roots.add(RootItem(real: realPart, imag: imagPart, display: '$variable = $d1'));
      roots.add(RootItem(real: realPart, imag: -imagPart, display: '$variable = $d2'));
    }
  } else if (degree >= 3) {
    steps.add('Using multi-start Newton-Raphson approximation + polynomial division');
    var currentPoly = List<double>.from(coefficients);
    var deg = degree;

    while (deg > 2) {
      double? foundRoot;
      final startPoints = [0.0, 1.0, -1.0, 2.5, -2.5, 5.0, -5.0, 10.0, -10.0];

      for (final start in startPoints) {
        var x = start;
        var converged = false;
        for (var iter = 0; iter < 100; iter++) {
          var pVal = 0.0;
          var dpVal = 0.0;
          for (var i = 0; i <= deg; i++) {
            pVal += currentPoly[i] * math.pow(x, i);
            if (i > 0) {
              dpVal += i * currentPoly[i] * math.pow(x, i - 1);
            }
          }

          if (dpVal.abs() < 1e-12) break;

          final nextX = x - pVal / dpVal;
          if ((nextX - x).abs() < 1e-10) {
            converged = true;
            x = nextX;
            break;
          }
          x = nextX;
        }

        var finalPVal = 0.0;
        for (var i = 0; i <= deg; i++) {
          finalPVal += currentPoly[i] * math.pow(x, i);
        }

        if (converged && finalPVal.abs() < 1e-6) {
          foundRoot = x;
          break;
        }
      }

      if (foundRoot != null) {
        steps.add('Found real root via Newton-Raphson: ${_fmt(foundRoot)}');
        roots.add(RootItem(
          real: foundRoot,
          imag: 0,
          display: '$variable = ${_fmt(foundRoot)}',
        ));

        // Synthetic division to deflate polynomial
        final deflated = List<double>.filled(deg, 0.0);
        var remainder = currentPoly[deg];
        deflated[deg - 1] = remainder;

        for (var i = deg - 1; i > 0; i--) {
          remainder = currentPoly[i] + remainder * foundRoot;
          deflated[i - 1] = remainder;
        }
        currentPoly = deflated;
        deg--;
      } else {
        steps.add('Newton-Raphson completed iterations.');
        break;
      }
    }

    if (deg == 2) {
      final c0 = currentPoly[0];
      final c1 = currentPoly[1];
      final c2 = currentPoly[2];
      final discriminant = c1 * c1 - 4 * c2 * c0;
      if (discriminant >= 0) {
        final r1 = (-c1 + math.sqrt(discriminant)) / (2 * c2);
        final r2 = (-c1 - math.sqrt(discriminant)) / (2 * c2);
        roots.add(RootItem(real: r1, imag: 0, display: '$variable = ${_fmt(r1)}'));
        if ((r1 - r2).abs() > 1e-9) {
          roots.add(RootItem(real: r2, imag: 0, display: '$variable = ${_fmt(r2)}'));
        }
      } else {
        final realPart = -c1 / (2 * c2);
        final imagPart = math.sqrt(-discriminant) / (2 * c2);
        roots.add(RootItem(
          real: realPart,
          imag: imagPart,
          display: '$variable = ${_fmt(realPart)} + ${_fmt(imagPart)}i',
        ));
        roots.add(RootItem(
          real: realPart,
          imag: -imagPart,
          display: '$variable = ${_fmt(realPart)} - ${_fmt(imagPart)}i',
        ));
      }
    } else if (deg == 1) {
      final r = -currentPoly[0] / currentPoly[1];
      roots.add(RootItem(real: r, imag: 0, display: '$variable = ${_fmt(r)}'));
    }
  }

  // Factorization Step if roots are available and all real
  final realOnlyRoots = roots.where((r) => r.imag.abs() < 1e-9).map((r) => r.real).toList();
  if (realOnlyRoots.length == degree && degree > 0) {
    final leadingCoeff = coefficients[coefficients.length - 1];
    final leadStr = (leadingCoeff == 1) ? '' : _fmt(leadingCoeff);

    final factorTerms = realOnlyRoots.map((r) {
      final rStr = -r;
      final part = rStr > 0 ? '+ ${_fmt(rStr)}' : rStr < 0 ? '- ${_fmt(rStr.abs())}' : '';
      return '($variable ${part.isNotEmpty ? part : ''})'.replaceAll('  ', ' ');
    }).toList();

    final factoredText = '$leadStr${factorTerms.join('')}';
    steps.add('Factored Form: $factoredText');
  }

  return PolynomialResult(
    degree: degree,
    coefficients: coefficients,
    roots: roots,
    steps: steps,
  );
}

/// Solves a system of linear equations A * X = B
SystemResult solveLinearSystem(Matrix a, List<double> b) {
  final steps = <String>[];
  final n = a.length;

  steps.add('Linear system received with dimension: ${n}x$n');
  steps.add('Solving system: A * X = B');

  if (b.length != n) {
    throw MatrixError('Dimension mismatch: Vector B must have identical length as rows in A');
  }

  try {
    final aInv = inverse(a);
    steps.add('Matrix is non-singular. Calculating matrix inverse A^-1...');

    final bMat = b.map((val) => [val]).toList();
    final xMat = multiply(aInv, bMat);
    final result = xMat.map((row) => double.parse(row[0].toStringAsPrecision(12))).toList();

    steps.add('Inverse multiplication: X = A^-1 * B');
    for (var i = 0; i < result.length; i++) {
      steps.add('Variable X_${i + 1} = ${result[i]}');
    }

    return SystemResult(result: result, steps: steps);
  } catch (err) {
    throw MatrixError('System of equations has singular coefficient matrix (no unique solution)');
  }
}

String _fmt(double v) {
  if (v.abs() < 1e-12) return '0';
  if (v % 1 == 0) return v.toInt().toString();
  return double.parse(v.toStringAsFixed(6)).toString();
}
