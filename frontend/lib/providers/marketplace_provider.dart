import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/marketplace_ad.dart';
import '../services/marketplace_service.dart';
import '../services/socket_service.dart';

class MarketplaceProvider with ChangeNotifier {
  final MarketplaceService _marketplaceService = MarketplaceService();
  final SocketService _socketService = SocketService();
  List<MarketplaceAd> _ads = [];
  bool _isLoading = false;
  String? _errorMessage;

  MarketplaceProvider() {
    _initSocket();
  }

  void _initSocket() {
    _socketService.init();
    _socketService.on('new_ad', (data) {
      fetchAds(); // Refresh list when new ad is received
    });
  }

  @override
  void dispose() {
    _socketService.dispose();
    super.dispose();
  }

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

  Future<bool> postAd(MarketplaceAd ad, XFile? imageFile) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _marketplaceService.postAd(ad, imageFile);

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

  Future<bool> deleteAd(int adId) async {
    final success = await _marketplaceService.deleteAd(adId);
    if (success) {
      await fetchAds();
    }
    return success;
  }
}
