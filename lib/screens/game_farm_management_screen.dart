import 'dart:async';

import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/farm_models.dart';
import '../services/farm_game_service.dart';

class GameFarmManagementScreen extends StatefulWidget {
  const GameFarmManagementScreen({super.key});

  @override
  State<GameFarmManagementScreen> createState() =>
      _GameFarmManagementScreenState();
}

class _GameFarmManagementScreenState extends State<GameFarmManagementScreen> {
  final FarmGameService _service = FarmGameService();
  late FarmState _state;
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _state = _service.createInitialState();
    _tickTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        setState(() {
          _state = _service.applyTick(_state);
        });
      },
    );
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('麻江农场经营'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                MiaoTheme.indigoDye,
                MiaoTheme.indigoDye.withAlpha((0.8 * 255).round()),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              MiaoTheme.waxWhite,
              MiaoTheme.indigoDye.withAlpha((0.05 * 255).round()),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildDashboard(),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Expanded(child: _buildAssetList()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Text(
      '通过合理升级农场资产、提升产出，体验麻江蓝莓等特色产业的发展节奏。',
      style: TextStyle(
        fontSize: 13,
        color: MiaoTheme.silverThread,
        height: 1.4,
      ),
    );
  }

  Widget _buildDashboard() {
    final funds = _state.funds.toStringAsFixed(0);
    final yieldPerTick = _state.totalYieldPerTick.toStringAsFixed(0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildDashboardItem(
          label: '资金',
          value: '¥$funds',
          icon: Icons.savings,
        ),
        _buildDashboardItem(
          label: '天数',
          value: '${_state.day}',
          icon: Icons.calendar_today,
        ),
        _buildDashboardItem(
          label: '每日产出',
          value: '+$yieldPerTick',
          icon: Icons.grass,
        ),
      ],
    );
  }

  Widget _buildDashboardItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.7 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: MiaoTheme.indigoDye),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: MiaoTheme.silverThread,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: MiaoTheme.indigoDye,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssetList() {
    final assets = _state.assets.values.toList();

    return ListView.separated(
      itemCount: assets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final asset = assets[index];
        return _buildAssetCard(asset);
      },
    );
  }

  Widget _buildAssetCard(FarmAsset asset) {
    final isMaxLevel = asset.level >= asset.maxLevel;
    final cost = asset.nextLevelCost();
    final canUpgrade = !isMaxLevel && _state.funds >= cost;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.9 * 255).round()),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            asset.id == 'blueberry' ? Icons.local_florist : Icons.water_drop,
            color: asset.id == 'blueberry'
                ? Colors.blue[700]
                : Colors.teal[700],
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: MiaoTheme.indigoDye,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '等级：${asset.level}/${asset.maxLevel} · 产出：+${asset.yieldPerTick * asset.level}/天',
                  style: const TextStyle(
                    fontSize: 11,
                    color: MiaoTheme.silverThread,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isMaxLevel
                      ? '已满级'
                      : '下一级成本：¥${cost.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isMaxLevel
                        ? Colors.grey
                        : (canUpgrade ? Colors.green[700] : Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: canUpgrade ? () => _onUpgrade(asset.id) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canUpgrade ? MiaoTheme.indigoDye : Colors.grey,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              isMaxLevel ? '满级' : '升级',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _onUpgrade(String assetId) {
    setState(() {
      _state = _service.upgradeAsset(_state, assetId);
    });
  }
}

