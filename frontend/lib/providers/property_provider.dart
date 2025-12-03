import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/property.dart';
import '../services/property_service.dart';

class PropertyProvider with ChangeNotifier {
  final PropertyService _propertyService = PropertyService();
  List<Property> _properties = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Property> get properties => _properties;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<Property?> fetchPropertyById(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final property = await _propertyService.getPropertyById(id);
      _isLoading = false;
      notifyListeners();
      return property;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> fetchProperties() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _properties = await _propertyService.getProperties();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProperty(Property property, {int? roomsPerFloor, double? defaultRent, XFile? imageFile}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _propertyService.createProperty(property, roomsPerFloor: roomsPerFloor, defaultRent: defaultRent, imageFile: imageFile);

    _isLoading = false;
    if (result['success']) {
      await fetchProperties(); // Refresh list
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }
}
