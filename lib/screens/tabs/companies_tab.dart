import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mooves/constants/colors.dart';
import 'package:mooves/constants/api_config.dart';
import 'package:mooves/services/store_service.dart';
import 'package:mooves/screens/store_profile_screen.dart';
import 'package:mooves/widgets/app_bar_logo.dart';

class CompaniesTab extends StatefulWidget {
  const CompaniesTab({super.key});

  @override
  State<CompaniesTab> createState() => _CompaniesTabState();
}

class _CompaniesTabState extends State<CompaniesTab> {
  List<Map<String, dynamic>> _companies = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final companies = await StoreService.getAllStores();
      setState(() {
        _companies = companies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load companies: $e';
        _isLoading = false;
      });
    }
  }

  String _getCompanyImageUrl(Map<String, dynamic>? company) {
    if (company == null) return '';
    return StoreService.getStoreImageUrl(company);
  }

  List<Map<String, dynamic>> get _filteredCompanies {
    if (_searchQuery.isEmpty) {
      return _companies;
    }
    final query = _searchQuery.toLowerCase();
    return _companies.where((company) {
      final name = (company['storeName'] ?? '').toString().toLowerCase();
      final description = (company['description'] ?? '').toString().toLowerCase();
      final location = (company['location'] ?? '').toString().toLowerCase();
      return name.contains(query) || 
             description.contains(query) || 
             location.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPink,
      appBar: AppBar(
        backgroundColor: AppColors.pinkCard,
        elevation: 0,
        title: const AppBarLogo(title: 'Companies'),
        iconTheme: const IconThemeData(color: AppColors.textOnPink),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.pinkCard,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search companies...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.backgroundPink,
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
                  borderSide: const BorderSide(color: AppColors.accentCoral, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              ),
            ),
          ),
          // Companies list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadCompanies,
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
                                onPressed: _loadCompanies,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _filteredCompanies.isEmpty
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
                                    _searchQuery.isEmpty
                                        ? 'No companies found'
                                        : 'No companies match your search',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textOnPink,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'Check back later for new companies!'
                                        : 'Try a different search term',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredCompanies.length,
                              itemBuilder: (context, index) {
                                final company = _filteredCompanies[index];
                                final imageUrl = _getCompanyImageUrl(company);
                                final storeId = company['id'] ?? company['_id'] ?? company['Id'] ?? company['ID'];
                                final storeIdString = storeId?.toString();

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  color: AppColors.pinkCard,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      if (storeIdString != null && storeIdString.isNotEmpty) {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => StoreProfileScreen(storeId: storeIdString),
                                          ),
                                        );
                                      } else {
                                        debugPrint('Company ID not found in company object');
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          // Company image
                                          Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppColors.pinkAccent.withOpacity(0.3),
                                                width: 2,
                                              ),
                                            ),
                                            child: imageUrl.isNotEmpty
                                                ? ClipOval(
                                                    child: Image.network(
                                                      imageUrl,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Container(
                                                          color: AppColors.pinkMedium,
                                                          child: const Icon(
                                                            Icons.store,
                                                            size: 40,
                                                            color: AppColors.textSecondary,
                                                          ),
                                                        );
                                                      },
                                                      loadingBuilder: (context, child, loadingProgress) {
                                                        if (loadingProgress == null) return child;
                                                        return Container(
                                                          color: AppColors.pinkMedium,
                                                          child: Center(
                                                            child: CircularProgressIndicator(
                                                              value: loadingProgress.expectedTotalBytes != null
                                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                                      loadingProgress.expectedTotalBytes!
                                                                  : null,
                                                              valueColor: const AlwaysStoppedAnimation<Color>(
                                                                AppColors.primaryPurple,
                                                              ),
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
                                                      size: 40,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                          ),
                                          const SizedBox(width: 16),
                                          // Company info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  company['storeName'] ?? 'Company',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.textOnPink,
                                                  ),
                                                ),
                                                if (company['description'] != null && (company['description'] as String).isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    company['description'],
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                                if (company['location'] != null && (company['location'] as String).isNotEmpty) ...[
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.location_on,
                                                        size: 16,
                                                        color: AppColors.textSecondary,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          company['location'],
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            color: AppColors.textSecondary,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.chevron_right,
                                            color: AppColors.textSecondary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

