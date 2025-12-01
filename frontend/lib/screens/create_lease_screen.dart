import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/property.dart';
import '../models/unit.dart';
import '../providers/lease_provider.dart';
import '../providers/property_provider.dart';
import '../providers/unit_provider.dart';
import '../utils/constants.dart';

class CreateLeaseScreen extends StatefulWidget {
  const CreateLeaseScreen({super.key});

  @override
  State<CreateLeaseScreen> createState() => _CreateLeaseScreenState();
}

class _CreateLeaseScreenState extends State<CreateLeaseScreen> {
  final _formKey = GlobalKey<FormState>();
  
  int? _selectedPropertyId;
  int? _selectedUnitId;
  final _emailController = TextEditingController();
  final _nameController = TextEditingController(); // Optional if user exists
  final _phoneController = TextEditingController();
  final _rentController = TextEditingController();
  final _termsController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;

  bool _isLoadingInit = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await Provider.of<PropertyProvider>(context, listen: false).fetchProperties();
    setState(() {
      _isLoadingInit = false;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _rentController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  void _onPropertyChanged(int? newValue) {
    setState(() {
      _selectedPropertyId = newValue;
      _selectedUnitId = null;
    });
    if (newValue != null) {
      Provider.of<UnitProvider>(context, listen: false).fetchUnits(newValue);
    }
  }

  void _onUnitChanged(int? newValue) {
    setState(() {
      _selectedUnitId = newValue;
    });
    if (newValue != null) {
      final unit = Provider.of<UnitProvider>(context, listen: false)
          .units
          .firstWhere((u) => u.id == newValue);
      _rentController.text = unit.rentAmount.toString();
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select start and end dates')),
        );
        return;
      }

      final leaseData = {
        'unit_id': _selectedUnitId,
        'email': _emailController.text,
        'name': _nameController.text, // Can be empty if user exists
        'phone': _phoneController.text,
        'rent_amount': double.parse(_rentController.text),
        'start_date': DateFormat('yyyy-MM-dd').format(_startDate!),
        'end_date': DateFormat('yyyy-MM-dd').format(_endDate!),
        'terms': _termsController.text,
      };

      final provider = Provider.of<LeaseProvider>(context, listen: false);
      final success = await provider.createLease(leaseData);

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lease created successfully!')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'Failed to create lease')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingInit) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Lease'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Property & Unit Selection
              Consumer<PropertyProvider>(
                builder: (context, provider, child) {
                  return DropdownButtonFormField<int>(
                    value: _selectedPropertyId,
                    decoration: const InputDecoration(
                      labelText: 'Select Property',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.apartment),
                    ),
                    items: provider.properties.map((Property prop) {
                      return DropdownMenuItem<int>(
                        value: prop.id,
                        child: Text(prop.name),
                      );
                    }).toList(),
                    onChanged: _onPropertyChanged,
                    validator: (value) => value == null ? 'Please select a property' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              Consumer<UnitProvider>(
                builder: (context, provider, child) {
                  // Filter for vacant units only? Or allow any unit?
                  // Usually only vacant units can have new leases.
                  // But let's just show all for now or filter if needed.
                  final units = provider.units; 
                  
                  return DropdownButtonFormField<int>(
                    value: _selectedUnitId,
                    decoration: const InputDecoration(
                      labelText: 'Select Unit',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.home),
                    ),
                    items: units.map((Unit unit) {
                      return DropdownMenuItem<int>(
                        value: unit.id,
                        child: Text('Unit ${unit.unitNumber} (${unit.status})'),
                      );
                    }).toList(),
                    onChanged: _onUnitChanged,
                    validator: (value) => value == null ? 'Please select a unit' : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Tenant Details
              const Text('Tenant Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Tenant Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                  helperText: 'If tenant exists, other fields are optional',
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tenant Name (New Tenant)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 24),

              // Lease Terms
              const Text('Lease Terms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _rentController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Rent Amount',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter rent amount' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _startDate == null ? '' : DateFormat('yyyy-MM-dd').format(_startDate!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _endDate == null ? '' : DateFormat('yyyy-MM-dd').format(_endDate!),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _termsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Additional Terms',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),

              Consumer<LeaseProvider>(
                builder: (context, provider, child) {
                  return ElevatedButton(
                    onPressed: provider.isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: provider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Create Lease',
                            style: TextStyle(fontSize: 18),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
