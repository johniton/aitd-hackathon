import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import 'squad_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _squadOnly = false;
  List<UserModel> _leaderboard = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await ApiService.getLeaderboard(limit: 20);
      setState(() {
        _leaderboard = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.bg1,
        body: Center(child: CircularProgressIndicator(color: AppTheme.emerald)),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.bg1,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error', style: const TextStyle(color: AppTheme.accentRed)),
              TextButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final topThree = _leaderboard.take(3).toList();
    final rest = _leaderboard.skip(3).toList();

    return Scaffold(
      backgroundColor: AppTheme.bg1,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: AppTheme.emerald,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Leaderboard',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() => _squadOnly = !_squadOnly);
                            if (_squadOnly) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SquadScreen(),
                                ),
                              );
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: _squadOnly
                                  ? AppTheme.emerald.withValues(alpha: 0.2)
                                  : AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _squadOnly
                                    ? AppTheme.emerald
                                    : AppTheme.emerald.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              '👥 Squad',
                              style: TextStyle(
                                color: _squadOnly
                                    ? AppTheme.emerald
                                    : AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _Podium(topThree: topThree),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((_, i) {
                    final user = rest[i];
                    final isMe = user.id == ApiService.currentUserId;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: GlassCard(
                        borderColor: isMe
                            ? AppTheme.emerald.withValues(alpha: 0.5)
                            : null,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 28,
                              child: Text(
                                '#${user.rank}',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            _Avatar(initials: user.avatarInitials, size: 36),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        user.name,
                                        style: TextStyle(
                                          color: isMe
                                              ? AppTheme.emerald
                                              : AppTheme.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.emerald.withValues(
                                              alpha: 0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: const Text(
                                            'You',
                                            style: TextStyle(
                                              color: AppTheme.emerald,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        '🔥 ${user.streakDays}d streak',
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '📍 ${user.city}',
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${user.totalCo2Saved.toStringAsFixed(0)} kg',
                                  style: const TextStyle(
                                    color: AppTheme.emerald,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '🪙 ${user.greenCoins.toInt()}',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }, childCount: rest.length),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<UserModel> topThree;
  const _Podium({required this.topThree});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (topThree.length > 1)
            _PodiumSlot(user: topThree[1], position: 2, height: 80),
          if (topThree.isNotEmpty)
            _PodiumSlot(user: topThree[0], position: 1, height: 110),
          if (topThree.length > 2)
            _PodiumSlot(user: topThree[2], position: 3, height: 60),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final UserModel user;
  final int position;
  final double height;
  const _PodiumSlot({
    required this.user,
    required this.position,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    const medals = ['🥇', '🥈', '🥉'];
    return Column(
      children: [
        _Avatar(initials: user.avatarInitials, size: position == 1 ? 52 : 42),
        const SizedBox(height: 6),
        Text(
          user.name.split(' ').first,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '${user.totalCo2Saved.toStringAsFixed(0)}kg',
          style: const TextStyle(color: AppTheme.emerald, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(medals[position - 1], style: const TextStyle(fontSize: 22)),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: position == 1
                  ? [
                      AppTheme.emerald.withValues(alpha: 0.4),
                      AppTheme.emerald.withValues(alpha: 0.1),
                    ]
                  : [AppTheme.surface, AppTheme.surface.withValues(alpha: 0.5)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          alignment: Alignment.center,
          child: Text(
            '#$position',
            style: TextStyle(
              color: position == 1 ? AppTheme.emerald : AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  final double size;
  const _Avatar({required this.initials, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.emeraldGradient,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: AppTheme.bg1,
          fontSize: size * 0.35,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
