import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/property.dart';
import '../providers/property_provider.dart';
import '../utils/constants.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _floorsController = TextEditingController();
  final _roomsPerFloorController = TextEditingController();
  final _defaultRentController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _floorsController.dispose();
    _roomsPerFloorController.dispose();
    _defaultRentController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final property = Property(
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        floorsCount: int.parse(_floorsController.text.trim()),
      );

      final success = await Provider.of<PropertyProvider>(context, listen: false)
          .addProperty(
            property,
            roomsPerFloor: int.parse(_roomsPerFloorController.text.trim()),
            defaultRent: double.parse(_defaultRentController.text.trim()),
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Property added successfully!')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Property'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Property Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter property name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter location' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _floorsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Number of Floors',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.layers),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter number of floors';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // New fields for auto-generation
              TextFormField(
                controller: _roomsPerFloorController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Rooms per Floor',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.meeting_room),
                  helperText: 'Auto-generates units (e.g., A1, A2...)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter rooms per floor';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _defaultRentController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Default Rent Amount',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter default rent';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Consumer<PropertyProvider>(
                builder: (context, provider, child) {
                  if (provider.errorMessage != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        provider.errorMessage!,
                        style: const TextStyle(color: AppConstants.errorColor),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return ElevatedButton(
                    onPressed: provider.isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: provider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Add Property'),
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
