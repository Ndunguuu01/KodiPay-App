import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/lease_provider.dart';
import '../providers/maintenance_provider.dart';
import '../models/maintenance_request.dart';
import '../utils/constants.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  bool _isInit = true;
  String? _userRole;
  int? _userId;

  // Form fields for new request
  final _formKey = GlobalKey<FormState>();
  String _issueType = 'plumbing';
  final _descriptionController = TextEditingController();

  @override
  void didChangeDependencies() {
    if (_isInit) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      _userRole = auth.userRole;
      _userId = auth.userId;
      
      if (_userId != null) {
        Provider.of<MaintenanceProvider>(context, listen: false)
            .fetchRequests(userId: _userId, isLandlord: _userRole == 'landlord');
      }
      _isInit = false;
    }
    super.didChangeDependencies();
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Issue'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _issueType,
                items: ['plumbing', 'electrical', 'appliance', 'structural', 'other']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _issueType = val!),
                decoration: const InputDecoration(labelText: 'Issue Type'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Consumer<MaintenanceProvider>(
            builder: (context, provider, child) {
              return ElevatedButton(
                onPressed: provider.isLoading ? null : () async {
                  if (_formKey.currentState!.validate()) {
                    // Fetch active lease to get unitId
                    final leaseProvider = Provider.of<LeaseProvider>(context, listen: false);
                    final activeLeases = leaseProvider.leases.where((l) => l.status == 'active');
                    
                    if (activeLeases.isEmpty) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No active lease found. Cannot report issue.')),
                      );
                      return;
                    }

                    final activeLease = activeLeases.first;

                    final request = MaintenanceRequest(
                      tenantId: _userId!,
                      unitId: activeLease.unitId,
                      issueType: _issueType,
                      description: _descriptionController.text,
                      priority: 'medium',
                      status: 'pending',
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    final success = await provider.createRequest(request);
                    if (success && context.mounted) {
                      Navigator.pop(context);
                      _descriptionController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Request submitted successfully')),
                      );
                    } else if (context.mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(provider.errorMessage ?? 'Failed')),
                      );
                    }
                  }
                },
                child: provider.isLoading
                    ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Submit'),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Requests'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: _userRole == 'tenant'
          ? FloatingActionButton(
              onPressed: _showCreateDialog,
              backgroundColor: AppConstants.secondaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Consumer<MaintenanceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.requests.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.requests.isEmpty) {
            return const Center(child: Text('No maintenance requests found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.requests.length,
            itemBuilder: (context, index) {
              final req = provider.requests[index];
              final status = req.status;
              Color statusColor = Colors.grey;
              if (status == 'pending') statusColor = Colors.orange;
              if (status == 'in_progress') statusColor = Colors.blue;
              if (status == 'resolved') statusColor = Colors.green;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            req.issueType.toUpperCase(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(req.description),
                      const SizedBox(height: 8),
                      Text(
                        'Unit: ${req.unitNumber ?? 'N/A'} • Date: ${req.createdAt.toString().substring(0, 10)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      // Landlord actions could go here (update status)
                      // For now, we just display.
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
