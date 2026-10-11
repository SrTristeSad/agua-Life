class GameHudState {
  const GameHudState({
    required this.coins,
    required this.food,
    required this.fishCount,
    required this.averageHunger,
    required this.averageHealth,
  });

  final int coins;
  final int food;
  final int fishCount;
  final double averageHunger;
  final double averageHealth;

  static const empty = GameHudState(
    coins: 0,
    food: 0,
    fishCount: 0,
    averageHunger: 1,
    averageHealth: 1,
  );
}
