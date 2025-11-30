import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mooves/constants/colors.dart';
import 'package:mooves/services/auth_service.dart';
import 'package:mooves/services/profile_service.dart';
import 'package:mooves/services/health_connect_service.dart';
import 'package:mooves/services/google_fit_service.dart';

class ProfileTab extends StatefulWidget {
  final Function(int) navigateToTab;

  const ProfileTab({super.key, required this.navigateToTab});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _bioController = TextEditingController();

  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isUploading = false;
  bool _isSaving = false;
  bool _isConnectingGoogleFit = false;
  bool _googleFitConnected = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      Map<String, dynamic>? profile;
      try {
        profile = await ProfileService.getProfile();
      } catch (e) {
        if (e.toString().contains('Profile not found')) {
          profile = {};
        } else {
          rethrow;
        }
      }

      if (!mounted) return;

      // Load Health Connect status
      final healthStatus = await HealthConnectService.getStatus();
      
      // Load Google Fit status
      final googleFitStatus = await GoogleFitService.getStatus();

      setState(() {
        // Preserve images if they exist and profile doesn't have them yet
        final existingImages = _profile?['images'];
        if (existingImages != null && 
            (profile?['images'] == null || 
             (profile?['images'] is List && (profile?['images'] as List).isEmpty))) {
          profile?['images'] = existingImages;
          // Also preserve profilePicture if it exists
          if (_profile?['profilePicture'] != null && profile?['profilePicture'] == null) {
            profile?['profilePicture'] = _profile?['profilePicture'];
          }
        }
        
        _profile = profile;
        _bioController.text = profile?['bio'] ?? '';
        _googleFitConnected = googleFitStatus['connected'] ?? false;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String? _currentImageUrl() {
    final images = _profile?['images'];
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first is Map<String, dynamic> && first['imageUrl'] is String) {
        final url = ProfileService.getFullImageUrl(first['imageUrl'] as String);
        debugPrint('🖼️ Profile image URL from images array: $url');
        return url;
      }
    }

    final profilePicture = _profile?['profilePicture'];
    if (profilePicture is String && profilePicture.isNotEmpty) {
      final url = ProfileService.getFullImageUrl(profilePicture);
      debugPrint('🖼️ Profile image URL from profilePicture: $url');
      return url;
    }

    debugPrint('❌ No profile image URL found. Images: ${_profile?['images']}, profilePicture: ${_profile?['profilePicture']}');
    return null;
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
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

      setState(() {
        _isUploading = true;
        _error = null;
      });

      final images = _profile?['images'];
      if (images is List && images.isNotEmpty) {
        final first = images.first;
        final imageId = first is Map<String, dynamic> ? first['id'] : null;
        if (imageId != null) {
          await ProfileService.deleteImage(imageId.toString());
        }
      }

      // Upload the image and get the updated response
      final uploadResponse = await ProfileService.uploadProfilePicture(image.path);
      
      // Update the profile state immediately with the images from the response
      // The upload response already has transformed URLs
      if (mounted && uploadResponse != null && uploadResponse['images'] != null) {
        final images = uploadResponse['images'] as List;
        if (images.isNotEmpty) {
          debugPrint('📸 Upload response received with ${images.length} images');
          setState(() {
            // Update profile with new images
            final currentProfile = Map<String, dynamic>.from(_profile ?? {});
            currentProfile['images'] = images;
            
            // Always use the first image as profilePicture (images are ordered by backend)
            final firstImage = images.first;
            if (firstImage is Map && firstImage['imageUrl'] != null) {
              final imageUrl = firstImage['imageUrl'] as String;
              currentProfile['profilePicture'] = imageUrl;
              debugPrint('✅ Updated profilePicture to: $imageUrl');
            }
            
            _profile = currentProfile;
            debugPrint('📋 Profile updated. Images count: ${(_profile?['images'] as List?)?.length ?? 0}');
          });
        } else {
          debugPrint('⚠️ Upload response has no images');
        }
      } else {
        debugPrint('⚠️ Upload response is null or missing images');
      }
      
      // Refresh the full profile after a short delay to ensure server has processed the upload
      // This ensures all profile data is in sync
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await _loadProfile();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Photo updated',
              style: TextStyle(color: AppColors.textOnPink),
            ),
            backgroundColor: AppColors.pinkCard,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'Failed to update photo';
      if (e.toString().contains('Network error')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      } else if (e.toString().contains('No authentication token')) {
        errorMessage = 'Please sign in again to upload photos.';
      } else if (e.toString().contains('Maximum of 6 images')) {
        errorMessage = 'You can only upload up to 6 photos. Please remove one first.';
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      setState(() {
        _error = errorMessage;
      });
      // Also show as SnackBar for immediate feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _removePhoto() async {
    final images = _profile?['images'];
    if (images is! List || images.isEmpty) {
      return;
    }

    final first = images.first;
    final imageId = first is Map<String, dynamic> ? first['id'] : null;
    if (imageId == null) {
      return;
    }

    try {
      setState(() {
        _isUploading = true;
        _error = null;
      });

      await ProfileService.deleteImage(imageId.toString());
      await _loadProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Photo removed',
              style: TextStyle(color: AppColors.textOnPink),
            ),
            backgroundColor: AppColors.pinkCard,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to remove photo: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final bio = _bioController.text.trim();
      await ProfileService.updateProfile(
        bio: bio.isEmpty ? null : bio,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Profile updated',
            style: TextStyle(color: AppColors.textOnPink),
          ),
          backgroundColor: AppColors.pinkCard,
        ),
      );
      await _loadProfile();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to save profile: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _connectGoogleFit() async {
    setState(() {
      _isConnectingGoogleFit = true;
      _error = null;
    });

    try {
      // Connect Google Fit (opens OAuth in browser)
      final result = await GoogleFitService.connectGoogleFit();
      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Please complete authorization in browser. Return to this app after authorizing.',
              style: const TextStyle(color: AppColors.textOnPink),
            ),
            backgroundColor: AppColors.pinkCard,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Check Status',
              textColor: AppColors.textOnPink,
              onPressed: () {
                _loadProfile();
              },
            ),
          ),
        );
        // Start polling for connection status after user returns from browser
        _pollGoogleFitStatus();
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to connect Google Fit';
        });
        if (!mounted) return;
        setState(() {
          _isConnectingGoogleFit = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error connecting Google Fit: $e';
        _isConnectingGoogleFit = false;
      });
    }
  }

  void _pollGoogleFitStatus() {
    // Poll every 2 seconds for up to 30 seconds to check if user completed authorization
    int attempts = 0;
    const maxAttempts = 15;
    
    Future.delayed(const Duration(seconds: 2), () async {
      while (attempts < maxAttempts && mounted) {
        attempts++;
        final status = await GoogleFitService.getStatus();
        if (status['connected'] == true) {
          if (mounted) {
            setState(() {
              _googleFitConnected = true;
              _isConnectingGoogleFit = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Google Fit connected successfully!',
                  style: TextStyle(color: AppColors.textOnPink),
                ),
                backgroundColor: AppColors.pinkCard,
              ),
            );
            await _loadProfile();
          }
          return;
        }
        await Future.delayed(const Duration(seconds: 2));
      }
      
      // Stop polling after max attempts
      if (mounted) {
        setState(() {
          _isConnectingGoogleFit = false;
        });
      }
    });
  }

  Future<void> _disconnectGoogleFit() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.pinkCard, // Pink background
        title: const Text(
          'Disconnect Google Fit',
          style: TextStyle(color: AppColors.textOnPink),
        ),
        content: const Text(
          'Are you sure you want to disconnect Google Fit?',
          style: TextStyle(color: AppColors.textOnPink),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textOnPink),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Disconnect',
              style: TextStyle(color: AppColors.textOnPink),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isConnectingGoogleFit = true;
      _error = null;
    });

    try {
      final result = await GoogleFitService.disconnect();
      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Google Fit disconnected',
              style: const TextStyle(color: AppColors.textOnPink),
            ),
            backgroundColor: AppColors.pinkCard,
          ),
        );
        await _loadProfile();
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to disconnect Google Fit';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error disconnecting Google Fit: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isConnectingGoogleFit = false;
      });
    }
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
        backgroundColor: AppColors.pinkCard, // Pink background
        title: const Text(
          'Delete Account',
          style: TextStyle(color: AppColors.textOnPink),
        ),
        content: const Text(
          'Are you sure? This will permanently remove your training history and rewards.',
          style: TextStyle(color: AppColors.textOnPink),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textOnPink),
            ),
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
        _isSaving = true;
      });

      final result = await AuthService.deleteAccount();
      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.of(context).pushNamedAndRemoveUntil('/signin', (route) => false);
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
        _isSaving = false;
      });
    }
  }

  Widget _buildAvatar() {
    final imageUrl = _currentImageUrl();
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.pinkCard,
              child: CircularProgressIndicator(
                color: AppColors.textOnPink,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ Error loading profile image: $error');
            debugPrint('   URL: $imageUrl');
            debugPrint('   Stack: $stackTrace');
            return const CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.pinkCard,
              child: Icon(
                Icons.person_outline,
                size: 48,
                color: AppColors.textSecondary,
              ),
            );
          },
        ),
      );
    }

    return const CircleAvatar(
      radius: 60,
      backgroundColor: AppColors.pinkCard,
      child: Icon(
        Icons.person_outline,
        size: 48,
        color: AppColors.textSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPink, // Pink background
      appBar: AppBar(
        backgroundColor: AppColors.pinkCard, // Pink app bar
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppColors.textOnPink,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textOnPink),
      ),
      body: RefreshIndicator(  
        onRefresh: _loadProfile,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
          const SizedBox(height: 8),
          Center(child: _buildAvatar()),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _isUploading ? null : () => _pickAndUploadImage(ImageSource.gallery),
                icon: _isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.photo_library_outlined),
                label: Text(_isUploading ? 'Uploading...' : 'Update photo'),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: _isUploading || _currentImageUrl() == null ? null : _removePhoto,
                child: const Text('Remove'),
              ),
            ],
          ),
          if (_error != null && _error!.contains('photo')) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              color: AppColors.pinkCard, // Pink background for input
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _bioController,
              maxLines: 4,
              style: const TextStyle(color: AppColors.textOnPink),
              decoration: InputDecoration(
                labelText: 'Training bio',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                hintText: 'Share what motivates you and the goals you are chasing.',
                hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.6)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.pinkAccent.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.pinkAccent.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.accentCoral, width: 2),
                ),
                filled: true,
                fillColor: AppColors.pinkCard,
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Google Fit Connection Section
          const Text(
            'Google Fit',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: AppColors.pinkCard, // Pink card background
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _googleFitConnected ? Icons.check_circle : Icons.link_off,
                        color: _googleFitConnected ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _googleFitConnected ? 'Connected' : 'Not Connected',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: _googleFitConnected ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _googleFitConnected
                        ? 'Your running activities are automatically synced from Google Fit.'
                        : 'Connect Google Fit to automatically track your running and detect when you reach your goals.',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  if (_googleFitConnected)
                    OutlinedButton.icon(
                      onPressed: _isConnectingGoogleFit ? null : _disconnectGoogleFit,
                      icon: const Icon(Icons.link_off),
                      label: const Text('Disconnect'),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _isConnectingGoogleFit ? null : _connectGoogleFit,
                      icon: _isConnectingGoogleFit
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.fitness_center),
                      label: const Text('Connect Google Fit'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Health Connect Connection Section
          const Text(
            'Health Connect',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: AppColors.pinkCard, // Pink card background
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<Map<String, dynamic>>(
                    future: HealthConnectService.getStatus(),
                    builder: (context, snapshot) {
                      final healthConnected = snapshot.data?['connected'] ?? false;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                healthConnected ? Icons.check_circle : Icons.link_off,
                                color: healthConnected ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                healthConnected ? 'Connected' : 'Not Connected',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: healthConnected ? Colors.green : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            healthConnected
                                ? 'Your running activities are automatically synced from Health Connect.'
                                : 'Connect Health Connect to automatically track your running and detect when you reach your goals.',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          if (healthConnected)
                            OutlinedButton.icon(
                              onPressed: () async {
                                // Health Connect doesn't have a disconnect method, 
                                // user needs to revoke permissions in Health Connect app
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'To disconnect, revoke permissions in Health Connect app settings.',
                                      style: TextStyle(color: AppColors.textOnPink),
                                    ),
                                    backgroundColor: AppColors.pinkCard,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.link_off),
                              label: const Text('Disconnect'),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: () async {
                                final result = await HealthConnectService.requestPermissions();
                                if (mounted) {
                                  if (result['success'] == true) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          result['message'] ?? 'Health Connect connected',
                                          style: const TextStyle(color: AppColors.textOnPink),
                                        ),
                                        backgroundColor: AppColors.pinkCard,
                                      ),
                                    );
                                    setState(() {}); // Refresh to show new status
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          result['message'] ?? 'Failed to connect Health Connect',
                                          style: const TextStyle(color: AppColors.textOnPink),
                                        ),
                                        backgroundColor: AppColors.pinkCard,
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.fitness_center),
                              label: const Text('Connect Health Connect'),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          if (_profile?['user'] != null) ...[
            const Text(
              'Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              (_profile!['user']?['firstName'] != null)
                  ? '${_profile!['user']['firstName']} ${_profile!['user']['lastName'] ?? ''}'
                  : 'Mooves athlete',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textOnPink,
              ),
            ),
            Text(
              _profile!['user']?['email'] ?? '',
              style: const TextStyle(fontSize: 16, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 16),
          ],
          if (_error != null) ...[
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
          ],
          ElevatedButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ?                 const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryPurple, // Purple instead of white
                    ),
                  )
                : const Text('Save changes'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _isSaving ? null : _handleSignOut,
            child: const Text('Sign out'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isSaving ? null : _handleDeleteAccount,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete account'),
          ),
        ],
      ),
      ),
    );
  }
}