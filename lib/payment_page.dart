import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'payment_success.dart';

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: SvgPicture.asset(
                              'assets/icons/back.svg',
                              width: 24,
                              height: 24,
                            ),
                          ),
                          Text(
                            "Payment",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(width: 24),
                        ],
                      ),
                      SizedBox(height: 24),

                      // Credit Card Section
                      Text(
                        "Credit Card",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildPaymentItem(
                        icon: 'assets/icons/visa_payment.svg',
                        iconSize: 40,
                        title: 'Visa',
                        subtitle: '**** **** **** 1234',
                      ),
                      SizedBox(height: 12),
                      _buildPaymentItem(
                        icon: 'assets/icons/mastercard_payment.svg',
                        iconSize: 40,
                        title: 'Mastercard',
                        subtitle: '**** **** **** 1234',
                      ),
                      SizedBox(height: 24),

                      // Bank Transfer Section
                      Text(
                        "Bank Transfer",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildPaymentItem(
                        icon: 'assets/icons/visa_payment.svg',
                        iconSize: 40,
                        title: 'BCA',
                        subtitle: '',
                      ),
                      SizedBox(height: 12),
                      _buildPaymentItem(
                        icon: 'assets/icons/visa_payment.svg',
                        iconSize: 40,
                        title: 'CIMB Niaga',
                        subtitle: '',
                      ),
                      SizedBox(height: 12),
                      _buildPaymentItem(
                        icon: 'assets/icons/visa_payment.svg',
                        iconSize: 40,
                        title: 'BRI',
                        subtitle: '',
                      ),
                      SizedBox(height: 12),
                      _buildPaymentItem(
                        icon: 'assets/icons/visa_payment.svg',
                        iconSize: 40,
                        title: 'Bank Syariah Indonesia',
                        subtitle: '',
                      ),
                      SizedBox(height: 12),
                      _buildPaymentItem(
                        icon: 'assets/icons/visa_payment.svg',
                        iconSize: 40,
                        title: 'Mandiri',
                        subtitle: '',
                      ),
                      SizedBox(height: 24),

                      // E-Wallet Section
                      Text(
                        "E-Wallet",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildPaymentItem(
                        icon: 'assets/icons/visa_payment.svg',
                        iconSize: 40,
                        title: 'GoPay',
                        subtitle: '',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Fixed Bottom Button
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentSuccess(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF4F0F),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        'Select Payment Method',
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

  Widget _buildPaymentItem({
    required String icon,
    required double iconSize,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: SvgPicture.asset(icon, width: iconSize, height: iconSize),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
