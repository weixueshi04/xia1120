import '../models/farm_models.dart';

/// 麻江农场经营小游戏核心逻辑
class FarmGameService {
  /// 创建一个初始农场状态
  FarmState createInitialState() {
    final assets = <String, FarmAsset>{
      'blueberry': const FarmAsset(
        id: 'blueberry',
        name: '蓝莓种植',
        level: 1,
        maxLevel: 5,
        baseCost: 100,
        costGrowth: 1.5,
        yieldPerTick: 10,
      ),
      'irrigation': const FarmAsset(
        id: 'irrigation',
        name: '智能灌溉',
        level: 0,
        maxLevel: 3,
        baseCost: 150,
        costGrowth: 1.8,
        yieldPerTick: 15,
      ),
    };

    return FarmState(
      funds: 200,
      day: 1,
      assets: assets,
    );
  }

  /// 模拟时间流逝一单位（例如一天或若干分钟）
  FarmState applyTick(FarmState state) {
    final newFunds = state.funds + state.totalYieldPerTick;
    return state.copyWith(
      funds: newFunds,
      day: state.day + 1,
    );
  }

  /// 尝试升级指定资产，如果资金不足则返回原状态
  FarmState upgradeAsset(FarmState state, String assetId) {
    final asset = state.assets[assetId];
    if (asset == null) return state;
    if (asset.level >= asset.maxLevel) return state;

    final cost = asset.nextLevelCost();
    if (state.funds < cost) return state;

    final updatedAsset = asset.levelUp();
    final updatedAssets = Map<String, FarmAsset>.from(state.assets)
      ..[assetId] = updatedAsset;

    return state.copyWith(
      funds: state.funds - cost,
      assets: updatedAssets,
    );
  }
}

