import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/agua_life_game.dart';

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
      body: SafeArea(
        child: GameWidget(game: _game),
      ),
    );
  }
}
