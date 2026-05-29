import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import '../../../core/firebase_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/common/app_scaffold.dart';

class NfcVinculationScreen extends ConsumerStatefulWidget {
  const NfcVinculationScreen({super.key});

  @override
  ConsumerState<NfcVinculationScreen> createState() =>
      _NfcVinculationScreenState();
}

class _NfcVinculationScreenState extends ConsumerState<NfcVinculationScreen> {
  bool _isScanning = false;
  bool _isNfcAvailable = false;
  String _statusMessage = 'Verificando NFC...';
  String? _deviceId;
  final List<String> _scannedTags = [];

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
  }

  Future<void> _checkNfcAvailability() async {
    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      if (mounted) {
        setState(() {
          _isNfcAvailable = availability == NFCAvailability.available;
          _statusMessage = availability == NFCAvailability.available
              ? 'NFC disponible. Acerca tu teléfono al ESP32.'
              : 'NFC no disponible en este dispositivo';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isNfcAvailable = false;
          _statusMessage = 'Error al verificar NFC: $e';
        });
      }
    }
  }

  Future<void> _startNfcScan() async {
    if (!_isNfcAvailable) {
      _showErrorDialog('NFC no disponible', 'Tu dispositivo no soporta NFC.');
      return;
    }

    setState(() {
      _isScanning = true;
      _statusMessage = 'Acerca tu teléfono al ESP32...';
      _scannedTags.clear();
    });

    try {
      // Iniciar sesión NFC para leer tags
      final pollResult = await FlutterNfcKit.poll();
      await _processNfcTag(pollResult);
    } catch (e) {
      _showErrorDialog('Error de NFC', 'Error al leer tag: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _statusMessage = 'Espera el pulso en el ESP32...';
        });
      }
    }
  }

  Future<void> _processNfcTag(NFCTag tag) async {
    try {
      setState(() {
        _statusMessage = 'Procesando tag NFC...';
        _scannedTags.add(tag.id);
      });

      // Extraer ID del dispositivo del tag NFC
      final deviceId = tag.id;

      // Guardar en Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final db = FirebaseDatabase.instanceFor(
          databaseURL: kFirebaseDatabaseUrl,
          app: Firebase.app(),
        );

        // Log opcional en nfc/registros (no usado para vinculación)
        await db.ref('nfc/registros').push().set({
          'usuario': user.uid,
          'nivel': 1,
          'timestamp': ServerValue.timestamp,
          'device_id': deviceId,
        });

        // Actualizar estado del usuario
        await db.ref('usuarios/${user.uid}').update({
          'esp32_vinculado': true,
          'esp32_id': deviceId,
        });
      }

      setState(() {
        _deviceId = deviceId;
        _statusMessage = '¡Dispositivo vinculado exitosamente!';
      });

      // Navegar al dashboard después de 2 segundos
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
      });
    } catch (e) {
      _showErrorDialog('Error al procesar', 'Error al procesar tag NFC: $e');
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.nfc,
                size: 80,
                color: _isNfcAvailable
                    ? AppColors.success
                    : AppColors.textMuted,
              ),
              const SizedBox(height: 16),
              Text(
                'Vinculación NFC',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: _statusMessage.contains('exitosamente')
                      ? AppColors.success
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              if (_scannedTags.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Último dispositivo vinculado:',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _deviceId ?? 'Desconocido',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.info,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isScanning || !_isNfcAvailable
                      ? null
                      : _startNfcScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isScanning || !_isNfcAvailable
                        ? AppColors.textMuted
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isScanning
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Escaneando...'),
                          ],
                        )
                      : Text(
                          _isNfcAvailable
                              ? 'Acerca Teléfono a ESP32'
                              : 'NFC No Disponible',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/'),
                child: Text(
                  'Omitir por ahora',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
