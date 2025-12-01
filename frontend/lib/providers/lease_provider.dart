import 'package:flutter/material.dart';
import '../models/lease.dart';
import '../services/lease_service.dart';

class LeaseProvider with ChangeNotifier {
  final LeaseService _leaseService = LeaseService();
  List<Lease> _leases = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Lease> get leases => _leases;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> createLease(Map<String, dynamic> leaseData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _leaseService.createLease(leaseData);

    _isLoading = false;
    if (result['success']) {
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchLeases(int userId, {bool isLandlord = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (isLandlord) {
        _leases = await _leaseService.getLandlordLeases(userId);
      } else {
        _leases = await _leaseService.getLeases(userId);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signLease(int leaseId, int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _leaseService.signLease(leaseId);

    _isLoading = false;
    if (result['success']) {
      await fetchLeases(userId); // Refresh list
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> terminateLease(int leaseId, int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _leaseService.terminateLease(leaseId);

    _isLoading = false;
    if (result['success']) {
      await fetchLeases(userId, isLandlord: true); // Refresh list
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }
}
