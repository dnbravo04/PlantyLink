import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';

/// Result of [chooseProfilePhoto].
sealed class ProfilePhotoAction {}

class ProfilePhotoPicked extends ProfilePhotoAction {
  final String base64Jpeg;
  ProfilePhotoPicked(this.base64Jpeg);
}

class ProfilePhotoRemoved extends ProfilePhotoAction {}

/// Shows a bottom sheet to pick a profile photo from the gallery or camera
/// (optionally offering removal), then compresses it client-side.
///
/// The photo is resized to ≤384 px JPEG (~15–50 KB) so it can live directly
/// in RTDB at `usuarios/{uid}/foto_b64` without needing Firebase Storage.
/// Returns null when the user cancels.
Future<ProfilePhotoAction?> chooseProfilePhoto(
  BuildContext context, {
  bool canRemove = false,
}) async {
  final c = AppColors.of(context);

  final choice = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: c.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: c.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(Icons.photo_library_outlined, color: c.primary),
            title: Text('Elegir de la galería',
                style: TextStyle(color: c.textPrimary, fontSize: 14)),
            onTap: () => Navigator.pop(ctx, 'gallery'),
          ),
          ListTile(
            leading: Icon(Icons.photo_camera_outlined, color: c.info),
            title: Text('Tomar foto',
                style: TextStyle(color: c.textPrimary, fontSize: 14)),
            onTap: () => Navigator.pop(ctx, 'camera'),
          ),
          if (canRemove)
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: c.error),
              title: Text('Quitar foto',
                  style: TextStyle(color: c.error, fontSize: 14)),
              onTap: () => Navigator.pop(ctx, 'remove'),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  if (choice == null) return null;
  if (choice == 'remove') return ProfilePhotoRemoved();

  final file = await ImagePicker().pickImage(
    source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
    maxWidth: 384,
    maxHeight: 384,
    imageQuality: 65,
    requestFullMetadata: false,
  );
  if (file == null) return null;

  final bytes = await file.readAsBytes();
  return ProfilePhotoPicked(base64Encode(bytes));
}
