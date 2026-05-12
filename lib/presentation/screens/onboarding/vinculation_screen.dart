import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/phone_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/common/app_scaffold.dart';

class VinculacionScreen extends StatefulWidget {
  const VinculacionScreen({super.key});

  @override
  State<VinculacionScreen> createState() => _VinculacionScreenState();
}

class _VinculacionScreenState extends State<VinculacionScreen> {
  final _controller = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _usandoEmail = true;
  bool _obscurePassword = true;
  bool _cargando = false;
  String? _error;

  Future<void> _continuar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final auth = FirebaseAuth.instance;
      final input = _controller.text.trim();

      if (_usandoEmail) {
        final password = _passwordController.text;
        final confirmPassword = _confirmPasswordController.text;

        if (password.isEmpty || password.length < 6) {
          setState(() {
            _error = 'La contrase\u00f1a debe tener al menos 6 caracteres';
            _cargando = false;
          });
          return;
        }
        if (password != confirmPassword) {
          setState(() {
            _error = 'Las contrase\u00f1as no coinciden';
            _cargando = false;
          });
          return;
        }

        try {
          await auth.createUserWithEmailAndPassword(
            email: input,
            password: password,
          );
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            await auth.signInWithEmailAndPassword(
              email: input,
              password: password,
            );
          } else {
            rethrow;
          }
        }
      } else {
        await _verifyPhoneNumber(input);
        return;
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding/perfil');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = switch (e.code) {
          'invalid-email' => 'Correo inv\u00e1lido',
          'weak-password' => 'Contrase\u00f1a muy d\u00e9bil',
          'invalid-phone-number' => 'N\u00famero de tel\u00e9fono inv\u00e1lido',
          'too-many-requests' => 'Demasiados intentos. Intenta m\u00e1s tarde',
          _ => 'Error: ${e.message}',
        };
      });
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  Future<void> _verifyPhoneNumber(String phoneNumber) async {
    final auth = FirebaseAuth.instance;

    await auth.verifyPhoneNumber(
      phoneNumber: formatPhoneNumber(phoneNumber),
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
        setState(() {
          _cargando = false;
        });
      },
      codeSent: (String verificationId, int? resendToken) {
        Navigator.pushNamed(
          context,
          '/onboarding/sms',
          arguments: {
            'verificationId': verificationId,
            'phoneNumber': phoneNumber,
          },
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        setState(() {
          _cargando = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Vinculaci\u00f3n',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ingresa tu correo o tel\u00e9fono para comenzar',
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 32),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Correo'),
                    icon: Icon(Icons.email),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Tel\u00e9fono'),
                    icon: Icon(Icons.phone),
                  ),
                ],
                selected: {_usandoEmail},
                onSelectionChanged: (val) =>
                    setState(() => _usandoEmail = val.first),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                keyboardType: _usandoEmail
                    ? TextInputType.emailAddress
                    : TextInputType.phone,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: _usandoEmail
                      ? 'Correo electr\u00f3nico'
                      : 'N\u00famero de tel\u00e9fono',
                  prefixIcon: Icon(_usandoEmail ? Icons.email : Icons.phone),
                  errorText: _usandoEmail ? null : _error,
                ),
              ),
              if (_usandoEmail) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'Contrase\u00f1a',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    errorText: _error,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Confirmar contrase\u00f1a',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _cargando ? null : _continuar,
                  child: _cargando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Continuar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
