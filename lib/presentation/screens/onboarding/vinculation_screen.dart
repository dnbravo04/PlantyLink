import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/phone_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../widgets/common/onboarding_step_indicator.dart';
import '../../../app.dart';

class VinculacionScreen extends StatefulWidget {
  const VinculacionScreen({super.key});

  @override
  State<VinculacionScreen> createState() => _VinculacionScreenState();
}

class _VinculacionScreenState extends State<VinculacionScreen>
    with TickerProviderStateMixin {
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool _usandoEmail      = true;
  bool _obscurePass      = true;
  bool _obscureConfirm   = true;
  bool _cargando         = false;
  String? _error;

  late AnimationController _entryAnim;
  late Animation<double>   _headerFade;
  late Animation<double>   _formFade;
  late Animation<Offset>   _formSlide;

  @override
  void initState() {
    super.initState();
    _entryAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _headerFade = CurvedAnimation(
      parent: _entryAnim,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _formFade = CurvedAnimation(
      parent: _entryAnim,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryAnim,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));
  }

  @override
  void dispose() {
    _entryAnim.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Validation ──────────────────────────────────────────────────────────────
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final _phoneRegex = RegExp(r'^\+?[0-9\s\-()]{7,15}$');

  // ── Auth logic ─────────────────────────────────────────────────────────────
  Future<void> _continuar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      if (_usandoEmail) {
        final email = _emailCtrl.text.trim();
        if (email.isEmpty || !_emailRegex.hasMatch(email)) {
          setState(() { _error = 'Ingresa un correo electrónico válido'; _cargando = false; });
          return;
        }
        final pass    = _passCtrl.text;
        final confirm = _confirmCtrl.text;
        if (pass.length < 6) {
          setState(() { _error = 'La contraseña debe tener al menos 6 caracteres'; _cargando = false; });
          return;
        }
        if (pass != confirm) {
          setState(() { _error = 'Las contraseñas no coinciden'; _cargando = false; });
          return;
        }
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email, password: pass,
        );
        if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.onboardingPerfil);
      } else {
        final phone = _emailCtrl.text.trim();
        if (phone.isEmpty || !_phoneRegex.hasMatch(phone)) {
          setState(() { _error = 'Ingresa un número de teléfono válido'; _cargando = false; });
          return;
        }
        await _verifyPhone(phone);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _mapError(e.code));
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _verifyPhone(String phone) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: formatPhoneNumber(phone),
      verificationCompleted: (PhoneAuthCredential cred) async {
        await FirebaseAuth.instance.signInWithCredential(cred);
        if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.onboardingPerfil);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() { _error = _mapError(e.code); _cargando = false; });
      },
      codeSent: (String verificationId, int? _) {
        setState(() => _cargando = false);
        Navigator.pushNamed(context, AppRoutes.onboardingOtp, arguments: {
          'verificationId': verificationId,
          'phoneNumber': phone,
        });
      },
      codeAutoRetrievalTimeout: (_) => setState(() => _cargando = false),
    );
  }

  String _mapError(String code) => switch (code) {
    'invalid-email'        => 'Correo inválido',
    'weak-password'        => 'Contraseña muy débil',
    'email-already-in-use' => 'Este correo ya tiene una cuenta',
    'invalid-phone-number' => 'Número de teléfono inválido',
    'too-many-requests'    => 'Demasiados intentos. Intenta más tarde',
    _                      => 'Algo salió mal. Intenta de nuevo',
  };

  int _passwordStrength(String p) {
    int score = 0;
    if (p.length >= 6)  score++;
    if (p.length >= 10) score++;
    if (p.contains(RegExp(r'[0-9]'))) score++;
    if (p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score++;
    return score;
  }

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
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              _buildHeader(c),
              const SizedBox(height: 28),
              _buildFormCard(c),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorScheme c) {
    return FadeTransition(
      opacity: _headerFade,
      child: Column(
        children: [
          // Back button
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pushReplacementNamed(context, '/login'),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.primary.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: c.primary,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Icon
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.primary, c.success],
              ),
              boxShadow: [
                BoxShadow(
                  color: c.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              size: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Crear cuenta',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Únete a la comunidad PlantyLink',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: c.textMuted,
            ),
          ),
        ],
      ),
    );
  }

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
              // Step indicator
              OnboardingStepIndicator(currentStep: 1, colors: c),
              const SizedBox(height: 24),

              // ── Method toggle ──
              _AuthMethodToggle(
                isPhone: !_usandoEmail,
                colors: c,
                onToggle: () => setState(() {
                  _usandoEmail = !_usandoEmail;
                  _error = null;
                  _emailCtrl.clear();
                  _passCtrl.clear();
                  _confirmCtrl.clear();
                }),
              ),
              const SizedBox(height: 20),

              // ── Input fields ──
              TextField(
                controller: _emailCtrl,
                keyboardType: _usandoEmail
                    ? TextInputType.emailAddress
                    : TextInputType.phone,
                style: TextStyle(color: c.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  labelText: _usandoEmail ? 'Correo electrónico' : 'Número de teléfono',
                  prefixIcon: Icon(_usandoEmail
                      ? Icons.mail_outline_rounded
                      : Icons.phone_outlined),
                ),
              ),

              if (_usandoEmail) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(color: c.textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                ),
                _PasswordStrengthBar(
                  strength: _passwordStrength(_passCtrl.text),
                  password: _passCtrl.text,
                  colors: c,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  style: TextStyle(color: c.textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                ),
              ],

              // ── Error ──
              if (_error != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(error: _error!, colors: c),
              ],

              const SizedBox(height: 24),

              // ── CTA ──
              _PrimaryButton(
                label: 'Crear cuenta',
                loading: _cargando,
                onPressed: _continuar,
                colors: c,
              ),

              const SizedBox(height: 20),

              // ── Login link ──
              Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('¿Ya tienes cuenta? ',
                      style: TextStyle(color: c.textMuted, fontSize: 13)),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    child: Text(
                      'Inicia sesión',
                      style: TextStyle(
                        color: c.primary, fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared widgets (duplicated from login_screen.dart to keep screens independent)
// ═══════════════════════════════════════════════════════════════════════════════

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
        color: c.isDark ? c.background : c.cardBorder.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTab('Correo', Icons.mail_outline_rounded, !isPhone, c, isPhone ? onToggle : null),
          _buildTab('Teléfono', Icons.phone_outlined, isPhone, c, !isPhone ? onToggle : null),
        ],
      ),
    );
  }

  Widget _buildTab(String label, IconData icon, bool selected, AppColorScheme c, VoidCallback? onTap) {
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
                ? [BoxShadow(color: c.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : c.textMuted),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : c.textMuted,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

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
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Text(label, key: ValueKey(label)),
        ),
      ),
    );
  }
}

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
      child: Row(children: [
        Icon(Icons.error_outline_rounded, color: c.error, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(error, style: TextStyle(color: c.error, fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}

// ── Password strength bar ─────────────────────────────────────────────────────
class _PasswordStrengthBar extends StatelessWidget {
  final int strength;
  final String password;
  final AppColorScheme colors;

  const _PasswordStrengthBar({
    required this.strength,
    required this.password,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final c = colors;
    final (barColor, label) = switch (strength) {
      0 => (c.error,   'Muy débil'),
      1 => (c.warning, 'Débil'),
      2 => (c.warning, 'Moderada'),
      3 => (c.success, 'Fuerte'),
      _ => (c.success, 'Muy fuerte'),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          ...List.generate(4, (i) => Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 3,
              margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
              decoration: BoxDecoration(
                color: i < strength ? barColor : c.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          )),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: barColor, fontSize: 11, fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
