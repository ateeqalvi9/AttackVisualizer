/// High-Precision Matrix Computation Engine
library;

import 'dart:math' as math;

typedef Matrix = List<List<double>>;

class MatrixError implements Exception {
  final String message;
  MatrixError(this.message);

  @override
  String toString() => 'MatrixError: $message';
}

class RrefResult {
  final Matrix rref;
  final List<String> steps;
  RrefResult({required this.rref, required this.steps});
}

void validateMatrix(Matrix a) {
  if (a.isEmpty || a[0].isEmpty) {
    throw MatrixError('Matrix must be a non-empty 2D array');
  }
  final cols = a[0].length;
  for (var r = 0; r < a.length; r++) {
    if (a[r].length != cols) {
      throw MatrixError(
        'Matrix has inconsistent column dimensions (not rectangular)',
      );
    }
  }
}

Matrix makeIdentity(int n) {
  return List.generate(
    n,
    (r) => List.generate(n, (c) => r == c ? 1.0 : 0.0),
  );
}

Matrix copyMatrix(Matrix a) {
  return a.map((row) => List<double>.from(row)).toList();
}

Matrix transpose(Matrix a) {
  validateMatrix(a);
  final rows = a.length;
  final cols = a[0].length;
  return List.generate(
    cols,
    (c) => List.generate(rows, (r) => a[r][c]),
  );
}

Matrix add(Matrix a, Matrix b) {
  validateMatrix(a);
  validateMatrix(b);
  if (a.length != b.length || a[0].length != b[0].length) {
    throw MatrixError('Matrix dimensions must match for addition');
  }
  final rows = a.length;
  final cols = a[0].length;
  return List.generate(
    rows,
    (r) => List.generate(cols, (c) => a[r][c] + b[r][c]),
  );
}

Matrix subtract(Matrix a, Matrix b) {
  validateMatrix(a);
  validateMatrix(b);
  if (a.length != b.length || a[0].length != b[0].length) {
    throw MatrixError('Matrix dimensions must match for subtraction');
  }
  final rows = a.length;
  final cols = a[0].length;
  return List.generate(
    rows,
    (r) => List.generate(cols, (c) => a[r][c] - b[r][c]),
  );
}

Matrix multiply(Matrix a, Matrix b) {
  validateMatrix(a);
  validateMatrix(b);
  final rA = a.length;
  final cA = a[0].length;
  final rB = b.length;
  final cB = b[0].length;

  if (cA != rB) {
    throw MatrixError(
      'Incompatible dimensions for multiplication: A is ${rA}x$cA, B is ${rB}x$cB.',
    );
  }

  return List.generate(rA, (r) {
    return List.generate(cB, (c) {
      var sum = 0.0;
      for (var k = 0; k < cA; k++) {
        sum += a[r][k] * b[k][c];
      }
      return sum;
    });
  });
}

Matrix scale(Matrix a, double factor) {
  validateMatrix(a);
  return a.map((row) => row.map((val) => val * factor).toList()).toList();
}

/// Reduced Row Echelon Form (RREF) step-by-step
RrefResult rref(Matrix a) {
  validateMatrix(a);
  final steps = <String>[];
  final rows = a.length;
  final cols = a[0].length;
  final m = copyMatrix(a);

  steps.add('Initial matrix dimensions: ${rows}x$cols');
  var lead = 0;

  for (var r = 0; r < rows; r++) {
    if (lead >= cols) break;
    var i = r;
    while (m[i][lead] == 0) {
      i++;
      if (i == rows) {
        i = r;
        lead++;
        if (lead == cols) break;
      }
    }
    if (lead == cols) break;

    if (i != r) {
      final temp = m[r];
      m[r] = m[i];
      m[i] = temp;
      steps.add('Swap Row ${r + 1} with Row ${i + 1}');
    }

    final val = m[r][lead];
    if (val != 0) {
      for (var c = 0; c < cols; c++) {
        m[r][c] /= val;
      }
      final normVal = val.abs() < 1e-4 ? val.toStringAsExponential(2) : val.toStringAsFixed(4);
      steps.add('Normalize Row ${r + 1} by dividing by $normVal');
    }

    for (var j = 0; j < rows; j++) {
      if (j != r) {
        final factor = m[j][lead];
        if (factor != 0) {
          for (var c = 0; c < cols; c++) {
            m[j][c] -= factor * m[r][c];
          }
          final fStr = factor.abs() < 1e-4 ? factor.toStringAsExponential(2) : factor.toStringAsFixed(4);
          steps.add('Subtract $fStr * Row ${r + 1} from Row ${j + 1}');
        }
      }
    }
    lead++;
  }

  final finalM = m.map((row) {
    return row.map((val) => val.abs() < 1e-12 ? 0.0 : double.parse(val.toStringAsPrecision(12))).toList();
  }).toList();

  return RrefResult(rref: finalM, steps: steps);
}

