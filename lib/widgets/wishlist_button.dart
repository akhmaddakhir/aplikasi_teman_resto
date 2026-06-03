import 'package:flutter/material.dart';

import '../models/partner_model.dart';
import '../services/wishlist_service.dart';

class WishlistButton extends StatefulWidget {
  final PartnerModel? restaurant;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final Widget Function(BuildContext context, bool saved, VoidCallback onTap)
      builder;

  const WishlistButton({
    super.key,
    required this.restaurant,
    required this.builder,
    this.size = 20,
    this.activeColor = const Color(0xFFFF4F0F),
    this.inactiveColor = const Color(0xFF000000),
  });

  @override
  State<WishlistButton> createState() => _WishlistButtonState();
}

class _WishlistButtonState extends State<WishlistButton> {
  bool? _optimisticSaved;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final currentRestaurant = widget.restaurant;
    if (currentRestaurant == null || currentRestaurant.id.trim().isEmpty) {
      return widget.builder(context, false, () {});
    }

    final service = WishlistService();
    return StreamBuilder<Set<String>>(
      stream: service.streamWishlistedRestaurantIds(),
      builder: (context, snapshot) {
        final remoteSaved =
            snapshot.data?.contains(currentRestaurant.id) ?? false;
        final saved = _optimisticSaved ?? remoteSaved;

        if (_optimisticSaved != null && _optimisticSaved == remoteSaved) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _optimisticSaved = null);
          });
        }

        return widget.builder(
          context,
          saved,
          () async {
            if (_saving) return;
            setState(() {
              _saving = true;
              _optimisticSaved = !saved;
            });

            try {
              await service.toggleWishlist(currentRestaurant);
            } catch (e) {
              if (mounted) {
                setState(() => _optimisticSaved = remoteSaved);
              }
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
            } finally {
              if (mounted) setState(() => _saving = false);
            }
          },
        );
      },
    );
  }
}
