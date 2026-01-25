import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tally/core/data/repositories/profile_repository.dart';
import 'package:tally/features/auth/data/repositories/auth_repository.dart';

import '../../../../core/presentation/widgets/section_header.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _nameController = TextEditingController();
  bool _isEditingName = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controller with current name
    final profile = ref.read(profileRepositoryProvider).getProfileSync();
    _nameController.text = profile?.name ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch profile changes
    final profileStream = ref.watch(
      profileRepositoryProvider.select((repo) => repo.watchProfile()),
    );

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        if (_isEditingName) {
          setState(() {
            _isEditingName = false;
            final profile = ref
                .read(profileRepositoryProvider)
                .getProfileSync();
            _nameController.text = profile?.name ?? '';
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Account',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
        ),
        body: StreamBuilder(
          stream: profileStream,
          initialData: ref.read(profileRepositoryProvider).getProfileSync(),
          builder: (context, snapshot) {
            final profile = snapshot.data;
            final user = ref.read(authRepositoryProvider).currentUser;

            // Sync controller if not editing
            if (!_isEditingName &&
                !_isLoading &&
                profile?.name != null &&
                _nameController.text != profile!.name) {
              _nameController.text = profile.name!;
            }

            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              children: [
                // 1. Profile Avatar Header
                Center(
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: ColoredBox(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              child: profile?.photoUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: profile!.photoUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          _buildAvatarPlaceholder(
                                            context,
                                            profile,
                                            user,
                                          ),
                                    )
                                  : _buildAvatarPlaceholder(
                                      context,
                                      profile,
                                      user,
                                    ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Material(
                          color: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 3,
                            ),
                          ),
                          elevation: 2,
                          child: InkWell(
                            onTap: _showPhotoOptions,
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Icon(
                                Icons.edit_rounded,
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 2. Personal Information Group
                const SectionHeader(title: 'Personal Information'),
                _buildSettingsGroup(
                  context,
                  children: [
                    // Name Tile with Inline Edit
                    _isEditingName
                        ? _buildInlineEditTile(context)
                        : _buildSettingsTile(
                            context,
                            label: 'Full Name',
                            value: profile?.name?.isNotEmpty == true
                                ? profile!.name
                                : 'Not set',
                            icon: Icons.person_outline_rounded,
                            onTap: () => setState(() => _isEditingName = true),
                            showChevron: true,
                          ),
                    const Divider(height: 1, indent: 56),
                    // Email Tile (Read Only)
                    _buildSettingsTile(
                      context,
                      label: 'Email',
                      value: user?.email,
                      icon: Icons.email_outlined,
                      onTap: null, // Read only
                      trailing: Icon(
                        Icons.lock_outline_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 3. Security Group
                const SectionHeader(title: 'Security'),
                _buildSettingsGroup(
                  context,
                  children: [
                    _buildSettingsTile(
                      context,
                      label: 'Change Password',
                      icon: Icons.key_rounded,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password reset coming soon'),
                          ),
                        );
                      },
                      showChevron: true,
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildSettingsTile(
                      context,
                      label: 'Two-Factor Authentication',
                      icon: Icons.verified_user_outlined,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('2FA coming soon')),
                        );
                      },
                      showChevron: true,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 4. Danger Zone
                const SectionHeader(title: 'Account Management'),
                _buildSettingsGroup(
                  context,
                  children: [
                    _buildSettingsTile(
                      context,
                      label: 'Delete Account',
                      icon: Icons.delete_outline_rounded,
                      iconColor: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.38),
                      textColor: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.38),
                      onTap: null,
                    ),
                  ],
                ),

                const SizedBox(height: 48),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(
    BuildContext context,
    dynamic profile,
    dynamic user,
  ) {
    return Center(
      child: Text(
        ((profile?.name?.isNotEmpty == true ? profile!.name![0] : null) ??
                (user?.email?.isNotEmpty == true ? user!.email![0] : 'U'))
            .toUpperCase(),
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required String label,
    required IconData icon,
    String? value,
    VoidCallback? onTap,
    Color? iconColor,
    Color? textColor,
    Widget? trailing,
    bool showChevron = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (iconColor ?? colorScheme.primary).withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: textColor ?? colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (value != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
              if (showChevron)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: colorScheme.outline.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInlineEditTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.edit_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Full Name',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: 20,
                  child: TextFormField(
                    controller: _nameController,
                    autofocus: true,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      hintText: 'Enter name',
                    ),
                    onFieldSubmitted: (_) => _saveName(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: _saveName,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _isEditingName = false;
      _isLoading = true;
    });

    try {
      await ref.read(profileRepositoryProvider).updateName(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update name: $e')));
        setState(() => _isEditingName = true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            if (ref
                    .read(profileRepositoryProvider)
                    .getProfileSync()
                    ?.photoUrl !=
                null)
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Remove Photo',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removePhoto();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Helper method used by _removePhoto and _pickImage
  Future<void> _deleteOldAvatar(SupabaseClient supabase, String userId) async {
    try {
      final List<FileObject> objects = await supabase.storage
          .from('avatars')
          .list(path: userId);

      if (objects.isNotEmpty) {
        final paths = objects.map((e) => '$userId/${e.name}').toList();
        await supabase.storage.from('avatars').remove(paths);
      }
    } catch (e) {
      debugPrint('Error deleting old avatar: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final userId = ref.read(authRepositoryProvider).currentUser?.id;

        if (userId == null) return;

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Uploading photo...')));
        }

        try {
          final supabase = ref.read(profileRepositoryProvider).supabase;

          // 0. Clean up old files to prevent accommodation
          await _deleteOldAvatar(supabase, userId);

          // 1. Upload file to Supabase Storage
          final fileExt = result.files.single.extension ?? 'jpg';
          final fileName = 'avatar.$fileExt';
          final filePath = '$userId/$fileName';

          // Upsert the file
          await supabase.storage
              .from('avatars')
              .upload(
                filePath,
                file,
                fileOptions: const FileOptions(upsert: true),
              );

          // 2. Get Public URL
          final publicUrl = supabase.storage
              .from('avatars')
              .getPublicUrl(filePath);

          // 3. Update Profile
          // Hack: Add timestamp to URL to force refresh if URL is same
          final timestampedUrl =
              '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

          await ref
              .read(profileRepositoryProvider)
              .updatePhotoUrl(timestampedUrl);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile photo updated')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Failed to upload: $e')));
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _removePhoto() async {
    try {
      final userId = ref.read(authRepositoryProvider).currentUser?.id;
      if (userId != null) {
        final supabase = ref.read(profileRepositoryProvider).supabase;
        await _deleteOldAvatar(supabase, userId);
      }

      await ref.read(profileRepositoryProvider).updatePhotoUrl(null);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Photo removed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to remove photo: $e')));
      }
    }
  }
}
