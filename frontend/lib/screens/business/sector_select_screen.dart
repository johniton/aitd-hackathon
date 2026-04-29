import 'package:flutter/material.dart';
import '../../models/business_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import 'business_shell.dart';

class SectorSelectScreen extends StatelessWidget {
  const SectorSelectScreen({super.key});

  static const _sectors = [
    _SectorInfo(BusinessSector.tourism, '🏖️', 'Tourism', 'Beach shacks, hotels, tour operators'),
    _SectorInfo(BusinessSector.cashew, '🌰', 'Cashew', 'Processing, roasting, export'),
    _SectorInfo(BusinessSector.farmer, '🌾', 'Farmer', 'Paddy, horticulture, spices'),
    _SectorInfo(BusinessSector.bakery, '🍞', 'Bakery', 'Pão de Goa, confectionery'),
    _SectorInfo(BusinessSector.other, '⚙️', 'Other', 'Custom business profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg1,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                const Text('Business Mode', style: TextStyle(color: AppTheme.emerald, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1)),
                const SizedBox(height: 8),
                const Text('Select your\nsector', style: TextStyle(color: AppTheme.textPrimary, fontSize: 32, fontWeight: FontWeight.w700, height: 1.2)),
                const SizedBox(height: 32),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: _sectors.map((s) => _SectorCard(
                      sector: s,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BusinessShell(sector: s.sector))),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectorInfo {
  final BusinessSector sector;
  final String emoji;
  final String title;
  final String description;
  const _SectorInfo(this.sector, this.emoji, this.title, this.description);
}

class _SectorCard extends StatelessWidget {
  final _SectorInfo sector;
  final VoidCallback onTap;
  const _SectorCard({required this.sector, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.emerald.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(child: Text(sector.emoji, style: const TextStyle(fontSize: 32))),
            ),
            const SizedBox(height: 12),
            Text(sector.title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(sector.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11), textAlign: TextAlign.center, maxLines: 2),
          ],
        ),
      ),
    );
  }
}
