/// Hardware-Accelerated 2D Function Plotter using CustomPainter
library;

import 'package:flutter/material.dart';
import '../../core/math_engine/ast.dart';
import '../../core/math_engine/evaluator.dart';
import '../../core/math_engine/parser.dart';
import '../../shared/theme/app_colors.dart';

class FormulaItem {
  final String id;
  String text;
  Color color;
  bool visible;
  ASTNode? parsedAst;
  String? error;

  FormulaItem({
    required this.id,
    required this.text,
    required this.color,
    this.visible = true,
  }) {
    updateText(text);
  }

  void updateText(String newText) {
    text = newText;
    try {
      parsedAst = parseExpression(newText);
      error = null;
    } catch (e) {
      parsedAst = null;
      error = e.toString().replaceFirst('Exception: ', '');
    }
  }
}

class Graphing2DView extends StatefulWidget {
  final String? initialFormula;

  const Graphing2DView({super.key, this.initialFormula});

  @override
  State<Graphing2DView> createState() => Graphing2DViewState();
}

class Graphing2DViewState extends State<Graphing2DView> {
  double _centerX = 0.0;
  double _centerY = 0.0;
  double _zoomScale = 40.0; // Screen pixels per math unit

  late List<FormulaItem> _formulas;
  final TextEditingController _addController = TextEditingController();
  bool _showFormulaDrawer = false;

  @override
  void initState() {
    super.initState();
    _formulas = [
      FormulaItem(id: '1', text: widget.initialFormula ?? 'sin(x)', color: AppColors.graphPalette[0]),
      FormulaItem(id: '2', text: 'x^2 - 4', color: AppColors.graphPalette[1]),
    ];
  }

