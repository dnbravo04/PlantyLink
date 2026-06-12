import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/phone_utils.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../app.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _cargando        = false;
  bool _usingPhone      = false;
  String? _error;

  late AnimationController _heroAnim;
  late Animation<double>   _heroFade;
  late Animation<Offset>   _heroSlide;

  @override
  void initState() {
    super.initState();
    _heroAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _heroFade  = CurvedAnimation(parent: _heroAnim, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _heroAnim, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _heroAnim.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Email/password ─────────────────────────────────────────────────────────
  Future<void> _signInWithEmail() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Completa todos los campos');
      return;
    }
    _setLoading(true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email, password: password,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _mapAuthError(e.code));
    } finally {
      _setLoading(false);
    }
  }

  // ── Phone ──────────────────────────────────────────────────────────────────
  Future<void> _signInWithPhone() async {
    final phone = _emailController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Ingresa tu número de teléfono');
      return;
    }
    _setLoading(true);
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: formatPhoneNumber(phone),
      verificationCompleted: (PhoneAuthCredential cred) async {
        await FirebaseAuth.instance.signInWithCredential(cred);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() { _error = _mapAuthError(e.code); _cargando = false; });
      },
      codeSent: (String verificationId, int? _) {
        setState(() => _cargando = false);
        Navigator.pushNamed(context, AppRoutes.onboardingOtp, arguments: {
          'verificationId': verificationId,
          'phoneNumber': phone,
          'isLogin': true,
        });
      },
      codeAutoRetrievalTimeout: (_) => setState(() => _cargando = false),
    );
  }

  // ── Google ─────────────────────────────────────────────────────────────────
  Future<void> _signInWithGoogle() async {
    _setLoading(true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) { _setLoading(false); return; }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      // Widget may be disposed by AuthGate rebuilding on auth success — stop here.
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _mapAuthError(e.code));
    } catch (_) {
      if (mounted) setState(() => _error = 'Error al iniciar con Google');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool v) { if (mounted) setState(() => _cargando = v); }

  String _mapAuthError(String code) => switch (code) {
    'invalid-email'        => 'Correo inválido',
    'user-not-found'       => 'No existe una cuenta con este correo',
    'wrong-password'       => 'Contraseña incorrecta',
    'invalid-credential'   => 'Credenciales incorrectas',
    'too-many-requests'    => 'Demasiados intentos. Intenta más tarde',
    'invalid-phone-number' => 'Número de teléfono inválido',
    _                      => 'Algo salió mal. Intenta de nuevo',
  };

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _buildGradientBackground(c),
          SafeArea(
            child: Column(
              children: [
                _buildHero(c),
                Expanded(child: _buildFormSheet(c)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero section ───────────────────────────────────────────────────────────
  Widget _buildGradientBackground(AppColorScheme c) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: c.isDark
              ? [const Color(0xFF0A2218), const Color(0xFF07110E)]
              : [const Color(0xFF059669), const Color(0xFF10B981)],
        ),
      ),
      child: Center(
        child: Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                c.primary.withValues(alpha: c.isDark ? 0.25 : 0.35),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(AppColorScheme c) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.38,
      child: FadeTransition(
        opacity: _heroFade,
        child: SlideTransition(
          position: _heroSlide,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.25),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.energy_savings_leaf_rounded,
                  size: 44,
                  color: c.isDark ? c.primary : Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'PlantyLink',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: c.isDark ? c.textPrimary : Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Conecta y cuida tu cultivo',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: c.isDark
                      ? c.textSecondary
                      : Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Form sheet ─────────────────────────────────────────────────────────────
  Widget _buildFormSheet(AppColorScheme c) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Iniciar sesión',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22, fontWeight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _usingPhone ? 'Usa tu número de teléfono' : 'Usa tu correo electrónico',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: c.textMuted,
              ),
            ),
            const SizedBox(height: 24),

            // Input field
            TextField(
              controller: _emailController,
              keyboardType: _usingPhone
                  ? TextInputType.phone
                  : TextInputType.emailAddress,
              style: TextStyle(color: c.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                labelText: _usingPhone ? 'Número de teléfono' : 'Correo electrónico',
                prefixIcon: Icon(
                  _usingPhone ? Icons.phone_outlined : Icons.mail_outline_rounded,
                ),
              ),
            ),

            if (!_usingPhone) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: TextStyle(color: c.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
            ],

            // Error message
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: c.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: c.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: c.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Primary CTA
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _cargando
                    ? null
                    : (_usingPhone ? _signInWithPhone : _signInWithEmail),
                style: FilledButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: Colors.white,
                ),
                child: _cargando
                    ? const SizedBox(
                        height: 22, width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white,
                        ),
                      )
                    : const Text('Iniciar sesión'),
              ),
            ),

            const SizedBox(height: 20),

            // Divider
            Row(children: [
              Expanded(child: Divider(color: c.cardBorder, thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'o continúa con',
                  style: TextStyle(color: c.textMuted, fontSize: 12),
                ),
              ),
              Expanded(child: Divider(color: c.cardBorder, thickness: 1)),
            ]),

            const SizedBox(height: 16),

            // Google sign-in button (full width)
            _SocialButton(
              onPressed: _cargando ? null : _signInWithGoogle,
              label: 'Continuar con Google',
              logo: _GoogleLogo(),
              borderColor: c.cardBorder,
              backgroundColor: c.cardBackground,
              textColor: c.textPrimary,
            ),

            const SizedBox(height: 20),

            // Toggle phone / email
            Center(
              child: TextButton(
                onPressed: () => setState(() {
                  _usingPhone = !_usingPhone;
                  _error = null;
                  _emailController.clear();
                }),
                child: Text(
                  _usingPhone
                      ? 'Usar correo electrónico'
                      : 'Usar número de teléfono',
                  style: TextStyle(color: c.primary, fontSize: 13),
                ),
              ),
            ),

            // Register link
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '¿No tienes cuenta? ',
                    style: TextStyle(color: c.textMuted, fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(
                        context, AppRoutes.onboardingVinculacion),
                    child: Text(
                      'Regístrate',
                      style: TextStyle(
                        color: c.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Social button ─────────────────────────────────────────────────────────────
class _SocialButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final Widget logo;
  final Color borderColor;
  final Color backgroundColor;
  final Color textColor;

  const _SocialButton({
    required this.onPressed,
    required this.label,
    required this.logo,
    required this.borderColor,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            logo,
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20, height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 2,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF4285F4),
          ),
        ),
      ),
    );
  }
}
