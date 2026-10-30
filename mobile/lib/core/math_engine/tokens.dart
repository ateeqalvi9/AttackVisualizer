/// Mathematical Expression Tokens & Tokenizer for CAS Engine
library;

enum TokenType {
  number,
  identifier,
  plus,
  minus,
  multiply,
  divide,
  power,
  lparen,
  rparen,
  comma,
  eof,
}

class Token {
  final TokenType type;
  final String value;
  final int position;

  const Token({
    required this.type,
    required this.value,
    required this.position,
  });

  @override
  String toString() => 'Token($type, "$value", pos: $position)';
}

class ParserError implements Exception {
  final String message;
  final int? position;

  ParserError(this.message, [this.position]);

  @override
  String toString() =>
      position != null ? '$message at position $position' : message;
}

const Set<String> mathFunctions = {
  'sin',
  'cos',
  'tan',
  'asin',
  'acos',
  'atan',
  'sinh',
  'cosh',
  'tanh',
  'log',
  'ln',
  'sqrt',
  'abs',
  'exp',
  // Calculus & CAS functions
  'diff',
  'd',
  'derivative',
  'integrate',
  'integral',
  'limit',
  'lim',
};

const Map<String, double> mathConstants = {
  'pi': 3.141592653589793,
  'PI': 3.141592653589793,
  'e': 2.718281828459045,
  'E': 2.718281828459045,
};

/// Tokenizes a raw mathematical string.
/// Automatically balances missing closing parentheses at EOF (e.g. sin(30 -> sin(30))
List<Token> tokenize(String expression) {
  final tokens = <Token>[];
  var i = 0;
  final len = expression.length;
  var openParenCount = 0;

  while (i < len) {
    final char = expression[i];

    if (char == ' ' || char == '\t' || char == '\n' || char == '\r') {
      i++;
      continue;
    }

    // Check for d/dx operator prefix
    if (expression.startsWith('d/dx', i)) {
      tokens.add(Token(type: TokenType.identifier, value: 'diff', position: i));
      i += 4;
      continue;
    }

    // Check for integral symbol ∫
    if (char == '∫') {
      tokens.add(Token(type: TokenType.identifier, value: 'integrate', position: i));
      i++;
      continue;
    }

    if (char == '+') {
      tokens.add(Token(type: TokenType.plus, value: '+', position: i));
      i++;
    } else if (char == '-') {
      tokens.add(Token(type: TokenType.minus, value: '-', position: i));
      i++;
    } else if (char == '*') {
      tokens.add(Token(type: TokenType.multiply, value: '*', position: i));
      i++;
    } else if (char == '/') {
      tokens.add(Token(type: TokenType.divide, value: '/', position: i));
      i++;
    } else if (char == '^') {
      tokens.add(Token(type: TokenType.power, value: '^', position: i));
      i++;
    } else if (char == '(') {
      openParenCount++;
      tokens.add(Token(type: TokenType.lparen, value: '(', position: i));
      i++;
    } else if (char == ')') {
      if (openParenCount > 0) openParenCount--;
      tokens.add(Token(type: TokenType.rparen, value: ')', position: i));
      i++;
    } else if (char == ',') {
      tokens.add(Token(type: TokenType.comma, value: ',', position: i));
      i++;
    } else if (_isDigitOrDot(char)) {
      final start = i;
      final buffer = StringBuffer();
      while (i < len && _isDigitOrDot(expression[i])) {
        buffer.write(expression[i]);
        i++;
      }
      final numStr = buffer.toString();
      if ('.'.allMatches(numStr).length > 1) {
        throw ParserError('Invalid number representation: $numStr', start);
      }
      tokens.add(Token(type: TokenType.number, value: numStr, position: start));
    } else if (_isAlphaOrUnderscore(char)) {
      final start = i;
      final buffer = StringBuffer();
      while (i < len && _isAlphaNumOrUnderscore(expression[i])) {
        buffer.write(expression[i]);
        i++;
      }
      tokens.add(Token(
        type: TokenType.identifier,
        value: buffer.toString(),
        position: start,
      ));
    } else {
      throw ParserError('Unexpected character: "$char"', i);
    }
  }

  // Auto-close any unclosed parentheses before EOF (calculator behavior)
  while (openParenCount > 0) {
    tokens.add(Token(type: TokenType.rparen, value: ')', position: i));
    openParenCount--;
  }

  tokens.add(Token(type: TokenType.eof, value: '', position: i));
  return tokens;
}

bool _isDigitOrDot(String char) {
  final code = char.codeUnitAt(0);
  return (code >= 48 && code <= 57) || code == 46; // 0-9 or .
}

bool _isAlphaOrUnderscore(String char) {
  final code = char.codeUnitAt(0);
  return (code >= 65 && code <= 90) || // A-Z
      (code >= 97 && code <= 122) || // a-z
      code == 95; // _
}

bool _isAlphaNumOrUnderscore(String char) {
  return _isAlphaOrUnderscore(char) || _isDigitOrDot(char);
}

/// Pre-processes token stream to inject implicit multiplication.
/// e.g. 2x -> 2 * x, 2(x+1) -> 2 * (x+1), (x+1)(x+2) -> (x+1) * (x+2), x sin(x) -> x * sin(x)
List<Token> injectImplicitMultiplication(List<Token> tokens) {
  if (tokens.length <= 1) return tokens;

  final result = <Token>[];

  for (var i = 0; i < tokens.length; i++) {
    final current = tokens[i];
    result.add(current);

    if (i + 1 < tokens.length) {
      final next = tokens[i + 1];

      final currentIsNum = current.type == TokenType.number;
      final currentIsParenClose = current.type == TokenType.rparen;
      final currentIsId = current.type == TokenType.identifier;

      final nextIsNum = next.type == TokenType.number;
      final nextIsId = next.type == TokenType.identifier;
      final nextIsParenOpen = next.type == TokenType.lparen;

      var shouldInsert = false;

      if (currentIsNum && (nextIsId || nextIsParenOpen)) {
        shouldInsert = true;
      } else if (currentIsParenClose &&
          (nextIsParenOpen || nextIsId || nextIsNum)) {
        shouldInsert = true;
      } else if (currentIsId && !mathFunctions.contains(current.value.toLowerCase())) {
        if (nextIsParenOpen || nextIsId || nextIsNum) {
          shouldInsert = true;
        }
      }

      if (shouldInsert) {
        result.add(Token(
          type: TokenType.multiply,
          value: '*',
          position: current.position + current.value.length,
        ));
      }
    }
  }

  return result;
}
