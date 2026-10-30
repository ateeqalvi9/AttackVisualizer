/// Pure Lightweight 3D Surface Visualizer using 3D Perspective Projection
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/math_engine/ast.dart';
import '../../core/math_engine/evaluator.dart';
import '../../core/math_engine/parser.dart';
import '../../shared/theme/app_colors.dart';

class Point3D {
  final double x;
  final double y;
  final double z;
  const Point3D(this.x, this.y, this.z);
}

class Graphing3DView extends StatefulWidget {
  final String? initialFormula;

  const Graphing3DView({super.key, this.initialFormula});

  @override
  State<Graphing3DView> createState() => Graphing3DViewState();
}

class Graphing3DViewState extends State<Graphing3DView> {
  String _formula = 'sin(x^2 + y^2) / (x^2 + y^2 + 0.5)';
  final TextEditingController _formulaController = TextEditingController();

  double _rotX = 0.6;
  double _rotY = -0.6;
  double _scale = 22.0;

  final int _resolution = 24; // Optimal for low-spec mobile 60 FPS
  bool _wireframeOnly = false;
  String _error = '';

  List<List<Point3D>> _grid = [];
  ASTNode? _parsedAst;

  final List<Map<String, String>> _presets = [
    {'name': 'Ripples', 'expr': 'sin(x^2 + y^2) / (x^2 + y^2 + 0.5)'},
    {'name': 'Saddle Surface', 'expr': 'x^2 - y^2'},
    {'name': 'Sine Waves', 'expr': 'sin(x) * cos(y)'},
    {'name': 'Gaussian Hat', 'expr': '3 * exp(-(x^2 + y^2) / 4)'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialFormula != null && widget.initialFormula!.isNotEmpty) {
      _formula = widget.initialFormula!;
    }
    _formulaController.text = _formula;
    _recomputeMesh();
  }

  void loadFormula(String expr) {
    setState(() {
      _formula = expr;
      _formulaController.text = expr;
      _recomputeMesh();
    });
  }

  void _recomputeMesh() {
    try {
      _parsedAst = parseExpression(_formula);
      _error = '';

      const minX = -5.0;
      const maxX = 5.0;
      const minY = -5.0;
      const maxY = 5.0;

      final stepX = (maxX - minX) / (_resolution - 1);
      final stepY = (maxY - minY) / (_resolution - 1);

      final newGrid = <List<Point3D>>[];

      for (var j = 0; j < _resolution; j++) {
        final row = <Point3D>[];
        final y = minY + j * stepY;

        for (var i = 0; i < _resolution; i++) {
          final x = minX + i * stepX;
          var z = 0.0;
          try {
            z = evaluateAST(_parsedAst!, {'x': x, 'y': y});
            if (z.isNaN || z.isInfinite) {
              z = 0.0;
            } else {
              z = z.clamp(-8.0, 8.0);
            }
          } catch (_) {
            z = 0.0;
          }
          row.add(Point3D(x, y, z));
        }
        newGrid.add(row);
      }

      setState(() {
        _grid = newGrid;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _grid = [];
      });
    }
  }

