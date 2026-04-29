import 'package:flutter/material.dart';
import '../../models/business_model.dart';
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

  @override
  Widget build(BuildContext context) {
    final screens = [
      BusinessDashboard(sector: widget.sector),
      BenchmarkScreen(sector: widget.sector),
      const SubsidyScreen(),
      const ExchangeScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.emerald.withValues(alpha: 0.15))),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.compare_arrows), label: 'Benchmark'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_outlined), activeIcon: Icon(Icons.account_balance), label: 'Subsidies'),
            BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Exchange'),
          ],
        ),
      ),
    );
  }
}
