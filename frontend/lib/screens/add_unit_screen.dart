import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/unit.dart';
import '../providers/unit_provider.dart';
import '../utils/constants.dart';

class AddUnitScreen extends StatefulWidget {
  final int propertyId;
  final Unit? unit;

  const AddUnitScreen({super.key, required this.propertyId, this.unit});

  @override
  State<AddUnitScreen> createState() => _AddUnitScreenState();
}

class _AddUnitScreenState extends State<AddUnitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _unitNumberController = TextEditingController();
  final _rentAmountController = TextEditingController();
  final _floorNumberController = TextEditingController();
  final _roomNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.unit != null) {
      _unitNumberController.text = widget.unit!.unitNumber;
      _rentAmountController.text = widget.unit!.rentAmount.toString();
      _floorNumberController.text = widget.unit!.floorNumber?.toString() ?? '';
      _roomNumberController.text = widget.unit!.roomNumber ?? '';
    }
  }

  @override
  void dispose() {
    _unitNumberController.dispose();
    _rentAmountController.dispose();
    _floorNumberController.dispose();
    _roomNumberController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final unit = Unit(
        id: widget.unit?.id,
        unitNumber: _unitNumberController.text.trim(),
        rentAmount: double.parse(_rentAmountController.text.trim()),
        status: widget.unit?.status ?? 'vacant',
        propertyId: widget.propertyId,
        floorNumber: int.parse(_floorNumberController.text.trim()),
        roomNumber: _roomNumberController.text.trim(),
        tenantId: widget.unit?.tenantId,
        tenantName: widget.unit?.tenantName,
      );

      bool success;
      final provider = Provider.of<UnitProvider>(context, listen: false);

      if (widget.unit != null) {
        success = await provider.updateUnit(widget.unit!.id!, unit);
      } else {
        success = await provider.addUnit(unit);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.unit != null ? 'Unit updated successfully!' : 'Unit added successfully!')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.unit != null ? 'Edit Unit' : 'Add New Unit'),
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
                controller: _unitNumberController,
                decoration: const InputDecoration(
                  labelText: 'Unit Number (e.g., A1)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.door_front_door),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter unit number' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rentAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Rent Amount',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter rent amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _floorNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Floor Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.layers),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter floor number';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roomNumberController,
                decoration: const InputDecoration(
                  labelText: 'Room Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.meeting_room),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter room number' : null,
              ),
              const SizedBox(height: 24),
              Consumer<UnitProvider>(
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
                        : Text(widget.unit != null ? 'Update Unit' : 'Add Unit'),
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
