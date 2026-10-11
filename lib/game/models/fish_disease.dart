enum FishDisease {
  none,
  ich,
  fungus,
}

extension FishDiseaseLabel on FishDisease {
  String get legacyLabel => switch (this) {
        FishDisease.none => 'HEALTHY',
        FishDisease.ich => 'ICK',
        FishDisease.fungus => 'FUNGUS',
      };
}
