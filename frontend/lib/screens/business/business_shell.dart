import 'package:flutter/material.dart';
import '../../models/business_model.dart';
import '../../services/tourism_engine_service.dart';
import '../../theme/app_theme.dart';
import 'business_dashboard.dart';
import 'benchmark_screen.dart';
import 'subsidy_screen.dart';
import 'exchange_screen.dart';

class BusinessShell extends StatefulWidget {
  final BusinessSector sector;
  const BusinessShell({super.key, required this.sector});

  @override
  State<BusinessShell> createState() => _BusinessShellState();
}

class _BusinessShellState extends State<BusinessShell> {
  int _index = 0;
  late TourismEngineController _controller;

  @override
  void initState() {
    super.initState();
    // Create controller for ALL sectors — each gets real-time AI
    _controller = TourismEngineController(sector: widget.sector)
      ..generateGeminiInsight();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      BusinessDashboard(
          sector: widget.sector, tourismController: _controller),
      BenchmarkScreen(
          sector: widget.sector, tourismController: _controller),
      SubsidyScreen(tourismController: _controller),
      ExchangeScreen(tourismController: _controller),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(
              top: BorderSide(
                  color: AppTheme.emerald.withValues(alpha: 0.15))),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Dashboard'),
            BottomNavigationBarItem(
                icon: Icon(Icons.compare_arrows), label: 'Benchmark'),
            BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_outlined),
                activeIcon: Icon(Icons.account_balance),
                label: 'Subsidies'),
            BottomNavigationBarItem(
                icon: Icon(Icons.swap_horiz), label: 'Exchange'),
          ],
        ),
      ),
    );
  }
}
