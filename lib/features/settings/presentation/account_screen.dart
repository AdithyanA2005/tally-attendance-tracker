import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tally/core/data/repositories/profile_repository.dart';
import 'package:tally/core/presentation/widgets/section_header.dart';
import 'package:tally/features/auth/data/repositories/auth_repository.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Account'), centerTitle: true),
      body: StreamBuilder(
        stream: profileStream,
        initialData: ref.read(profileRepositoryProvider).getProfileSync(),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          final user = ref.read(authRepositoryProvider).currentUser;

          // Fallback if name not yet set in local state but present in profile
          if (!_isEditingName &&
              profile?.name != null &&
              _nameController.text != profile!.name) {
            _nameController.text = profile.name!;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Profile Photo
                Center(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          backgroundImage: profile?.photoUrl != null
                              ? CachedNetworkImageProvider(profile!.photoUrl!)
                              : null,
                          child: profile?.photoUrl == null
                              ? Text(
                                  ((profile?.name?.isNotEmpty == true
                                              ? profile!.name![0]
                                              : null) ??
                                          (user?.email?.isNotEmpty == true
                                              ? user!.email![0]
                                              : 'U'))
                                      .toUpperCase(),
                                  style: const TextStyle(fontSize: 48),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Material(
                          color: Theme.of(context).colorScheme.primary,
                          shape: const CircleBorder(),
                          elevation: 4,
                          child: InkWell(
                            onTap: _showPhotoOptions,
                            customBorder: const CircleBorder(),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Name Field
                const SectionHeader(title: 'Personal Info'),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  enabled: _isEditingName,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            onPressed: () {
                              if (_isEditingName) {
                                _saveName();
                              } else {
                                setState(() => _isEditingName = true);
                              }
                            },
                            icon: Icon(
                              _isEditingName
                                  ? Icons.check_rounded
                                  : Icons.edit_rounded,
                              color: _isEditingName
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                  ),
                  onSubmitted: (_) => _saveName(),
                ),

                const SizedBox(height: 24),

                // Email Field (Read-only)
                TextField(
                  controller: TextEditingController(text: user?.email),
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerLow,
                  ),
                ),
              ],
            ),
          );
        },
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
        setState(() => _isEditingName = true); // Re-enable if failed
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => Column(
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
          if (ref.read(profileRepositoryProvider).getProfileSync()?.photoUrl !=
              null)
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
              ),
              title: const Text(
                'Remove Photo',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _removePhoto();
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

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
      // Continue even if delete fails (e.g. folder empty)
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
