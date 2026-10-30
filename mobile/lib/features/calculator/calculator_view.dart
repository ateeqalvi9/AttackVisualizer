/// Scientific Calculator View with Memory Registers and Step Inspections
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/math_engine/calculator.dart';
import '../../core/math_engine/evaluator.dart';
import '../../core/storage/history_repository.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/math_keypad.dart';

class CalculatorView extends StatefulWidget {
  final String? initialExpression;
  final VoidCallback? onHistoryUpdated;

  const CalculatorView({
    super.key,
    this.initialExpression,
    this.onHistoryUpdated,
  });

  @override
  State<CalculatorView> createState() => CalculatorViewState();
}

class CalculatorViewState extends State<CalculatorView> {
  String _expression = '';
  String _result = '';
  String? _fractionResult;
  String? _decimalResult;
  bool _showFraction = true;
  double _numericResult = 0.0;
  List<String> _steps = [];
  String _error = '';
  AngleMode _angleMode = AngleMode.degrees;
  double _memory = 0.0;
  final Map<String, double> _variables = {'x': 2.0, 'y': 3.0};
  bool _showVariables = false;

  final TextEditingController _varXController = TextEditingController(text: '2');
  final TextEditingController _varYController = TextEditingController(text: '3');

  @override
  void initState() {
    super.initState();
    if (widget.initialExpression != null && widget.initialExpression!.isNotEmpty) {
      _expression = widget.initialExpression!;
      _evaluate();
    }
  }

  void loadExpression(String expr) {
    setState(() {
      _expression = expr;
      _error = '';
      _result = '';
      _fractionResult = null;
      _decimalResult = null;
      _steps = [];
    });
    _evaluate();
  }

  void _onKeyPress(String val) {
    setState(() {
      _error = '';
      _expression += val;
    });
  }

  void _onClear() {
    setState(() {
      _expression = '';
      _result = '';
      _fractionResult = null;
      _decimalResult = null;
      _steps = [];
      _error = '';
    });
  }

  void _onDelete() {
    if (_expression.isNotEmpty) {
      setState(() {
        _expression = _expression.substring(0, _expression.length - 1);
        _error = '';
      });
    }
  }

  void _toggleFractionDecimal() {
    if (_fractionResult == null || _decimalResult == null) return;
    if (_fractionResult == _decimalResult) return;
    HapticFeedback.selectionClick();
    setState(() {
      _showFraction = !_showFraction;
      _result = _showFraction ? _fractionResult! : _decimalResult!;
    });
  }

  void _evaluate() {
    if (_expression.trim().isEmpty) return;

    try {
      final eval = evaluateScientific(
        _expression,
        variables: _variables,
        angleMode: _angleMode,
      );

      _numericResult = eval.result;
      _fractionResult = eval.fraction;
      _decimalResult = eval.decimal;

      // Select active display string based on fraction toggle preference
      final displayRes = (_showFraction && _fractionResult != null && _fractionResult!.isNotEmpty)
          ? _fractionResult!
          : (_decimalResult ?? eval.display);

      setState(() {
        _result = displayRes;
        _steps = eval.steps;
        _error = '';
      });

      HistoryRepository.insertHistory(
        type: 'calculator',
        expression: _expression,
        result: displayRes,
        variables: _variables,
      ).then((_) {
        widget.onHistoryUpdated?.call();
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _result = '';
        _fractionResult = null;
        _decimalResult = null;
        _steps = [];
      });
    }
  }

