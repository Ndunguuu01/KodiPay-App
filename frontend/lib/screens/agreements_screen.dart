import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lease_provider.dart';
import '../utils/constants.dart';
import 'agreement_details_screen.dart';

class AgreementsScreen extends StatefulWidget {
  const AgreementsScreen({super.key});

  @override
  State<AgreementsScreen> createState() => _AgreementsScreenState();
}

class _AgreementsScreenState extends State<AgreementsScreen> {
  @override
  void initState() {
    super.initState();
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    if (userId != null) {
      Future.microtask(() => Provider.of<LeaseProvider>(context, listen: false)
          .fetchLeases(userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Agreements'),
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
            return const Center(
              child: Text('No agreements found.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.leases.length,
            itemBuilder: (context, index) {
              final lease = provider.leases[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text('Lease #${lease.id}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rent: KES ${lease.rentAmount}'),
                      Text('Status: ${lease.status.toUpperCase()}'),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AgreementDetailsScreen(lease: lease),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
