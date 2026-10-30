/// CAS Calculus Workspace, Polynomial Solvers & Systems of Equations
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/math_engine/calculus.dart';
import '../../core/math_engine/fraction.dart';
import '../../core/math_engine/solver.dart';
import '../../core/storage/history_repository.dart';
import '../../shared/theme/app_colors.dart';

enum CASSubTab { calculus, polynomial, systems, limits }

class CalculusSolverView extends StatefulWidget {
  final VoidCallback? onHistoryUpdated;

  const CalculusSolverView({super.key, this.onHistoryUpdated});

  @override
  State<CalculusSolverView> createState() => CalculusSolverViewState();
}

class CalculusSolverViewState extends State<CalculusSolverView> {
  CASSubTab _activeTab = CASSubTab.calculus;

  // 1. Calculus State
  final TextEditingController _calcExprCtrl = TextEditingController(text: '3x^3 + 5sin(x) - exp(x)');
  String _diffType = 'symbolic'; // 'symbolic' | 'numeric'
  String _integralType = 'definite'; // 'definite' | 'symbolic'
  final TextEditingController _diffPointCtrl = TextEditingController(text: '2');
  final TextEditingController _integralACtrl = TextEditingController(text: '0');
  final TextEditingController _integralBCtrl = TextEditingController(text: '3.14159');
  final String _integralMethod = 'simpson';

  // 2. Limit State
  final TextEditingController _limitExprCtrl = TextEditingController(text: 'sin(x) / x');
  final TextEditingController _limitTargetCtrl = TextEditingController(text: '0');

  // 3. Polynomial State
  final TextEditingController _polyExprCtrl = TextEditingController(text: 'x^3 - 6x^2 + 11x - 6');

  // 4. Systems State
  int _sysDim = 3;
  late List<List<TextEditingController>> _sysACtrl;
  late List<TextEditingController> _sysBCtrl;

  // Results State
  dynamic _result;
  List<String> _steps = [];
  String _error = '';
  String _calcType = '';

  @override
  void initState() {
    super.initState();
    _initSystemsGrid();
  }

  void _initSystemsGrid() {
    _sysACtrl = [
      [TextEditingController(text: '2'), TextEditingController(text: '1'), TextEditingController(text: '-1')],
      [TextEditingController(text: '-3'), TextEditingController(text: '-1'), TextEditingController(text: '2')],
      [TextEditingController(text: '-2'), TextEditingController(text: '1'), TextEditingController(text: '2')],
    ];
    _sysBCtrl = [
      TextEditingController(text: '8'),
      TextEditingController(text: '-11'),
      TextEditingController(text: '-3'),
    ];
  }

  void loadExpression(String expr) {
    setState(() {
      _calcExprCtrl.text = expr;
      _polyExprCtrl.text = expr;
      _error = '';
    });
  }

