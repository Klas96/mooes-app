import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mooves/constants/colors.dart';
import 'package:mooves/constants/api_config.dart';
import 'package:mooves/services/coupon_service.dart';
import 'package:mooves/services/store_goal_service.dart';
import 'package:mooves/screens/reward_qr_screen.dart';
import 'package:mooves/screens/store_profile_screen.dart';
import 'package:mooves/screens/store_goal_detail_screen.dart';
import 'package:mooves/models/training_entry.dart';
import 'package:mooves/widgets/app_bar_logo.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  List<Map<String, dynamic>> _coupons = [];
  List<Map<String, dynamic>> _challenges = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load both coupons and challenges in parallel
      final results = await Future.wait([
        CouponService.getUserCoupons(),
        StoreGoalService.getActiveGoals(),
      ]);

      setState(() {
        _coupons = results[0] as List<Map<String, dynamic>>;
        _challenges = results[1] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCoupons() async {
    await _loadData();
  }

  String _getStoreImageUrl(Map<String, dynamic>? store) {
    if (store == null) return '';
    final imagePath = store['profilePicture'] ?? store['logo'];
    if (imagePath == null || imagePath.isEmpty) return '';
    
    // If it's already a full URL, return as is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    
    // If it's a relative path, construct full URL
    if (imagePath.startsWith('/uploads/')) {
      return '${ApiConfig.baseUrl}$imagePath';
    }
    
    return imagePath;
  }

  String _formatDistance(int? meters) {
    if (meters == null) return '';
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(0)} km';
    }
    return '$meters m';
  }

  String _formatDuration(int? minutes) {
    if (minutes == null) return '';
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '$hours h';
      }
      return '$hours h $mins min';
    }
    return '$minutes min';
  }

  Widget _buildChallengeCard(Map<String, dynamic> goal) {
    final store = goal['store'] as Map<String, dynamic>?;
    final isFull = goal['isFull'] == true;
    final isCompleted = goal['isCompleted'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isCompleted 
          ? AppColors.accentCoral.withOpacity(0.1)
          : AppColors.pinkCard,
      elevation: isCompleted ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCompleted
            ? const BorderSide(
                color: AppColors.accentCoral,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StoreGoalDetailScreen(goalId: goal['id']),
            ),
          );
          if (result == true) {
            _loadData(); // Refresh if user joined or completed
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store name
              if (store != null) ...[
                InkWell(
                  onTap: () {
                    final storeId = store['id'] ?? store['Id'] ?? store['ID'];
                    final storeIdString = storeId?.toString();
                    if (storeIdString != null && storeIdString.isNotEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StoreProfileScreen(storeId: storeIdString),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_getStoreImageUrl(store).isNotEmpty)
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: NetworkImage(_getStoreImageUrl(store)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        if (_getStoreImageUrl(store).isNotEmpty) const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            store['storeName'] ?? 'Store',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.open_in_new,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // Goal title with completion status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goal['title'] ?? 'Challenge',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textOnPink,
                      ),
                    ),
                  ),
                  if (goal['isCompleted'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentCoral.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accentCoral,
                          width: 1.5,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppColors.accentCoral,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentCoral,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (goal['description'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  goal['description'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              // Goal targets
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (goal['targetDistanceMeters'] != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.straighten,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDistance(goal['targetDistanceMeters']),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textOnPink,
                          ),
                        ),
                      ],
                    ),
                  if (goal['targetDurationMinutes'] != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(goal['targetDurationMinutes']),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textOnPink,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Dates
              Row(
                children: [
                  if (goal['startDate'] != null)
                    Text(
                      'Starts: ${DateFormat('MMM d, y').format(DateTime.parse(goal['startDate']))}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (goal['endDate'] != null) ...[
                    const SizedBox(width: 16),
                    Text(
                      'Ends: ${DateFormat('MMM d, y').format(DateTime.parse(goal['endDate']))}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              if (goal['participantCount'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${goal['participantCount']} participants',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (goal['isCompleted'] == true) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentCoral.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accentCoral.withOpacity(0.5),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        size: 20,
                        color: AppColors.accentCoral,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You completed this challenge! 🎉',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentCoral,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (isFull && goal['isCompleted'] != true) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentCoral.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Full',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentCoral,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Reward preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryPurple.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_offer,
                      size: 20,
                      color: AppColors.primaryPurple,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        goal['couponDescription'] ?? 'Reward coupon',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textOnPink,
                        ),
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
        title: const AppBarLogo(title: 'Challenges & Coupons'),
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
                : _challenges.isEmpty && _coupons.isEmpty
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
                              'No challenges or coupons yet',
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
                        itemCount: _challenges.length + _coupons.length,
                        itemBuilder: (context, index) {
                          // Show challenges first, then coupons
                          if (index < _challenges.length) {
                            return _buildChallengeCard(_challenges[index]);
                          }
                          final couponIndex = index - _challenges.length;
                          final coupon = _coupons[couponIndex];
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
                                          if (coupon['store'] != null && _getStoreImageUrl(coupon['store']).isNotEmpty)
                                            InkWell(
                                              onTap: () {
                                                final storeId = coupon['store']['id']?.toString();
                                                if (storeId != null) {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) => StoreProfileScreen(storeId: storeId),
                                                    ),
                                                  );
                                                }
                                              },
                                              borderRadius: BorderRadius.circular(16),
                                              child: Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  image: DecorationImage(
                                                    image: NetworkImage(_getStoreImageUrl(coupon['store'])),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          if (coupon['store'] != null && _getStoreImageUrl(coupon['store']).isNotEmpty)
                                            const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (coupon['store'] != null)
                                                  InkWell(
                                                    onTap: () {
                                                      final storeId = coupon['store']['id']?.toString();
                                                      if (storeId != null) {
                                                        Navigator.of(context).push(
                                                          MaterialPageRoute(
                                                            builder: (_) => StoreProfileScreen(storeId: storeId),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Flexible(
                                                            child: Text(
                                                              coupon['store']['storeName'] ?? 'Store',
                                                              style: const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight: FontWeight.w600,
                                                                color: AppColors.textSecondary,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 4),
                                                          const Icon(
                                                            Icons.open_in_new,
                                                            size: 14,
                                                            color: AppColors.textSecondary,
                                                          ),
                                                        ],
                                                      ),
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

