import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import '../../../core/firebase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/common/app_scaffold.dart';

class Esp32VinculacionScreen extends StatefulWidget {
  const Esp32VinculacionScreen({super.key});

  @override
  State<Esp32VinculacionScreen> createState() => _Esp32VinculacionScreenState();
}

class _Esp32VinculacionScreenState extends State<Esp32VinculacionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool? _exitoso;
  bool _isScanning = false;
  bool _isNfcAvailable = false;
  String? _esp32Id;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _checkNfcAvailability();
  }

  Future<void> _checkNfcAvailability() async {
    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      if (mounted) {
        setState(() {
          _isNfcAvailable = availability == NFCAvailability.available;
        });
        if (_isNfcAvailable) {
          _startNfcScan();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isNfcAvailable = false;
          _exitoso = false;
          _animController.stop();
        });
      }
    }
  }

  Future<void> _startNfcScan() async {
    if (!_isNfcAvailable) return;

    setState(() {
      _isScanning = true;
      _exitoso = null;
    });

    try {
      final pollResult = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 30),
      );
      await _processNfcTag(pollResult);
    } catch (e) {
      if (mounted) {
        setState(() {
          _exitoso = false;
          _isScanning = false;
          _animController.stop();
        });
      }
    }
  }

  Future<void> _processNfcTag(NFCTag tag) async {
    try {
      final deviceId = tag.id;

      await _firebaseService.vincularESP32(deviceId);

      if (mounted) {
        setState(() {
          _exitoso = true;
          _esp32Id = deviceId;
          _isScanning = false;
          _animController.stop();
        });

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _exitoso = false;
          _isScanning = false;
          _animController.stop();
        });
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                'Vinculaci\u00f3n con ESP32',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isNfcAvailable
                    ? 'Acerca tu tel\u00e9fono al ESP32'
                    : 'NFC no disponible en este dispositivo',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
              const Spacer(),
              if (_exitoso == null && _isNfcAvailable) ...[
                RotationTransition(
                  turns: _animController,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 4,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      ),
                    ),
                    child: const Icon(
                      Icons.nfc,
                      size: 60,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _isScanning
                      ? 'Escaneando tag NFC...'
                      : 'Esperando tag NFC...',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ] else if (_exitoso == true) ...[
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 120,
                ),
                const SizedBox(height: 24),
                const Text(
                  '\u00a1Vinculaci\u00f3n exitosa!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_esp32Id != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'ID: $_esp32Id',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ] else ...[
                const Icon(Icons.cancel, color: AppColors.error, size: 120),
                const SizedBox(height: 24),
                Text(
                  _isNfcAvailable
                      ? 'No se detect\u00f3 el tag NFC. Intenta de nuevo.'
                      : 'NFC no disponible',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                if (_isNfcAvailable)
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _exitoso = null;
                        _isScanning = false;
                      });
                      _animController.repeat();
                      _startNfcScan();
                    },
                    child: const Text('Reintentar'),
                  ),
              ],
              const Spacer(),
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