  void _computeDerivative() {
    HapticFeedback.lightImpact();
    setState(() {
      _error = '';
      _result = null;
      _steps = [];
      _calcType = _diffType == 'symbolic' ? 'Symbolic Derivative' : 'Derivative at Point';
    });

    try {
      final expr = _calcExprCtrl.text.trim();
      if (_diffType == 'symbolic') {
        final res = getSymbolicDerivative(expr);
        setState(() {
          _result = res;
          _steps = ['Differentiated expression: d/dx [$expr]', 'Simplified derivative: $res'];
        });
        HistoryRepository.insertHistory(type: 'calculus', expression: 'd/dx [$expr]', result: res);
      } else {
        final pt = double.tryParse(_diffPointCtrl.text) ?? 0.0;
        final res = numericDerivative(expr, pt);
        final formatted = Fraction.format(res);
        setState(() {
          _result = formatted.display;
          _steps = [
            'Calculated numeric derivative via 5-point central stencil at x = $pt',
            if (formatted.fraction != null && formatted.fraction != formatted.decimal)
              'Exact Form: ${formatted.fraction}',
            'Decimal Value: ${formatted.decimal}',
          ];
        });
        HistoryRepository.insertHistory(type: 'calculus', expression: 'd/dx [$expr] at x=$pt', result: formatted.display);
      }
      widget.onHistoryUpdated?.call();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _computeIntegral() {
    HapticFeedback.lightImpact();
    setState(() {
      _error = '';
      _result = null;
      _steps = [];
      _calcType = _integralType == 'symbolic' ? 'Indefinite Integral (Antiderivative)' : 'Definite Integral with Limits';
    });

    try {
      final expr = _calcExprCtrl.text.trim();
      if (_integralType == 'symbolic') {
        final res = getSymbolicIntegral(expr);
        setState(() {
          _result = res;
          _steps = [
            'Found antiderivative for: ∫ [$expr] dx',
            'Result: $res',
          ];
        });
        HistoryRepository.insertHistory(
          type: 'calculus',
          expression: '∫ [$expr] dx',
          result: res,
        );
      } else {
        final a = double.tryParse(_integralACtrl.text) ?? 0.0;
        final b = double.tryParse(_integralBCtrl.text) ?? 1.0;
        final res = numericalIntegration(expr, a, b, method: _integralMethod);
        final formatted = Fraction.format(res);

        setState(() {
          _result = formatted.display;
          _steps = [
            'Evaluated definite integral from a = $a to b = $b',
            'Compound integration rule: ${_integralMethod.toUpperCase()}',
            if (formatted.fraction != null && formatted.fraction != formatted.decimal)
              'Exact Form: ${formatted.fraction}',
            'Decimal Value: ${formatted.decimal}',
          ];
        });
        HistoryRepository.insertHistory(
          type: 'calculus',
          expression: '∫_($a)^($b) [$expr] dx',
          result: formatted.display,
        );
      }
      widget.onHistoryUpdated?.call();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _computeLimit() {
    HapticFeedback.lightImpact();
    setState(() {
      _error = '';
      _result = null;
      _steps = [];
      _calcType = 'Limit Approximation';
    });

    try {
      final expr = _limitExprCtrl.text.trim();
      final target = double.tryParse(_limitTargetCtrl.text) ?? 0.0;
      final res = approximateLimit(expr, target);

      setState(() {
        _result = res.formatted;
        _steps = [
          'Approaching target x -> $target',
          'Left approach limit: ${res.directionLeft}',
          'Right approach limit: ${res.directionRight}',
          'Convergence test: ${res.converges ? "Passed" : "Failed (Discontinuous)"}',
        ];
      });
      HistoryRepository.insertHistory(
        type: 'calculus',
        expression: 'lim_(x->$target) [$expr]',
        result: res.formatted,
      );
      widget.onHistoryUpdated?.call();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _solvePolynomial() {
    HapticFeedback.lightImpact();
    setState(() {
      _error = '';
      _result = null;
      _steps = [];
      _calcType = 'Polynomial Solver';
    });

    try {
      final expr = _polyExprCtrl.text.trim();
      final poly = solvePolynomial(expr);

      setState(() {
        _result = poly.roots.map((r) => r.display).join('\n');
        _steps = poly.steps;
      });
      HistoryRepository.insertHistory(
        type: 'solver',
        expression: '$expr = 0',
        result: poly.roots.map((r) => r.display).join(', '),
      );
      widget.onHistoryUpdated?.call();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _solveSystem() {
    HapticFeedback.lightImpact();
    setState(() {
      _error = '';
      _result = null;
      _steps = [];
      _calcType = 'Linear System (Ax = B)';
    });

    try {
      final a = List.generate(_sysDim, (r) {
        return List.generate(_sysDim, (c) {
          return double.tryParse(_sysACtrl[r][c].text.trim()) ?? 0.0;
        });
      });
      final b = List.generate(_sysDim, (i) {
        return double.tryParse(_sysBCtrl[i].text.trim()) ?? 0.0;
      });

      final sys = solveLinearSystem(a, b);
      final resStrs = List.generate(sys.result.length, (i) => 'x_${i + 1} = ${sys.result[i]}');

      setState(() {
        _result = resStrs.join(', ');
        _steps = sys.steps;
      });
      HistoryRepository.insertHistory(
        type: 'solver',
        expression: 'System Ax=B ($_sysDim x $_sysDim)',
        result: resStrs.join(', '),
      );
      widget.onHistoryUpdated?.call();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtabs Navigation Switcher
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                _subTabItem(CASSubTab.calculus, 'Calculus'),
                _subTabItem(CASSubTab.limits, 'Limits'),
                _subTabItem(CASSubTab.polynomial, 'Polynomials'),
                _subTabItem(CASSubTab.systems, 'Linear Systems'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Active Panel
          if (_activeTab == CASSubTab.calculus) _buildCalculusPanel(),
          if (_activeTab == CASSubTab.limits) _buildLimitsPanel(),
          if (_activeTab == CASSubTab.polynomial) _buildPolynomialPanel(),
          if (_activeTab == CASSubTab.systems) _buildSystemsPanel(),

          const SizedBox(height: 14),

          // Error Display
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

          // Result Display Card
          if (_result != null) _buildResultCard(),
        ],
      ),
    );
  }

  Widget _subTabItem(CASSubTab tab, String label) {
    final isSelected = _activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _activeTab = tab;
          _error = '';
          _result = null;
          _steps = [];
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalculusPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Function f(x):', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextField(
            controller: _calcExprCtrl,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontFamily: 'monospace'),
            decoration: InputDecoration(
              fillColor: AppColors.background,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12),

          // Derivative Controls
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: _computeDerivative,
                  icon: const Icon(Icons.show_chart, size: 16, color: Colors.white),
                  label: Text(_diffType == 'symbolic' ? 'Symbolic d/dx' : 'd/dx at Point x₀',
                      style: const TextStyle(fontSize: 12, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _diffType,
                dropdownColor: AppColors.card,
                items: const [
                  DropdownMenuItem(value: 'symbolic', child: Text('Symbolic', style: TextStyle(color: Colors.white, fontSize: 12))),
                  DropdownMenuItem(value: 'numeric', child: Text('At Point x₀', style: TextStyle(color: Colors.white, fontSize: 12))),
                ],
                onChanged: (v) => setState(() => _diffType = v!),
              ),
            ],
          ),

          if (_diffType == 'numeric') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('At point x₀ = ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                SizedBox(
                  width: 80,
                  height: 32,
                  child: TextField(
                    controller: _diffPointCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      fillColor: AppColors.background,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const Divider(color: AppColors.borderSubtle, height: 24),

          // Integral Controls
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
                  onPressed: _computeIntegral,
                  icon: const Icon(Icons.functions, size: 16, color: Colors.white),
                  label: Text(
                      _integralType == 'symbolic' ? 'Indefinite ∫ (Antiderivative)' : 'Definite ∫ with Limits',
                      style: const TextStyle(fontSize: 12, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _integralType,
                dropdownColor: AppColors.card,
                items: const [
                  DropdownMenuItem(value: 'definite', child: Text('Definite [a, b]', style: TextStyle(color: Colors.white, fontSize: 12))),
                  DropdownMenuItem(value: 'symbolic', child: Text('Antiderivative', style: TextStyle(color: Colors.white, fontSize: 12))),
                ],
                onChanged: (v) => setState(() => _integralType = v!),
              ),
            ],
          ),

          if (_integralType == 'definite') ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('Lower limit a = ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  SizedBox(
                    width: 60,
                    height: 32,
                    child: TextField(
                      controller: _integralACtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        fillColor: AppColors.background,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Upper limit b = ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  SizedBox(
                    width: 60,
                    height: 32,
                    child: TextField(
                      controller: _integralBCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        fillColor: AppColors.background,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLimitsPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Expression f(x):', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextField(
            controller: _limitExprCtrl,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontFamily: 'monospace'),
            decoration: InputDecoration(
              fillColor: AppColors.background,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Target point x -> ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              SizedBox(
                width: 60,
                height: 32,
                child: TextField(
                  controller: _limitTargetCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    fillColor: AppColors.background,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: _computeLimit,
                child: const Text('Evaluate Limit', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPolynomialPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Polynomial P(x) = 0:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextField(
            controller: _polyExprCtrl,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: 'e.g. x^3 - 6x^2 + 11x - 6',
              fillColor: AppColors.background,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: _solvePolynomial,
            child: const Text('Find Roots & Factorization', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemsPanel() {
    return Container(
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
              const Text('System Matrix [A | B]:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Row(
                children: [
                  const Text('Variables: ', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  DropdownButton<int>(
                    value: _sysDim,
                    dropdownColor: AppColors.card,
                    isDense: true,
                    underline: const SizedBox(),
                    items: [2, 3]
                        .map((n) => DropdownMenuItem(value: n, child: Text('$n', style: const TextStyle(color: Colors.white, fontSize: 12))))
                        .toList(),
                    onChanged: (n) => setState(() => _sysDim = n!),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Grid Editor: A rows + B column
          ...List.generate(_sysDim, (r) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  ...List.generate(_sysDim, (c) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: SizedBox(
                          height: 36,
                          child: TextField(
                            controller: _sysACtrl[r][c],
                            keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontFamily: 'monospace'),
                            decoration: InputDecoration(
                              fillColor: AppColors.background,
                              filled: true,
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text('=', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                  ),
                  SizedBox(
                    width: 50,
                    height: 36,
                    child: TextField(
                      controller: _sysBCtrl[r],
                      keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: AppColors.success, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        fillColor: AppColors.background,
                        filled: true,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: _solveSystem,
            child: const Text('Solve Ax = B', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
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
              Text(_calcType, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.success)),
              IconButton(
                icon: const Icon(Icons.copy, size: 16, color: AppColors.textMuted),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _result.toString()));
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            _result.toString(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontFamily: 'monospace'),
          ),
          if (_steps.isNotEmpty) ...[
            const Divider(color: AppColors.borderSubtle, height: 16),
            const Text('Steps:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            ..._steps.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text('• $s', style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontFamily: 'monospace')),
                )),
          ],
        ],
      ),
    );
  }
}
