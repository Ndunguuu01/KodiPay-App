import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lease.dart';
import '../providers/auth_provider.dart';
import '../providers/lease_provider.dart';
import '../utils/constants.dart';

class AgreementDetailsScreen extends StatelessWidget {
  final Lease lease;

  const AgreementDetailsScreen({super.key, required this.lease});

  void _signLease(BuildContext context) async {
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    if (userId == null) return;

    final success = await Provider.of<LeaseProvider>(context, listen: false)
        .signLease(lease.id!, userId);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agreement signed successfully!')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agreement #${lease.id}'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Status', lease.status.toUpperCase()),
            const Divider(),
            _buildDetailRow('Start Date', lease.startDate ?? 'N/A'),
            const Divider(),
            _buildDetailRow('End Date', lease.endDate ?? 'N/A'),
            const Divider(),
            _buildDetailRow('Rent Amount', 'KES ${lease.rentAmount}'),
            const Divider(),
            const Text(
              'Terms & Conditions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                lease.terms ?? 'No terms specified.',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),
            if (lease.status == 'pending')
              SizedBox(
                width: double.infinity,
                child: Consumer<LeaseProvider>(
                  builder: (context, provider, child) {
                    return ElevatedButton(
                      onPressed: provider.isLoading ? null : () => _signLease(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: provider.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Sign Agreement',
                              style: TextStyle(fontSize: 18),
                            ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
