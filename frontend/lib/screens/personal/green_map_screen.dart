import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/map_zone_model.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class GreenMapScreen extends StatefulWidget {
  const GreenMapScreen({super.key});

  @override
  State<GreenMapScreen> createState() => _GreenMapScreenState();
}

class _GreenMapScreenState extends State<GreenMapScreen> {
  static const LatLng _goaCenter = LatLng(15.4000, 73.9000);

  bool _loading = true;
  String? _error;
  int? _selectedHotspot;
  List<_CoinHotspot> _hotspots = const [];

  @override
  void initState() {
    super.initState();
    _loadHeatmapData();
  }

  Future<void> _loadHeatmapData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      List<_CoinHotspot> hotspots;
      try {
        final densityPoints = await ApiService.getUserDensityPoints();
        final raw = densityPoints
            .where((p) => p.users > 0)
            .map(
              (p) => _CoinHotspot(
                point: LatLng(p.latitude, p.longitude),
                users: p.users,
                coinTotal: p.coinTotal,
                city: p.city,
              ),
            )
            .toList();
        hotspots = _clusterByRadius(raw, radiusKm: 10);
      } catch (_) {
        // Graceful fallback for older backends where /map/user-density is missing.
        hotspots = await _loadLegacyHotspotsFromCityMatches();
      }

      hotspots.sort((a, b) => b.users.compareTo(a.users));
      if (!mounted) return;
      setState(() {
        _hotspots = hotspots;
        _selectedHotspot = hotspots.isEmpty ? null : 0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<List<_CoinHotspot>> _loadLegacyHotspotsFromCityMatches() async {
    final results = await Future.wait([
      ApiService.getMapZones(),
      ApiService.getLeaderboard(limit: 100),
    ]);
    final zones = results[0] as List<MapZoneModel>;
    final users = results[1] as List<UserModel>;
    final groupedUsers = <String, int>{};
    for (final user in users) {
      final city = user.city.trim();
      if (city.isEmpty) continue;
      groupedUsers[city] = (groupedUsers[city] ?? 0) + 1;
    }

    final hotspots = <_CoinHotspot>[];
    for (final zone in zones) {
      final zoneLower = zone.name.toLowerCase();
      int usersInZone = 0;
      for (final entry in groupedUsers.entries) {
        final cityLower = entry.key.toLowerCase();
        if (zoneLower == cityLower ||
            zoneLower.contains(cityLower) ||
            cityLower.contains(zoneLower)) {
          usersInZone = entry.value;
          break;
        }
      }
      if (usersInZone == 0) continue;
      hotspots.add(
        _CoinHotspot(
          point: _zoneToLatLng(zone),
          users: usersInZone,
          coinTotal: 0,
          city: zone.name,
        ),
      );
    }
    return hotspots;
  }

  List<_CoinHotspot> _clusterByRadius(
    List<_CoinHotspot> points, {
    required double radiusKm,
  }) {
    final clusters = <_CoinHotspot>[];
    for (final p in points) {
      int match = -1;
      for (int i = 0; i < clusters.length; i++) {
        final d = const Distance().as(
          LengthUnit.Kilometer,
          p.point,
          clusters[i].point,
        );
        if (d <= radiusKm) {
          match = i;
          break;
        }
      }
      if (match == -1) {
        clusters.add(p);
      } else {
        final c = clusters[match];
        clusters[match] = _CoinHotspot(
          point: LatLng(
            (c.point.latitude + p.point.latitude) / 2,
            (c.point.longitude + p.point.longitude) / 2,
          ),
          users: c.users + p.users,
          coinTotal: c.coinTotal + p.coinTotal,
          city: c.city ?? p.city,
        );
      }
    }
    return clusters;
  }

  LatLng _zoneToLatLng(MapZoneModel zone) {
    const minLat = 14.92;
    const maxLat = 15.82;
    const minLng = 73.67;
    const maxLng = 74.25;
    final lat = minLat + (maxLat - minLat) * zone.positionY;
    final lng = minLng + (maxLng - minLng) * zone.positionX;
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg1,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Green Map',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Leaflet density heatmap of active users',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _buildMapBody(),
                    ),
                  ),
                ),
              ),
              if (!_loading && _error == null && _hotspots.isNotEmpty)
                _buildInfoPanel(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.emerald),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Failed to load map data',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loadHeatmapData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_hotspots.isEmpty) {
      return const Center(
        child: Text(
          'No Supabase user location points available.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    final maxCoins = _hotspots
        .map((h) => h.coinTotal)
        .fold<double>(0, (prev, curr) => curr > prev ? curr : prev);
    final heatCircles = <CircleMarker>[];
    for (final hotspot in _hotspots) {
      final weight = maxCoins <= 0
          ? 0.1
          : (hotspot.coinTotal / maxCoins).clamp(0.1, 1.0);
      final zoneColor = weight >= 0.66
          ? AppTheme.emerald
          : weight >= 0.33
          ? AppTheme.accentAmber
          : AppTheme.accentRed;
      heatCircles.addAll([
        CircleMarker(
          point: hotspot.point,
          useRadiusInMeter: true,
          radius: 3600 + (5600 * weight),
          color: zoneColor.withValues(alpha: 0.14 * weight),
          borderStrokeWidth: 0,
        ),
        CircleMarker(
          point: hotspot.point,
          useRadiusInMeter: true,
          radius: 2200 + (3800 * weight),
          color: zoneColor.withValues(alpha: 0.23 * weight),
          borderStrokeWidth: 0,
        ),
        CircleMarker(
          point: hotspot.point,
          useRadiusInMeter: true,
          radius: 1100 + (1800 * weight),
          color: zoneColor.withValues(alpha: 0.34 * weight),
          borderStrokeWidth: 0,
        ),
      ]);
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: _goaCenter,
        initialZoom: 9.7,
        minZoom: 8.2,
        maxZoom: 15,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.aitd_hackathon.app',
        ),
        CircleLayer(circles: heatCircles),
        MarkerLayer(
          markers: _hotspots.asMap().entries.map((entry) {
            final index = entry.key;
            final hotspot = entry.value;
            final selected = index == _selectedHotspot;
            return Marker(
              point: hotspot.point,
              width: 34,
              height: 34,
              child: GestureDetector(
                onTap: () => setState(() => _selectedHotspot = index),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? AppTheme.emerald
                        : AppTheme.surface,
                    border: Border.all(
                      color: selected ? AppTheme.bg1 : AppTheme.lime,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    hotspot.coinTotal.toStringAsFixed(0),
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInfoPanel() {
    final hotspot = _hotspots[_selectedHotspot ?? 0];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: GlassCard(
        borderColor: AppTheme.emerald.withValues(alpha: 0.55),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.emerald.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: AppTheme.accentRed,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotspot.city ?? 'Unknown area',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Users: ${hotspot.users} • Coins in 10km: ${hotspot.coinTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              hotspot.coinTotal.toStringAsFixed(0),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinHotspot {
  final LatLng point;
  final int users;
  final double coinTotal;
  final String? city;

  const _CoinHotspot({
    required this.point,
    required this.users,
    required this.coinTotal,
    required this.city,
  });
}
