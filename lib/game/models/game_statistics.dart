class GameStatistics {
  int fishSold = 0;
  int fishTrashed = 0;
  int fishCured = 0;
  int moneyEarned = 0;
  int moneySpent = 0;
  int foodGiven = 0;
  double playSeconds = 0;
  int topFishPrice = 0;
  int magicFishBred = 0;
  int totalFishBred = 0;

  double get averageMoneyPerFish => fishSold == 0 ? 0 : moneyEarned / fishSold;
  double get hoursPlayed => playSeconds / 3600;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'fishSold': fishSold,
        'fishTrashed': fishTrashed,
        'fishCured': fishCured,
        'moneyEarned': moneyEarned,
        'moneySpent': moneySpent,
        'foodGiven': foodGiven,
        'playSeconds': playSeconds,
        'topFishPrice': topFishPrice,
        'magicFishBred': magicFishBred,
        'totalFishBred': totalFishBred,
      };

  static GameStatistics fromJson(Map<String, dynamic>? json) {
    final stats = GameStatistics();
    if (json == null) return stats;
    stats
      ..fishSold = _asInt(json['fishSold'])
      ..fishTrashed = _asInt(json['fishTrashed'])
      ..fishCured = _asInt(json['fishCured'])
      ..moneyEarned = _asInt(json['moneyEarned'])
      ..moneySpent = _asInt(json['moneySpent'])
      ..foodGiven = _asInt(json['foodGiven'])
      ..playSeconds = _asDouble(json['playSeconds'])
      ..topFishPrice = _asInt(json['topFishPrice'])
      ..magicFishBred = _asInt(json['magicFishBred'])
      ..totalFishBred = _asInt(json['totalFishBred']);
    return stats;
  }

  static int _asInt(dynamic value) => value is num ? value.toInt() : 0;
  static double _asDouble(dynamic value) => value is num ? value.toDouble() : 0;
}
