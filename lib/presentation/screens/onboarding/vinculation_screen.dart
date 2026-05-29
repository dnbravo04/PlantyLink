import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/phone_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../widgets/common/onboarding_step_indicator.dart';

class VinculacionScreen extends StatefulWidget {
  const VinculacionScreen({super.key});

  @override
  State<VinculacionScreen> createState() => _VinculacionScreenState();
}

class _VinculacionScreenState extends State<VinculacionScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool _usandoEmail      = true;
  bool _obscurePass      = true;
  bool _obscureConfirm   = true;
  bool _cargando         = false;
  String? _error;

  late AnimationController _anim;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _anim.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Auth logic ─────────────────────────────────────────────────────────────
  Future<void> _continuar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      if (_usandoEmail) {
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
        try {
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailCtrl.text.trim(), password: pass,
          );
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: _emailCtrl.text.trim(), password: pass,
            );
          } else { rethrow; }
        }
        if (mounted) Navigator.pushReplacementNamed(context, '/onboarding/perfil');
      } else {
        await _verifyPhone(_emailCtrl.text.trim());
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
        if (mounted) Navigator.pushReplacementNamed(context, '/onboarding/perfil');
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() { _error = _mapError(e.code); _cargando = false; });
      },
      codeSent: (String verificationId, int? _) {
        setState(() => _cargando = false);
        Navigator.pushNamed(context, '/onboarding/otp', arguments: {
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
      body: Stack(
        children: [
          _buildTopBackground(c),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(c),
                Expanded(child: _buildSheet(c)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBackground(AppColorScheme c) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: c.isDark
              ? [const Color(0xFF0A2218), const Color(0xFF07110E)]
              : [const Color(0xFF059669), const Color(0xFF34D399)],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorScheme c) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.28,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back to login
                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: c.isDark ? c.textPrimary : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Crear cuenta',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: c.isDark ? c.textPrimary : Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Únete a la comunidad PlantyLink',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: c.isDark
                        ? c.textSecondary
                        : Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheet(AppColorScheme c) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator
            OnboardingStepIndicator(currentStep: 1, colors: c),
            const SizedBox(height: 28),

            // Input
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

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: c.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.error.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  Icon(Icons.error_outline_rounded, color: c.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: TextStyle(color: c.error, fontSize: 13))),
                ]),
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _cargando ? null : _continuar,
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
                    : const Text('Continuar'),
              ),
            ),

            const SizedBox(height: 16),

            Center(
              child: TextButton(
                onPressed: () => setState(() {
                  _usandoEmail = !_usandoEmail;
                  _error = null;
                  _emailCtrl.clear();
                }),
                child: Text(
                  _usandoEmail
                      ? 'Usar número de teléfono'
                      : 'Usar correo electrónico',
                  style: TextStyle(color: c.primary, fontSize: 13),
                ),
              ),
            ),

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
            child: Container(
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
