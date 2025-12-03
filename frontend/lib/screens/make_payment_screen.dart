import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/payment.dart';
import '../providers/payment_provider.dart';
import '../utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/stripe_service.dart';

class MakePaymentScreen extends StatefulWidget {
  final double? initialAmount;
  final int? unitId;
  final int? tenantId;

  const MakePaymentScreen({
    super.key, 
    this.initialAmount, 
    this.unitId, 
    this.tenantId
  });

  @override
  State<MakePaymentScreen> createState() => _MakePaymentScreenState();
}

class _MakePaymentScreenState extends State<MakePaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  final _phoneController = TextEditingController();
  late TextEditingController _unitIdController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialAmount?.toString() ?? ''
    );
    _unitIdController = TextEditingController(
      text: widget.unitId?.toString() ?? ''
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _unitIdController.dispose();
    super.dispose();
  }

  void _submitPayment() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found. Please login again.')),
        );
        return;
      }

      // Mock unit ID for now if not provided, or assume user knows it
      // Ideally we fetch user's rented unit
      int unitId = widget.unitId ?? int.tryParse(_unitIdController.text) ?? 1; 

      final payment = Payment(
        tenantId: userId,
        unitId: unitId,
        amount: double.parse(_amountController.text),
        paymentMethod: 'mpesa',
        status: 'pending',
        phone: _phoneController.text,
      );

      final provider = Provider.of<PaymentProvider>(context, listen: false);
      final success = await provider.makePayment(payment);

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment initiated successfully!')),
        );
      }
    }
  }

  void _payWithCard() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter amount')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found. Please login again.')),
      );
      return;
    }

    int unitId = widget.unitId ?? int.tryParse(_unitIdController.text) ?? 1;

    await StripeService().makePayment(context, amount, 'usd', userId, unitId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Payment'),
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
              const Text(
                'Pay Rent via M-Pesa',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (KES)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'M-Pesa Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_android),
                  hintText: '2547...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unitIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Unit ID (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                  helperText: 'Leave empty to use default',
                ),
              ),
              const SizedBox(height: 32),
              Consumer<PaymentProvider>(
                builder: (context, provider, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: provider.isLoading ? null : _submitPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: provider.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Pay Now (M-Pesa)',
                                style: TextStyle(fontSize: 18),
                              ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _payWithCard,
                        icon: const Icon(Icons.credit_card),
                        label: const Text('Pay with Card (Stripe)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (Provider.of<PaymentProvider>(context).errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    Provider.of<PaymentProvider>(context).errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
