import 'package:flutter/material.dart';

class ReviewCard extends StatefulWidget {
  final Map<String, dynamic> review;

  const ReviewCard({super.key, required this.review});

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool _helpful = false;

  String get _initials {
    final name = widget.review['name'] as String;
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    final double rating = (review['rating'] as num).toDouble();
    final int likes = (review['likes'] as int);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(review, rating),
          const SizedBox(height: 10),
          _buildBody(review),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFEDEDED), height: 1, thickness: 1),
          const SizedBox(height: 10),
          _buildActions(likes),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> review, double rating) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFFFF4F0F),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            _initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Name + meta
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                review['name'] as String,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              _buildStars(rating),
            ],
          ),
        ),

        // Time
        Text(
          review['timeAgo'] as String,
          style: const TextStyle(fontSize: 11, color: Colors.black45),
        ),
      ],
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      children: [
        ...List.generate(5, (i) {
          if (rating >= i + 1.0) {
            return const Icon(Icons.star_rounded,
                color: Color(0xFFFF4F0F), size: 14);
          } else if (rating >= i + 0.5) {
            return const Icon(Icons.star_half_rounded,
                color: Color(0xFFFF4F0F), size: 14);
          } else {
            return const Icon(Icons.star_outline_rounded,
                color: Color(0xFFFF4F0F), size: 14);
          }
        }),
        const SizedBox(width: 4),
        Text(
          rating.toString(),
          style: const TextStyle(
              fontSize: 11,
              color: Colors.black45,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildBody(Map<String, dynamic> review) {
    return Text(
      review['review'] as String,
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFF555555),
        height: 1.6,
      ),
    );
  }

  Widget _buildActions(int likes) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() => _helpful = !_helpful),
          child: Row(
            children: [
              Icon(
                _helpful
                    ? Icons.thumb_up_rounded
                    : Icons.thumb_up_outlined,
                size: 15,
                color: _helpful
                    ? const Color(0xFFFF4F0F)
                    : Colors.black45,
              ),
              const SizedBox(width: 5),
              Text(
                'Helpful (${_helpful ? likes + 1 : likes})',
                style: TextStyle(
                  fontSize: 12,
                  color: _helpful ? const Color(0xFFFF4F0F) : Colors.black45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        GestureDetector(
          onTap: () {},
          child: const Row(
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 15, color: Colors.black45),
              SizedBox(width: 5),
              Text(
                'Reply',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
