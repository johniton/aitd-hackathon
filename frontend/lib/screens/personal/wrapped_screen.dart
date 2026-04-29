import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class WrappedScreen extends StatefulWidget {
  const WrappedScreen({super.key});

  @override
  State<WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends State<WrappedScreen> {
  final _controller = PageController();
  int _page = 0;
  bool _isLoading = true;
  String _error = '';
  List<_WrappedPage> _pages = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final stats = await ApiService.getWrapped();
      setState(() {

        _pages = [
          _WrappedPage(
            bg: const LinearGradient(colors: [Color(0xFF064E3B), Color(0xFF065F46)]),
            emoji: '🌍',
            headline: '${stats['co2Saved']} kg',
            subtitle: 'of CO₂ saved\nthis year',
            accent: AppTheme.emerald,
          ),
          _WrappedPage(
            bg: const LinearGradient(colors: [Color(0xFF1A3A1A), Color(0xFF2D5A2D)]),
            emoji: '🌳',
            headline: '${stats['treesEquivalent']} trees',
            subtitle: 'worth of carbon absorbed\nin 2025',
            accent: AppTheme.lime,
          ),
          _WrappedPage(
            bg: const LinearGradient(colors: [Color(0xFF1C1A0A), Color(0xFF3B3500)]),
            emoji: '🏆',
            headline: 'Top ${100 - (stats['percentile'] as num).toInt()}%',
            subtitle: 'Most eco-conscious users\nin Goa',
            accent: const Color(0xFFFACC15),
          ),
          _WrappedPage(
            bg: const LinearGradient(colors: [Color(0xFF0A0F1A), Color(0xFF0D1A3A)]),
            emoji: '🚲',
            headline: '${stats['topCategory']}',
            subtitle: 'Your greenest category\nthis year',
            accent: const Color(0xFF60A5FA),
          ),
          _WrappedPage(
            bg: const LinearGradient(colors: [Color(0xFF1A0A0F), Color(0xFF3A0D1A)]),
            emoji: '🔥',
            headline: '${stats['activitiesLogged']}',
            subtitle: 'eco actions logged\nKeep it up!',
            accent: const Color(0xFFF97316),
          ),
        ];
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
  void dispose() {
    _controller.dispose();
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
              Text('Error: $_error', style: const TextStyle(color: Colors.red)),
              TextButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _pages.length,
            itemBuilder: (_, i) => _WrappedPageWidget(data: _pages[i]),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.white70),
                  ),
                  const Spacer(),
                  Row(
                    children: List.generate(_pages.length, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _page == i ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _page == i ? Colors.white : Colors.white38,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    )),
                  ),
                  const Spacer(),
                  if (_page == _pages.length - 1)
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                        child: const Text('Share 📤', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () => _controller.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut),
                      child: const Icon(Icons.chevron_right, color: Colors.white70),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WrappedPage {
  final LinearGradient bg;
  final String emoji;
  final String headline;
  final String subtitle;
  final Color accent;

  const _WrappedPage({
    required this.bg,
    required this.emoji,
    required this.headline,
    required this.subtitle,
    required this.accent,
  });
}

class _WrappedPageWidget extends StatefulWidget {
  final _WrappedPage data;
  const _WrappedPageWidget({required this.data});

  @override
  State<_WrappedPageWidget> createState() => _WrappedPageWidgetState();
}

class _WrappedPageWidgetState extends State<_WrappedPageWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: widget.data.bg),
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.data.emoji, style: const TextStyle(fontSize: 80)),
                  const SizedBox(height: 32),
                  Text(
                    widget.data.headline,
                    style: TextStyle(
                      color: widget.data.accent,
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.data.subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 20, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
