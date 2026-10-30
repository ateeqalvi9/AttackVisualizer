/// Recursive-Descent AST Parser for Mathematical Expressions
library;

import 'ast.dart';
import 'tokens.dart';

class ASTParser {
  final List<Token> tokens;
  int _currentIdx = 0;

  ASTParser(String expression)
      : tokens = injectImplicitMultiplication(tokenize(expression));

  Token _current() {
    return tokens[_currentIdx];
  }

  bool _match(TokenType type) {
    if (_current().type == type) {
      _currentIdx++;
      return true;
    }
    return false;
  }

  Token _expect(TokenType type, String errMsg) {
    final token = _current();
    if (token.type != type) {
      throw ParserError(
        '$errMsg (found: ${token.type} "${token.value}")',
        token.position,
      );
    }
    _currentIdx++;
    return token;
  }

  /// Parse Entry Point
  ASTNode parse() {
    final node = _parseExpression();
    _expect(TokenType.eof, 'Unexpected trailing tokens');
    return node;
  }

  /// Expression -> Term ( ('+' | '-') Term )*
  ASTNode _parseExpression() {
    var node = _parseTerm();

    while (true) {
      if (_match(TokenType.plus)) {
        final right = _parseTerm();
        node = BinaryOpNode(operator: '+', left: node, right: right);
      } else if (_match(TokenType.minus)) {
        final right = _parseTerm();
        node = BinaryOpNode(operator: '-', left: node, right: right);
      } else {
        break;
      }
    }

    return node;
  }

  /// Term -> Factor ( ('*' | '/') Factor )*
  ASTNode _parseTerm() {
    var node = _parseFactor();

    while (true) {
      if (_match(TokenType.multiply)) {
        final right = _parseFactor();
        node = BinaryOpNode(operator: '*', left: node, right: right);
      } else if (_match(TokenType.divide)) {
        final right = _parseFactor();
        node = BinaryOpNode(operator: '/', left: node, right: right);
      } else {
        break;
      }
    }

    return node;
  }

  /// Factor -> UnaryOp | Power
  ASTNode _parseFactor() {
    if (_match(TokenType.plus)) {
      return UnaryOpNode(operator: '+', operand: _parseFactor());
    }
    if (_match(TokenType.minus)) {
      return UnaryOpNode(operator: '-', operand: _parseFactor());
    }
    return _parsePower();
  }

  /// Power -> Primary ( '^' Factor )? (Right-associative)
  ASTNode _parsePower() {
    final node = _parsePrimary();

    if (_match(TokenType.power)) {
      final right = _parseFactor(); // Recurse to preserve right-associativity
      return BinaryOpNode(operator: '^', left: node, right: right);
    }

    return node;
  }

  /// Primary -> Number | Constant | Variable | Function | '(' Expression ')'
  ASTNode _parsePrimary() {
    final token = _current();

    if (_match(TokenType.number)) {
      final val = double.tryParse(token.value);
      if (val == null) {
        throw ParserError('Invalid numeric value: ${token.value}', token.position);
      }
      return NumberNode(val);
    }

    if (_match(TokenType.identifier)) {
      final name = token.value;

      // Check if known constant (pi, e)
      if (mathConstants.containsKey(name)) {
        return ConstantNode(name, mathConstants[name]!);
      }

      // Check if known function (sin, cos, diff, integrate, limit, etc.)
      if (mathFunctions.contains(name.toLowerCase())) {
        _expect(TokenType.lparen, 'Expected "(" after function name $name');
        final args = <ASTNode>[];
        if (!_match(TokenType.rparen) && _current().type != TokenType.eof) {
          args.add(_parseExpression());
          while (_match(TokenType.comma)) {
            args.add(_parseExpression());
          }
          if (_current().type == TokenType.rparen) {
            _match(TokenType.rparen);
          } else if (_current().type != TokenType.eof) {
            _expect(TokenType.rparen, 'Expected ")" after arguments for $name');
          }
        }
        return FunctionNode(name: name, arguments: args);
      }

      // Otherwise, it's a variable
      return VariableNode(name);
    }

    if (_match(TokenType.lparen)) {
      final node = _parseExpression();
      if (_current().type == TokenType.rparen) {
        _match(TokenType.rparen);
      } else if (_current().type != TokenType.eof) {
        _expect(TokenType.rparen, 'Expected matching closing parenthesis ")"');
      }
      return node;
    }

    throw ParserError('Unexpected token "${token.value}"', token.position);
  }
}

/// Parses an expression string into an ASTNode.
ASTNode parseExpression(String expression) {
  final clean = expression.trim();
  if (clean.isEmpty) {
    throw ParserError('Empty mathematical expression');
  }
  final parser = ASTParser(clean);
  return parser.parse();
}
