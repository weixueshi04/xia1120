import 'package:flutter_test/flutter_test.dart';
import 'package:xiaapp/services/farm_game_service.dart';

void main() {
  group('FarmGameService', () {
    final service = FarmGameService();

    test('should create initial farm state with assets', () {
      final state = service.createInitialState();
      expect(state.funds, greaterThan(0));
      expect(state.assets.keys, containsAll(['blueberry', 'irrigation']));
      expect(state.totalYieldPerTick, greaterThan(0));
    });

    test('applyTick should increase funds and day', () {
      final state = service.createInitialState();
      final next = service.applyTick(state);

      expect(next.day, state.day + 1);
      expect(next.funds, greaterThan(state.funds));
    });

    test('upgradeAsset should consume funds and increase level when affordable',
        () {
      var state = service.createInitialState();
      final original = state.assets['blueberry']!;

      state = state.copyWith(funds: 10000); // ensure enough funds
      final next = service.upgradeAsset(state, 'blueberry');
      final upgraded = next.assets['blueberry']!;

      expect(upgraded.level, original.level + 1);
      expect(next.funds, lessThan(state.funds));
    });

    test('upgradeAsset should do nothing when funds are insufficient', () {
      var state = service.createInitialState();
      // 强制设置资金不足以升级
      state = state.copyWith(funds: 0);
      final original = state.assets['blueberry']!;

      final next = service.upgradeAsset(state, 'blueberry');
      final upgraded = next.assets['blueberry']!;

      expect(upgraded.level, original.level);
      expect(next.funds, state.funds);
    });
  });
}