  void _resetAngles() {
    setState(() {
      _rotX = 0.6;
      _rotY = -0.6;
      _scale = 22.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Top Controls Bar: Formula Input and Preset Selectors
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: AppColors.surface,
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'z = ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _formulaController,
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'f(x, y) formula',
                          hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          fillColor: AppColors.background,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.borderSubtle),
                          ),
                        ),
                        onSubmitted: (v) {
                          _formula = v;
                          _recomputeMesh();
                        },
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
                    onPressed: () {
                      _formula = _formulaController.text;
                      _recomputeMesh();
                    },
                    child: const Text('Plot', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Presets Row & Wireframe Toggle
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ..._presets.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: AppColors.card,
                          label: Text(
                            p['name']!,
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          ),
                          onPressed: () {
                            _formula = p['expr']!;
                            _formulaController.text = _formula;
                            _recomputeMesh();
                          },
                        ),
                      ),
                    ),
                    ActionChip(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: _wireframeOnly ? AppColors.primary : AppColors.card,
                      label: Text(
                        _wireframeOnly ? 'Wireframe Only' : 'Shaded Mesh',
                        style: TextStyle(
                          fontSize: 10,
                          color: _wireframeOnly ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                      onPressed: () => setState(() => _wireframeOnly = !_wireframeOnly),
                    ),
                  ],
                ),
              ),

              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _error,
                    style: const TextStyle(color: AppColors.error, fontSize: 11),
                  ),
                ),
            ],
          ),
        ),

        // 2. Interactive 3D Perspective Projection Canvas
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onScaleUpdate: (details) {
                    setState(() {
                      if (details.scale != 1.0) {
                        _scale = (_scale * details.scale).clamp(8.0, 60.0);
                      }
                      _rotY += details.focalPointDelta.dx * 0.01;
                      _rotX -= details.focalPointDelta.dy * 0.01;
                    });
                  },
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _Graph3DPainter(
                        grid: _grid,
                        rotX: _rotX,
                        rotY: _rotY,
                        scale: _scale,
                        wireframeOnly: _wireframeOnly,
                      ),
                    ),
                  ),
                ),
              ),

              // Reset Angle Floating Action
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.small(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.textPrimary,
                  tooltip: 'Reset Angles',
                  onPressed: _resetAngles,
                  child: const Icon(Icons.refresh, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Graph3DPainter extends CustomPainter {
  final List<List<Point3D>> grid;
  final double rotX;
  final double rotY;
  final double scale;
  final bool wireframeOnly;

  _Graph3DPainter({
    required this.grid,
    required this.rotX,
    required this.rotY,
    required this.scale,
    required this.wireframeOnly,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF09090B);
    canvas.drawRect(Offset.zero & size, bgPaint);

    if (grid.isEmpty) return;

    final cx = size.width / 2.0;
    final cy = size.height / 2.0;

    final cosX = math.cos(rotX);
    final sinX = math.sin(rotX);
    final cosY = math.cos(rotY);
    final sinY = math.sin(rotY);

    // 3D Perspective Projection Function: (X, Y, Z) -> (ScreenX, ScreenY, Depth)
    (Offset, double) project(Point3D p) {
      // Rotate around Y
      final x1 = p.x * cosY + p.y * sinY;
      final y1 = -p.x * sinY + p.y * cosY;

      // Rotate around X (Elevation)
      final y2 = y1 * cosX - p.z * sinX;
      final z2 = y1 * sinX + p.z * cosX;

      const cameraDistance = 25.0;
      final fov = cameraDistance / (cameraDistance + y2);

      final screenX = cx + x1 * scale * fov;
      final screenY = cy - z2 * scale * fov;

      return (Offset(screenX, screenY), y2);
    }

    final rows = grid.length;
    final cols = grid[0].length;

    // Optional Quad Shading: Sort quads back to front for depth-sorting
    if (!wireframeOnly) {
      final quadList = <_Quad>[];

      for (var r = 0; r < rows - 1; r++) {
        for (var c = 0; c < cols - 1; c++) {
          final p00 = grid[r][c];
          final p10 = grid[r + 1][c];
          final p11 = grid[r + 1][c + 1];
          final p01 = grid[r][c + 1];

          final (s00, d00) = project(p00);
          final (s10, d10) = project(p10);
          final (s11, d11) = project(p11);
          final (s01, d01) = project(p01);

          final avgDepth = (d00 + d10 + d11 + d01) / 4.0;
          final avgZ = (p00.z + p10.z + p11.z + p01.z) / 4.0;

          // Color calculation based on height Z
          final t = ((avgZ + 4.0) / 8.0).clamp(0.0, 1.0);
          final color = Color.lerp(
            const Color(0xFF3B82F6), // Indigo/blue valleys
            const Color(0xFFEC4899), // Pink/rose peaks
            t,
          )!.withValues(alpha: 0.65);

          quadList.add(_Quad(
            pts: [s00, s10, s11, s01],
            depth: avgDepth,
            color: color,
          ));
        }
      }

      // Sort quads descending by distance (painter's algorithm)
      quadList.sort((a, b) => b.depth.compareTo(a.depth));

      final quadPaint = Paint()..style = PaintingStyle.fill;
      for (final quad in quadList) {
        quadPaint.color = quad.color;
        final quadPath = Path()
          ..moveTo(quad.pts[0].dx, quad.pts[0].dy)
          ..lineTo(quad.pts[1].dx, quad.pts[1].dy)
          ..lineTo(quad.pts[2].dx, quad.pts[2].dy)
          ..lineTo(quad.pts[3].dx, quad.pts[3].dy)
          ..close();
        canvas.drawPath(quadPath, quadPaint);
      }
    }

    // Draw Wireframe Grid lines
    final linePaint = Paint()
      ..color = const Color(0xFF6366F1).withValues(alpha: 0.55)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (var r = 0; r < rows; r++) {
      final path = Path();
      for (var c = 0; c < cols; c++) {
        final (screenPt, _) = project(grid[r][c]);
        if (c == 0) {
          path.moveTo(screenPt.dx, screenPt.dy);
        } else {
          path.lineTo(screenPt.dx, screenPt.dy);
        }
      }
      canvas.drawPath(path, linePaint);
    }

    for (var c = 0; c < cols; c++) {
      final path = Path();
      for (var r = 0; r < rows; r++) {
        final (screenPt, _) = project(grid[r][c]);
        if (r == 0) {
          path.moveTo(screenPt.dx, screenPt.dy);
        } else {
          path.lineTo(screenPt.dx, screenPt.dy);
        }
      }
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _Graph3DPainter old) {
    return old.rotX != rotX ||
        old.rotY != rotY ||
        old.scale != scale ||
        old.wireframeOnly != wireframeOnly ||
        old.grid != grid;
  }
}

class _Quad {
  final List<Offset> pts;
  final double depth;
  final Color color;
  _Quad({required this.pts, required this.depth, required this.color});
}
