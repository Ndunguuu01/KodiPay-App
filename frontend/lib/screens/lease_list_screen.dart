import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lease_provider.dart';
import '../utils/constants.dart';
import 'create_lease_screen.dart';
import 'lease_details_screen.dart';
import '../widgets/empty_state.dart';

class LeaseListScreen extends StatefulWidget {
  const LeaseListScreen({super.key});

  @override
  State<LeaseListScreen> createState() => _LeaseListScreenState();
}

class _LeaseListScreenState extends State<LeaseListScreen> {
  bool _isInit = true;
  bool _isLandlord = false;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      _isLandlord = auth.userRole == 'landlord';
      final userId = auth.userId;

      if (userId != null) {
        Provider.of<LeaseProvider>(context, listen: false)
            .fetchLeases(userId, isLandlord: _isLandlord);
      }
      _isInit = false;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lease Agreements'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<LeaseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(child: Text('Error: ${provider.errorMessage}'));
          }

          if (provider.leases.isEmpty) {
            return EmptyStateWidget(
              title: 'No Leases Found',
              message: _isLandlord
                  ? 'You have not created any leases yet.'
                  : 'You do not have any active lease agreements.',
              icon: Icons.description_outlined,
              actionLabel: _isLandlord ? 'Create Lease' : null,
              onActionPressed: _isLandlord
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const CreateLeaseScreen()),
                      );
                    }
                  : null,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.leases.length,
            itemBuilder: (context, index) {
              final lease = provider.leases[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(
                    'Unit ${lease.unit?.unitNumber ?? "Unknown"}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${lease.status.toUpperCase()}'),
                      Text(
                          'Rent: KES ${lease.rentAmount.toStringAsFixed(2)}'),
                      if (_isLandlord && lease.tenantName != null)
                        Text('Tenant: ${lease.tenantName}'),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LeaseDetailsScreen(lease: lease),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _isLandlord
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateLeaseScreen()),
                );
              },
              backgroundColor: AppConstants.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
