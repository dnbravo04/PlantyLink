import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/phone_utils.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_color_scheme.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/common/brand_mark.dart';
import '../../app.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _cargando        = false;
  bool _usingPhone      = false;
  String? _error;

  late AnimationController _entryAnim;
  late Animation<double>   _logoFade;
  late Animation<double>   _formFade;
  late Animation<Offset>   _formSlide;

  @override
  void initState() {
    super.initState();
    _entryAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _logoFade = CurvedAnimation(
      parent: _entryAnim,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _formFade = CurvedAnimation(
      parent: _entryAnim,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryAnim,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));
  }

  @override
  void dispose() {
    _entryAnim.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Validation ──────────────────────────────────────────────────────────────
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final _phoneRegex = RegExp(r'^\+?[0-9\s\-()]{7,15}$');

  // ── Email/password ─────────────────────────────────────────────────────────
  Future<void> _signInWithEmail() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      setState(() => _error = 'Ingresa un correo electrónico válido');
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = 'Ingresa tu contraseña');
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
    if (phone.isEmpty || !_phoneRegex.hasMatch(phone)) {
      setState(() => _error = 'Ingresa un número de teléfono válido');
      return;
    }
    _setLoading(true);
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: formatPhoneNumber(phone),
      verificationCompleted: (PhoneAuthCredential cred) async {
        await FirebaseAuth.instance.signInWithCredential(cred);
        // Dismiss the OTP screen if it was already pushed; AuthGate
        // takes over routing once the auth state changes.
        if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
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
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _mapAuthError(e.code));
    } catch (_) {
      if (mounted) setState(() => _error = 'Error al iniciar con Google');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      setState(() => _error = 'Ingresa un correo válido para recuperar la contraseña');
      return;
    }
    _setLoading(true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        setState(() => _error = null);
        AppToast.show(context,
            message: 'Se envió un enlace de recuperación a $email',
            type: ToastType.success);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _mapAuthError(e.code));
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.06),
              _buildLogo(c),
              const SizedBox(height: 40),
              _buildFormCard(c),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Logo ───────────────────────────────────────────────────────────────────
  Widget _buildLogo(AppColorScheme c) {
    return FadeTransition(
      opacity: _logoFade,
      child: Column(
        children: [
          const BrandMark(logoSize: 84, wordmarkWidth: 210, spacing: 14),
          const SizedBox(height: 12),
          Text(
            'Conecta y cuida tu cultivo',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: c.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ── Form card ──────────────────────────────────────────────────────────────
  Widget _buildFormCard(AppColorScheme c) {
    return FadeTransition(
      opacity: _formFade,
      child: SlideTransition(
        position: _formSlide,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: c.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: c.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: c.isDark ? 0.2 : 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Iniciar sesión',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _usingPhone
                    ? 'Ingresa tu número de teléfono'
                    : 'Ingresa tus credenciales',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: c.textMuted,
                ),
              ),
              const SizedBox(height: 24),

              // ── Method toggle (segmented style) ──
              _AuthMethodToggle(
                isPhone: _usingPhone,
                colors: c,
                onToggle: () => setState(() {
                  _usingPhone = !_usingPhone;
                  _error = null;
                  _emailController.clear();
                  _passwordController.clear();
                }),
              ),
              const SizedBox(height: 20),

              // ── Input fields ──
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
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _cargando ? null : _resetPassword,
                    child: Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(color: c.primary, fontSize: 12),
                    ),
                  ),
                ),
              ],

              // ── Error ──
              if (_error != null) ...[
                const SizedBox(height: 8),
                _ErrorBanner(error: _error!, colors: c),
              ],

              const SizedBox(height: 20),

              // ── Primary CTA ──
              _PrimaryButton(
                label: 'Iniciar sesión',
                loading: _cargando,
                onPressed: _usingPhone ? _signInWithPhone : _signInWithEmail,
                colors: c,
              ),

              const SizedBox(height: 20),

              // ── Divider ──
              Row(children: [
                Expanded(child: Divider(color: c.cardBorder, thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'o continúa con',
                    style: TextStyle(color: c.textMuted, fontSize: 12),
                  ),
                ),
                Expanded(child: Divider(color: c.cardBorder, thickness: 1)),
              ]),

              const SizedBox(height: 20),

              // ── Google sign-in ──
              _GoogleSignInButton(
                loading: _cargando,
                onPressed: _signInWithGoogle,
                colors: c,
              ),

              const SizedBox(height: 24),

              // ── Register link ──
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
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared auth widgets — used by both LoginScreen and VinculacionScreen
// ═══════════════════════════════════════════════════════════════════════════════

/// Segmented toggle between email and phone auth.
class _AuthMethodToggle extends StatelessWidget {
  final bool isPhone;
  final AppColorScheme colors;
  final VoidCallback onToggle;

  const _AuthMethodToggle({
    required this.isPhone,
    required this.colors,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: c.isDark
            ? c.background
            : c.cardBorder.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTab(
            label: 'Correo',
            icon: Icons.mail_outline_rounded,
            selected: !isPhone,
            c: c,
            onTap: isPhone ? onToggle : null,
          ),
          _buildTab(
            label: 'Teléfono',
            icon: Icons.phone_outlined,
            selected: isPhone,
            c: c,
            onTap: !isPhone ? onToggle : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required IconData icon,
    required bool selected,
    required AppColorScheme c,
    required VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? c.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [BoxShadow(
                    color: c.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : c.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : c.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated primary CTA button.
class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;
  final AppColorScheme colors;

  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: c.primary.withValues(alpha: 0.5),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: loading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  height: 22, width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white,
                  ),
                )
              : Text(label, key: ValueKey(label)),
        ),
      ),
    );
  }
}

/// Error banner with icon.
class _ErrorBanner extends StatelessWidget {
  final String error;
  final AppColorScheme colors;

  const _ErrorBanner({required this.error, required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: c.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: c.error, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// Google sign-in button with official SVG logo.
class _GoogleSignInButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;
  final AppColorScheme colors;

  const _GoogleSignInButton({
    required this.loading,
    required this.onPressed,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Material(
      color: c.isDark ? c.cardBackground : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.cardBorder, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'lib/core/theme/Google logo.svg',
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Continuar con Google',
                style: GoogleFonts.plusJakartaSans(
                  color: c.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
