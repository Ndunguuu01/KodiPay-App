import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/unit.dart';
import '../models/payment.dart';
import '../providers/payment_provider.dart';
import '../providers/unit_provider.dart';
import '../services/user_service.dart';
import '../utils/constants.dart';

import 'add_unit_screen.dart';

class UnitDetailsScreen extends StatefulWidget {
  final Unit unit;

  const UnitDetailsScreen({super.key, required this.unit});

  @override
  State<UnitDetailsScreen> createState() => _UnitDetailsScreenState();
}

class _UnitDetailsScreenState extends State<UnitDetailsScreen> {
  bool _isLoading = true;
  List<Payment> _unitPayments = [];
  Map<String, dynamic>? _tenantDetails;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    // Fetch payments for this unit
    // Note: In a real app, we might want a specific endpoint for unit payments
    // For now, we'll fetch all payments and filter (or rely on provider if it supports filtering)
    // Ideally, PaymentProvider should have a method to fetch by unitId
    
    // Simulating fetch for now or using existing provider
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    await paymentProvider.fetchPayments(); // This fetches all payments for the user (if tenant) or all for landlord?
    // We need to verify what fetchPayments does for a landlord.
    // If it fetches ALL payments, we can filter here.
    
    // Fetch tenant details if tenantId exists
    if (widget.unit.tenantId != null) {
      try {
        final userDetails = await UserService().getUserById(widget.unit.tenantId!);
        if (mounted) {
          setState(() {
            _tenantDetails = userDetails;
          });
        }
      } catch (e) {
        // Handle error silently or show snackbar
        print('Error fetching tenant details: $e');
      }
    }

    if (mounted) {
      setState(() {
        _unitPayments = paymentProvider.payments.where((p) => p.unitId == widget.unit.id).toList();
        _isLoading = false;
      });
    }
  }

  void _deleteUnit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Unit'),
        content: const Text('Are you sure you want to delete this unit? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await Provider.of<UnitProvider>(context, listen: false)
          .deleteUnit(widget.unit.id!, widget.unit.propertyId!);

      if (success && mounted) {
        Navigator.of(context).pop(); // Return to property details
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unit deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Unit ${widget.unit.unitNumber}'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddUnitScreen(
                    propertyId: widget.unit.propertyId!,
                    unit: widget.unit,
                  ),
                ),
              );
              // Refresh data after edit
              if (mounted) {
                 // We might need to re-fetch unit details or rely on provider update
                 // Since we passed unit object, it might be stale. 
                 // Ideally we should fetch unit by ID again or pop back.
                 // For now, let's just pop back to property details to see updated list is safer
                 // Or we can just setState if we had a way to refresh 'widget.unit'
                 Navigator.of(context).pop();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteUnit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTenantInfoCard(),
            const SizedBox(height: 24),
            Text(
              'Payment History',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildPaymentHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildTenantInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: AppConstants.primaryColor,
                  child: Icon(Icons.person, size: 30, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.unit.tenantName ?? 'Unknown Tenant',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Occupant',
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow(Icons.email, 'Email', _tenantDetails?['email'] ?? 'N/A'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone, 'Phone', _tenantDetails?['phone'] ?? 'N/A'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.attach_money, 'Rent Amount', 'KES ${widget.unit.rentAmount}'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.calendar_today, 'Lease Status', 'Active'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppConstants.secondaryColor),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentHistory() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_unitPayments.isEmpty) {
      return const Center(child: Text('No payment history found.'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _unitPayments.length,
      itemBuilder: (context, index) {
        final payment = _unitPayments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: payment.status == 'completed' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              child: Icon(
                payment.status == 'completed' ? Icons.check : Icons.access_time,
                color: payment.status == 'completed' ? Colors.green : Colors.orange,
              ),
            ),
            title: Text('KES ${payment.amount}'),
            subtitle: Text(payment.paymentMethod.toUpperCase()),
            trailing: Text(
              payment.createdAt != null
                  ? '${payment.createdAt!.day}/${payment.createdAt!.month}/${payment.createdAt!.year}'
                  : '-',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}
