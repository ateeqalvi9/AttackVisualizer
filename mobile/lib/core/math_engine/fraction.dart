/// Rational Fraction & Radical Form Engine for CAS Outputs
library;

import 'dart:math' as math;

class Fraction {
  final int numerator;
  final int denominator;

  const Fraction(this.numerator, this.denominator);

  @override
  String toString() {
    if (denominator == 1) return '$numerator';
    return '$numerator/$denominator';
  }

  /// Mixed fraction string, e.g. 7/2 -> "3 1/2"
  String toMixedString() {
    if (denominator == 1) return '$numerator';
    final whole = numerator ~/ denominator;
    final rem = (numerator % denominator).abs();
    if (whole == 0) return '$numerator/$denominator';
    return '$whole $rem/$denominator';
  }

  /// Greatest common divisor
  static int _gcd(int a, int b) {
    var x = a.abs();
    var y = b.abs();
    while (y != 0) {
      final t = y;
      y = x % y;
      x = t;
    }
    return x;
  }

  /// Converts a decimal number to its exact or best rational fraction
  /// using the Continued Fractions algorithm.
  static Fraction? fromDouble(
    double value, {
    double tolerance = 1e-9,
    int maxDenominator = 100000,
  }) {
    if (value.isNaN || value.isInfinite) return null;
    if (value.abs() > 1e12) return null;

    final sign = value < 0 ? -1 : 1;
    var x = value.abs();

    // Check if effectively an integer
    if ((x - x.round()).abs() <= tolerance) {
      return Fraction(sign * x.round(), 1);
    }

    var m00 = 1, m01 = 0;
    var m10 = 0, m11 = 1;

    for (var iter = 0; iter < 40; iter++) {
      final a = x.floor();
      final t10 = m00 * a + m10;
      final t11 = m01 * a + m11;

      if (t11 > maxDenominator) break;

      m10 = m00;
      m11 = m01;
      m00 = t10;
      m01 = t11;

      final diff = (value.abs() - (m00 / m01)).abs();
      if (diff <= tolerance) {
        final g = _gcd(m00, m01);
        return Fraction(sign * (m00 ~/ g), m01 ~/ g);
      }

      final frac = x - a;
      if (frac < 1e-14) break;
      x = 1.0 / frac;
    }

    if (m01 > 1 && m01 <= maxDenominator) {
      final diff = (value.abs() - (m00 / m01)).abs();
      if (diff <= 1e-5) {
        final g = _gcd(m00, m01);
        return Fraction(sign * (m00 ~/ g), m01 ~/ g);
      }
    }

    return null;
  }

  /// Detects exact algebraic radical forms for common trigonometric values:
  /// e.g. 0.8660254038 -> "√3/2"
  ///      0.7071067812 -> "√2/2"
  ///      0.5773502692 -> "√3/3"
  ///      1.7320508076 -> "√3"
  static String? detectRadical(double value, {double tolerance = 1e-6}) {
    if (value.isNaN || value.isInfinite) return null;
    final signStr = value < 0 ? '-' : '';
    final absVal = value.abs();

    final testValues = [
      (math.sqrt(2) / 2.0, '√2/2'),
      (math.sqrt(3) / 2.0, '√3/2'),
      (math.sqrt(3) / 3.0, '√3/3'),
      (math.sqrt(2), '√2'),
      (math.sqrt(3), '√3'),
      (math.sqrt(5), '√5'),
      (1.0 / math.sqrt(2), '√2/2'),
      (2.0 * math.sqrt(3) / 3.0, '2√3/3'),
      (math.pi, 'π'),
      (math.pi / 2.0, 'π/2'),
      (math.pi / 3.0, 'π/3'),
      (math.pi / 4.0, 'π/4'),
      (math.pi / 6.0, 'π/6'),
      (2.0 * math.pi, '2π'),
      (math.e, 'e'),
    ];

    for (final (v, str) in testValues) {
      if ((absVal - v).abs() <= tolerance) {
        return '$signStr$str';
      }
    }

    return null;
  }

  /// Formats a double into the cleanest mathematical representation:
  /// returns a record with { String display, String? fraction, String? decimal }
  static FormattedResult format(double value) {
    if (value.isNaN) return FormattedResult(display: 'NaN', decimal: 'NaN');
    if (value.isInfinite) {
      return FormattedResult(
        display: value > 0 ? '∞' : '-∞',
        decimal: value > 0 ? '∞' : '-∞',
      );
    }

    // Exact integer
    if (value % 1 == 0 && value.abs() < 1e14) {
      final intStr = value.toInt().toString();
      return FormattedResult(display: intStr, decimal: intStr);
    }

    final radical = detectRadical(value);
    final frac = fromDouble(value);
    final decStr = value.abs() < 1e-12 ? '0' : value.toStringAsPrecision(10);
    final cleanedDec = double.parse(decStr).toString();

    if (radical != null) {
      return FormattedResult(
        display: radical,
        fraction: radical,
        decimal: cleanedDec,
      );
    }

    if (frac != null && frac.denominator > 1) {
      return FormattedResult(
        display: frac.toString(),
        fraction: frac.toString(),
        decimal: cleanedDec,
      );
    }

    return FormattedResult(
      display: cleanedDec,
      decimal: cleanedDec,
    );
  }
}

class FormattedResult {
  final String display;
  final String? fraction;
  final String? decimal;

  const FormattedResult({
    required this.display,
    this.fraction,
    this.decimal,
  });
}
