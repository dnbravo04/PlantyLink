import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/phone_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/common/app_scaffold.dart';

class SmsVerificationScreen extends StatefulWidget {
  const SmsVerificationScreen({super.key});

  @override
  State<SmsVerificationScreen> createState() => _SmsVerificationScreenState();
}

class _SmsVerificationScreenState extends State<SmsVerificationScreen> {
  final _codeController = TextEditingController();
  bool _cargando = false;
  String? _error;
  String _verificationId = '';
  String _phoneNumber = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
    if (args != null) {
      _verificationId = args['verificationId'] ?? '';
      _phoneNumber = args['phoneNumber'] ?? '';
    }
  }

  Future<void> _verifyCode() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final auth = FirebaseAuth.instance;
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _codeController.text.trim(),
      );

      await auth.signInWithCredential(credential);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding/perfil');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = switch (e.code) {
          'invalid-verification-code' => 'C\u00f3digo inv\u00e1lido',
          'code-expired' => 'C\u00f3digo expirado. Solicita uno nuevo',
          'session-expired' => 'Sesi\u00f3n expirada. Intenta nuevamente',
          _ => 'Error: ${e.message}',
        };
      });
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final auth = FirebaseAuth.instance;
      await auth.verifyPhoneNumber(
        phoneNumber: formatPhoneNumber(_phoneNumber),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await auth.signInWithCredential(credential);
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/onboarding/perfil');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _error = switch (e.code) {
              'invalid-phone-number' => 'N\u00famero de tel\u00e9fono inv\u00e1lido',
              'too-many-requests' => 'Demasiados intentos. Intenta m\u00e1s tarde',
              'quota-exceeded' => 'L\u00edmite de SMS excedido',
              _ => 'Error de verificaci\u00f3n: ${e.message}',
            };
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _cargando = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('C\u00f3digo reenviado')));
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _cargando = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Error al reenviar c\u00f3digo: $e';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppScaffold(
      appBar: AppBar(title: const Text('Verificaci\u00f3n SMS')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'Verifica tu tel\u00e9fono',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enviamos un c\u00f3digo SMS a $_phoneNumber',
                style: TextStyle(color: c.textMuted),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  letterSpacing: 8,
                  color: c.textPrimary,
                ),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'C\u00f3digo de verificaci\u00f3n',
                  hintText: '123456',
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _cargando ? null : _resendCode,
                child: _cargando
                    ? const CircularProgressIndicator()
                    : const Text('Reenviar c\u00f3digo'),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _cargando ? null : _verifyCode,
                  child: _cargando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Verificar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
