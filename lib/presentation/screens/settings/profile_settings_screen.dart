import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/utils/profile_photo.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/user_avatar.dart';
import '../../../app.dart';

/// User profile & account management screen.
class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  bool _isEditingName = false;
  bool _isEditingCity = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveUserProfile() async {
    try {
      await ref.read(userServiceProvider)?.updateUserProfile(
            _nameController.text.trim(),
            _cityController.text.trim(),
          );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar perfil')),
        );
      }
    }
  }

  Future<void> _changePhoto(bool hasPhoto) async {
    final service = ref.read(userServiceProvider);
    if (service == null) {
      AppToast.show(context,
          message: 'No disponible en modo demo', type: ToastType.info);
      return;
    }
    final action = await chooseProfilePhoto(context, canRemove: hasPhoto);
    if (action == null) return;
    try {
      switch (action) {
        case ProfilePhotoPicked(:final bytes):
          await service.setUserPhoto(bytes);
        case ProfilePhotoRemoved():
          await service.removeUserPhoto();
      }
      if (mounted) {
        AppToast.show(context,
            message: 'Foto de perfil actualizada', type: ToastType.success);
      }
    } catch (_) {
      if (mounted) {
        AppToast.show(context,
            message: 'Error al actualizar la foto', type: ToastType.error);
      }
    }
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final isEmailUser =
        user.providerData.any((p) => p.providerId == 'password');
    if (!isEmailUser) {
      if (!mounted) return;
      final c = AppColors.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'El cambio de contraseña solo aplica para cuentas de correo electrónico.'),
          backgroundColor: c.textMuted,
        ),
      );
      return;
    }

    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final dc = AppColors.of(ctx);
          return AlertDialog(
            backgroundColor: dc.cardBackground,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Cambiar contraseña',
                style: TextStyle(color: dc.textPrimary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                      labelText: 'Contraseña actual',
                      labelStyle: TextStyle(color: dc.textMuted)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                      labelText: 'Nueva contraseña',
                      labelStyle: TextStyle(color: dc.textMuted)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                      labelText: 'Confirmar contraseña',
                      labelStyle: TextStyle(color: dc.textMuted)),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Cancelar',
                      style: TextStyle(color: dc.textSecondary))),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child:
                      Text('Guardar', style: TextStyle(color: dc.primary))),
            ],
          );
        },
      );

      if (confirmed != true || !mounted) return;
      final c = AppColors.of(context);

      if (newCtrl.text != confirmCtrl.text) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Las contraseñas no coinciden.'),
            backgroundColor: c.error));
        return;
      }
      if (newCtrl.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text(
                'La contraseña debe tener al menos 6 caracteres.'),
            backgroundColor: c.error));
        return;
      }

      try {
        final cred = EmailAuthProvider.credential(
            email: user.email!, password: currentCtrl.text);
        await user.reauthenticateWithCredential(cred);
        await user.updatePassword(newCtrl.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Contraseña actualizada.'),
              backgroundColor: c.success));
        }
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        final msg = e.code == 'wrong-password'
            ? 'Contraseña actual incorrecta.'
            : 'Error: ${e.message}';
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: c.error));
      }
    } finally {
      currentCtrl.dispose();
      newCtrl.dispose();
      confirmCtrl.dispose();
    }
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dc = AppColors.of(ctx);
        return AlertDialog(
          backgroundColor: dc.cardBackground,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Eliminar cuenta', style: TextStyle(color: dc.error)),
          content: Text(
            'Esta acción es irreversible. Se eliminarán tu perfil y todos tus datos.\n\n¿Deseas continuar?',
            style: TextStyle(color: dc.textSecondary),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancelar',
                    style: TextStyle(color: dc.textSecondary))),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Eliminar', style: TextStyle(color: dc.error))),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      final uid = user.uid;
      await ref.read(userServiceProvider)?.deleteUserData(uid);
      await GoogleSignIn().signOut();
      await user.delete();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.home, (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final c = AppColors.of(context);
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text(
                'Por seguridad, cierra sesión y vuelve a iniciarla antes de eliminar la cuenta.'),
            backgroundColor: c.error));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: ${e.message}'), backgroundColor: c.error));
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dc = AppColors.of(ctx);
        return AlertDialog(
          backgroundColor: dc.cardBackground,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Cerrar sesión',
              style: TextStyle(color: dc.textPrimary, fontSize: 18)),
          content: Text('¿Estás seguro de que quieres cerrar sesión?',
              style: TextStyle(color: dc.textSecondary)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancelar',
                    style: TextStyle(color: dc.textSecondary))),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Cerrar sesión',
                    style: TextStyle(color: dc.error))),
          ],
        );
      },
    );

    if (confirmed == true) {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.home, (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final userAsync = ref.watch(userProfileProvider);

    // Seed the controllers from the profile's current value. A ref.listen
    // would miss it: the provider is usually alive (dashboard watches it),
    // so no new emission arrives after this screen opens.
    final user = userAsync.value;
    if (!_initialized && user != null) {
      _initialized = true;
      _nameController.text = user['nombre']?.toString() ?? '';
      _cityController.text = user['ciudad']?.toString() ?? '';
    }

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Perfil y cuenta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildSectionTitle('Perfil de usuario', c),
          const SizedBox(height: 8),
          _buildProfileCard(userAsync, c),
          const SizedBox(height: 24),
          _buildSectionTitle('Cuenta', c),
          const SizedBox(height: 8),
          _buildAccountCard(c),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, AppColorScheme c) {
    return Text(
      title,
      style: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary),
    );
  }

  Widget _buildProfileCard(
      AsyncValue<Map<String, dynamic>> userAsync, AppColorScheme c) {
    return userAsync.when(
      data: (user) {
        final hasPhoto = (user['foto_b64'] as String?)?.isNotEmpty == true ||
            (user['foto_url'] as String?)?.isNotEmpty == true;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: c.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.cardBorder, width: 1.5),
          ),
          child: Column(
            children: [
              // Tappable avatar with camera badge → pick/remove photo
              GestureDetector(
                onTap: () => _changePhoto(hasPhoto),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    UserAvatar(user: user, size: 88, radius: 26),
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
              const SizedBox(height: 6),
              Text('Toca para cambiar la foto',
                  style: TextStyle(fontSize: 11, color: c.textMuted)),
              const SizedBox(height: 16),
              _buildEditableRow(
                  label: 'Nombre',
                  controller: _nameController,
                  isEditing: _isEditingName,
                  onEdit: () => setState(() => _isEditingName = true),
                  onSave: () {
                    setState(() => _isEditingName = false);
                    _saveUserProfile();
                  },
                  c: c),
              const SizedBox(height: 12),
              _buildEditableRow(
                  label: 'Ciudad',
                  controller: _cityController,
                  isEditing: _isEditingCity,
                  onEdit: () => setState(() => _isEditingCity = true),
                  onSave: () {
                    setState(() => _isEditingCity = false);
                    _saveUserProfile();
                  },
                  c: c),
              const SizedBox(height: 12),
              _buildAccountInfoRow(c),
            ],
          ),
        );
      },
      loading: () =>
          Center(child: CircularProgressIndicator(strokeWidth: 2, color: c.primary)),
      error: (_, _) =>
          Text('Error al cargar perfil', style: TextStyle(color: c.textSecondary)),
    );
  }

  /// Read-only sign-in identity: email or phone plus the auth provider.
  Widget _buildAccountInfoRow(AppColorScheme c) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final providerIds = user.providerData.map((p) => p.providerId).toSet();
    final (providerLabel, providerIcon) = providerIds.contains('google.com')
        ? ('Google', Icons.g_mobiledata_rounded)
        : providerIds.contains('phone')
            ? ('Teléfono', Icons.phone_outlined)
            : ('Correo', Icons.mail_outline_rounded);

    final identity = user.email ?? user.phoneNumber ?? '—';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cuenta',
                  style: TextStyle(fontSize: 11, color: c.textSecondary)),
              const SizedBox(height: 2),
              Text(identity,
                  style: TextStyle(fontSize: 14, color: c.textPrimary)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: c.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(providerIcon, size: 14, color: c.primary),
              const SizedBox(width: 4),
              Text(providerLabel,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c.primary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableRow({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onEdit,
    required VoidCallback onSave,
    required AppColorScheme c,
  }) {
    return Row(
      children: [
        Expanded(
          child: isEditing
              ? TextField(
                  controller: controller,
                  style: TextStyle(color: c.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: label,
                    labelStyle: TextStyle(color: c.textSecondary, fontSize: 12),
                    filled: true,
                    fillColor: c.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: c.cardBorder)),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  autofocus: true,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(fontSize: 11, color: c.textSecondary)),
                    const SizedBox(height: 2),
                    Text(controller.text.isEmpty ? '—' : controller.text,
                        style: TextStyle(fontSize: 14, color: c.textPrimary)),
                  ],
                ),
        ),
        IconButton(
          icon: Icon(isEditing ? Icons.check : Icons.edit,
              color: isEditing ? c.success : c.textSecondary, size: 18),
          onPressed: isEditing ? onSave : onEdit,
        ),
      ],
    );
  }

  Widget _buildAccountCard(AppColorScheme c) {
    return Container(
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.cardBorder, width: 1.5),
      ),
      child: Column(
        children: [
          ListTile(
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.lock_reset_rounded, color: c.primary, size: 20),
            ),
            title: Text('Cambiar contraseña',
                style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
            subtitle: Text('Solo cuentas de correo',
                style: TextStyle(color: c.textMuted, fontSize: 12)),
            trailing: Icon(Icons.chevron_right_rounded, color: c.textMuted),
            onTap: _changePassword,
          ),
          Divider(height: 1, color: c.cardBorder),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: c.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.logout_rounded, color: c.warning, size: 20),
            ),
            title: Text('Cerrar sesión',
                style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
            trailing: Icon(Icons.chevron_right_rounded, color: c.textMuted),
            onTap: _signOut,
          ),
          Divider(height: 1, color: c.cardBorder),
          ListTile(
            shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(20))),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: c.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
              child:
                  Icon(Icons.delete_forever_rounded, color: c.error, size: 20),
            ),
            title: Text('Eliminar cuenta',
                style: TextStyle(
                    color: c.error,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
            subtitle: Text('Acción irreversible',
                style: TextStyle(color: c.textMuted, fontSize: 12)),
            trailing: Icon(Icons.chevron_right_rounded, color: c.textMuted),
            onTap: _deleteAccount,
          ),
        ],
      ),
    );
  }
}
