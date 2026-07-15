import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/utils/app_page_route.dart';
import '../../../core/utils/haptics.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/onboarding_step_indicator.dart';
import '../../../app.dart';

class Esp32VinculacionScreen extends ConsumerStatefulWidget {
  const Esp32VinculacionScreen({super.key});

  @override
  ConsumerState<Esp32VinculacionScreen> createState() =>
      _Esp32VinculacionScreenState();
}

class _Esp32VinculacionScreenState
    extends ConsumerState<Esp32VinculacionScreen>
    with TickerProviderStateMixin {
  // Ripple controllers (3 rings at staggered delays)
  late List<AnimationController> _rippleControllers;
  late List<Animation<double>>   _rippleAnimations;

  // Success checkmark stroke animation
  late AnimationController _checkCtrl;
  late Animation<double>   _checkProgress;

  bool? _exitoso;
  bool  _isScanning      = false;
  bool  _isNfcAvailable  = false;
  String? _esp32Id;
  String? _errorMessage;

  /// True when opened from settings (not onboarding).
  bool get _isFromSettings => Navigator.of(context).canPop();

  @override
  void initState() {
    super.initState();
    _rippleControllers = List.generate(3, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2400),
      );
      Future.delayed(Duration(milliseconds: i * 600), () {
        if (mounted) ctrl.repeat();
      });
      return ctrl;
    });
    _rippleAnimations = _rippleControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .toList();

    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _checkProgress = CurvedAnimation(
      parent: _checkCtrl,
      curve: Curves.easeOutCubic,
    );

    _checkNfcAvailability();
  }

  @override
  void dispose() {
    for (final c in _rippleControllers) {
      c.dispose();
    }
    _checkCtrl.dispose();
    NfcManager.instance.stopSession();
    super.dispose();
  }

  Future<void> _checkNfcAvailability() async {
    try {
      final avail = await NfcManager.instance.checkAvailability();
      if (mounted) {
        setState(() => _isNfcAvailable = avail == NfcAvailability.enabled);
        if (_isNfcAvailable) _startNfcScan();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isNfcAvailable = false);
        _stopRipples();
      }
    }
  }

  Future<void> _startNfcScan() async {
    if (!_isNfcAvailable) return;
    setState(() {
      _isScanning   = true;
      _exitoso      = null;
      _errorMessage = null;
    });
    _startRipples();

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        onDiscovered: (NfcTag tag) async {
          final deviceId = _extractTagId(tag);
          await _processDeviceId(deviceId);
          await NfcManager.instance.stopSession();
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _exitoso      = false;
          _isScanning   = false;
          _errorMessage = 'No se detectó el tag NFC. Intenta de nuevo.';
        });
        _stopRipples();
      }
    }
  }

  /// Extracts a hex string identifier from the NFC tag.
  String _extractTagId(NfcTag tag) {
    final androidTag = NfcTagAndroid.from(tag);
    if (androidTag != null) {
      return androidTag.id
          .map((e) => e.toRadixString(16).padLeft(2, '0'))
          .join(':');
    }
    return 'esp32-${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Validates that the device ID is a safe, plausible identifier.
  /// Allows hex colon-separated (NFC), alphanumeric-dash (QR), or MAC-like formats.
  static final _validDeviceIdPattern = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9:\-_]{2,63}$');

  bool _isValidDeviceId(String id) => _validDeviceIdPattern.hasMatch(id);

  Future<void> _processDeviceId(String deviceId) async {
    if (!_isValidDeviceId(deviceId)) {
      if (mounted) {
        setState(() {
          _exitoso = false;
          _isScanning = false;
          _errorMessage = 'ID inválido. Debe ser alfanumérico (3-64 caracteres).';
        });
        _stopRipples();
      }
      return;
    }

    try {
      await ref.read(deviceServiceProvider).vincularESP32(deviceId);
      if (mounted) {
        AppHaptics.medium();
        setState(() {
          _exitoso   = true;
          _esp32Id   = deviceId;
          _isScanning = false;
        });
        _stopRipples();
        _checkCtrl.forward();
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (!mounted) return;
          if (_isFromSettings) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _exitoso      = false;
          _isScanning   = false;
          _errorMessage = 'Error al vincular el ESP32. Intenta de nuevo.';
        });
        _stopRipples();
      }
    }
  }

  void _startRipples() {
    for (final c in _rippleControllers) {
      c.repeat();
    }
  }

  void _stopRipples() {
    for (final c in _rippleControllers) {
      c.stop();
      c.reset();
    }
  }

  void _retry() {
    setState(() {
      _exitoso      = null;
      _isScanning   = false;
      _errorMessage = null;
    });
    if (_isNfcAvailable) {
      _startNfcScan();
    }
  }

  // ── Manual ID input ─────────────────────────────────────────────────────

  Future<void> _showManualInputDialog() async {
    final ctrl = TextEditingController();
    try {
      final deviceId = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final c = AppColors.of(ctx);
          return AlertDialog(
            backgroundColor: c.cardBackground,
            title: Text(
              'Ingresar ID del ESP32',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ingresa el ID que se encuentra en la etiqueta '
                  'de tu dispositivo ESP32.',
                  style: TextStyle(color: c.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  style: TextStyle(color: c.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Ej: a1:b2:c3:d4:e5',
                    hintStyle: TextStyle(color: c.textMuted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.memory_rounded, color: c.primary),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar', style: TextStyle(color: c.textMuted)),
              ),
              FilledButton(
                onPressed: () {
                  final text = ctrl.text.trim();
                  if (text.isEmpty) return;
                  if (!_isValidDeviceId(text)) {
                    AppToast.show(ctx,
                        message:
                            'ID inválido. Solo letras, números, ":", "-" o "_" (3-64 caracteres).',
                        type: ToastType.error);
                    return;
                  }
                  Navigator.pop(ctx, text);
                },
                style: FilledButton.styleFrom(backgroundColor: c.primary),
                child: const Text('Vincular'),
              ),
            ],
          );
        },
      );
      if (deviceId != null && deviceId.isNotEmpty) {
        await _processDeviceId(deviceId);
      }
    } finally {
      ctrl.dispose();
    }
  }

  // ── QR Code scanning ──────────────────────────────────────────────────

  Future<void> _scanQrCode() async {
    final deviceId = await Navigator.push<String>(
      context,
      AppPageRoute(builder: (_) => const _QrScannerPage()),
    );
    if (deviceId != null && deviceId.isNotEmpty && mounted) {
      await _processDeviceId(deviceId);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return PopScope(
      canPop: _isFromSettings,
      child: Scaffold(
      backgroundColor: c.background,
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
      ),
    );
  }

  Widget _buildTopBackground(AppColorScheme c) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.28,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: c.isDark
              ? [const Color(0xFF081824), const Color(0xFF07110E)]
              : [const Color(0xFF0891B2), const Color(0xFF0E7490)],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorScheme c) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.24,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _isFromSettings
                  ? Navigator.pop(context)
                  : Navigator.pushReplacementNamed(context, AppRoutes.onboardingWelcome),
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
              'Conectar dispositivo',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26, fontWeight: FontWeight.w800,
                color: c.isDark ? c.textPrimary : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _isNfcAvailable
                  ? 'Acerca tu teléfono al ESP32'
                  : 'Vincula tu dispositivo ESP32',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: c.isDark
                    ? c.textSecondary
                    : Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 16),
          ],
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          children: [
            if (!_isFromSettings) ...[
              OnboardingStepIndicator(currentStep: 3, colors: c),
              const SizedBox(height: 32),
            ],

            Expanded(child: _buildStateContent(c)),

            const SizedBox(height: 16),

            // ── Alternative linking methods ──────────────────────
            if (_exitoso != true) ...[
              _buildAlternativeMethods(c),
              const SizedBox(height: 12),
              if (_isFromSettings)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: c.textMuted, fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else
                TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, AppRoutes.home),
                  child: Text(
                    'Omitir por ahora  \u2192',
                    style: TextStyle(
                      color: c.textMuted, fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlternativeMethods(AppColorScheme c) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _scanQrCode,
                icon: Icon(Icons.qr_code_scanner_rounded, size: 18, color: c.primary),
                label: Text(
                  'Escanear QR',
                  style: TextStyle(color: c.textPrimary, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: c.cardBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showManualInputDialog,
                icon: Icon(Icons.keyboard_rounded, size: 18, color: c.primary),
                label: Text(
                  'Ingresar ID',
                  style: TextStyle(color: c.textPrimary, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: c.cardBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStateContent(AppColorScheme c) {
    if (_exitoso == true) return _buildSuccess(c);
    if (_exitoso == false) return _buildError(c);
    if (_isNfcAvailable) return _buildScanning(c);
    return _buildNoNfc(c);
  }

  Widget _buildNoNfc(AppColorScheme c) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 96, height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.warning.withValues(alpha: 0.12),
            border: Border.all(color: c.warning.withValues(alpha: 0.4), width: 2),
          ),
          child: Icon(Icons.nfc_rounded, size: 48, color: c.warning),
        ),
        const SizedBox(height: 24),
        Text(
          'NFC no disponible',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20, fontWeight: FontWeight.w800, color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Activa NFC en los ajustes de tu teléfono\no usa las opciones alternativas.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: c.textMuted, height: 1.5),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () async {
            AppHaptics.light();
            // Open Android NFC settings
            const channel = MethodChannel('com.plantylink.app/settings');
            try {
              await channel.invokeMethod('openNfcSettings');
            } catch (_) {
              // Fallback: open general wireless settings
              try {
                await channel.invokeMethod('openWirelessSettings');
              } catch (_) {}
            }
          },
          icon: const Icon(Icons.settings_rounded, size: 16),
          label: const Text('Abrir ajustes NFC', style: TextStyle(fontSize: 13)),
          style: FilledButton.styleFrom(
            backgroundColor: c.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            AppHaptics.light();
            _checkNfcAvailability();
          },
          icon: Icon(Icons.refresh_rounded, size: 16, color: c.primary),
          label: Text('Verificar NFC de nuevo',
              style: TextStyle(color: c.primary, fontSize: 13)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: c.primary.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanning(AppColorScheme c) {
    final ringColor = c.isDark ? const Color(0xFF22D3EE) : const Color(0xFF0891B2);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 200, height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (int i = 0; i < 3; i++)
                AnimatedBuilder(
                  animation: _rippleAnimations[i],
                  builder: (_, _) {
                    final val = _rippleAnimations[i].value;
                    return Opacity(
                      opacity: (1.0 - val).clamp(0.0, 0.6),
                      child: Container(
                        width: 80 + val * 120,
                        height: 80 + val * 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: ringColor, width: 1.5),
                        ),
                      ),
                    );
                  },
                ),
              // Rotating gradient ring around the center icon
              AnimatedBuilder(
                animation: _rippleControllers[0],
                builder: (_, _) => Transform.rotate(
                  angle: _rippleControllers[0].value * 2 * math.pi,
                  child: SizedBox(
                    width: 90, height: 90,
                    child: CustomPaint(
                      painter: _GradientRingPainter(color: ringColor),
                    ),
                  ),
                ),
              ),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ringColor.withValues(alpha: 0.12),
                  boxShadow: [
                    BoxShadow(
                      color: ringColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Icon(Icons.nfc_rounded, size: 40, color: ringColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _isScanning ? 'Escaneando...' : 'Esperando tag NFC...',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18, fontWeight: FontWeight.w700, color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Mantén tu teléfono cerca del\ndispositivo ESP32',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: c.textMuted, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildSuccess(AppColorScheme c) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _checkProgress,
          builder: (context, _) => Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.success.withValues(alpha: 0.12),
              border: Border.all(color: c.success.withValues(alpha: 0.4), width: 2),
              boxShadow: [
                BoxShadow(
                  color: c.success.withValues(alpha: 0.1 + _checkProgress.value * 0.25),
                  blurRadius: 12 + _checkProgress.value * 16,
                ),
              ],
            ),
            child: CustomPaint(
              painter: _CheckmarkPainter(
                progress: _checkProgress.value,
                color: c.success,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '¡Vinculación exitosa!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20, fontWeight: FontWeight.w800, color: c.textPrimary,
          ),
        ),
        if (_esp32Id != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: c.cardBorder.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'ID: $_esp32Id',
              style: TextStyle(
                fontSize: 12, color: c.textMuted, fontFamily: 'monospace',
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'Redirigiendo al inicio...',
          style: TextStyle(fontSize: 13, color: c.textMuted),
        ),
      ],
    );
  }

  Widget _buildError(AppColorScheme c) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 96, height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.error.withValues(alpha: 0.10),
            border: Border.all(color: c.error.withValues(alpha: 0.4), width: 2),
          ),
          child: Icon(Icons.wifi_off_rounded, size: 48, color: c.error),
        ),
        const SizedBox(height: 24),
        Text(
          'No se pudo conectar',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18, fontWeight: FontWeight.w700, color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _errorMessage ?? 'Intenta acercar tu teléfono nuevamente.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: c.textMuted, height: 1.5),
        ),
        if (_isNfcAvailable) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _retry,
              style: FilledButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Intentar de nuevo'),
            ),
          ),
        ],
      ],
    );
  }
}

