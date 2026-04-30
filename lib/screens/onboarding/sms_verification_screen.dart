import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/phone_utils.dart';

class SmsVerificationScreen extends StatefulWidget {
  const SmsVerificationScreen({super.key});

  @override
  State<SmsVerificationScreen> createState() => _SmsVerificationScreenState();
}

class _SmsVerificationScreenState extends State<SmsVerificationScreen> {
  final _codeController = TextEditingController();
  bool _cargando = false;
  String? _error;
  late String _verificationId;
  late String _phoneNumber;

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
          'invalid-verification-code' => 'Código inválido',
          'code-expired' => 'Código expirado. Solicita uno nuevo',
          'session-expired' => 'Sesión expirada. Intenta nuevamente',
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
              'invalid-phone-number' => 'Número de teléfono inválido',
              'too-many-requests' => 'Demasiados intentos. Intenta más tarde',
              'quota-exceeded' => 'Límite de SMS excedido',
              _ => 'Error de verificación: ${e.message}',
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
          ).showSnackBar(const SnackBar(content: Text('Código reenviado')));
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _cargando = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Error al reenviar código: $e';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verificación SMS')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Verifica tu teléfono',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Enviamos un código SMS a $_phoneNumber',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Código de verificación',
                  hintText: '123456',
                  errorText: _error,
                ),
              ),

              const SizedBox(height: 24),

              TextButton(
                onPressed: _cargando ? null : _resendCode,
                child: _cargando
                    ? const CircularProgressIndicator()
                    : const Text('Reenviar código'),
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
