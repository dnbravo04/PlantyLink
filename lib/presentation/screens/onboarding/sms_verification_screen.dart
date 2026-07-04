import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/phone_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../app.dart';

class SmsVerificationScreen extends StatefulWidget {
  const SmsVerificationScreen({super.key});

  @override
  State<SmsVerificationScreen> createState() => _SmsVerificationScreenState();
}

class _SmsVerificationScreenState extends State<SmsVerificationScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _digitControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  bool _cargando = false;
  String? _error;
  String _verificationId = '';
  String _phoneNumber = '';
  bool _isLogin = false;

  late AnimationController _entryAnim;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entryAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fade = CurvedAnimation(parent: _entryAnim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryAnim, curve: Curves.easeOutCubic));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      _verificationId = args['verificationId'] as String? ?? '';
      _phoneNumber = args['phoneNumber'] as String? ?? '';
      _isLogin = args['isLogin'] == true;
    }
  }

  /// Login flow: pop back to AuthGate, which routes by auth state.
  /// Registration flow: AuthGate was replaced by the registration route,
  /// so continue explicitly to profile creation.
  void _navigateAfterSignIn() {
    if (!mounted) return;
    if (_isLogin) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.onboardingPerfil);
    }
  }

  String get _fullCode =>
      _digitControllers.map((c) => c.text).join();

  Future<void> _verifyCode() async {
    final code = _fullCode;
    if (code.length < 6) {
      setState(() => _error = 'Ingresa el código completo de 6 dígitos');
      return;
    }

    setState(() { _cargando = true; _error = null; });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: code,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      _navigateAfterSignIn();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = switch (e.code) {
          'invalid-verification-code' => 'Código inválido. Verifica e intenta de nuevo',
          'code-expired' => 'El código expiró. Solicita uno nuevo',
          'session-expired' => 'La sesión expiró. Intenta nuevamente',
          _ => 'No se pudo verificar el código. Intenta de nuevo',
        };
      });
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _resendCode() async {
    setState(() { _cargando = true; _error = null; });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formatPhoneNumber(_phoneNumber),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          _navigateAfterSignIn();
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _error = switch (e.code) {
              'invalid-phone-number' => 'Número de teléfono inválido',
              'too-many-requests' => 'Demasiados intentos. Intenta más tarde',
              'quota-exceeded' => 'Límite de SMS excedido',
              _ => 'Error de verificación: ${e.message}',
            };
            _cargando = false;
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _cargando = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Código reenviado exitosamente'),
              backgroundColor: AppColors.of(context).success,
            ));
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() => _cargando = false);
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Error al reenviar código';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                  _buildHeader(c),
                  const SizedBox(height: 32),
                  _buildCodeCard(c),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorScheme c) {
    return Column(
      children: [
        // Back button
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
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
        const SizedBox(height: 28),
        // Icon
        Container(
          width: 72, height: 72,
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
            Icons.sms_outlined,
            size: 32,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Verificar teléfono',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enviamos un código SMS a',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: c.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _phoneNumber.isNotEmpty ? _phoneNumber : '...',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCodeCard(AppColorScheme c) {
    return Container(
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
        children: [
          Text(
            'Ingresa el código de 6 dígitos',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: 24),

          // ── 6-digit code input ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) => _buildDigitField(i, c)),
          ),

          // ── Error ──
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: c.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.error.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                Icon(Icons.error_outline_rounded, color: c.error, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  _error!,
                  style: TextStyle(color: c.error, fontSize: 13, fontWeight: FontWeight.w500),
                )),
              ]),
            ),
          ],

          const SizedBox(height: 24),

          // ── Verify button ──
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _cargando ? null : _verifyCode,
              style: FilledButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: c.primary.withValues(alpha: 0.5),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _cargando
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        height: 22, width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('Verificar', key: ValueKey('verify')),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Resend ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '¿No recibiste el código? ',
                style: TextStyle(color: c.textMuted, fontSize: 13),
              ),
              GestureDetector(
                onTap: _cargando ? null : _resendCode,
                child: Text(
                  'Reenviar',
                  style: TextStyle(
                    color: _cargando ? c.textMuted : c.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDigitField(int index, AppColorScheme c) {
    return Container(
      width: 44,
      height: 52,
      margin: EdgeInsets.only(right: index < 5 ? 8 : 0),
      child: TextField(
        controller: _digitControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        maxLength: 1,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: c.textPrimary,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c.primary, width: 2),
          ),
          filled: true,
          fillColor: c.isDark ? c.background : c.cardBackground,
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          // Auto-verify when all 6 digits entered
          if (_fullCode.length == 6) {
            _verifyCode();
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _entryAnim.dispose();
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }
}
