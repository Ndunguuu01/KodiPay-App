import 'dart:async';
import 'dart:convert';
// import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../providers/marketplace_provider.dart';
import '../utils/constants.dart';
import '../models/marketplace_ad.dart';

class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key});

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  Timer? _timer;
  Map<int, VideoPlayerController> _videoControllers = {};

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
    Future.microtask(() => 
      Provider.of<MarketplaceProvider>(context, listen: false).fetchAds()
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _disposeVideoControllers();
    super.dispose();
  }

  void _disposeVideoControllers() {
    _videoControllers.forEach((_, controller) => controller.dispose());
    _videoControllers.clear();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      final ads = Provider.of<MarketplaceProvider>(context, listen: false).ads;
      if (ads.isEmpty) return;

      _currentPage++;

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }


  Widget _buildMediaContent(MarketplaceAd ad, int index) {
    if (ad.type == 'video' && ad.imageUrl != null) {
      // For base64 video, we need to write to a temp file first
      // This is complex for a carousel. For now, let's show a placeholder or try to initialize if not too heavy
      // Real implementation would require caching.
      // Let's stick to image placeholder for video or icon for now to avoid freezing UI
      return Center(
        child: Icon(Icons.play_circle_fill, size: 50, color: Colors.white.withOpacity(0.8)),
      );
    } else if (ad.imageUrl != null) {
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: MemoryImage(base64Decode(ad.imageUrl!)),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.3),
              BlendMode.darken,
            ),
          ),
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MarketplaceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator(color: AppConstants.primaryColor)),
          );
        }

        if (provider.ads.isEmpty) {
          return SizedBox(
            height: 180,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No ads yet. Be the first to post!', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        return SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            // itemCount: null, // Infinite scrolling
            onPageChanged: (int index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              // Use modulo to loop through ads
              final adIndex = index % provider.ads.length;
              final ad = provider.ads[adIndex];
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8), // Adjusted margin
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildMediaContent(ad, adIndex),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              ad.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ad.description ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (ad.contactInfo != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.phone, color: Colors.white, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      ad.contactInfo!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
