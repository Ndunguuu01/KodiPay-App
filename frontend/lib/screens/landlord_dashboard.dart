import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/auth_provider.dart';
import '../providers/property_provider.dart';
import '../utils/constants.dart';
import 'add_property_screen.dart';

import 'login_screen.dart';
import 'profile_screen.dart';
import 'property_details_screen.dart';
import 'payments_screen.dart';
import 'messages_screen.dart';
import 'agreements_screen.dart';
import 'maintenance_screen.dart';
import '../services/dashboard_service.dart';
import '../services/notification_service.dart';
import '../services/report_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';
import 'post_ad_screen.dart';
import '../widgets/promo_carousel.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/empty_state.dart';

class LandlordDashboard extends StatefulWidget {
  const LandlordDashboard({super.key});

  @override
  State<LandlordDashboard> createState() => _LandlordDashboardState();
}

class _LandlordDashboardState extends State<LandlordDashboard> {
  Map<String, dynamic>? _insights;
  bool _isLoadingInsights = true;

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<PropertyProvider>(context, listen: false).fetchProperties();
      _fetchInsights();
      NotificationService().init();
    });
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = AdService.createBannerAd()
      ..load().then((_) {
        if (mounted) {
          setState(() {
            _isAdLoaded = true;
          });
        }
      });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _fetchInsights() async {
    try {
      final insights = await DashboardService().getLandlordInsights();
      if (mounted) {
        setState(() {
          _insights = insights;
          _isLoadingInsights = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingInsights = false);
      }
      // Fail silently or show snackbar
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Properties'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      drawer: _buildDrawer(context),
      body: Consumer<PropertyProvider>(
        builder: (context, provider, child) {
          // ... (existing builder code) ...
          if (provider.errorMessage != null) {
            return Center(child: Text('Error: ${provider.errorMessage}'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.fetchProperties();
              await _fetchInsights();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreeting(),
                  if (_isLoadingInsights)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_insights != null)
                    Column(
                      children: [
                        _buildStatsGrid(),
                        if (_insights!['fraudAlerts'] != null && (_insights!['fraudAlerts'] as List).isNotEmpty)
                          _buildRiskAlerts(_insights!['fraudAlerts']),
                      ],
                    ),
                  
                  const SizedBox(height: 16),
                  // Global Ads Section
                  const PromoCarousel(),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Marketplace',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const PostAdScreen()),
                            );
                          },
                          child: const Text('Post Ad'),
                        ),
                      ],
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Properties',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                             Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
                            );
                          }, 
                          child: const Text('Add New'),
                        ),
                      ],
                    ),
                  ),

                  if (provider.isLoading)
                    const PropertyListSkeleton()
                  else if (provider.properties.isEmpty)
                    EmptyStateWidget(
                      title: 'No Properties Yet',
                      message: 'Add your first property to start managing units and tenants.',
                      icon: Icons.apartment,
                      actionLabel: 'Add Property',
                      onActionPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
                        );
                      },
                    )
                  else
                    AnimationLimiter(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: provider.properties.length,
                        itemBuilder: (context, index) {
                          final property = provider.properties[index];
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(12),
                                    leading: Hero(
                                      tag: 'property_icon_${property.id}',
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppConstants.primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.apartment, color: AppConstants.primaryColor),
                                      ),
                                    ),
                                    title: Text(property.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(property.location, style: const TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text('${property.floorsCount} Floors', style: const TextStyle(fontSize: 12, color: AppConstants.secondaryColor)),
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => PropertyDetailsScreen(property: property),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 80), // Space for FAB
                  ],
                ),
              ),
            );
          },
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'ai_fab',
              onPressed: () {
                // Navigate to AI Chat
                // Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiChatScreen()));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('KodiPay AI coming soon!')));
              },
              backgroundColor: AppConstants.secondaryColor,
              child: const Icon(Icons.auto_awesome, color: Colors.white),
            ),
            const SizedBox(height: 16),
            FloatingActionButton.extended(
              heroTag: 'add_property_fab',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
                );
              },
              backgroundColor: AppConstants.primaryColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Property', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        bottomNavigationBar: _isAdLoaded
            ? SizedBox(
                height: _bannerAd!.size.height.toDouble(),
                width: _bannerAd!.size.width.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              )
            : null,
      );
    }

    Widget _buildStatsGrid() {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
              Expanded(
                child: _buildStatCard(
                  'Occupancy',
                  '${_insights!['occupancyRate']}%',
                  Icons.pie_chart,
                  Colors.blue,
                  '${_insights!['occupiedUnits']}/${_insights!['totalUnits']} Units',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Revenue',
                  'KES ${_insights!['monthlyRevenue']}',
                  Icons.attach_money,
                  Colors.green,
                  'Monthly Potential',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Maintenance',
                  '${_insights!['pendingMaintenance']}',
                  Icons.build,
                  Colors.orange,
                  'Pending Requests',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Properties',
                  '${_insights!['totalProperties']}',
                  Icons.domain,
                  Colors.purple,
                  'Total Managed',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ReportService().generateMonthlyReport(_insights!);
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Generate Monthly Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.secondaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskAlerts(List<dynamic> alerts) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Risk Alerts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.errorColor),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return Card(
                color: Colors.red[50],
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text('Suspicious Payment: KES ${alert['amount']}'),
                  subtitle: Text('Unit: ${alert['unit']['unit_number']} - ${alert['fraud_flags'][0]}'),
                  trailing: Text(alert['fraud_status'].toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[500], fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        final name = auth.userName ?? 'Landlord';
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          decoration: const BoxDecoration(
            color: AppConstants.primaryColor,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting,',
                style: const TextStyle(fontSize: 18, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.apartment, size: 48, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  'KodiPay',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Properties'),
            onTap: () {
              Navigator.pop(context); // Close drawer
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Payments'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PaymentsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text('Messages'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MessagesScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Agreements'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AgreementsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.build),
            title: const Text('Maintenance'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MaintenanceScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
