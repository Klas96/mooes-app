import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mooves/constants/colors.dart';
import 'package:mooves/constants/api_config.dart';
import 'package:mooves/services/store_service.dart';
import 'package:mooves/services/coupon_service.dart';
import 'package:mooves/widgets/app_bar_logo.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class StoreProfileScreen extends StatefulWidget {
  final String storeId;

  const StoreProfileScreen({super.key, required this.storeId});

  @override
  State<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> {
  Map<String, dynamic>? _store;
  List<Map<String, dynamic>> _coupons = [];
  bool _isLoading = true;
  bool _couponsLoading = false;
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

      // Load coupons after store is loaded
      if (store != null) {
        _loadCoupons();
      }
    } catch (e) {
      debugPrint('Error loading store: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load store: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCoupons() async {
    setState(() {
      _couponsLoading = true;
    });

    try {
      final coupons = await CouponService.getStoreCoupons(widget.storeId);
      if (!mounted) return;

      setState(() {
        _coupons = coupons;
        _couponsLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading coupons: $e');
      if (!mounted) return;
      setState(() {
        _couponsLoading = false;
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
                                // Website
                                if (_store!['website'] != null &&
                                    (_store!['website'] as String).isNotEmpty) ...[
                                  InkWell(
                                    onTap: () async {
                                      final website = _store!['website'] as String;
                                      final url = Uri.parse(
                                        website.startsWith('http://') || website.startsWith('https://')
                                            ? website
                                            : 'https://$website'
                                      );
                                      try {
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url, mode: LaunchMode.externalApplication);
                                        }
                                      } catch (e) {
                                        debugPrint('Error launching website: $e');
                                      }
                                    },
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.language,
                                          color: AppColors.primaryPurple,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _store!['website'],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: AppColors.primaryPurple,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.open_in_new,
                                          size: 16,
                                          color: AppColors.primaryPurple,
                                        ),
                                      ],
                                    ),
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
                        // Coupons Section
                        if (!_couponsLoading && _coupons.isNotEmpty) ...[
                          const Text(
                            'Available Coupons',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textOnPink,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._coupons.map((coupon) => _buildCouponCard(coupon)),
                          const SizedBox(height: 24),
                        ] else if (_couponsLoading) ...[
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> coupon) {
    final isExpired = coupon['expiresAt'] != null &&
        DateTime.parse(coupon['expiresAt']).isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.pinkCard,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Goal info if available
            if (coupon['goal'] != null) ...[
              Text(
                coupon['goal']['title'] ?? 'Challenge Reward',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Coupon description
            Text(
              coupon['description'] ?? 'Reward coupon',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textOnPink,
              ),
            ),
            const SizedBox(height: 8),
            // Discount info
            Row(
              children: [
                const Icon(
                  Icons.local_offer,
                  size: 20,
                  color: AppColors.primaryPurple,
                ),
                const SizedBox(width: 8),
                if (coupon['discount'] != null)
                  Text(
                    '${coupon['discount']}% off',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                if (coupon['discountAmount'] != null)
                  Text(
                    '${coupon['discountAmount']} kr off',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryPurple,
                    ),
                  ),
              ],
            ),
            if (coupon['expiresAt'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: isExpired ? Colors.red : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Expires: ${DateFormat('MMM d, y').format(DateTime.parse(coupon['expiresAt']))}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isExpired ? Colors.red : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            if (isExpired) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Expired',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

