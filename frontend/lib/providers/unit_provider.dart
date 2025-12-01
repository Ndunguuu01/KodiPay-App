import 'package:flutter/material.dart';
import '../models/unit.dart';
import '../services/unit_service.dart';

class UnitProvider with ChangeNotifier {
  final UnitService _unitService = UnitService();
  List<Unit> _units = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Unit> get units => _units;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUnits(int propertyId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _units = await _unitService.getUnits(propertyId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addUnit(Unit unit) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _unitService.createUnit(unit);

    _isLoading = false;
    if (result['success']) {
      if (unit.propertyId != null) {
        await fetchUnits(unit.propertyId!); // Refresh list
      }
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> assignTenant(int unitId, int tenantId, int propertyId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _unitService.assignTenant(unitId, tenantId);

    _isLoading = false;
    if (result['success']) {
      await fetchUnits(propertyId); // Refresh list
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUnit(int unitId, Unit unit) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _unitService.updateUnit(unitId, unit);

    _isLoading = false;
    if (result['success']) {
      if (unit.propertyId != null) {
        await fetchUnits(unit.propertyId!); // Refresh list
      }
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUnit(int unitId, int propertyId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _unitService.deleteUnit(unitId);

    _isLoading = false;
    if (result['success']) {
      await fetchUnits(propertyId); // Refresh list
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }
}
