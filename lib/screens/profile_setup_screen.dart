import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mooves/constants/colors.dart';
import 'package:mooves/main.dart';
import 'package:mooves/services/auth_service.dart';
import 'package:mooves/services/profile_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _initialising = true;
  bool _isProcessing = false;
  String? _selectedImagePath;
  Map<String, dynamic>? _profile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      Map<String, dynamic>? data;
      try {
        data = await ProfileService.getProfile();
      } catch (e) {
        if (!e.toString().contains('Profile not found')) {
          rethrow;
        }
      }

      if (!mounted) return;
      setState(() {
        _profile = data;
        _initialising = false;
        _error = null;
      });

      if (data != null && ProfileService.isProfileComplete(data)) {
        _navigateHome();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initialising = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        return;
      }

      if (!mounted) return;
      setState(() {
        _selectedImagePath = image.path;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to pick image: $e';
      });
    }
  }

  Future<void> _uploadSelectedImage() async {
    if (_selectedImagePath == null) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final images = _profile?['images'];
      if (images is List && images.isNotEmpty) {
        final first = images.first;
        final imageId = first is Map<String, dynamic> ? first['id'] : null;
        if (imageId != null) {
          await ProfileService.deleteImage(imageId.toString());
        }
      }

      await ProfileService.uploadProfilePicture(_selectedImagePath!);
      final refreshedProfile = await ProfileService.getProfile();
      if (!mounted) return;
      setState(() {
        _profile = refreshedProfile;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to upload image: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _handleContinue() async {
    if (_isProcessing) return;

    if (_selectedImagePath != null) {
      await _uploadSelectedImage();
      if (!mounted) return;
    }

    _navigateHome();
  }

  Future<void> _handleSkip() async {
    if (_isProcessing) return;
    _navigateHome();
  }

  Future<void> _handleSignOut() async {
    try {
      await AuthService.signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/signin');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to sign out: $e';
      });
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This will remove all of your training data and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    try {
      setState(() {
        _isProcessing = true;
      });

      final result = await AuthService.deleteAccount();
      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/signin', (route) => false);
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to delete account';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to delete account: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _navigateHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainTabScreen()),
    );
  }

  String? _existingImageUrl() {
    final images = _profile?['images'];
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first is Map && first['imageUrl'] != null) {
        return ProfileService.getFullImageUrl(first['imageUrl'] as String);
      }
    }
    final profilePicture = _profile?['profilePicture'];
    if (profilePicture is String && profilePicture.isNotEmpty) {
      return ProfileService.getFullImageUrl(profilePicture);
    }
    return null;
  }

  Widget _buildImagePreview() {
    final localPath = _selectedImagePath;
    final remoteUrl = _existingImageUrl();

    if (localPath != null) {
      if (kIsWeb) {
        return ClipOval(
          child: Image.network(
            localPath,
            width: 140,
            height: 140,
            fit: BoxFit.cover,
          ),
        );
      }
      return ClipOval(
        child: Image.file(
          File(localPath),
          width: 140,
          height: 140,
          fit: BoxFit.cover,
        ),
      );
    }

    if (remoteUrl != null && remoteUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          remoteUrl,
          width: 140,
          height: 140,
          fit: BoxFit.cover,
        ),
      );
    }

    return CircleAvatar(
      radius: 70,
      backgroundColor: AppColors.surfaceLight,
      child: const Icon(
        Icons.camera_alt_outlined,
        size: 48,
        color: AppColors.textSecondaryLight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initialising) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Your Profile'),
        actions: [
          TextButton(
            onPressed: _handleSkip,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add a photo (optional)',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Mooves uses your photo on QR rewards and in your training timeline. You can always add one later.',
                style: TextStyle(
                    fontSize: 16, color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 32),
              Center(child: _buildImagePreview()),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Choose Photo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing
                          ? null
                          : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Take Photo'),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 12),
              ],
              ElevatedButton(
                onPressed: _isProcessing ? null : _handleContinue,
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Continue'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _isProcessing ? null : _handleSkip,
                child: const Text('Set up later'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _isProcessing ? null : _handleSignOut,
                    child: const Text('Sign out'),
                  ),
                  TextButton(
                    onPressed: _isProcessing ? null : _handleDeleteAccount,
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete account'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
