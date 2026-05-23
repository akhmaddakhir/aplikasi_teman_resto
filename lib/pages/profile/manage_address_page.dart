import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageAddressPage extends StatefulWidget {
  const ManageAddressPage({Key? key}) : super(key: key);

  @override
  State<ManageAddressPage> createState() => _ManageAddressPageState();
}

class _ManageAddressPageState extends State<ManageAddressPage> {
  static const Color _orange = Color(0xFFFF4F0F);

  final List<_AddressData> _addresses = [
    _AddressData(
      id: '1',
      label: 'Home',
      icon: Icons.home_rounded,
      name: 'Floyd Miles',
      phone: '+62 812-3456-7890',
      address: 'Jl. Sudirman No.12, Kel. Karet Tengsin, Kec. Tanah Abang',
      city: 'Jakarta Pusat, DKI Jakarta 10220',
      isDefault: true,
    ),
    _AddressData(
      id: '2',
      label: 'Office',
      icon: Icons.business_rounded,
      name: 'Floyd Miles',
      phone: '+62 812-3456-7890',
      address: 'Gedung Sampoerna Strategic, Jl. Jend. Sudirman Kav. 45',
      city: 'Jakarta Selatan, DKI Jakarta 12930',
      isDefault: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: _addresses.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                      itemCount: _addresses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) =>
                          _buildAddressCard(_addresses[i], context),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildAddButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: const Color(0xFF0D0D0D),
          ),
          Expanded(
            child: Text(
              'Manage Address',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D0D0D),
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildAddressCard(_AddressData data, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: data.isDefault
              ? _orange.withOpacity(0.4)
              : Colors.white.withOpacity(0.28),
          width: data.isDefault ? 1 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(data.icon, color: _orange, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  data.label,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                if (data.isDefault) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: _orange,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      'Default',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: Color(0xFFBBBBBB), size: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showAddressSheet(context, existing: data);
                    } else if (value == 'default') {
                      _setDefault(data.id);
                    } else if (value == 'delete') {
                      _confirmDelete(context, data);
                    }
                  },
                  itemBuilder: (_) => [
                    if (!data.isDefault)
                      PopupMenuItem(
                        value: 'default',
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded,
                                size: 18, color: Color(0xFF1A1A1A)),
                            const SizedBox(width: 8),
                            Text('Set as Default',
                                style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined,
                              size: 18, color: Color(0xFF1A1A1A)),
                          const SizedBox(width: 8),
                          Text('Edit',
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    if (!data.isDefault)
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline_rounded,
                                size: 18, color: Color(0xFFE24B4A)),
                            const SizedBox(width: 8),
                            Text('Delete',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFE24B4A),
                                )),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Address detail
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${data.name}  ·  ${data.phone}',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: const Color(0xFF555555),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(Icons.location_on_outlined,
                          size: 14, color: Colors.grey.shade500),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${data.address},\n${data.city}',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: const Color(0xFF777777),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _orange.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.home_outlined, color: _orange, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'No addresses yet',
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add your delivery address to\nget started with ordering.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: const Color(0xFF888888),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showAddressSheet(context),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text(
            'Add New Address',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  void _setDefault(String id) {
    setState(() {
      for (final a in _addresses) {
        a.isDefault = a.id == id;
      }
    });
  }

  void _confirmDelete(BuildContext context, _AddressData data) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEEEE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFE24B4A), size: 26),
              ),
              const SizedBox(height: 16),
              Text(
                'Delete Address?',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Are you sure you want to remove the "${data.label}" address?',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: const Color(0xFF888888),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF7F6F2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() =>
                            _addresses.removeWhere((a) => a.id == data.id));
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE24B4A),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Delete',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddressSheet(BuildContext context, {_AddressData? existing}) {
    final labelController = TextEditingController(text: existing?.label ?? '');
    final nameController = TextEditingController(text: existing?.name ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final addressController =
        TextEditingController(text: existing?.address ?? '');
    final cityController = TextEditingController(text: existing?.city ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                existing == null ? 'Add New Address' : 'Edit Address',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 16),
              _buildField('Label (e.g. Home, Office)', labelController),
              const SizedBox(height: 12),
              _buildField('Full Name', nameController),
              const SizedBox(height: 12),
              _buildField('Phone Number', phoneController,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _buildField('Street Address', addressController, maxLines: 2),
              const SizedBox(height: 12),
              _buildField('City & Postal Code', cityController),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (existing == null) {
                      setState(() {
                        _addresses.add(_AddressData(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          label: labelController.text.isEmpty
                              ? 'Address'
                              : labelController.text,
                          icon: Icons.location_on_rounded,
                          name: nameController.text,
                          phone: phoneController.text,
                          address: addressController.text,
                          city: cityController.text,
                          isDefault: _addresses.isEmpty,
                        ));
                      });
                    } else {
                      setState(() {
                        existing.label = labelController.text;
                        existing.name = nameController.text;
                        existing.phone = phoneController.text;
                        existing.address = addressController.text;
                        existing.city = cityController.text;
                      });
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    existing == null ? 'Save Address' : 'Update Address',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String hint,
    TextEditingController controller, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F6F2),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF1A1A1A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.nunito(
            color: const Color(0xFFBBBAB5),
            fontSize: 14,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
class _AddressData {
  final String id;
  String label;
  final IconData icon;
  String name;
  String phone;
  String address;
  String city;
  bool isDefault;

  _AddressData({
    required this.id,
    required this.label,
    required this.icon,
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    required this.isDefault,
  });
}
