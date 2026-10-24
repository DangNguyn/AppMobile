import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

String? destinationAssetFor(String location) {
  final normalized = location.toLowerCase();
  if (normalized.contains('hạ long')) return 'assets/images/vinh-ha-long.jpg';
  if (normalized.contains('phú quốc')) {
    return 'assets/images/dao-ngoc-phu-quoc.jpg';
  }
  if (normalized.contains('hội an')) return 'assets/images/pho-co-hoi-an.jpg';
  if (normalized.contains('đà nẵng')) return 'assets/images/tp-da-nang.jpg';
  if (normalized.contains('sa pa')) return 'assets/images/anh-sa-pa.jpg';
  if (normalized.contains('hồ chí minh')) return 'assets/images/tp-hcm.jpg';
  if (normalized.contains('hà nội')) return 'assets/images/tp-ha-noi.jpg';
  if (normalized.contains('đà lạt')) return 'assets/images/tp-da-lat.jpg';
  if (normalized.contains('huế')) return 'assets/images/tp-hue.jpg';
  if (normalized.contains('nha trang')) return 'assets/images/tp-nha-trang.jpg';
  return null;
}

class DestinationImage extends StatelessWidget {
  const DestinationImage({
    super.key,
    required this.location,
    required this.networkUrl,
    this.fit = BoxFit.cover,
  });

  final String location;
  final String networkUrl;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final asset = destinationAssetFor(location);
    if (asset == null) return _networkImage();
    return Image.asset(
      asset,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _networkImage(),
    );
  }

  Widget _networkImage() {
    if (networkUrl.trim().isEmpty) return _fallback();
    return CachedNetworkImage(
      imageUrl: networkUrl,
      fit: fit,
      placeholder: (_, __) => _fallback(),
      errorWidget: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() => const ColoredBox(
        color: Color(0xFFE7EEF5),
        child: Center(
          child:
              Icon(Icons.landscape_rounded, color: Color(0xFF9AA9B8), size: 34),
        ),
      );
}
