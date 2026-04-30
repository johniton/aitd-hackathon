import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'mode_select_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateAsUser(UserModel user) async {
    await ApiService.setUserId(user.id);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => ChangeNotifierProvider(
          create: (_) => AppState(userId: user.id),
          child: const ModeSelectScreen(),
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 40, 28, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🌱', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    const Text(
                      'GoaGreen',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 32, fontWeight: FontWeight.w800, height: 1.1),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Track your carbon footprint,\nearn rewards, and help Goa go green.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: AppTheme.emerald,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelColor: AppTheme.bg1,
                        unselectedLabelColor: AppTheme.textSecondary,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: 'Log In'),
                          Tab(text: 'Register'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _LoginTab(onLogin: _navigateAsUser),
                    _RegisterTab(onRegister: _navigateAsUser),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Login Tab ───────────────────────────────────────────────────────────────

class _LoginTab extends StatefulWidget {
  final void Function(UserModel) onLogin;
  const _LoginTab({required this.onLogin});

  @override
  State<_LoginTab> createState() => _LoginTabState();
}

class _LoginTabState extends State<_LoginTab> {
  final _nameCtrl = TextEditingController();
  bool _searching = false;
  String _error = '';
  List<UserModel> _results = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter your name to search');
      return;
    }
    setState(() { _searching = true; _error = ''; _results = []; });
    try {
      final users = await ApiService.searchUsers(name);
      setState(() {
        _results = users;
        _searching = false;
        if (users.isEmpty) _error = 'No account found for "$name"';
      });
    } catch (e) {
      setState(() { _error = e.toString(); _searching = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Name', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: 'e.g. Priya Sharma',
                    hintStyle: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.textSecondary.withValues(alpha: 0.2))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.textSecondary.withValues(alpha: 0.2))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.emerald)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _searching ? null : _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emerald,
                    foregroundColor: AppTheme.bg1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  child: _searching
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: AppTheme.bg1, strokeWidth: 2))
                      : const Icon(Icons.search),
                ),
              ),
            ],
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_error, style: const TextStyle(color: AppTheme.warning, fontSize: 13)),
          ],
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Select your account', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            ..._results.map((u) => _UserTile(user: u, onTap: () => widget.onLogin(u))),
          ],
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  const _UserTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.emeraldGradient),
              alignment: Alignment.center,
              child: Text(user.avatarInitials, style: const TextStyle(color: AppTheme.bg1, fontSize: 15, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                  Text('📍 ${user.city}  •  🌿 ${user.totalCo2Saved.toStringAsFixed(1)} kg saved', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppTheme.emerald, size: 14),
          ],
        ),
      ),
    );
  }
}

// ─── Register Tab ────────────────────────────────────────────────────────────

class _RegisterTab extends StatefulWidget {
  final void Function(UserModel) onRegister;
  const _RegisterTab({required this.onRegister});

  @override
  State<_RegisterTab> createState() => _RegisterTabState();
}

class _RegisterTabState extends State<_RegisterTab> {
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  bool _loading = false;
  String _error = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required');
      return;
    }
    setState(() { _loading = true; _error = ''; });
    try {
      final user = await ApiService.register(name, city);
      widget.onRegister(user);
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildField('Your Name', _nameCtrl, 'e.g. Priya Sharma'),
          const SizedBox(height: 16),
          _buildField('City', _cityCtrl, 'e.g. Panaji'),
          const SizedBox(height: 28),
          if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error, style: const TextStyle(color: AppTheme.warning, fontSize: 13)),
            ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emerald,
                foregroundColor: AppTheme.bg1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: AppTheme.bg1, strokeWidth: 2))
                  : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.5)),
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.textSecondary.withValues(alpha: 0.2))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.textSecondary.withValues(alpha: 0.2))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.emerald)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
