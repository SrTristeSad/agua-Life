enum GameSpeed {
  slow,
  normal,
  fast,
  paused,
}

extension GameSpeedLegacy on GameSpeed {
  String get label => switch (this) {
        GameSpeed.slow => 'SLOW',
        GameSpeed.normal => 'NORMAL',
        GameSpeed.fast => 'FAST',
        GameSpeed.paused => 'PAUSED',
      };

  int get legacyMinutesPerAge => switch (this) {
        GameSpeed.slow => 15,
        GameSpeed.normal => 10,
        GameSpeed.fast => 5,
        GameSpeed.paused => 10000,
      };

  double get simulationMultiplier => switch (this) {
        GameSpeed.slow => 2 / 3,
        GameSpeed.normal => 1,
        GameSpeed.fast => 2,
        GameSpeed.paused => 0,
      };
}

class GameSettings {
  GameSettings({
    this.music = true,
    this.sound = true,
    this.helpMessages = true,
    this.speed = GameSpeed.normal,
  });

  bool music;
  bool sound;
  bool helpMessages;
  GameSpeed speed;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'music': music,
        'sound': sound,
        'helpMessages': helpMessages,
        'speed': speed.name,
      };

  static GameSettings fromJson(Map<String, dynamic>? json) {
    if (json == null) return GameSettings();
    final speedName = json['speed'] as String?;
    var speed = GameSpeed.normal;
    for (final candidate in GameSpeed.values) {
      if (candidate.name == speedName) {
        speed = candidate;
        break;
      }
    }
    return GameSettings(
      music: json['music'] is bool ? json['music'] as bool : true,
      sound: json['sound'] is bool ? json['sound'] as bool : true,
      helpMessages: json['helpMessages'] is bool ? json['helpMessages'] as bool : true,
      speed: speed,
    );
  }
}