  void loadFormula(String expr) {
    setState(() {
      _formulas.insert(
        0,
        FormulaItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          text: expr,
          color: AppColors.graphPalette[_formulas.length % AppColors.graphPalette.length],
        ),
      );
      _resetView();
    });
  }

  void _resetView() {
    setState(() {
      _centerX = 0.0;
      _centerY = 0.0;
      _zoomScale = 40.0;
    });
  }

  void _addFormula() {
    final text = _addController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _formulas.add(FormulaItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: text,
        color: AppColors.graphPalette[_formulas.length % AppColors.graphPalette.length],
      ));
      _addController.clear();
      _showFormulaDrawer = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Interactive 2D Graph Canvas
        Positioned.fill(
          child: GestureDetector(
            onScaleUpdate: (details) {
              setState(() {
                if (details.scale != 1.0) {
                  _zoomScale = (_zoomScale * details.scale).clamp(4.0, 600.0);
                }
                _centerX -= details.focalPointDelta.dx / _zoomScale;
                _centerY += details.focalPointDelta.dy / _zoomScale;
              });
            },
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _Graph2DPainter(
                  formulas: _formulas.where((f) => f.visible && f.parsedAst != null).toList(),
                  centerX: _centerX,
                  centerY: _centerY,
                  zoomScale: _zoomScale,
                ),
              ),
            ),
          ),
        ),

        // 2. Top Viewport HUD: Center Coordinates & Quick Controls
        Positioned(
          top: 10,
          left: 10,
          right: 10,
          child: Row(
            children: [
              // Coordinate Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  'Center: (${_centerX.toStringAsFixed(2)}, ${_centerY.toStringAsFixed(2)}) | Zoom: ${_zoomScale.toInt()}px',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const Spacer(),

              // Formula List Toggle
              GestureDetector(
                onTap: () => setState(() => _showFormulaDrawer = !_showFormulaDrawer),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _showFormulaDrawer ? AppColors.primary : AppColors.surface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.functions, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '${_formulas.length} Curves',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 3. Floating Bottom-Right Zoom & Reset Controls
        Positioned(
          right: 16,
          bottom: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _floatingBtn(
                Icons.add,
                'Zoom In',
                () => setState(() => _zoomScale = (_zoomScale * 1.25).clamp(4.0, 600.0)),
              ),
              const SizedBox(height: 8),
              _floatingBtn(
                Icons.remove,
                'Zoom Out',
                () => setState(() => _zoomScale = (_zoomScale / 1.25).clamp(4.0, 600.0)),
              ),
              const SizedBox(height: 8),
              _floatingBtn(
                Icons.center_focus_strong,
                'Reset View',
                _resetView,
              ),
            ],
          ),
        ),

        // 4. Slide-over Formula Management Drawer
        if (_showFormulaDrawer)
          Positioned(
            top: 50,
            left: 10,
            right: 10,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 340),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 4)),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Active Functions',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() => _showFormulaDrawer = false),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.borderSubtle, height: 16),

                  // Formula List
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _formulas.length,
                      itemBuilder: (context, idx) {
                        final item = _formulas[idx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: item.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.text,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: item.visible ? AppColors.textPrimary : AppColors.textMuted,
                                    fontFamily: 'monospace',
                                    decoration: item.visible ? null : TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                              // Toggle Visibility
                              IconButton(
                                icon: Icon(
                                  item.visible ? Icons.visibility : Icons.visibility_off,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () {
                                  setState(() => item.visible = !item.visible);
                                },
                              ),
                              // Delete
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                                onPressed: () {
                                  setState(() => _formulas.removeAt(idx));
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 8),
                  // Add New Formula Input
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: TextField(
                            controller: _addController,
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'e.g. 2*sin(x) or x^3 - x',
                              hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              fillColor: AppColors.background,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.borderSubtle),
                              ),
                            ),
                            onSubmitted: (_) => _addFormula(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onPressed: _addFormula,
                        child: const Text('Add', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _floatingBtn(IconData icon, String tooltip, VoidCallback onTap) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(10),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _Graph2DPainter extends CustomPainter {
  final List<FormulaItem> formulas;
  final double centerX;
  final double centerY;
  final double zoomScale;

  _Graph2DPainter({
    required this.formulas,
    required this.centerX,
    required this.centerY,
    required this.zoomScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Clean Dark Background
    final bgPaint = Paint()..color = const Color(0xFF09090B);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final width = size.width;
    final height = size.height;

    // Origin Pixel Coordinate in Screen Space
    final originX = width / 2.0 - centerX * zoomScale;
    final originY = height / 2.0 + centerY * zoomScale;

    // Convert Screen Coordinate -> Math Coordinate
    double toMathX(double px) => (px - originX) / zoomScale;
    double toMathY(double py) => (originY - py) / zoomScale;

    // Convert Math Coordinate -> Screen Coordinate
    double toScreenX(double mx) => originX + mx * zoomScale;
    double toScreenY(double my) => originY - my * zoomScale;

    // Dynamic grid spacing ticks
    double gridSpacing = 1.0;
    if (zoomScale < 12) {
      gridSpacing = 10.0;
    } else if (zoomScale < 25) {
      gridSpacing = 5.0;
    } else if (zoomScale > 150) {
      gridSpacing = 0.2;
    } else if (zoomScale > 350) {
      gridSpacing = 0.05;
    }

    final leftBoundX = toMathX(0);
    final rightBoundX = toMathX(width);
    final bottomBoundY = toMathY(height);
    final topBoundY = toMathY(0);

    // 2. Draw Subtle Grid Lines & Axis Numbers
    final gridPaint = Paint()
      ..color = const Color(0xFF1E1E24)
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // X-Grid Lines
    final startX = (leftBoundX / gridSpacing).floor() * gridSpacing;
    for (double x = startX; x <= rightBoundX; x += gridSpacing) {
      final sx = toScreenX(x);
      canvas.drawLine(Offset(sx, 0), Offset(sx, height), gridPaint);

      // Tick Labels
      if (x.abs() > 1e-9) {
        final labelY = (originY + 12).clamp(14.0, height - 14.0);
        final labelText = x % 1 == 0 ? x.toInt().toString() : x.toStringAsFixed(1);
        textPainter.text = TextSpan(
          text: labelText,
          style: const TextStyle(fontSize: 9, color: Color(0xFF71717A), fontFamily: 'monospace'),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(sx - textPainter.width / 2, labelY));
      }
    }

    // Y-Grid Lines
    final startY = (bottomBoundY / gridSpacing).floor() * gridSpacing;
    for (double y = startY; y <= topBoundY; y += gridSpacing) {
      final sy = toScreenY(y);
      canvas.drawLine(Offset(0, sy), Offset(width, sy), gridPaint);

      // Tick Labels
      if (y.abs() > 1e-9) {
        final labelX = (originX + 6).clamp(6.0, width - 28.0);
        final labelText = y % 1 == 0 ? y.toInt().toString() : y.toStringAsFixed(1);
        textPainter.text = TextSpan(
          text: labelText,
          style: const TextStyle(fontSize: 9, color: Color(0xFF71717A), fontFamily: 'monospace'),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(labelX, sy - textPainter.height / 2));
      }
    }

    // 3. Draw Main Axes Vectors
    final axisPaint = Paint()
      ..color = const Color(0xFF3F3F46)
      ..strokeWidth = 1.6;

    canvas.drawLine(Offset(0, originY), Offset(width, originY), axisPaint);
    canvas.drawLine(Offset(originX, 0), Offset(originX, height), axisPaint);

    // 4. Render Active Mathematical Curves
    // Low-spec optimization: step by 2 physical pixels across screen width
    const stepPixels = 2.0;

    for (final formula in formulas) {
      final ast = formula.parsedAst;
      if (ast == null) continue;

      final curvePaint = Paint()
        ..color = formula.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      bool isSegmentOpen = false;
      double lastPy = 0.0;

      for (double px = 0.0; px <= width; px += stepPixels) {
        final mx = toMathX(px);

        try {
          final my = evaluateAST(ast, {'x': mx});

          if (my.isNaN || my.isInfinite || my.abs() > 10000) {
            isSegmentOpen = false;
            continue;
          }

          final py = toScreenY(my);

          // Detect asymptote discontinuity (e.g. tan(x) flipping between +inf and -inf)
          if (isSegmentOpen && (py - lastPy).abs() > height * 0.8) {
            isSegmentOpen = false;
          }

          // Discard points severely off viewport to keep Path buffer lightweight
          if (py < -height || py > height * 2) {
            isSegmentOpen = false;
            continue;
          }

          if (!isSegmentOpen) {
            path.moveTo(px, py);
            isSegmentOpen = true;
          } else {
            path.lineTo(px, py);
          }
          lastPy = py;
        } catch (_) {
          isSegmentOpen = false;
        }
      }

      canvas.drawPath(path, curvePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _Graph2DPainter old) {
    return old.centerX != centerX ||
        old.centerY != centerY ||
        old.zoomScale != zoomScale ||
        old.formulas != formulas;
  }
}
