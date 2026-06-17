import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/app_scaffold.dart';
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
      await ref.read(profileServiceProvider)?.updateUserProfile(
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
      await ref.read(profileServiceProvider)?.deleteUserData(uid);
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

    ref.listen<AsyncValue<Map<String, dynamic>>>(userProfileProvider,
        (_, next) {
      next.whenData((user) {
        if (!_initialized) {
          _initialized = true;
          if (!_isEditingName) {
            _nameController.text = user['nombre']?.toString() ?? '';
          }
          if (!_isEditingCity) {
            _cityController.text = user['ciudad']?.toString() ?? '';
          }
        }
      });
    });

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
        final name = _nameController.text.isNotEmpty
            ? _nameController.text
            : user['nombre']?.toString() ?? '';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: c.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.cardBorder, width: 1.5),
          ),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [c.info, c.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ),
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
