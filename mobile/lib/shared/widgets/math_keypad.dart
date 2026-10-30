/// Custom Mobile Mathematical Keypad for Scientific & CAS Workstations
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

enum KeypadCategory { basic, functions, calculus }

class MathKeypad extends StatefulWidget {
  final ValueChanged<String> onKeyPress;
  final VoidCallback onClear;
  final VoidCallback onDelete;
  final VoidCallback onEvaluate;

  const MathKeypad({
    super.key,
    required this.onKeyPress,
    required this.onClear,
    required this.onDelete,
    required this.onEvaluate,
  });

  @override
  State<MathKeypad> createState() => _MathKeypadState();
}

class _MathKeypadState extends State<MathKeypad> {
  KeypadCategory _category = KeypadCategory.basic;

  void _tap(String val) {
    HapticFeedback.lightImpact();
    widget.onKeyPress(val);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mode Category Switcher
          Container(
            height: 32,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                _buildCategoryTab('123 Basic', KeypadCategory.basic),
                _buildCategoryTab('f(x) Trig/Log', KeypadCategory.functions),
                _buildCategoryTab('d/dx Calc', KeypadCategory.calculus),
              ],
            ),
          ),

          // Keypad Grids based on category
          if (_category == KeypadCategory.basic) _buildBasicKeypad(),
          if (_category == KeypadCategory.functions) _buildFunctionsKeypad(),
          if (_category == KeypadCategory.calculus) _buildCalculusKeypad(),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(String title, KeypadCategory cat) {
    final isSelected = _category == cat;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _category = cat);
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicKeypad() {
    return Column(
      children: [
        _row([
          _btn('(', color: AppColors.card),
          _btn(')', color: AppColors.card),
          _btn('^', color: AppColors.card),
          _btn('√', val: 'sqrt(', color: AppColors.card),
          _actionBtn('DEL', widget.onDelete, color: const Color(0xFF374151)),
          _actionBtn('AC', widget.onClear, color: AppColors.error),
        ]),
        const SizedBox(height: 5),
        _row([
          _btn('x', color: AppColors.card),
          _btn('7'),
          _btn('8'),
          _btn('9'),
          _btn('/', color: AppColors.card),
          _btn('π', val: 'pi', color: AppColors.card),
        ]),
        const SizedBox(height: 5),
        _row([
          _btn('y', color: AppColors.card),
          _btn('4'),
          _btn('5'),
          _btn('6'),
          _btn('*', color: AppColors.card),
          _btn('e', color: AppColors.card),
        ]),
        const SizedBox(height: 5),
        _row([
          _btn('sin(', color: AppColors.card),
          _btn('1'),
          _btn('2'),
          _btn('3'),
          _btn('-', color: AppColors.card),
          _btn('cos(', color: AppColors.card),
        ]),
        const SizedBox(height: 5),
        _row([
          _btn('0'),
          _btn('.'),
          _btn(',', color: AppColors.card),
          _btn('+', color: AppColors.card),
          _actionBtn('=', widget.onEvaluate, color: AppColors.primary, flex: 2),
        ]),
      ],
    );
  }

  Widget _buildFunctionsKeypad() {
    return Column(
      children: [
        _row([
          _btn('sin', val: 'sin(', color: AppColors.card),
          _btn('cos', val: 'cos(', color: AppColors.card),
          _btn('tan', val: 'tan(', color: AppColors.card),
          _btn('ln', val: 'ln(', color: AppColors.card),
          _actionBtn('DEL', widget.onDelete, color: const Color(0xFF374151)),
          _actionBtn('AC', widget.onClear, color: AppColors.error),
        ]),
        const SizedBox(height: 5),
        _row([
          _btn('asin', val: 'asin(', color: AppColors.card),
          _btn('acos', val: 'acos(', color: AppColors.card),
          _btn('atan', val: 'atan(', color: AppColors.card),
          _btn('log', val: 'log(', color: AppColors.card),
          _btn('exp', val: 'exp(', color: AppColors.card),
          _btn('^', color: AppColors.card),
        ]),
        const SizedBox(height: 5),
        _row([
          _btn('sinh', val: 'sinh(', color: AppColors.card),
          _btn('cosh', val: 'cosh(', color: AppColors.card),
          _btn('tanh', val: 'tanh(', color: AppColors.card),
          _btn('abs', val: 'abs(', color: AppColors.card),
          _btn('sqrt', val: 'sqrt(', color: AppColors.card),
          _btn('pi', color: AppColors.card),
        ]),
        const SizedBox(height: 5),
        _row([
          _btn('(', color: AppColors.card),
          _btn(')', color: AppColors.card),
          _btn(',', color: AppColors.card),
          _btn('e', color: AppColors.card),
          _btn('/', color: AppColors.card),
          _btn('*', color: AppColors.card),
        ]),
        const SizedBox(height: 5),
        _row([
          _btn('x', color: AppColors.card),
          _btn('y', color: AppColors.card),
          _btn('-', color: AppColors.card),
          _btn('+', color: AppColors.card),
          _actionBtn('=', widget.onEvaluate, color: AppColors.primary, flex: 2),
        ]),
      ],
    );
  }

  Widget _buildCalculusKeypad() {
    return Column(
      children: [
        _row([
          _btn('d/dx', val: 'diff(', color: AppColors.card),
          _btn('∫', val: 'integrate(', color: AppColors.card),
          _btn('lim', val: 'limit(', color: AppColors.card),
          _btn('x', color: AppColors.card),
          _actionBtn('DEL', widget.onDelete, color: const Color(0xFF374151)),
          _actionBtn('AC', widget.onClear, color: AppColors.error),
        ]),
        const SizedBox(height: 5),
        _row([
          _btn('x^2', val: 'x^2', color: AppColors.card),
          _btn('x^3', val: 'x^3', color: AppColors.card),
          _btn('exp', val: 'exp(', color: AppColors.card),
          _btn('ln', val: 'ln(', color: AppColors.card),
          _btn('1/x', val: '1/x', color: AppColors.card),
          _btn('√', val: 'sqrt(', color: AppColors.card),
        ]),
        const SizedBox(height: 5),
        _row([
          _btn('sin', val: 'sin(', color: AppColors.card),
          _btn('cos', val: 'cos(', color: AppColors.card),
          _btn('tan', val: 'tan(', color: AppColors.card),
          _btn('^', color: AppColors.card),
          _btn('/', color: AppColors.card),
          _btn('*', color: AppColors.card),
        ]),
        const SizedBox(height: 5),
        _row([
          _btn('(', color: AppColors.card),
          _btn(')', color: AppColors.card),
          _btn(',', color: AppColors.card),
          _btn('y', color: AppColors.card),
          _btn('-', color: AppColors.card),
          _btn('+', color: AppColors.card),
        ]),
        const SizedBox(height: 5),
        _row([
          _btn('0'),
          _btn('1'),
          _btn('2'),
          _btn('.'),
          _actionBtn('=', widget.onEvaluate, color: AppColors.primary, flex: 2),
        ]),
      ],
    );
  }

  Widget _row(List<Widget> children) {
    return Row(
      children: children
          .map((c) => Expanded(
                flex: (c is _FlexWidget) ? c.flex : 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: c,
                ),
              ))
          .toList(),
    );
  }

  Widget _btn(String label, {String? val, Color? color}) {
    return Material(
      color: color ?? AppColors.background,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _tap(val ?? label),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderSubtle, width: 0.8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(
    String label,
    VoidCallback onTap, {
    required Color color,
    int flex = 1,
  }) {
    return _FlexWidget(
      flex: flex,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlexWidget extends StatelessWidget {
  final int flex;
  final Widget child;
  const _FlexWidget({required this.flex, required this.child});

  @override
  Widget build(BuildContext context) => child;
}
