import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class SquadScreen extends StatefulWidget {
  const SquadScreen({super.key});

  @override
  State<SquadScreen> createState() => _SquadScreenState();
}

class _SquadScreenState extends State<SquadScreen> {
  bool _isLoading = true;
  String _error = '';
  List<UserModel> _squadMembers = [];
  final List<_SquadGroup> _groups = [];
  final Set<String> _selectedIds = {};
  final TextEditingController _groupNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final leaderboard = await ApiService.getLeaderboard(limit: 4);
      setState(() {
        _squadMembers = leaderboard;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<String> _suggestedActivitiesFor(List<UserModel> members) {
    final activities = <String>[
      'Carpool to college/work 3 days this week',
      'Host a no-plastic grocery run challenge',
      'Do a 5km cycle/walk Sunday squad ride',
      'Run a home energy audit and reduce AC runtime by 1 hour/day',
      'Start a compost corner challenge in your neighborhood',
    ];
    if (members.any((m) => m.city.toLowerCase().contains('panaji'))) {
      activities.add('Take Panaji-Betim ferry + public bus challenge day');
    }
    return activities.take(3).toList();
  }

  void _createGroup() {
    final name = _groupNameController.text.trim();
    if (name.isEmpty || _selectedIds.isEmpty) return;
    final members = _squadMembers
        .where((m) => _selectedIds.contains(m.id))
        .toList();
    setState(() {
      _groups.insert(
        0,
        _SquadGroup(
          name: name,
          members: members,
          suggestions: _suggestedActivitiesFor(members),
        ),
      );
      _groupNameController.clear();
      _selectedIds.clear();
    });
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
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

    final totalSaved = _squadMembers.fold(
      0.0,
      (sum, u) => sum + u.totalCo2Saved,
    );

    return Scaffold(
      backgroundColor: AppTheme.bg1,
      appBar: AppBar(
        title: const Text('My Squad'),
        backgroundColor: AppTheme.bg1,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GlassCard(
              child: Column(
                children: [
                  const Text(
                    'Squad CO₂ Saved',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${totalSaved.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      color: AppTheme.emerald,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Combined this month',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ..._squadMembers.map(
              (u) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.emeraldGradient,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          u.avatarInitials,
                          style: const TextStyle(
                            color: AppTheme.bg1,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u.name,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '🔥 ${u.streakDays}d  📍 ${u.city}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${u.totalCo2Saved.toStringAsFixed(0)} kg',
                        style: const TextStyle(
                          color: AppTheme.emerald,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Create Squad Group',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            GlassCard(
              child: Column(
                children: [
                  TextField(
                    controller: _groupNameController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Group name (e.g. Green Warriors)',
                      hintStyle: TextStyle(color: AppTheme.textSecondary),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _squadMembers.map((u) {
                      final selected = _selectedIds.contains(u.id);
                      return FilterChip(
                        label: Text(u.name.split(' ').first),
                        selected: selected,
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _selectedIds.add(u.id);
                            } else {
                              _selectedIds.remove(u.id);
                            }
                          });
                        },
                        selectedColor: AppTheme.emerald.withValues(alpha: 0.25),
                        checkmarkColor: AppTheme.emerald,
                        labelStyle: TextStyle(
                          color: selected
                              ? AppTheme.emerald
                              : AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                        backgroundColor: AppTheme.surface,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  GradientButton(
                    label: 'Create Group + Suggest Activities',
                    onPressed: _createGroup,
                    icon: Icons.groups,
                    width: double.infinity,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ..._groups.map(
              (g) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  borderColor: AppTheme.emerald.withValues(alpha: 0.35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${g.members.length} members',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...g.suggestions.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '• ',
                                style: TextStyle(color: AppTheme.emerald),
                              ),
                              Expanded(
                                child: Text(
                                  s,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            GradientButton(
              label: '+ Invite Friends',
              onPressed: () {},
              icon: Icons.person_add,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}

class _SquadGroup {
  final String name;
  final List<UserModel> members;
  final List<String> suggestions;

  const _SquadGroup({
    required this.name,
    required this.members,
    required this.suggestions,
  });
}
