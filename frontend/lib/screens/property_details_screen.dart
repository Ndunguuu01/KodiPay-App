import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/property.dart';
import '../models/unit.dart';
import '../providers/unit_provider.dart';
import '../services/user_service.dart';
import '../utils/constants.dart';
import 'add_unit_screen.dart';
import 'assign_tenant_screen.dart';
import 'add_bill_screen.dart';
import 'unit_details_screen.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final Property property;

  const PropertyDetailsScreen({super.key, required this.property});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<UnitProvider>(context, listen: false)
        .fetchUnits(widget.property.id!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.property.name),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Hero(
                      tag: 'property_icon_${widget.property.id}',
                      child: const Icon(Icons.location_on, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.property.location,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.layers, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.property.floorsCount} Floors',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Units',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Consumer<UnitProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null) {
                  return Center(child: Text('Error: ${provider.errorMessage}'));
                }

                if (provider.units.isEmpty) {
                  return const Center(
                    child: Text('No units found. Add one!'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.units.length,
                  itemBuilder: (context, index) {
                    final unit = provider.units[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: unit.status == 'occupied'
                            ? () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => UnitDetailsScreen(unit: unit),
                                  ),
                                );
                              }
                            : null,
                        leading: CircleAvatar(
                          backgroundColor: unit.status == 'vacant'
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          child: Text(
                            unit.unitNumber,
                            style: TextStyle(
                              color: unit.status == 'vacant'
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          unit.status == 'occupied' && unit.tenantName != null 
                              ? unit.tenantName! 
                              : 'Unit ${unit.unitNumber}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Rent: KES ${unit.rentAmount}'),
                            Text(
                              unit.status.toUpperCase(),
                              style: TextStyle(
                                color: unit.status == 'vacant'
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (unit.status == 'occupied')
                              IconButton(
                                icon: const Icon(Icons.receipt_long, color: Colors.orange),
                                tooltip: 'Add Bill',
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AddBillScreen(
                                        unitId: unit.id!,
                                        tenantId: unit.tenantId!,
                                        unitNumber: unit.unitNumber,
                                        tenantName: unit.tenantName ?? 'Unknown',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            unit.status == 'vacant'
                                ? IconButton(
                                    icon: const Icon(Icons.person_add, color: AppConstants.primaryColor),
                                    onPressed: () => _showAssignTenantDialog(context, unit),
                                  )
                                : const SizedBox.shrink(), // Placeholder for more options
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddUnitScreen(propertyId: widget.property.id!),
            ),
          );
        },
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAssignTenantDialog(BuildContext context, Unit unit) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AssignTenantScreen(
          unitId: unit.id!,
          unitNumber: unit.unitNumber,
          rentAmount: unit.rentAmount,
        ),
      ),
    );
  }
}
