import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/agua_life_game.dart';
import 'game/models/fish_selection.dart';
import 'game/models/game_hud_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AguaLifeApp());
}

class AguaLifeApp extends StatelessWidget {
  const AguaLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Agua Life',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF42C6F5),
      ),
      home: const AguaLifeScreen(),
    );
  }
}

class AguaLifeScreen extends StatefulWidget {
  const AguaLifeScreen({super.key});

  @override
  State<AguaLifeScreen> createState() => _AguaLifeScreenState();
}

class _AguaLifeScreenState extends State<AguaLifeScreen> {
  late final AguaLifeGame _game = AguaLifeGame();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071C28),
      body: Stack(
        fit: StackFit.expand,
        children: [
          GameWidget(game: _game),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: ValueListenableBuilder<GameHudState>(
                    valueListenable: _game.hud,
                    builder: (context, state, _) => _AquariumHud(state: state),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ValueListenableBuilder<FishSelection?>(
                    valueListenable: _game.selectedFish,
                    builder: (context, fish, _) {
                      if (fish == null) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _FishInspector(fish: fish),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: ValueListenableBuilder<GameHudState>(
                    valueListenable: _game.hud,
                    builder: (context, state, _) {
                      return _BottomControls(
                        food: state.food,
                        onFeed: () {
                          final fed = _game.feedFish();
                          if (!fed && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sem comida no estoque.'),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AquariumHud extends StatelessWidget {
  const _AquariumHud({required this.state});

  final GameHudState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xD9163445),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x665DE5FF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Agua Life',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              _InfoChip(
                icon: Icons.monetization_on_rounded,
                label: '${state.coins}',
              ),
              const SizedBox(width: 7),
              _InfoChip(
                icon: Icons.set_meal_rounded,
                label: '${state.fishCount}',
              ),
              const SizedBox(width: 7),
              _InfoChip(
                icon: Icons.rice_bowl_rounded,
                label: '${state.food}',
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _StatusMeter(
                  label: 'Fome',
                  value: state.averageHunger,
                  icon: Icons.restaurant_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatusMeter(
                  label: 'Saúde',
                  value: state.averageHealth,
                  icon: Icons.favorite_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FishInspector extends StatelessWidget {
  const _FishInspector({required this.fish});

  final FishSelection fish;

  @override
  Widget build(BuildContext context) {
    final growth = (fish.growthProgress * 100).round();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xE51A3545),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x884DE5FF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.water_rounded,
                size: 18,
                color: Color(0xFF75E9FF),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  fish.speciesName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (fish.shimmer)
                const _TraitBadge(label: 'Raro ✦')
              else
                _TraitBadge(label: fish.patternLabel),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: _TinyStat(
                  label: 'Crescimento',
                  value: '$growth%',
                ),
              ),
              Expanded(
                child: _TinyStat(
                  label: 'Corpo',
                  value: '${fish.bodyScale.toStringAsFixed(2)}×',
                ),
              ),
              Expanded(
                child: _TinyStat(
                  label: 'Nadadeiras',
                  value: '${fish.finScale.toStringAsFixed(2)}×',
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: _StatusMeter(
                  label: 'Fome',
                  value: fish.hunger,
                  icon: Icons.restaurant_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatusMeter(
                  label: 'Saúde',
                  value: fish.health,
                  icon: Icons.favorite_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TraitBadge extends StatelessWidget {
  const _TraitBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xAA28566A),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TinyStat extends StatelessWidget {
  const _TinyStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFB8D4DF),
            fontSize: 10,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x882A5265),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFFFD55A)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _StatusMeter extends StatelessWidget {
  const _StatusMeter({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final double value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0, 1).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFFC9F5FF)),
            const SizedBox(width: 4),
            Text(
              '$label ${(safeValue * 100).round()}%',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: safeValue,
            minHeight: 6,
            backgroundColor: const Color(0x66314A57),
            color: const Color(0xFF60E5D0),
          ),
        ),
      ],
    );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({required this.food, required this.onFeed});

  final int food;
  final VoidCallback onFeed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xDB102B3A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x554EDAF2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: food > 0 ? onFeed : null,
              icon: const Icon(Icons.restaurant_rounded),
              label: Text('Alimentar  ($food)'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: null,
            tooltip: 'Loja — em desenvolvimento',
            icon: const Icon(Icons.storefront_rounded),
          ),
          const SizedBox(width: 6),
          IconButton.filledTonal(
            onPressed: null,
            tooltip: 'Peixes — em desenvolvimento',
            icon: const Icon(Icons.pets_rounded),
          ),
        ],
      ),
    );
  }
}
