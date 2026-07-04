import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// The user's avatar, resolved in priority order:
///
/// 1. `usuarios/{uid}/foto_b64` — legacy inline photo (pre-Storage)
/// 2. `usuarios/{uid}/foto_url` — photo uploaded to Firebase Storage
/// 3. [FirebaseAuth] `photoURL` — e.g. the Google account picture
/// 4. Gradient tile with the first letter of `nombre`
class UserAvatar extends StatelessWidget {
  /// The `usuarios/{uid}` map from `userProfileProvider` (may be empty).
  final Map<String, dynamic> user;
  final double size;

  /// Corner radius; defaults to a rounded square like the dashboard tile.
  final double? radius;

  const UserAvatar({
    super.key,
    required this.user,
    this.size = 42,
    this.radius,
  });

  // Decoding 30–80 KB of base64 on every rebuild (dashboard ticks every 3 s)
  // is wasteful — memoize the last decoded photo.
  static String? _cachedB64;
  static Uint8List? _cachedBytes;

  static Uint8List? _decode(String b64) {
    if (b64 == _cachedB64) return _cachedBytes;
    try {
      _cachedBytes = base64Decode(b64);
      _cachedB64 = b64;
      return _cachedBytes;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final borderRadius = BorderRadius.circular(radius ?? size / 3);

    final b64 = user['foto_b64'] as String?;
    final bytes = b64 != null && b64.isNotEmpty ? _decode(b64) : null;
    if (bytes != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    }

    final nombre = user['nombre']?.toString() ?? '';
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.primary, c.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: borderRadius,
      ),
      child: Center(
        child: nombre.isNotEmpty
            ? Text(
                nombre[0].toUpperCase(),
                style: TextStyle(
                  fontSize: size * 0.43,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              )
            : Icon(Icons.person_rounded,
                size: size * 0.5, color: Colors.white),
      ),
    );

    final photoUrl = (user['foto_url'] as String?) ??
        FirebaseAuth.instance.currentUser?.photoURL;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image.network(
          photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => fallback,
        ),
      );
    }

    return fallback;
  }
}
