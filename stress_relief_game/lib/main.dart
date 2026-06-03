import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() {
  runApp(const CalmPopApp());
}

class CalmPopApp extends StatelessWidget {
  const CalmPopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Calm Pop',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff12a594),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Arial',
        useMaterial3: true,
      ),
      home: const CalmPopGame(),
    );
  }
}

class CalmPopGame extends StatefulWidget {
  const CalmPopGame({super.key});

  @override
  State<CalmPopGame> createState() => _CalmPopGameState();
}

class _CalmPopGameState extends State<CalmPopGame>
    with SingleTickerProviderStateMixin {
  static const int _maxBubbles = 18;
  static const double _spawnEvery = 0.72;
  static const Duration _roundDuration = Duration(seconds: 90);

  final Random _random = Random();
  final List<CalmBubble> _bubbles = <CalmBubble>[];
  final List<CalmRipple> _ripples = <CalmRipple>[];

  late final Ticker _ticker;
  Size _boardSize = Size.zero;
  double _spawnTimer = 0;
  double _breathPhase = 0;
  double _timeLeft = _roundDuration.inSeconds.toDouble();
  int _score = 0;
  int _combo = 0;
  int _bestCombo = 0;
  bool _isRunning = true;
  DateTime? _lastFrame;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final DateTime now = DateTime.now();
    final double dt = _lastFrame == null
        ? 1 / 60
        : now.difference(_lastFrame!).inMicroseconds / 1000000;
    _lastFrame = now;

    if (!_isRunning) {
      setState(() => _breathPhase += dt * .24);
      return;
    }

    setState(() {
      _timeLeft = max(0, _timeLeft - dt);
      _breathPhase += dt * .24;
      _spawnTimer += dt;

      if (_boardSize != Size.zero &&
          _spawnTimer >= _spawnEvery &&
          _bubbles.length < _maxBubbles) {
        _spawnTimer = 0;
        _bubbles.add(_createBubble());
      }

      for (final CalmBubble bubble in _bubbles) {
        bubble.age += dt;
        bubble.center += bubble.velocity * dt;
        bubble.velocity = Offset(
          bubble.velocity.dx + sin(bubble.age * 1.8 + bubble.seed) * dt * 6,
          bubble.velocity.dy - dt * 2,
        );
      }

      _bubbles.removeWhere((CalmBubble bubble) {
        final bool isOffscreen = bubble.center.dy + bubble.radius < -24;
        if (isOffscreen) {
          _combo = max(0, _combo - 1);
        }
        return isOffscreen;
      });

      for (final CalmRipple ripple in _ripples) {
        ripple.age += dt;
      }
      _ripples.removeWhere((CalmRipple ripple) => ripple.age > ripple.life);

      if (_timeLeft <= 0) {
        _isRunning = false;
      }
    });
  }

  CalmBubble _createBubble() {
    final double radius = 26 + _random.nextDouble() * 34;
    final double x =
        radius + _random.nextDouble() * (_boardSize.width - radius * 2);
    final double y = _boardSize.height + radius + _random.nextDouble() * 80;
    final List<Color> colors = <Color>[
      const Color(0xff6debd0),
      const Color(0xffffd166),
      const Color(0xfff78fb3),
      const Color(0xff8ec5ff),
      const Color(0xffc5f277),
    ];

    return CalmBubble(
      center: Offset(x, y),
      radius: radius,
      color: colors[_random.nextInt(colors.length)],
      velocity: Offset(
        (_random.nextDouble() - .5) * 24,
        -42 - _random.nextDouble() * 42,
      ),
      seed: _random.nextDouble() * pi * 2,
    );
  }

  void _popBubble(Offset tapPosition) {
    if (!_isRunning) {
      return;
    }

    for (int i = _bubbles.length - 1; i >= 0; i--) {
      final CalmBubble bubble = _bubbles[i];
      final double distance = (tapPosition - bubble.center).distance;
      if (distance <= bubble.radius + 8) {
        setState(() {
          _bubbles.removeAt(i);
          _combo += 1;
          _bestCombo = max(_bestCombo, _combo);
          _score += 10 + (_combo * 2) + (bubble.radius < 38 ? 8 : 0);
          _ripples.add(
            CalmRipple(
              center: bubble.center,
              color: bubble.color,
              radius: bubble.radius,
            ),
          );
        });
        return;
      }
    }

    setState(() {
      _combo = 0;
      _ripples.add(
        CalmRipple(
          center: tapPosition,
          color: Colors.white.withOpacity(.55),
          radius: 22,
        ),
      );
    });
  }

  void _restart() {
    setState(() {
      _bubbles.clear();
      _ripples.clear();
      _spawnTimer = 0;
      _timeLeft = _roundDuration.inSeconds.toDouble();
      _score = 0;
      _combo = 0;
      _bestCombo = 0;
      _isRunning = true;
      _lastFrame = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          _boardSize = Size(constraints.maxWidth, constraints.maxHeight);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (TapDownDetails details) =>
                _popBubble(details.localPosition),
            child: Stack(
              children: <Widget>[
                CustomPaint(
                  size: _boardSize,
                  painter: CalmGamePainter(
                    bubbles: _bubbles,
                    ripples: _ripples,
                    breathPhase: _breathPhase,
                    timeProgress: _timeLeft / _roundDuration.inSeconds,
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                    child: Column(
                      children: <Widget>[
                        _GameHeader(
                          score: _score,
                          combo: _combo,
                          secondsLeft: _timeLeft.ceil(),
                          isRunning: _isRunning,
                          onRestart: _restart,
                        ),
                        const Spacer(),
                        if (!_isRunning)
                          _GameOverPanel(
                            score: _score,
                            bestCombo: _bestCombo,
                            onRestart: _restart,
                          ),
                        const SizedBox(height: 14),
                        _BreathBar(phase: _breathPhase),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GameHeader extends StatelessWidget {
  const _GameHeader({
    required this.score,
    required this.combo,
    required this.secondsLeft,
    required this.isRunning,
    required this.onRestart,
  });

  final int score;
  final int combo;
  final int secondsLeft;
  final bool isRunning;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Calm Pop',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                isRunning
                    ? 'Chạm bong bóng, thở chậm, giữ combo.'
                    : 'Ván chơi đã kết thúc.',
                style: TextStyle(
                  color: Colors.white.withOpacity(.72),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        _MetricPill(label: 'Điểm', value: '$score'),
        const SizedBox(width: 8),
        _MetricPill(label: 'Combo', value: 'x$combo'),
        const SizedBox(width: 8),
        FilledButton.tonalIcon(
          onPressed: onRestart,
          icon: const Icon(Icons.refresh_rounded),
          label: Text('${secondsLeft}s'),
        ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 74),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(.14)),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style:
                TextStyle(fontSize: 11, color: Colors.white.withOpacity(.64)),
          ),
        ],
      ),
    );
  }
}

class _BreathBar extends StatelessWidget {
  const _BreathBar({required this.phase});

  final double phase;

  @override
  Widget build(BuildContext context) {
    final double pulse = (sin(phase * pi * 2) + 1) / 2;
    final String text = pulse > .5 ? 'Hít vào' : 'Thở ra';

    return Container(
      height: 54,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.24),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(.12)),
      ),
      child: Row(
        children: <Widget>[
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 34 + pulse * 18,
            height: 34 + pulse * 18,
            decoration: BoxDecoration(
              color: const Color(0xff6debd0).withOpacity(.22 + pulse * .28),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(.32)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                minHeight: 12,
                value: pulse,
                backgroundColor: Colors.white.withOpacity(.12),
                color: const Color(0xffffd166),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 62,
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameOverPanel extends StatelessWidget {
  const _GameOverPanel({
    required this.score,
    required this.bestCombo,
    required this.onRestart,
  });

  final int score;
  final int bestCombo;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff102c34).withOpacity(.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Tâm trí nhẹ hơn rồi.',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text('Điểm: $score  |  Combo tốt nhất: x$bestCombo'),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRestart,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Chơi lại'),
          ),
        ],
      ),
    );
  }
}

class CalmGamePainter extends CustomPainter {
  CalmGamePainter({
    required this.bubbles,
    required this.ripples,
    required this.breathPhase,
    required this.timeProgress,
  });

  final List<CalmBubble> bubbles;
  final List<CalmRipple> ripples;
  final double breathPhase;
  final double timeProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..isAntiAlias = true;
    final Rect bounds = Offset.zero & size;

    paint.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        Color(0xff09333d),
        Color(0xff173f57),
        Color(0xff275a53),
      ],
    ).createShader(bounds);
    canvas.drawRect(bounds, paint);

    _drawWaveGrid(canvas, size);
    _drawTimeGlow(canvas, size);

    for (final CalmRipple ripple in ripples) {
      final double t = (ripple.age / ripple.life).clamp(0, 1);
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 + (1 - t) * 5
        ..shader = null
        ..color = ripple.color.withOpacity((1 - t) * .55);
      canvas.drawCircle(ripple.center, ripple.radius + t * 72, paint);
    }

    for (final CalmBubble bubble in bubbles) {
      final double wobble = sin(bubble.age * 3 + bubble.seed) * 2.4;
      final Offset center = bubble.center + Offset(wobble, 0);
      final double radius = bubble.radius + sin(bubble.age * 2.2) * 1.8;

      paint
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          center: const Alignment(-.35, -.35),
          radius: .9,
          colors: <Color>[
            Colors.white.withOpacity(.86),
            bubble.color.withOpacity(.76),
            bubble.color.withOpacity(.14),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);

      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = null
        ..color = Colors.white.withOpacity(.34);
      canvas.drawCircle(center, radius, paint);
    }
  }

  void _drawWaveGrid(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(.06);
    final Path path = Path();
    final double phase = breathPhase * pi * 2;

    for (double y = 100; y < size.height; y += 78) {
      path.reset();
      path.moveTo(0, y);
      for (double x = 0; x <= size.width; x += 18) {
        path.lineTo(x, y + sin(x / 48 + phase + y / 90) * 9);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawTimeGlow(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = null
      ..color = const Color(0xffffd166).withOpacity(.2);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * timeProgress.clamp(0, 1), 4),
      paint,
    );
  }

  @override
  bool shouldRepaint(CalmGamePainter oldDelegate) => true;
}

class CalmBubble {
  CalmBubble({
    required this.center,
    required this.radius,
    required this.color,
    required this.velocity,
    required this.seed,
  });

  Offset center;
  final double radius;
  final Color color;
  Offset velocity;
  final double seed;
  double age = 0;
}

class CalmRipple {
  CalmRipple({
    required this.center,
    required this.color,
    required this.radius,
  });

  final Offset center;
  final Color color;
  final double radius;
  final double life = .72;
  double age = 0;
}
