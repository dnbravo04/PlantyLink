import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/firebase_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/utils/profile_photo.dart';
import '../../widgets/common/onboarding_step_indicator.dart';
import '../../../app.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen>
    with SingleTickerProviderStateMixin {
  final _nombreCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  bool   _cargando    = false;
  String? _error;
  String? _fotoB64;

  late AnimationController _anim;
  late Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _anim.dispose();
    _nombreCtrl.dispose();
    _ciudadCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFoto() async {
    final action = await chooseProfilePhoto(context, canRemove: _fotoB64 != null);
    if (action == null) return;
    setState(() => _fotoB64 = switch (action) {
      ProfilePhotoPicked(:final base64Jpeg) => base64Jpeg,
      ProfilePhotoRemoved() => null,
    });
  }

  Future<void> _siguiente() async {
    final nombre = _nombreCtrl.text.trim();
    final ciudad = _ciudadCtrl.text.trim();

    if (nombre.isEmpty) {
      setState(() => _error = 'Ingresa tu nombre');
      return;
    }
    setState(() { _cargando = true; _error = null; });

    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: kFirebaseDatabaseUrl,
    );
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() { _error = 'No hay usuario autenticado'; _cargando = false; });
      return;
    }

    try {
      // update(), not set(): a returning user may already have esp32_id,
      // dispositivos, settings or fcm_token under this node.
      await db.ref('usuarios/${user.uid}').update({
        'nombre': nombre,
        if (ciudad.isNotEmpty) 'ciudad': ciudad,
        if (_fotoB64 != null) 'foto_b64': _fotoB64,
        'creado': ServerValue.timestamp,
      });
    } catch (e) {
      if (mounted) {
        setState(() { _error = 'Error al guardar perfil. Intenta de nuevo.'; _cargando = false; });
      }
      return;
    }

    if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.onboardingWelcome);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final nombre = _nombreCtrl.text;

    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: c.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Top gradient
          Container(
            height: MediaQuery.of(context).size.height * 0.28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: c.isDark
                    ? [const Color(0xFF0A2218), const Color(0xFF07110E)]
                    : [const Color(0xFF059669), const Color(0xFF34D399)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.24,
                  child: FadeTransition(
                    opacity: _fade,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(width: 36, height: 36),
                          const Spacer(),
                          Text(
                            'Cuéntanos sobre ti',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: c.isDark ? c.textPrimary : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Personaliza tu experiencia',
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
                  ),
                ),

                // Form sheet
                Expanded(
                  child: Container(
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                      child: Column(
                        children: [
                          OnboardingStepIndicator(currentStep: 2, colors: c),
                          const SizedBox(height: 28),

                          // Avatar — tap to add an optional profile photo
                          _AvatarPlaceholder(
                            inicial: nombre.isNotEmpty ? nombre[0].toUpperCase() : null,
                            fotoB64: _fotoB64,
                            onTap: _cargando ? null : _elegirFoto,
                            colors: c,
                          ),
                          const SizedBox(height: 28),

                          // Name field
                          TextField(
                            controller: _nombreCtrl,
                            onChanged: (_) => setState(() {}),
                            style: TextStyle(color: c.textPrimary, fontSize: 15),
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Nombre de usuario',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // City field
                          TextField(
                            controller: _ciudadCtrl,
                            style: TextStyle(color: c.textPrimary, fontSize: 15),
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Ciudad (opcional)',
                              prefixIcon: Icon(Icons.location_city_outlined),
                            ),
                          ),

                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: c.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: c.error.withValues(alpha: 0.3)),
                              ),
                              child: Row(children: [
                                Icon(Icons.error_outline_rounded, color: c.error, size: 16),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_error!, style: TextStyle(color: c.error, fontSize: 13))),
                              ]),
                            ),
                          ],

                          const SizedBox(height: 28),

                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _cargando ? null : _siguiente,
                              style: FilledButton.styleFrom(
                                backgroundColor: c.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: _cargando
                                  ? const SizedBox(
                                      height: 22, width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5, color: Colors.white,
                                      ),
                                    )
                                  : const Text('Siguiente'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ── Avatar placeholder ────────────────────────────────────────────────────────
class _AvatarPlaceholder extends StatelessWidget {
  final String? inicial;
  final String? fotoB64;
  final VoidCallback? onTap;
  final AppColorScheme colors;

  const _AvatarPlaceholder({
    this.inicial,
    this.fotoB64,
    this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [c.primary, c.success],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: c.primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: fotoB64 != null
                    ? ClipOval(
                        child: Image.memory(
                          base64Decode(fotoB64!),
                          width: 88, height: 88,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        ),
                      )
                    : Center(
                        child: inicial != null
                            ? Text(
                                inicial!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                Icons.person_rounded,
                                size: 44,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                      ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: c.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.cardBackground, width: 2),
                  ),
                  child: const Icon(Icons.photo_camera_rounded,
                      size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Toca para agregar una foto (opcional)',
          style: TextStyle(color: c.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}
