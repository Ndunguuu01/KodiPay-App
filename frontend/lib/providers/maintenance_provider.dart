import 'package:flutter/material.dart';
import '../models/maintenance_request.dart';
import '../services/maintenance_service.dart';

class MaintenanceProvider with ChangeNotifier {
  final MaintenanceService _maintenanceService = MaintenanceService();
  List<MaintenanceRequest> _requests = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MaintenanceRequest> get requests => _requests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchRequests({int? userId, bool isLandlord = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (isLandlord && userId != null) {
        _requests = await _maintenanceService.getLandlordRequests(userId);
      } else {
        _requests = await _maintenanceService.getRequests();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createRequest(MaintenanceRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _maintenanceService.createRequest(request);

    _isLoading = false;
    if (result['success']) {
      await fetchRequests(); // Refresh list
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }
}
