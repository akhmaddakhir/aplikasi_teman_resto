import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget kartu restoran yang dipakai di HomePage, WishlistPage,
/// SearchPage, SearchResults, dan OrdersPage (versi horizontal).
///
/// [isHorizontal] → layout baris (gambar kiri, info kanan) untuk OrdersPage & SearchPage
/// [isHorizontal] false → layout vertikal (gambar atas, info bawah) untuk HomePage & SearchResults
class RestaurantCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final String cuisine;
  final String rating;
  final String duration;
  final String address;
  final VoidCallback onTap;
  final bool isHorizontal;
  final bool showSaveIcon;

  const RestaurantCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.cuisine,
    required this.rating,
    required this.duration,
    required this.address,
    required this.onTap,
    this.isHorizontal = false,
    this.showSaveIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isHorizontal ? _buildHorizontal() : _buildVertical(),
      ),
    );
  }

  Widget _buildVertical() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Stack(
            children: [
              Image.asset(
                imagePath,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
              if (showSaveIcon)
                Positioned(
                  top: 8,
                  right: 8,
                  child: SvgPicture.asset(
                    'assets/icons/save.svg',
                    width: 28,
                    height: 28,
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildInfo(titleSize: 18, detailSize: 14),
        ),
      ],
    );
  }

  Widget _buildHorizontal() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              imagePath,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _buildInfo(titleSize: 16, detailSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInfo({required double titleSize, required double detailSize}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/rating_card.svg',
                  width: detailSize,
                  height: detailSize,
                ),
                const SizedBox(width: 4),
                Text(
                  rating,
                  style: TextStyle(
                    fontSize: detailSize,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SvgPicture.asset(
              'assets/icons/clock_card.svg',
              width: detailSize,
              height: detailSize,
            ),
            const SizedBox(width: 6),
            Text(
              duration,
              style: TextStyle(
                fontSize: detailSize,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 10),
            Text('•', style: TextStyle(fontSize: detailSize, color: Colors.grey)),
            const SizedBox(width: 10),
            SvgPicture.asset(
              'assets/icons/bowl_card.svg',
              width: detailSize,
              height: detailSize,
            ),
            const SizedBox(width: 6),
            Text(
              cuisine,
              style: TextStyle(
                fontSize: detailSize,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SvgPicture.asset(
              'assets/icons/location_card.svg',
              width: detailSize,
              height: detailSize,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                address,
                style: TextStyle(
                  fontSize: detailSize,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
