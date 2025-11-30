import 'package:flutter/material.dart';
import 'package:mooves/constants/colors.dart';
import 'package:mooves/services/coupon_service.dart';
import 'package:mooves/screens/reward_qr_screen.dart';
import 'package:mooves/models/training_entry.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  List<Map<String, dynamic>> _coupons = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final coupons = await CouponService.getUserCoupons();
      setState(() {
        _coupons = coupons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load coupons: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _useCoupon(String couponId) async {
    try {
      final result = await CouponService.useCoupon(couponId);
      if (result['success'] == true) {
        await _loadCoupons();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Coupon marked as used',
                style: TextStyle(color: AppColors.textOnPink),
              ),
              backgroundColor: AppColors.pinkCard,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Failed to use coupon',
                style: const TextStyle(color: AppColors.textOnPink),
              ),
              backgroundColor: AppColors.pinkCard,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error using coupon: $e',
              style: const TextStyle(color: AppColors.textOnPink),
            ),
            backgroundColor: AppColors.pinkCard,
          ),
        );
      }
    }
  }

  void _showCouponQR(Map<String, dynamic> coupon) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.pinkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Coupon Code',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textOnPink,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: QrImageView(
                data: coupon['code'] ?? '',
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.pinkMedium,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                coupon['code'] ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnPink,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (coupon['description'] != null) ...[
              const SizedBox(height: 12),
              Text(
                coupon['description'],
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (coupon['expiresAt'] != null) ...[
              const SizedBox(height: 12),
              Text(
                'Expires: ${DateFormat('MMM d, y').format(DateTime.parse(coupon['expiresAt']))}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (coupon['isUsed'] != true)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _useCoupon(coupon['id']);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Mark as Used'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPink,
      appBar: AppBar(
        backgroundColor: AppColors.pinkCard,
        elevation: 0,
        title: const Text(
          'My Coupons',
          style: TextStyle(
            color: AppColors.textOnPink,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textOnPink),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCoupons,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
                ),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: AppColors.textOnPink),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadCoupons,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _coupons.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_offer_outlined,
                              size: 64,
                              color: AppColors.textSecondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No coupons yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textOnPink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Complete store challenges to earn coupons!',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _coupons.length,
                        itemBuilder: (context, index) {
                          final coupon = _coupons[index];
                          final isUsed = coupon['isUsed'] == true;
                          final isExpired = coupon['expiresAt'] != null &&
                              DateTime.parse(coupon['expiresAt']).isBefore(DateTime.now());

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            color: AppColors.pinkCard,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: InkWell(
                              onTap: () => _showCouponQR(coupon),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Store and goal info
                                    if (coupon['store'] != null || coupon['goal'] != null) ...[
                                      Row(
                                        children: [
                                          if (coupon['store'] != null &&
                                              coupon['store']['logo'] != null)
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                image: DecorationImage(
                                                  image: NetworkImage(coupon['store']['logo']),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          if (coupon['store'] != null &&
                                              coupon['store']['logo'] != null)
                                            const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (coupon['store'] != null)
                                                  Text(
                                                    coupon['store']['storeName'] ?? 'Store',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                                if (coupon['goal'] != null) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    coupon['goal']['title'] ?? 'Challenge',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          if (isUsed)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.textSecondary.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                'Used',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                          if (isExpired && !isUsed)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
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
                                      ),
                                      const SizedBox(height: 12),
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
                                      Text(
                                        'Expires: ${DateFormat('MMM d, y').format(DateTime.parse(coupon['expiresAt']))}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                    if (coupon['usedAt'] != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Used: ${DateFormat('MMM d, y').format(DateTime.parse(coupon['usedAt']))}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    // Tap to view QR code
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryPurple.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.qr_code,
                                            size: 20,
                                            color: AppColors.primaryPurple,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Tap to view QR code',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: AppColors.primaryPurple,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

