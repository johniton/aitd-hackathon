import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'leaderboard_screen.dart';
import 'green_map_screen.dart';
import 'house_game_screen.dart';
import 'profile_screen.dart';
import 'sensor_tracker_screen.dart';

class PersonalShell extends StatefulWidget {
  const PersonalShell({super.key});

  @override
  State<PersonalShell> createState() => _PersonalShellState();
}

class _PersonalShellState extends State<PersonalShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    LeaderboardScreen(),
    GreenMapScreen(),
    HouseGameScreen(),
    ProfileScreen(),
    SensorTrackerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isSensors = _index == 5;
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(
              color: isSensors
                  ? AppTheme.emerald.withValues(alpha: 0.45)
                  : AppTheme.emerald.withValues(alpha: 0.15),
              width: isSensors ? 1.5 : 1.0,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard_outlined),
              activeIcon: Icon(Icons.leaderboard),
              label: 'Ranks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'House',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sensors_outlined),
              activeIcon: Icon(Icons.sensors),
              label: 'Sensors',
            ),
          ],
        ),
      ),
    );
  }
}