// ── QR Scanner Page ─────────────────────────────────────────────────────────

class _QrScannerPage extends StatefulWidget {
  const _QrScannerPage();

  @override
  State<_QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<_QrScannerPage> {
  final MobileScannerController _scannerCtrl = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    _scannerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Escanear código QR',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerCtrl,
            onDetect: (capture) {
              if (_scanned) return;
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                _scanned = true;
                Navigator.pop(context, barcodes.first.rawValue);
              }
            },
          ),
          Center(
            child: SizedBox(
              width: 250, height: 250,
              child: CustomPaint(
                painter: _ScannerCornerPainter(color: c.primary),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0, right: 0,
            child: Text(
              'Apunta al código QR del ESP32',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated checkmark painter ──────────────────────────────────────────────

class _CheckmarkPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0
  final Color color;

  _CheckmarkPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    // Checkmark shape: left leg then right leg
    final p1 = Offset(cx - 18, cy + 2);  // start
    final p2 = Offset(cx - 4, cy + 16);  // bottom
    final p3 = Offset(cx + 20, cy - 12); // end

    final path = Path()..moveTo(p1.dx, p1.dy);

    // First leg: 0 → 0.4 of progress
    if (progress <= 0.4) {
      final t = progress / 0.4;
      path.lineTo(
        p1.dx + (p2.dx - p1.dx) * t,
        p1.dy + (p2.dy - p1.dy) * t,
      );
    } else {
      path.lineTo(p2.dx, p2.dy);
      // Second leg: 0.4 → 1.0 of progress
      final t = (progress - 0.4) / 0.6;
      path.lineTo(
        p2.dx + (p3.dx - p2.dx) * t,
        p2.dy + (p3.dy - p2.dy) * t,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckmarkPainter old) =>
      progress != old.progress || color != old.color;
}

// ── QR scanner corner brackets painter ──────────────────────────────────────

class _ScannerCornerPainter extends CustomPainter {
  final Color color;

  _ScannerCornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const cornerLen = 36.0;
    const r = 12.0;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLen)
        ..lineTo(0, r)
        ..arcToPoint(Offset(r, 0), radius: const Radius.circular(r))
        ..lineTo(cornerLen, 0),
      paint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLen, 0)
        ..lineTo(size.width - r, 0)
        ..arcToPoint(Offset(size.width, r), radius: const Radius.circular(r))
        ..lineTo(size.width, cornerLen),
      paint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - cornerLen)
        ..lineTo(0, size.height - r)
        ..arcToPoint(Offset(r, size.height), radius: const Radius.circular(r))
        ..lineTo(cornerLen, size.height),
      paint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLen, size.height)
        ..lineTo(size.width - r, size.height)
        ..arcToPoint(Offset(size.width, size.height - r),
            radius: const Radius.circular(r))
        ..lineTo(size.width, size.height - cornerLen),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ScannerCornerPainter old) => color != old.color;
}

// ── Rotating gradient ring for NFC scanning ─────────────────────────────────

class _GradientRingPainter extends CustomPainter {
  final Color color;

  _GradientRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.6),
          color,
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi * 1.5,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_GradientRingPainter old) => color != old.color;
}
