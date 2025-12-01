import 'package:flutter/material.dart';
import '../models/marketplace_ad.dart';
import '../services/marketplace_service.dart';

class MarketplaceProvider with ChangeNotifier {
  final MarketplaceService _marketplaceService = MarketplaceService();
  List<MarketplaceAd> _ads = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MarketplaceAd> get ads => _ads;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAds() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _ads = await _marketplaceService.getAds();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> postAd(MarketplaceAd ad) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _marketplaceService.postAd(ad);

    _isLoading = false;
    if (result['success']) {
      await fetchAds(); // Refresh list
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }
}
