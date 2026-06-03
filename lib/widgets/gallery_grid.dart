import 'package:flutter/material.dart';

class GalleryGrid extends StatelessWidget {
  final List<String> images;
  final void Function(int index) onTap;

  const GalleryGrid({
    super.key,
    required this.images,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox();

    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 12.0;
          const columns = 2;
          final cellSize = (constraints.maxWidth - gap) / columns;

          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: List.generate(images.length, (i) {
              final image = images[i];
              final isNetwork =
                  image.startsWith('http://') || image.startsWith('https://');
              return GestureDetector(
                onTap: () => onTap(i),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: cellSize,
                    height: cellSize,
                    child: isNetwork
                        ? Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _fallback(),
                          )
                        : Image.asset(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _fallback(),
                          ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.image_outlined, color: Colors.grey),
    );
  }
}
