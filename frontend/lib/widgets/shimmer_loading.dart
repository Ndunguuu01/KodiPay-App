import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoadingWidget extends StatelessWidget {
  final double width;
  final double height;
  final ShapeBorder shapeBorder;

  const ShimmerLoadingWidget.rectangular({
    super.key,
    this.width = double.infinity,
    required this.height,
  }) : shapeBorder = const RoundedRectangleBorder();

  const ShimmerLoadingWidget.circular({
    super.key,
    required this.width,
    required this.height,
    this.shapeBorder = const CircleBorder(),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          color: Colors.grey[400]!,
          shape: shapeBorder,
        ),
      ),
    );
  }
}

class PropertyListSkeleton extends StatelessWidget {
  const PropertyListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShimmerLoadingWidget.rectangular(height: 80, width: 80),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerLoadingWidget.rectangular(height: 16, width: double.infinity),
                    const SizedBox(height: 8),
                    const ShimmerLoadingWidget.rectangular(height: 12, width: 150),
                    const SizedBox(height: 8),
                    const ShimmerLoadingWidget.rectangular(height: 12, width: 100),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
class MessageListSkeleton extends StatelessWidget {
  final int itemCount;

  const MessageListSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              const ShimmerLoadingWidget.circular(height: 40, width: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerLoadingWidget.rectangular(height: 16, width: 100),
                    const SizedBox(height: 8),
                    const ShimmerLoadingWidget.rectangular(height: 12, width: 200),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
