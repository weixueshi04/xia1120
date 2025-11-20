/// 农场中的可升级资产（种子、农机、灌溉等）
class FarmAsset {
  final String id;
  final String name;
  final int level;
  final int maxLevel;
  final double baseCost;
  final double costGrowth; // 每级成本倍数
  final double yieldPerTick; // 单位时间带来的基础收益

  const FarmAsset({
    required this.id,
    required this.name,
    required this.level,
    required this.maxLevel,
    required this.baseCost,
    required this.costGrowth,
    required this.yieldPerTick,
  });

  double nextLevelCost() {
    final factor = level <= 0 ? 1 : level;
    return baseCost * (costGrowth * factor);
  }

  FarmAsset levelUp() {
    if (level >= maxLevel) return this;
    return FarmAsset(
      id: id,
      name: name,
      level: level + 1,
      maxLevel: maxLevel,
      baseCost: baseCost,
      costGrowth: costGrowth,
      yieldPerTick: yieldPerTick,
    );
  }
}

/// 农场整体状态
class FarmState {
  final double funds;
  final int day;
  final Map<String, FarmAsset> assets;

  const FarmState({
    required this.funds,
    required this.day,
    required this.assets,
  });

  double get totalYieldPerTick {
    double total = 0;
    for (final asset in assets.values) {
      total += asset.yieldPerTick * asset.level;
    }
    return total;
  }

  FarmState copyWith({
    double? funds,
    int? day,
    Map<String, FarmAsset>? assets,
  }) {
    return FarmState(
      funds: funds ?? this.funds,
      day: day ?? this.day,
      assets: assets ?? this.assets,
    );
  }
}
