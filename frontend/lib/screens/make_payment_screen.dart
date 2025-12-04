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

  String _selectedMethod = 'mpesa';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Make Payment'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppConstants.primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Total Amount Due',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'KES ${_amountController.text.isEmpty ? "0.00" : _amountController.text}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              onChanged: (val) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: 'Amount (KES)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.attach_money),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Enter amount';
                                if (double.tryParse(value) == null) return 'Invalid number';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _unitIdController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Unit ID (Optional)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.home),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Select Method',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMethodCard(
                            'M-Pesa',
                            Icons.phone_android,
                            Colors.green,
                            'mpesa',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildMethodCard(
                            'Card',
                            Icons.credit_card,
                            Colors.indigo,
                            'card',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_selectedMethod == 'mpesa')
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'M-Pesa Phone Number',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.phone),
                              hintText: '2547...',
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (value) {
                              if (_selectedMethod == 'mpesa' && (value == null || value.isEmpty)) {
                                return 'Enter phone number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
                    Consumer<PaymentProvider>(
                      builder: (context, provider, child) {
                        return SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: provider.isLoading
                                ? null
                                : () {
                                    if (_selectedMethod == 'mpesa') {
                                      _submitPayment();
                                    } else {
                                      _payWithCard();
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedMethod == 'mpesa' ? Colors.green : Colors.indigo,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                            ),
                            child: provider.isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    _selectedMethod == 'mpesa' ? 'Pay with M-Pesa' : 'Pay with Card',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard(String title, IconData icon, Color color, String method) {
    final isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Icon(Icons.check_circle, color: color, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}