  void _handleMemory(String op) {
    HapticFeedback.lightImpact();
    final numVal = _numericResult != 0.0
        ? _numericResult
        : (double.tryParse(_result) ?? double.tryParse(_expression));

    setState(() {
      _error = '';
      switch (op) {
        case 'MC':
          _memory = 0.0;
          break;
        case 'MR':
          _expression += _memory % 1 == 0 ? _memory.toInt().toString() : _memory.toString();
          break;
        case 'M+':
          if (numVal != null) {
            _memory += numVal;
          } else {
            _error = 'No valid numeric display to add to memory';
          }
          break;
        case 'M-':
          if (numVal != null) {
            _memory -= numVal;
          } else {
            _error = 'No valid numeric display to subtract from memory';
          }
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Toolbar: Angle Mode & Memory Buttons & Variables toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: AppColors.background,
          child: Row(
            children: [
              // Angle Mode Switch
              GestureDetector(
                onTap: () {
                  setState(() {
                    _angleMode = _angleMode == AngleMode.radians
                        ? AngleMode.degrees
                        : AngleMode.radians;
                  });
                  if (_expression.isNotEmpty) _evaluate();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Text(
                    _angleMode == AngleMode.radians ? 'RAD' : 'DEG',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Memory Registers
              _memBtn('MC'),
              _memBtn('MR'),
              _memBtn('M+'),
              _memBtn('M-'),

              const Spacer(),

              // Variables Toggle
              IconButton(
                icon: Icon(
                  Icons.tune,
                  size: 18,
                  color: _showVariables ? AppColors.primary : AppColors.textSecondary,
                ),
                tooltip: 'Variable Scope',
                onPressed: () {
                  setState(() => _showVariables = !_showVariables);
                },
              ),
            ],
          ),
        ),

        // Variable Scope Drawer
        if (_showVariables) _buildVariablesPanel(),

        // Formula & Result Display Area
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.background,
            child: SingleChildScrollView(
              reverse: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Expression Text (Horizontally scrollable to eliminate overflow)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: SelectableText(
                      _expression.isEmpty ? '0' : _expression,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w400,
                        color: _expression.isEmpty
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Result Display (Horizontally scrollable with fraction toggle)
                  if (_result.isNotEmpty) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_fractionResult != null &&
                              _decimalResult != null &&
                              _fractionResult != _decimalResult) ...[
                            GestureDetector(
                              onTap: _toggleFractionDecimal,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.5)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.swap_horiz,
                                        size: 14, color: AppColors.primary),
                                    SizedBox(width: 4),
                                    Text(
                                      'F ↔ D',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          IconButton(
                            icon: const Icon(Icons.copy,
                                size: 16, color: AppColors.textMuted),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _result));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Result copied to clipboard'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                          SelectableText(
                            '= $_result',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_fractionResult != null &&
                        _decimalResult != null &&
                        _fractionResult != _decimalResult) ...[
                      const SizedBox(height: 2),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Text(
                          _showFraction
                              ? '≈ ${_decimalResult!}'
                              : 'exact = ${_fractionResult!}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ],

                  // Error Banner
                  if (_error.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 14, color: AppColors.error),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _error,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.error,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Step Breakdown Expansion
                  if (_steps.isNotEmpty)
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text(
                        'Evaluation Steps',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      children: _steps
                          .map(
                            (s) => Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                '• $s',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Custom Mathematical Keypad
        MathKeypad(
          onKeyPress: _onKeyPress,
          onClear: _onClear,
          onDelete: _onDelete,
          onEvaluate: _evaluate,
        ),
      ],
    );
  }

  Widget _memBtn(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => _handleMemory(label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVariablesPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      child: Row(
        children: [
          const Text(
            'Variables: ',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                const Text('x = ', style: TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                SizedBox(
                  width: 50,
                  height: 28,
                  child: TextField(
                    controller: _varXController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      fillColor: AppColors.background,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    onChanged: (v) {
                      final parsed = double.tryParse(v);
                      if (parsed != null) _variables['x'] = parsed;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                const Text('y = ', style: TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                SizedBox(
                  width: 50,
                  height: 28,
                  child: TextField(
                    controller: _varYController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      fillColor: AppColors.background,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    onChanged: (v) {
                      final parsed = double.tryParse(v);
                      if (parsed != null) _variables['y'] = parsed;
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
