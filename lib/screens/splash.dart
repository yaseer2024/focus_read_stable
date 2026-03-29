import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainFadeController;
  late Animation<double> _mainFadeIn;
  late AnimationController _textController;
  late AnimationController _captionController;
  late AnimationController _pageController;

  late Animation<Offset> _focusSlide;
  late Animation<Offset> _readSlide;
  late Animation<double> _fadeIn;
  late Animation<double> _letterSpacing;
  late Animation<double> _fadeOut;
  late Animation<double> _frFadeIn;
  late Animation<double> _frScale;
  late Animation<double> _pageTurn;

  bool showFR = false;
  String displayedCaption = '';
  final String fullCaption = 'Focus • Read • Grow';

  static const _bgDark = Color(0xFF0B1120);
  static const _bgDarkSurf = Color(0xFF141E30);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textMuted = Color(0xFF9CA3AF);

  @override
  void initState() {
    super.initState();

    _mainFadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _mainFadeIn = CurvedAnimation(parent: _mainFadeController, curve: Curves.easeIn);

    _textController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _captionController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _pageController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

    _focusSlide = Tween<Offset>(begin: const Offset(-1.5, 0), end: Offset.zero).animate(
        CurvedAnimation(parent: _textController, curve: const Interval(0.0, 0.25, curve: Curves.easeOutCubic)));

    _readSlide = Tween<Offset>(begin: const Offset(1.5, 0), end: Offset.zero).animate(
        CurvedAnimation(parent: _textController, curve: const Interval(0.0, 0.25, curve: Curves.easeOutCubic)));

    _fadeIn = CurvedAnimation(parent: _textController, curve: const Interval(0.0, 0.2, curve: Curves.easeOut));

    _letterSpacing = Tween<double>(begin: 12.0, end: -8.0).animate(
        CurvedAnimation(parent: _textController, curve: const Interval(0.35, 0.65, curve: Curves.easeInOutCubic)));

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _textController, curve: const Interval(0.65, 0.8, curve: Curves.easeOut)));

    _frFadeIn = CurvedAnimation(parent: _textController, curve: const Interval(0.75, 0.95, curve: Curves.easeIn));

    _frScale = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _textController, curve: const Interval(0.75, 0.95, curve: Curves.easeOutBack)));

    _pageTurn = CurvedAnimation(parent: _pageController, curve: Curves.easeInOutQuart);

    _captionController.addListener(_updateCaption);
    _startSequence();
  }

  void _updateCaption() {
    final progress = _captionController.value;
    final targetLength = (fullCaption.length * progress).round();
    if (displayedCaption.length != targetLength) {
      setState(() => displayedCaption = fullCaption.substring(0, targetLength));
    }
  }

  Future<void> _startSequence() async {
    _mainFadeController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _captionController.forward();
    await Future.delayed(const Duration(milliseconds: 1400));
    setState(() => showFR = true);
    await Future.delayed(const Duration(milliseconds: 800));
    _pageController.forward();
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => const HomeScreen(),
      transitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
    ));
  }

  @override
  void dispose() {
    _mainFadeController.dispose();
    _textController.dispose();
    _captionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: FadeTransition(
        opacity: _mainFadeIn,
        child: Stack(
          children: [
            // Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF111827), _bgDark],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Subtle Silver Radial Glow
            Center(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Colors.white.withOpacity(0.05), Colors.transparent],
                  ),
                ),
              ),
            ),

            // Main Content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 180,
                    child: AnimatedBuilder(
                      animation: _textController,
                      builder: (_, __) {
                        return Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            if (!showFR)
                              Opacity(
                                opacity: _fadeIn.value * _fadeOut.value,
                                child: OverflowBox(
                                  maxWidth: double.infinity,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SlideTransition(position: _focusSlide, child: Text('Focus', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w300, letterSpacing: _letterSpacing.value, color: _textPrimary))),
                                      SizedBox(width: (12 + _letterSpacing.value).clamp(0.0, 24.0)),
                                      SlideTransition(position: _readSlide, child: Text('Read', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w300, letterSpacing: _letterSpacing.value, color: _textPrimary))),
                                    ],
                                  ),
                                ),
                              ),

                            // METALLIC SILVER FR LOGO
                            if (showFR)
                              FadeTransition(
                                opacity: _frFadeIn,
                                child: Transform.scale(
                                  scale: _frScale.value,
                                  child: ShaderMask(
                                    shaderCallback: (bounds) => const LinearGradient(
                                      colors: [
                                        Color(0xFF4B5563), // Dark Steel
                                        Color(0xFFD1D5DB), // Light Silver
                                        Color(0xFFF9FAFB), // White Shine
                                        Color(0xFF9CA3AF), // Medium Gray
                                        Color(0xFF374151), // Deep Shadow
                                      ],
                                      stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(bounds),
                                    child: const Text(
                                      'FR',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 120,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 4,
                                        color: Colors.white,
                                        height: 1.0,
                                        fontFamily: 'serif',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(displayedCaption, style: const TextStyle(fontSize: 13, letterSpacing: 4, color: _textMuted, fontWeight: FontWeight.w300)),
                ],
              ),
            ),

            // Page Turn Transition
            AnimatedBuilder(
              animation: _pageTurn,
              builder: (_, __) {
                final progress = _pageTurn.value;
                if (progress <= 0) return const SizedBox.shrink();
                return Stack(
                  children: [
                    if (progress > 0.15)
                      Positioned.fill(child: Opacity(opacity: ((progress - 0.15) / 0.85).clamp(0.0, 1.0), child: Container(color: _bgDark))),
                    Positioned.fill(
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: (1 - progress).clamp(0.0, 1.0),
                          child: Transform(
                            alignment: Alignment.centerRight,
                            transform: Matrix4.identity()..setEntry(3, 2, 0.0006)..rotateY(-math.pi / 2 * progress),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [_bgDark, Color.lerp(_bgDarkSurf, const Color(0xFF0D1525), progress)!]),
                              ),
                              child: CustomPaint(painter: _PageShadowPainter(progress)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PageShadowPainter extends CustomPainter {
  final double progress;
  _PageShadowPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.05) return;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.black.withOpacity(0), Colors.black.withOpacity(0.4 * progress), Colors.black.withOpacity(0.6 * progress)],
        begin: Alignment.centerLeft, end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }
  @override
  bool shouldRepaint(_PageShadowPainter old) => old.progress != progress;
}