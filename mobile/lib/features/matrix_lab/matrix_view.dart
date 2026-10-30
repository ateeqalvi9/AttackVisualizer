/// Matrix Computations Lab with Step-by-Step RREF and QR Eigenvalues
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/math_engine/matrix.dart';
import '../../core/storage/history_repository.dart';
import '../../shared/theme/app_colors.dart';

class MatrixView extends StatefulWidget {
  final VoidCallback? onHistoryUpdated;

  const MatrixView({super.key, this.onHistoryUpdated});

  @override
  State<MatrixView> createState() => _MatrixViewState();
}

class _MatrixViewState extends State<MatrixView> {
  int _rowsA = 3;
  int _colsA = 3;
  int _rowsB = 3;
  int _colsB = 3;

  late List<List<TextEditingController>> _ctrlA;
  late List<List<TextEditingController>> _ctrlB;

  final TextEditingController _scalarController = TextEditingController(text: '2');
  String _activeMatrix = 'A';

  dynamic _result;
  List<String> _steps = [];
  String _error = '';
  String _lastOp = '';

  @override
  void initState() {
    super.initState();
    _initGrids();
  }

  void _initGrids() {
    _ctrlA = List.generate(
      4,
      (r) => List.generate(
        4,
        (c) => TextEditingController(
          text: r < 3 && c < 3
              ? (r == 0
                  ? [1, 2, 3][c].toString()
                  : r == 1
                      ? [-1, 0, 1][c].toString()
                      : [1, 1, 2][c].toString())
              : '0',
        ),
      ),
    );

    _ctrlB = List.generate(
      4,
      (r) => List.generate(
        4,
        (c) => TextEditingController(
          text: r < 3 && c < 3
              ? (r == 0
                  ? [2, 0, -1][c].toString()
                  : r == 1
                      ? [1, 1, 1][c].toString()
                      : [-1, 2, 0][c].toString())
              : '0',
        ),
      ),
    );
  }

  Matrix _extractMatrix(String which) {
    final rows = which == 'A' ? _rowsA : _rowsB;
    final cols = which == 'A' ? _colsA : _colsB;
    final ctrl = which == 'A' ? _ctrlA : _ctrlB;

    return List.generate(rows, (r) {
      return List.generate(cols, (c) {
        return double.tryParse(ctrl[r][c].text.trim()) ?? 0.0;
      });
    });
  }

