/// Advanced Scientific CAS Mobile Application
/// Optimized for ultra-low-spec hardware with pure Dart math engine & offline persistence
library;

import 'package:flutter/material.dart';
import 'features/calculator/calculator_view.dart';
import 'features/cas_solver/calculus_solver_view.dart';
import 'features/graphing_2d/graphing_2d_view.dart';
import 'features/graphing_3d/graphing_3d_view.dart';
import 'features/history/history_drawer.dart';
import 'features/matrix_lab/matrix_view.dart';
import 'shared/theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ScientificCasApp());
}

class ScientificCasApp extends StatelessWidget {
  const ScientificCasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advanced Scientific CAS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      home: const MainCasShell(),
    );
  }
}

class MainCasShell extends StatefulWidget {
  const MainCasShell({super.key});

  @override
  State<MainCasShell> createState() => _MainCasShellState();
}

class _MainCasShellState extends State<MainCasShell> {
  int _currentIndex = 0;

  final GlobalKey<CalculatorViewState> _calcKey = GlobalKey();
  final GlobalKey<Graphing2DViewState> _graph2DKey = GlobalKey();
  final GlobalKey<Graphing3DViewState> _graph3DKey = GlobalKey();
  final GlobalKey<CalculusSolverViewState> _casKey = GlobalKey();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  void _onSelectPreset(String expr) {
    switch (_currentIndex) {
      case 0:
        _calcKey.currentState?.loadExpression(expr);
        break;
      case 1:
        _graph2DKey.currentState?.loadFormula(expr);
        break;
      case 2:
        _graph3DKey.currentState?.loadFormula(expr);
        break;
      case 4:
        _casKey.currentState?.loadExpression(expr);
        break;
      default:
        _calcKey.currentState?.loadExpression(expr);
        setState(() => _currentIndex = 0);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded "$expr" into current workspace', style: const TextStyle(fontSize: 12)),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.card,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: HistoryDrawer(
        onSelectExpression: _onSelectPreset,
      ),
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scientific CAS',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  '100% Offline Math Engine',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Live Engine Indicator Badge
          Container(
            margin: const EdgeInsets.symmetric(vertical: 14),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 3, backgroundColor: AppColors.success),
                SizedBox(width: 5),
                Text(
                  'OFFLINE ACTIVE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Drawer History Action
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.textPrimary),
            tooltip: 'Session Logs & Presets',
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          CalculatorView(key: _calcKey),
          Graphing2DView(key: _graph2DKey),
          Graphing3DView(key: _graph3DKey),
          const MatrixView(),
          CalculusSolverView(key: _casKey),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withValues(alpha: 0.2),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final isSelected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final isSelected = states.contains(WidgetState.selected);
            return IconThemeData(
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          height: 60,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.calculate_outlined),
              selectedIcon: Icon(Icons.calculate),
              label: 'Calculator',
            ),
            NavigationDestination(
              icon: Icon(Icons.show_chart_outlined),
              selectedIcon: Icon(Icons.show_chart),
              label: '2D Plotter',
            ),
            NavigationDestination(
              icon: Icon(Icons.layers_outlined),
              selectedIcon: Icon(Icons.layers),
              label: '3D Surface',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_on_outlined),
              selectedIcon: Icon(Icons.grid_on),
              label: 'Matrix Lab',
            ),
            NavigationDestination(
              icon: Icon(Icons.functions_outlined),
              selectedIcon: Icon(Icons.functions),
              label: 'CAS Solver',
            ),
          ],
        ),
      ),
    );
  }
}
