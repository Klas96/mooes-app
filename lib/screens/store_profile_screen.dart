import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mooves/constants/colors.dart';
import 'package:mooves/constants/api_config.dart';
import 'package:mooves/services/store_service.dart';
import 'package:mooves/widgets/app_bar_logo.dart';

class StoreProfileScreen extends StatefulWidget {
  final String storeId;

  const StoreProfileScreen({super.key, required this.storeId});

  @override
  State<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> {
  Map<String, dynamic>? _store;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStore();
  }

  Future<void> _loadStore() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('Loading store with ID: ${widget.storeId}');
      final store = await StoreService.getStoreById(widget.storeId);
      if (!mounted) return;

      setState(() {
        _store = store;
        _isLoading = false;
        if (store == null) {
          _error = 'Store not found. The store may not exist or may have been removed.';
        } else {
          debugPrint('Store loaded successfully: ${store['storeName']}');
        }
      });
    } catch (e) {
      debugPrint('Error loading store: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load store: $e';
        _isLoading = false;
      });
    }
  }

  String _getStoreImageUrl() {
    if (_store == null) return '';
    return StoreService.getStoreImageUrl(_store);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPink,
      appBar: AppBar(
        backgroundColor: AppColors.pinkCard,
        elevation: 0,
        title: const AppBarLogo(title: 'Store Profile'),
        iconTheme: const IconThemeData(color: AppColors.textOnPink),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
              ),
            )
          : _error != null || _store == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.store_outlined,
                        size: 64,
                        color: AppColors.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error ?? 'Store not found',
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppColors.textOnPink,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStore,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStore,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Picture
                        Center(
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.pinkCard,
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryPurple.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _getStoreImageUrl().isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      _getStoreImageUrl(),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: AppColors.pinkMedium,
                                          child: const Icon(
                                            Icons.store,
                                            size: 64,
                                            color: AppColors.textSecondary,
                                          ),
                                        );
                                      },
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                    loadingProgress.expectedTotalBytes!
                                                : null,
                                            valueColor: const AlwaysStoppedAnimation<Color>(
                                              AppColors.primaryPurple,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : Container(
                                    color: AppColors.pinkMedium,
                                    child: const Icon(
                                      Icons.store,
                                      size: 64,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Store Name
                        Center(
                          child: Text(
                            _store!['storeName'] ?? 'Store',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textOnPink,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Store Information Card
                        Card(
                          color: AppColors.pinkCard,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Description
                                if (_store!['description'] != null &&
                                    (_store!['description'] as String).isNotEmpty) ...[
                                  const Text(
                                    'About',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textOnPink,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _store!['description'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textSecondary,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                // Location
                                if (_store!['location'] != null &&
                                    (_store!['location'] as String).isNotEmpty) ...[
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        color: AppColors.primaryPurple,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _store!['location'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: AppColors.textOnPink,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                // Status
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      color: AppColors.textSecondary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _store!['isActive'] == true
                                          ? 'Active Store'
                                          : 'Inactive Store',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _store!['isActive'] == true
                                            ? AppColors.primaryPurple
                                            : AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }
}