/// Computes determinant using Gaussian elimination
double determinant(Matrix a) {
  validateMatrix(a);
  final n = a.length;
  if (n != a[0].length) {
    throw MatrixError('Determinant requires a square matrix');
  }

  if (n == 1) return a[0][0];
  if (n == 2) return a[0][0] * a[1][1] - a[0][1] * a[1][0];

  final m = copyMatrix(a);
  var swapCount = 0;
  var det = 1.0;

  for (var col = 0; col < n; col++) {
    var pivotRow = col;
    for (var row = col + 1; row < n; row++) {
      if (m[row][col].abs() > m[pivotRow][col].abs()) {
        pivotRow = row;
      }
    }

    if (m[pivotRow][col].abs() < 1e-15) {
      return 0.0; // Singular matrix
    }

    if (pivotRow != col) {
      final temp = m[col];
      m[col] = m[pivotRow];
      m[pivotRow] = temp;
      swapCount++;
    }

    final pivotVal = m[col][col];
    det *= pivotVal;

    for (var row = col + 1; row < n; row++) {
      final factor = m[row][col] / pivotVal;
      for (var c = col; c < n; c++) {
        m[row][c] -= factor * m[col][c];
      }
    }
  }

  return (swapCount % 2 == 1) ? -det : det;
}

/// Computes inverse of a square matrix using Gauss-Jordan [A | I]
Matrix inverse(Matrix a) {
  validateMatrix(a);
  final n = a.length;
  if (n != a[0].length) {
    throw MatrixError('Inverse requires a square matrix');
  }

  final augmented = <List<double>>[];
  final id = makeIdentity(n);
  for (var r = 0; r < n; r++) {
    augmented.add([...a[r], ...id[r]]);
  }

  final cols = n * 2;
  var lead = 0;

  for (var r = 0; r < n; r++) {
    if (lead >= cols) break;
    var i = r;
    while (augmented[i][lead] == 0) {
      i++;
      if (i == n) {
        i = r;
        lead++;
        if (lead == cols) break;
      }
    }
    if (lead == cols) break;

    if (i != r) {
      final temp = augmented[r];
      augmented[r] = augmented[i];
      augmented[i] = temp;
    }

    final val = augmented[r][lead];
    if (val.abs() < 1e-15) {
      throw MatrixError('Matrix is singular and cannot be inverted');
    }

    for (var c = 0; c < cols; c++) {
      augmented[r][c] /= val;
    }

    for (var j = 0; j < n; j++) {
      if (j != r) {
        final factor = augmented[j][lead];
        for (var c = 0; c < cols; c++) {
          augmented[j][c] -= factor * augmented[r][c];
        }
      }
    }
    lead++;
  }

  final result = <List<double>>[];
  for (var r = 0; r < n; r++) {
    result.add(augmented[r].sublist(n));
  }

  // Validate inverse
  final check = multiply(a, result);
  for (var r = 0; r < n; r++) {
    for (var j = 0; j < n; j++) {
      final expected = r == j ? 1.0 : 0.0;
      if ((check[r][j] - expected).abs() > 1e-3) {
        throw MatrixError('Matrix is singular or ill-conditioned');
      }
    }
  }

  return result.map((row) {
    return row.map((val) => val.abs() < 1e-12 ? 0.0 : double.parse(val.toStringAsPrecision(12))).toList();
  }).toList();
}

/// Approximates eigenvalues of a matrix using QR algorithm
List<double> eigenvalues(Matrix a, [int maxIterations = 100]) {
  validateMatrix(a);
  final n = a.length;
  if (n != a[0].length) {
    throw MatrixError('Eigenvalues require a square matrix');
  }

  var ak = copyMatrix(a);

  for (var iter = 0; iter < maxIterations; iter++) {
    final qr = _qrDecomposition(ak);
    ak = multiply(qr.r, qr.q);

    var offDiagSum = 0.0;
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (r != c) offDiagSum += ak[r][c].abs();
      }
    }
    if (offDiagSum < 1e-10) break;
  }

  final evals = <double>[];
  for (var i = 0; i < n; i++) {
    evals.add(double.parse(ak[i][i].toStringAsFixed(8)));
  }
  evals.sort((a, b) => b.compareTo(a));
  return evals;
}

class _QRResult {
  final Matrix q;
  final Matrix r;
  _QRResult({required this.q, required this.r});
}

_QRResult _qrDecomposition(Matrix a) {
  final n = a.length;
  final q = List.generate(n, (_) => List.filled(n, 0.0));
  final r = List.generate(n, (_) => List.filled(n, 0.0));

  for (var j = 0; j < n; j++) {
    final v = List<double>.generate(n, (i) => a[i][j]);

    for (var i = 0; i < j; i++) {
      var dot = 0.0;
      for (var k = 0; k < n; k++) {
        dot += q[k][i] * a[k][j];
      }
      r[i][j] = dot;

      for (var k = 0; k < n; k++) {
        v[k] -= dot * q[k][i];
      }
    }

    var normSq = 0.0;
    for (var k = 0; k < n; k++) {
      normSq += v[k] * v[k];
    }
    final norm = math.sqrt(normSq);
    r[j][j] = norm;

    if (norm > 1e-15) {
      for (var k = 0; k < n; k++) {
        q[k][j] = v[k] / norm;
      }
    } else {
      for (var k = 0; k < n; k++) {
        q[k][j] = 0.0;
      }
    }
  }

  return _QRResult(q: q, r: r);
}
