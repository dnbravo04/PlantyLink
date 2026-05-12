import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../core/firebase_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/common/app_scaffold.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _nombreController = TextEditingController();
  final _ciudadController = TextEditingController();
  bool _cargando = false;
  String? _errorNombre;

  Future<void> _siguiente() async {
    final nombre = _nombreController.text.trim();
    final ciudad = _ciudadController.text.trim();

    if (nombre.isEmpty || ciudad.isEmpty) {
      setState(() => _errorNombre = 'Completa todos los campos');
      return;
    }

    setState(() {
      _cargando = true;
      _errorNombre = null;
    });

    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: kFirebaseDatabaseUrl,
    );
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorNombre = 'No hay usuario autenticado';
        _cargando = false;
      });
      return;
    }
    final uid = user.uid;

    final snapshot = await db
        .ref('usuarios')
        .orderByChild('nombre')
        .equalTo(nombre)
        .get();

    if (snapshot.exists) {
      setState(() {
        _errorNombre = 'Este nombre ya est\u00e1 en uso, elige otro';
        _cargando = false;
      });
      return;
    }

    await db.ref('usuarios/$uid').set({
      'nombre': nombre,
      'ciudad': ciudad,
      'creado': ServerValue.timestamp,
    });

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/onboarding/esp32');
    }
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
                'Inicio de cuenta',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nombreController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Nombre de usuario',
                  prefixIcon: const Icon(Icons.person),
                  errorText: _errorNombre,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ciudadController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Ciudad',
                  prefixIcon: Icon(Icons.location_city),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _cargando ? null : _siguiente,
                  child: _cargando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Siguiente'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
