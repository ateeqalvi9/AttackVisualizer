/// Abstract Syntax Tree (AST) Hierarchy for CAS Engine
library;

sealed class ASTNode {
  const ASTNode();
}

class NumberNode extends ASTNode {
  final double value;
  const NumberNode(this.value);

  @override
  String toString() => 'NumberNode($value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NumberNode && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

class VariableNode extends ASTNode {
  final String name;
  const VariableNode(this.name);

  @override
  String toString() => 'VariableNode($name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VariableNode && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class ConstantNode extends ASTNode {
  final String name;
  final double value;
  const ConstantNode(this.name, this.value);

  @override
  String toString() => 'ConstantNode($name, $value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConstantNode &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          value == other.value;

  @override
  int get hashCode => Object.hash(name, value);
}

class BinaryOpNode extends ASTNode {
  final String operator; // '+', '-', '*', '/', '^'
  final ASTNode left;
  final ASTNode right;

  const BinaryOpNode({
    required this.operator,
    required this.left,
    required this.right,
  });

  @override
  String toString() => 'BinaryOpNode("$operator", $left, $right)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BinaryOpNode &&
          runtimeType == other.runtimeType &&
          operator == other.operator &&
          left == other.left &&
          right == other.right;

  @override
  int get hashCode => Object.hash(operator, left, right);
}

class UnaryOpNode extends ASTNode {
  final String operator; // '+', '-'
  final ASTNode operand;

  const UnaryOpNode({
    required this.operator,
    required this.operand,
  });

  @override
  String toString() => 'UnaryOpNode("$operator", $operand)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnaryOpNode &&
          runtimeType == other.runtimeType &&
          operator == other.operator &&
          operand == other.operand;

  @override
  int get hashCode => Object.hash(operator, operand);
}

class FunctionNode extends ASTNode {
  final String name; // 'sin', 'cos', 'diff', 'integrate', etc.
  final List<ASTNode> arguments;

  FunctionNode({
    required this.name,
    List<ASTNode>? arguments,
    ASTNode? argument,
  }) : arguments = arguments ?? (argument != null ? [argument] : const []);

  /// Convenience getter for single-argument functions
  ASTNode get argument =>
      arguments.isNotEmpty ? arguments.first : const NumberNode(0);

  @override
  String toString() => 'FunctionNode("$name", $arguments)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FunctionNode || runtimeType != other.runtimeType) return false;
    if (name != other.name || arguments.length != other.arguments.length) return false;
    for (var i = 0; i < arguments.length; i++) {
      if (arguments[i] != other.arguments[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(name, Object.hashAll(arguments));
}
