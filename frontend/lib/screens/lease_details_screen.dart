import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lease.dart';
import '../providers/auth_provider.dart';
import '../providers/lease_provider.dart';
import '../utils/constants.dart';

class LeaseDetailsScreen extends StatelessWidget {
  final Lease lease;

  const LeaseDetailsScreen({super.key, required this.lease});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isLandlord = auth.userRole == 'landlord';
    final userId = auth.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lease Details'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailCard(
              title: 'Unit Information',
              children: [
                _buildDetailRow('Unit Number', lease.unit?.unitNumber ?? 'Unknown'),
                _buildDetailRow('Property', lease.unit?.propertyName ?? 'Unknown'), // Assuming Unit has propertyName
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              title: 'Lease Terms',
              children: [
                _buildDetailRow('Start Date', lease.startDate),
                _buildDetailRow('End Date', lease.endDate),
                _buildDetailRow('Rent Amount', 'KES ${lease.rentAmount.toStringAsFixed(2)}'),
                _buildDetailRow('Status', lease.status.toUpperCase(), 
                  valueColor: _getStatusColor(lease.status)),
              ],
            ),
            const SizedBox(height: 16),
            if (lease.terms != null && lease.terms!.isNotEmpty)
              _buildDetailCard(
                title: 'Additional Terms',
                children: [
                  Text(lease.terms!),
                ],
              ),
            const SizedBox(height: 32),
            
            // Actions
            Consumer<LeaseProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!isLandlord && lease.status == 'pending') {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final success = await provider.signLease(lease.id!, userId!);
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Lease signed successfully!')),
                          );
                          Navigator.of(context).pop();
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(provider.errorMessage ?? 'Failed to sign lease')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Sign Lease Agreement'),
                    ),
                  );
                }

                if (isLandlord && lease.status == 'active') {
                   return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Show confirmation dialog
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Terminate Lease'),
                            content: const Text('Are you sure you want to terminate this lease? This action cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Terminate', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          final success = await provider.terminateLease(lease.id!, userId!);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Lease terminated successfully!')),
                            );
                            Navigator.of(context).pop();
                          } else if (context.mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(provider.errorMessage ?? 'Failed to terminate lease')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Terminate Lease'),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'terminated':
        return Colors.red;
      default:
        return Colors.black;
    }
  }
}
