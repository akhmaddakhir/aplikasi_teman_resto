import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SearchingResults extends StatelessWidget {
  const SearchingResults({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  'assets/icons/back.svg',
                  width: 20,
                  height: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
