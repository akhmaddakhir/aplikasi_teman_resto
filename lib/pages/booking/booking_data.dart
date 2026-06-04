import 'package:flutter/material.dart';
import './booking_add.dart';

class BookingData extends StatelessWidget {
  final String restaurantId;
  final String restaurantName;
  final String restaurantAddress;
  final String? restaurantPhotoUrl;
  final List<String> paymentMethods;
  final Map<dynamic, dynamic> menuRequest;

  const BookingData({
    Key? key,
    required this.menuRequest,
    this.restaurantId = '',
    this.restaurantName = '',
    this.restaurantAddress = '',
    this.restaurantPhotoUrl,
    this.paymentMethods = const ['Online Payment'],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BookingFormPage(
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      restaurantAddress: restaurantAddress,
      restaurantPhotoUrl: restaurantPhotoUrl,
      paymentMethods: paymentMethods,
      menuRequest: menuRequest,
    );
  }
}

class BookingFormPage extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final String restaurantAddress;
  final String? restaurantPhotoUrl;
  final List<String> paymentMethods;
  final Map<dynamic, dynamic> menuRequest;

  const BookingFormPage({
    Key? key,
    this.restaurantId = '',
    this.restaurantName = '',
    this.restaurantAddress = '',
    this.restaurantPhotoUrl,
    this.paymentMethods = const ['Online Payment'],
    this.menuRequest = const {},
  }) : super(key: key);

  @override
  State<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends State<BookingFormPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _selectedCountryCode = '+62';
  String? _selectedOccasion;

  final List<String> _countryCodes = ['+62', '+1', '+44', '+61', '+81'];
  final List<String> _occasions = [
    'Birthday',
    'Anniversary',
    'Business Dinner',
    'Casual Dining',
    'Date Night',
    'Family Gathering',
    'Other'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        size: 20, color: Colors.black),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Booking',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            /// FORM
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Name',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    _buildInput(_nameController, 'Ex. Om Gatot'),

                    const SizedBox(height: 20),

                    /// PHONE
                    const Text(
                      'Phone Number',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: DropdownButton<String>(
                              value: _selectedCountryCode,
                              underline: const SizedBox(),
                              items: _countryCodes
                                  .map((code) => DropdownMenuItem(
                                        value: code,
                                        child: Text(code),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCountryCode = value!;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                hintText: 'Enter Phone Number',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// OCCASION
                    const Text(
                      'Occasion',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedOccasion,
                        decoration: const InputDecoration(
                          hintText: 'Select',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        items: _occasions
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedOccasion = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingAddPage(
                          restaurantId: widget.restaurantId,
                          restaurantName: widget.restaurantName,
                          restaurantAddress: widget.restaurantAddress,
                          restaurantPhotoUrl: widget.restaurantPhotoUrl,
                          paymentMethods: widget.paymentMethods,
                          menuRequest: widget.menuRequest,
                          name: _nameController.text,
                          phone:
                              '$_selectedCountryCode ${_phoneController.text}',
                          occasion: _selectedOccasion ?? 'Other',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4F0F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint,
      {TextInputType keyboard = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