  void _compute(String op) {
    HapticFeedback.lightImpact();
    setState(() {
      _error = '';
      _result = null;
      _steps = [];
      _lastOp = op;
    });

    try {
      final matA = _extractMatrix('A');
      final matB = _extractMatrix('B');
      final target = _activeMatrix == 'A' ? matA : matB;
      final scalarVal = double.tryParse(_scalarController.text) ?? 2.0;

      dynamic computed;
      var stepList = <String>[];

      switch (op) {
        case 'add':
          computed = add(matA, matB);
          stepList.add('Performed element-wise addition A + B');
          break;
        case 'subtract':
          computed = subtract(matA, matB);
          stepList.add('Performed element-wise subtraction A - B');
          break;
        case 'multiply':
          computed = multiply(matA, matB);
          stepList.add('Multiplied Matrix A ($_rowsA x $_colsA) by Matrix B ($_rowsB x $_colsB)');
          break;
        case 'scale':
          computed = scale(target, scalarVal);
          stepList.add('Multiplied Matrix $_activeMatrix by scalar factor $scalarVal');
          break;
        case 'transpose':
          computed = transpose(target);
          stepList.add('Transposed Matrix $_activeMatrix');
          break;
        case 'rref':
          final rrefData = rref(target);
          computed = rrefData.rref;
          stepList = rrefData.steps;
          break;
        case 'det':
          computed = determinant(target);
          stepList.add('Calculated determinant of Matrix $_activeMatrix: $computed');
          break;
        case 'inverse':
          computed = inverse(target);
          stepList.add('Computed inverse of Matrix $_activeMatrix using Gauss-Jordan elimination');
          break;
        case 'eigenvalues':
          computed = eigenvalues(target);
          stepList.add('Computed eigenvalues via QR algorithm iterations');
          break;
      }

      setState(() {
        _result = computed;
        _steps = stepList;
      });

      HistoryRepository.insertHistory(
        type: 'matrix',
        expression: 'Matrix Op: $op ($_activeMatrix)',
        result: computed is Matrix
            ? 'Matrix ${computed.length}x${computed[0].length}'
            : computed.toString(),
      ).then((_) {
        widget.onHistoryUpdated?.call();
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '').replaceFirst('MatrixError: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Matrix A & B Selector Tabs
          Row(
            children: [
              _matrixSelectorTab('A', 'Matrix A (${_rowsA}x$_colsA)'),
              const SizedBox(width: 8),
              _matrixSelectorTab('B', 'Matrix B (${_rowsB}x$_colsB)'),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Active Matrix Dimension Controls & Grid Editor
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Matrix $_activeMatrix Editor',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        const Text('Size: ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        _dimensionDropdown(
                          _activeMatrix == 'A' ? _rowsA : _rowsB,
                          (v) => setState(() {
                            if (_activeMatrix == 'A') {
                              _rowsA = v!;
                            } else {
                              _rowsB = v!;
                            }
                          }),
                        ),
                        const Text(' x ', style: TextStyle(color: AppColors.textMuted)),
                        _dimensionDropdown(
                          _activeMatrix == 'A' ? _colsA : _colsB,
                          (v) => setState(() {
                            if (_activeMatrix == 'A') {
                              _colsA = v!;
                            } else {
                              _colsB = v!;
                            }
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Matrix Grid Cells
                _buildMatrixGrid(_activeMatrix),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Operations Panel
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Operations',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),

                // Binary Operations (A and B)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _opBtn('A + B', 'add', AppColors.primary),
                    _opBtn('A - B', 'subtract', AppColors.primary),
                    _opBtn('A × B', 'multiply', AppColors.primary),
                  ],
                ),
                const SizedBox(height: 8),

                // Unary Operations on Selected Matrix
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _opBtn('RREF ($_activeMatrix)', 'rref', const Color(0xFF0284C7)),
                    _opBtn('det($_activeMatrix)', 'det', const Color(0xFF0D9488)),
                    _opBtn('inv($_activeMatrix)', 'inverse', const Color(0xFF7C3AED)),
                    _opBtn('($_activeMatrix)ᵀ', 'transpose', const Color(0xFF4B5563)),
                    _opBtn('Eigenvalues', 'eigenvalues', const Color(0xFFD97706)),
                  ],
                ),
                const SizedBox(height: 10),

                // Scalar Factor Scaling
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 34,
                        child: TextField(
                          controller: _scalarController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            labelText: 'Scalar Factor (k)',
                            labelStyle: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                            fillColor: AppColors.background,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _opBtn('k × $_activeMatrix', 'scale', const Color(0xFF059669)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. Computation Results & Steps
          if (_error.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Text(_error, style: const TextStyle(fontSize: 12, color: AppColors.error)),
            ),

          if (_result != null) _buildResultDisplay(),
        ],
      ),
    );
  }

  Widget _matrixSelectorTab(String id, String label) {
    final isSelected = _activeMatrix == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeMatrix = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.borderSubtle),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _dimensionDropdown(int current, ValueChanged<int?> onChanged) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: DropdownButton<int>(
        value: current,
        dropdownColor: AppColors.card,
        underline: const SizedBox(),
        isDense: true,
        items: [1, 2, 3, 4]
            .map((val) => DropdownMenuItem(
                  value: val,
                  child: Text('$val', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildMatrixGrid(String which) {
    final rows = which == 'A' ? _rowsA : _rowsB;
    final cols = which == 'A' ? _colsA : _colsB;
    final ctrl = which == 'A' ? _ctrlA : _ctrlB;

    return Column(
      children: List.generate(rows, (r) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: List.generate(cols, (c) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: SizedBox(
                    height: 38,
                    child: TextField(
                      controller: ctrl[r][c],
                      keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        fillColor: AppColors.background,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: AppColors.borderSubtle),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _opBtn(String label, String op, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        visualDensity: VisualDensity.compact,
      ),
      onPressed: () => _compute(op),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _buildResultDisplay() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Result: $_lastOp',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.success),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16, color: AppColors.textMuted),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _result.toString()));
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_result is Matrix)
            _renderMatrixResult(_result as Matrix)
          else if (_result is List<double>)
            Text(
              'Eigenvalues: ${_result.map((v) => v.toString()).join(", ")}',
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontFamily: 'monospace'),
            )
          else
            Text(
              '= $_result',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),

          if (_steps.isNotEmpty) ...[
            const Divider(color: AppColors.borderSubtle, height: 18),
            const Text(
              'Computation Steps:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            ..._steps.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('• $s', style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontFamily: 'monospace')),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _renderMatrixResult(Matrix mat) {
    return Column(
      children: mat.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((val) {
              final valStr = val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(3);
              return Container(
                width: 55,
                padding: const EdgeInsets.symmetric(vertical: 4),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  valStr,
                  style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, fontFamily: 'monospace'),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
