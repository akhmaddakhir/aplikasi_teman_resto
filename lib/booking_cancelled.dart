import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BookingCancelled extends StatefulWidget {
  const BookingCancelled({super.key});

  @override
  State<BookingCancelled> createState() => _BookingDetailState();
}

class _BookingDetailState extends State<BookingCancelled> {
  bool isOn = false;

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
                    // Header
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
                            "Cancel Booking",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(width: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
