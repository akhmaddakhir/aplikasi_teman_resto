import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  String selectedCuisine = 'All';
  String? selectedRating;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header (TIDAK DIRUBAH)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: SvgPicture.asset(
                              'assets/icons/back.svg',
                              width: 16,
                              height: 16,
                            ),
                          ),
                          Text(
                            "Filter",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(width: 20),
                        ],
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 8),

                          // Cuisine Section
                          Text(
                            "Cuisine",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),

                          // Cuisine Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFFF4F0F),
                                  foregroundColor: Colors.white,
                                ),
                                child: Text("All"),
                              ),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[200],
                                  foregroundColor: Colors.black,
                                ),
                                child: Text("Javanese"),
                              ),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[200],
                                  foregroundColor: Colors.black,
                                ),
                                child: Text("Balinese"),
                              ),
                            ],
                          ),

                          SizedBox(height: 24),

                          // Reviews Section
                          Text(
                            "Reviews",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),

                          _buildRatingOption('4.6 - 5.0', 5),
                          SizedBox(height: 12),
                          _buildRatingOption('4.1 - 4.5', 5),
                          SizedBox(height: 12),
                          _buildRatingOption('3.6 - 4.0', 5),
                          SizedBox(height: 12),
                          _buildRatingOption('3.1 - 3.5', 5),
                          SizedBox(height: 12),
                          _buildRatingOption('2.6 - 3.0', 5),

                          SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Apply filter
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF4F0F),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        'Apply',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingOption(String ratingRange, int starCount) {
    bool isSelected = selectedRating == ratingRange;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRating = isSelected ? null : ratingRange;
        });
      },
      child: Row(
        children: [
          // Stars
          Row(
            children: List.generate(
              starCount,
              (index) => Padding(
                padding: EdgeInsets.only(right: 6),
                child: SvgPicture.asset(
                  'assets/icons/rating_card.svg',
                  width: 18,
                  height: 18,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          // Rating Range
          Text(
            ratingRange,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Spacer(),
          // Radio Button
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Color(0xFFFF4F0F) : Colors.grey.shade400,
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFF4F0F),
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
