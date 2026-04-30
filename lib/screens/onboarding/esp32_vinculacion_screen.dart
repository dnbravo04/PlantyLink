import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../core/firebase_constants.dart';

class Esp32VinculacionScreen extends StatefulWidget {
  const Esp32VinculacionScreen({super.key});

  @override
  State<Esp32VinculacionScreen> createState() => _Esp32VinculacionScreenState();
}

class _Esp32VinculacionScreenState extends State<Esp32VinculacionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool? _exitoso; // null=esperando, true=ok, false=error

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _escucharESP32();
  }

  void _escucharESP32() {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: kFirebaseDatabaseUrl,
    );
    // Escucha el nodo heartbeat del ESP32
    db.ref('esp32/heartbeat').onValue.listen((event) {
      final valor = event.snapshot.value;
      if (valor != null && mounted) {
        setState(() => _exitoso = true);
        _animController.stop();
        // Guardar vinculación
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          db.ref('usuarios/${user.uid}/esp32_vinculado').set(true);
        }
        // Ir al dashboard después de 1.5s
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
        });
      }
    });

    // Timeout de 30 segundos
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && _exitoso == null) {
        setState(() => _exitoso = false);
        _animController.stop();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                'Vinculación con ESP32',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Asegúrate de que el ESP32 esté encendido y conectado al WiFi',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),

              const Spacer(),

              // Animación / resultado
              if (_exitoso == null) ...[
                RotationTransition(
                  turns: _animController,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 4,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      ),
                    ),
                    child: const Icon(
                      Icons.router,
                      size: 60,
                      color: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Acerque su teléfono al ESP32',
                  style: TextStyle(fontSize: 16),
                ),
              ] else if (_exitoso == true) ...[
                const Icon(Icons.check_circle, color: Colors.green, size: 120),
                const SizedBox(height: 24),
                const Text(
                  '¡Vinculación exitosa!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ] else ...[
                const Icon(Icons.cancel, color: Colors.red, size: 120),
                const SizedBox(height: 24),
                const Text(
                  'No se pudo conectar. Intenta de nuevo.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => setState(() {
                    _exitoso = null;
                    _animController.repeat();
                    _escucharESP32();
                  }),
                  child: const Text('Reintentar'),
                ),
              ],

              const Spacer(),

              // Saltar por ahora (para testing)
              TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/dashboard'),
                child: const Text('Saltar por ahora'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
