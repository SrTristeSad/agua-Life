import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pixel-art splash and main menu shown before the legacy 352x416 game frame.
class PixelLandingScreen extends StatefulWidget {
  const PixelLandingScreen({
    super.key,
    required this.gameBuilder,
    required this.newGameBuilder,
  });

  final WidgetBuilder gameBuilder;
  final WidgetBuilder newGameBuilder;

  @override
  State<PixelLandingScreen> createState() => _PixelLandingScreenState();
}

class _PixelLandingScreenState extends State<PixelLandingScreen> {
  late final Future<ui.Image> _atlas = _loadAtlas();
  bool _showSplash = true;

  // Runtime menu atlas is intentionally tiny and scaled with nearest-neighbor.
  // This keeps the presentation close to the Java-era pixel aesthetic.
  static const Rect _logo = Rect.fromLTWH(2, 2, 66, 27);
  static const Rect _continueButton = Rect.fromLTWH(2, 29, 46, 13);
  static const Rect _newGameButton = Rect.fromLTWH(48, 29, 46, 13);
  static const Rect _helpButton = Rect.fromLTWH(2, 42, 23, 9);
  static const Rect _aboutButton = Rect.fromLTWH(24, 42, 22, 9);
  static const Rect _creditsButton = Rect.fromLTWH(47, 42, 22, 9);
  static const Rect _optionsButton = Rect.fromLTWH(69, 42, 25, 9);

  Future<ui.Image> _loadAtlas() async {
    final data = await rootBundle.load('assets/images/pixel/menu_atlas.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF031B31),
      body: FutureBuilder<ui.Image>(
        future: _atlas,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final atlas = snapshot.data!;
          return _showSplash ? _splash(atlas) : _menu(atlas);
        },
      ),
    );
  }

  Widget _splash(ui.Image atlas) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _showSplash = false),
      child: _oceanBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _AtlasSlice(atlas: atlas, source: _logo, height: 176),
              ),
              const Spacer(),
              const _PixelCaption('VIRTUAL AQUARIUM TYCOON', size: 18),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0xE6FF9F16),
                  border: Border.all(color: const Color(0xFFFFD25C), width: 3),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Color(0xAA001A32), offset: Offset(0, 5)),
                  ],
                ),
                child: const _PixelCaption('TOQUE PARA INICIAR', size: 18),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menu(ui.Image atlas) {
    return _oceanBackdrop(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                children: [
                  _AtlasSlice(atlas: atlas, source: _logo, height: 160),
                  const Spacer(),
                  _MenuAtlasButton(
                    atlas: atlas,
                    source: _continueButton,
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: widget.gameBuilder),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _MenuAtlasButton(
                    atlas: atlas,
                    source: _newGameButton,
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: widget.newGameBuilder),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MenuAtlasButton(
                          atlas: atlas,
                          source: _helpButton,
                          onTap: () => _dialog(
                            'AJUDA',
                            'Alimente os peixes, cuide da saúde, use o tanque de isolamento e descubra novas espécies pela reprodução.',
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: _MenuAtlasButton(
                          atlas: atlas,
                          source: _aboutButton,
                          onTap: () => _dialog(
                            'SOBRE',
                            'Agua Life reconstrói para celulares atuais a experiência clássica de aquário em Java, com código e arte novos.',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _MenuAtlasButton(
                          atlas: atlas,
                          source: _creditsButton,
                          onTap: () => _dialog(
                            'CRÉDITOS',
                            'Agua Life • desenvolvimento independente.',
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: _MenuAtlasButton(
                          atlas: atlas,
                          source: _optionsButton,
                          onTap: () => _dialog(
                            'OPÇÕES',
                            'Música, som e velocidade continuam disponíveis dentro do jogo.',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 2),
                  const _PixelCaption('ARTE PIXEL • BUILD DE TESTE', size: 11),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _oceanBackdrop({required Widget child}) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0B8FE8),
            Color(0xFF0868B8),
            Color(0xFF03335E),
            Color(0xFF021B33),
          ],
          stops: [0, 0.35, 0.72, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const IgnorePointer(child: _BubbleBackdrop()),
          child,
        ],
      ),
    );
  }

  Future<void> _dialog(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF07345D),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFF45C8FF), width: 3),
          borderRadius: BorderRadius.circular(8),
        ),
        title: _PixelCaption(title, size: 18),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFFFFD452),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuAtlasButton extends StatelessWidget {
  const _MenuAtlasButton({
    required this.atlas,
    required this.source,
    required this.onTap,
  });

  final ui.Image atlas;
  final Rect source;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _AtlasSlice(
        atlas: atlas,
        source: source,
        height: source.width > 30 ? 74 : 58,
      ),
    );
  }
}

class _AtlasSlice extends StatelessWidget {
  const _AtlasSlice({
    required this.atlas,
    required this.source,
    required this.height,
  });

  final ui.Image atlas;
  final Rect source;
  final double height;

  @override
  Widget build(BuildContext context) {
    final aspect = source.width / source.height;
    return SizedBox(
      height: height,
      width: height * aspect,
      child: CustomPaint(
        painter: _AtlasPainter(atlas: atlas, source: source),
      ),
    );
  }
}

class _AtlasPainter extends CustomPainter {
  const _AtlasPainter({required this.atlas, required this.source});

  final ui.Image atlas;
  final Rect source;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      atlas,
      source,
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(covariant _AtlasPainter oldDelegate) {
    return oldDelegate.atlas != atlas || oldDelegate.source != source;
  }
}

class _PixelCaption extends StatelessWidget {
  const _PixelCaption(this.text, {required this.size});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: size,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
          shadows: const [
            Shadow(color: Color(0xFF001B36), offset: Offset(2, 2)),
            Shadow(color: Color(0xFF001B36), offset: Offset(-1, -1)),
          ],
        ),
      );
}

class _BubbleBackdrop extends StatelessWidget {
  const _BubbleBackdrop();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _BubblePainter());
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0x669BEAFF);
    const bubbles = <(double, double, double)>[
      (0.08, 0.16, 11),
      (0.15, 0.32, 6),
      (0.90, 0.18, 9),
      (0.83, 0.42, 5),
      (0.11, 0.70, 8),
      (0.92, 0.78, 12),
      (0.72, 0.09, 5),
      (0.31, 0.13, 4),
    ];
    for (final bubble in bubbles) {
      canvas.drawCircle(
        Offset(size.width * bubble.$1, size.height * bubble.$2),
        bubble.$3,
        stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
