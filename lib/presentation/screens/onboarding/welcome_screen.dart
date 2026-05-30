import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_color_scheme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _iconAnim;
  late Animation<double>   _iconFloat;

  static const _pages = [
    _OnboardingData(
      icon:        Icons.water_drop_rounded,
      title:       'Tu cultivo,\nsiempre contigo',
      description: 'Monitorea pH, temperatura, conductividad y niveles de agua en tiempo real, las 24 horas del día.',
      gradientDark:  [Color(0xFF0A2A1C), Color(0xFF07110E)],
      gradientLight: [Color(0xFF059669), Color(0xFF047857)],
      iconColor:   Color(0xFF34D399),
      accentColor: Color(0xFF10B981),
    ),
    _OnboardingData(
      icon:        Icons.tune_rounded,
      title:       'Control total\nen tiempo real',
      description: 'Activa bombas, ajusta dosificaciones y responde a alertas desde cualquier lugar.',
      gradientDark:  [Color(0xFF1C1A08), Color(0xFF07110E)],
      gradientLight: [Color(0xFFD97706), Color(0xFFB45309)],
      iconColor:   Color(0xFFFBBF24),
      accentColor: Color(0xFFF59E0B),
    ),
    _OnboardingData(
      icon:        Icons.nfc_rounded,
      title:       'Conecta con\nun toque',
      description: 'Vincula tu ESP32 con NFC en segundos y configura perfiles de cultivo personalizados.',
      gradientDark:  [Color(0xFF081824), Color(0xFF07110E)],
      gradientLight: [Color(0xFF0891B2), Color(0xFF0E7490)],
      iconColor:   Color(0xFF67E8F9),
      accentColor: Color(0xFF22D3EE),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _iconAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _iconFloat = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _iconAnim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _iconAnim.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/onboarding/esp32');
    }
  }

  void _skip() => Navigator.pushReplacementNamed(context, '/onboarding/esp32');

  @override
  Widget build(BuildContext context) {
    final c    = AppColors.of(context);
    final page = _pages[_currentPage];

    return PopScope(
      canPop: false,
      child: Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: c.isDark ? page.gradientDark : page.gradientLight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 20, 0),
                  child: TextButton(
                    onPressed: _skip,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withValues(alpha: 0.7),
                    ),
                    child: Text(
                      'Saltar',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) =>
                      _buildPage(_pages[index], c, index == _currentPage),
                ),
              ),

              // Bottom controls
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 36),
                child: Column(
                  children: [
                    // Pill indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        final isActive = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 6,
                          width: isActive ? 28 : 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 28),

                    // Next/Start button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: page.accentColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _currentPage == _pages.length - 1
                              ? 'Comenzar'
                              : 'Siguiente',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildPage(_OnboardingData page, AppColorScheme c, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Floating icon with radial glow
          AnimatedBuilder(
            animation: _iconFloat,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, isActive ? _iconFloat.value : 0),
              child: child,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow ring
                Container(
                  width: 180, height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        page.iconColor.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // Icon container
                Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: page.iconColor.withValues(alpha: 0.3),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    page.icon,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                // Orbit ring
                _OrbitRing(color: page.iconColor),
              ],
            ),
          ),

          const SizedBox(height: 48),

          Text(
            page.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            page.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.80),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Orbit ring decoration ─────────────────────────────────────────────────────
class _OrbitRing extends StatefulWidget {
  final Color color;
  const _OrbitRing({required this.color});

  @override
  State<_OrbitRing> createState() => _OrbitRingState();
}

class _OrbitRingState extends State<_OrbitRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.rotate(
        angle: _ctrl.value * 2 * math.pi,
        child: child,
      ),
      child: SizedBox(
        width: 150, height: 150,
        child: CustomPaint(painter: _OrbitPainter(color: widget.color)),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  final Color color;
  const _OrbitPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Dashed orbit ring
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 12; i++) {
      final startAngle = (i * 2 * math.pi / 12);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        math.pi / 18,
        false,
        paint,
      );
    }

    // Dot on orbit
    final dotAngle = 0.0;
    final dotX = center.dx + radius * math.cos(dotAngle);
    final dotY = center.dy + radius * math.sin(dotAngle);
    canvas.drawCircle(
      Offset(dotX, dotY),
      5,
      Paint()..color = color.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.color != color;
}

// ── Data class ────────────────────────────────────────────────────────────────
class _OnboardingData {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradientDark;
  final List<Color> gradientLight;
  final Color iconColor;
  final Color accentColor;

  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradientDark,
    required this.gradientLight,
    required this.iconColor,
    required this.accentColor,
  });
}
