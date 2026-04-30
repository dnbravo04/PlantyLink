import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/phone_utils.dart';

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
            _error = 'La contraseña debe tener al menos 6 caracteres';
            _cargando = false;
          });
          return;
        }
        if (password != confirmPassword) {
          setState(() {
            _error = 'Las contraseñas no coinciden';
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
        // Autenticación por teléfono
        await _verifyPhoneNumber(input);
        return; // Esperar verificación SMS
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding/perfil');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = switch (e.code) {
          'invalid-email' => 'Correo inválido',
          'weak-password' => 'Contraseña muy débil',
          'invalid-phone-number' => 'Número de teléfono inválido',
          'too-many-requests' => 'Demasiados intentos. Intenta más tarde',
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
        // Auto-verificación (Android)
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
        setState(() {
          _cargando = false;
        });
      },
      codeSent: (String verificationId, int? resendToken) {
        // Navegar a pantalla de verificación SMS
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
        // Timeout de auto-recuperación
        setState(() {
          _cargando = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Vinculación',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ingresa tu correo o teléfono para comenzar',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // Toggle email/teléfono
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Correo'),
                    icon: Icon(Icons.email),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Teléfono'),
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
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: _usandoEmail
                      ? 'Correo electrónico'
                      : 'Número de teléfono',
                  prefixIcon: Icon(_usandoEmail ? Icons.email : Icons.phone),
                  errorText: _usandoEmail ? null : _error,
                ),
              ),

              if (_usandoEmail) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'Contraseña',
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
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Confirmar contraseña',
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
