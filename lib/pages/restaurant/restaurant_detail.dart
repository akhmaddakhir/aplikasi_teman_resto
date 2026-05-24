import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:teman_resto/widgets/gallery_grid.dart';
import 'package:teman_resto/widgets/menu_card.dart';
import 'package:teman_resto/widgets/review_card.dart';
import 'package:teman_resto/pages/booking/booking_data.dart';
import 'package:teman_resto/pages/orders/review_page.dart';

class RestaurantDetail extends StatefulWidget {
  const RestaurantDetail({super.key});

  @override
  State<RestaurantDetail> createState() => RestaurantDetailState();
}

class RestaurantDetailState extends State<RestaurantDetail>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedFilter = 'Most relevant';
  String searchQuery = '';

  final List<String> reviewFilters = [
    'Most relevant',
    'Newest',
    'Highest',
    'Lowest',
  ];

  // ============ ORDER STATE ============
  final Map<String, int> _cart = {};

  int get _totalItems => _cart.values.fold(0, (a, b) => a + b);
  int get _totalPrice {
    int total = 0;
    for (final item in menuItems) {
      final qty = _cart[item['name']] ?? 0;
      if (qty > 0) {
        final priceStr = item['price']
            .toString()
            .replaceAll('Rp ', '')
            .replaceAll('.', '')
            .replaceAll(',', '');
        total += (int.tryParse(priceStr) ?? 0) * qty;
      }
    }
    return total;
  }

  String _formatPrice(int price) {
    final s = price.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'Rp ${buf.toString()}';
  }

  // ================= DATA SOURCE =================
  final List<Map<String, dynamic>> menuItems = [
    {
      'name': 'Gudeg Jogja',
      'price': 'Rp 25.000',
      'priceNum': 25000,
      'image': 'assets/images/gambar_makanan_2.jfif',
      'category': 'VEGETABLE',
      'description':
          'Young jackfruit slow-cooked 8 hrs in palm sugar and coconut milk, with areh and krecek.',
    },
    {
      'name': 'Nasi Goreng Spesial',
      'price': 'Rp 20.000',
      'priceNum': 20000,
      'image': 'assets/images/gambar_makanan_4.jfif',
      'category': 'RICE',
      'description':
          'Wok-fried rice with egg, chicken, shrimp, and house special sambal.',
    },
    {
      'name': 'Rawon Daging',
      'price': 'Rp 30.000',
      'priceNum': 30000,
      'image': 'assets/images/gambar_restoran_4.jfif',
      'category': 'MAIN COURSE',
      'description':
          'East Javanese black beef soup with kluwek nut, served with salted egg and bean sprouts.',
    },
    {
      'name': 'Ayam Bakar Madu',
      'price': 'Rp 28.000',
      'priceNum': 28000,
      'image': 'assets/images/gambar_restoran_5.jfif',
      'category': 'POULTRY',
      'description':
          'Free-range chicken marinated 12 hrs in opor spices, charcoal-grilled, with fresh greens and mortar sambal.',
    },
    {
      'name': 'Soto Ayam',
      'price': 'Rp 18.000',
      'priceNum': 18000,
      'image': 'assets/images/gambar_makanan_2.jfif',
      'category': 'SOUP',
      'description':
          'Javanese chicken soup with turmeric broth, glass noodles, boiled egg, and crispy shallots.',
    },
    {
      'name': 'Tongseng Ayam',
      'price': 'Rp 28.000',
      'priceNum': 28000,
      'image': 'assets/images/gambar_makanan_2.jfif',
      'category': 'MAIN COURSE',
      'description':
          'Braised chicken in sweet soy and coconut milk with cabbage, tomato, and leek.',
    },
    {
      'name': 'Gado-Gado',
      'price': 'Rp 15.000',
      'priceNum': 15000,
      'image': 'assets/images/gambar_resto_2.jpg',
      'category': 'VEGETABLE',
      'description':
          'Mixed blanched vegetables with tofu, tempeh, and thick peanut sauce dressing.',
    },
    {
      'name': 'Es Teh Manis',
      'price': 'Rp 5.000',
      'priceNum': 5000,
      'image': 'assets/images/gambar_makanan_4.jfif',
      'category': 'BEVERAGE',
      'description': 'Classic Javanese sweet iced tea, freshly brewed.',
    },
    {
      'name': 'Kopi Tubruk',
      'price': 'Rp 12.000',
      'priceNum': 12000,
      'image': 'assets/images/gambar_makanan_2.jfif',
      'category': 'BEVERAGE',
      'description':
          'Traditional Indonesian ground coffee steeped directly in hot water.',
    },
    {
      'name': 'Wedang Jahe',
      'price': 'Rp 15.000',
      'priceNum': 15000,
      'image': 'assets/images/gambar_makanan_2.jfif',
      'category': 'BEVERAGE',
      'description':
          'Warm ginger drink with palm sugar and pandan, a Javanese herbal classic.',
    },
    {
      'name': 'Es Dawet',
      'price': 'Rp 10.000',
      'priceNum': 10000,
      'image': 'assets/images/gambar_makanan_2.jfif',
      'category': 'BEVERAGE',
      'description':
          'Chilled coconut milk drink with pandan jelly, palm sugar, and shaved ice.',
    },
  ];

  final List<String> galleryImages = [
    'assets/images/gambar_makanan_2.jfif',
    'assets/images/gambar_resto_2.jpg',
    'assets/images/gambar_restoran_4.jfif',
    'assets/images/gambar_restoran_5.jfif',
    'assets/images/gambar_makanan_4.jfif',
    'assets/images/gambar_makanan_2.jfif',
    'assets/images/gambar_resto_2.jpg',
    'assets/images/gambar_restoran_4.jfif',
  ];

  final List<Map<String, dynamic>> allReviews = [
    {
      'name': 'Budi Santoso',
      'date': DateTime(2025, 2, 5),
      'timeAgo': '6 days ago',
      'rating': 5.0,
      'review':
          'Rawonnya enak banget! Bumbunya meresap sempurna dan dagingnya empuk. Tempatnya juga bersih dan nyaman. Pelayanannya ramah. Pasti balik lagi!',
      'likes': 45,
    },
    {
      'name': 'Siti Nurhaliza',
      'date': DateTime(2025, 1, 28),
      'timeAgo': '2 weeks ago',
      'rating': 4.5,
      'review':
          'Soto ayamnya recommended banget. Kuahnya seger, isian komplit. Harga sesuai dengan rasa. Cuma kadang pas weekend agak rame jadi harus nunggu.',
      'likes': 38,
    },
    {
      'name': 'Ahmad Fauzi',
      'date': DateTime(2025, 1, 15),
      'timeAgo': '3 weeks ago',
      'rating': 5.0,
      'review':
          'Pertama kali ke sini langsung jatuh cinta sama nasi gorengnya. Porsinya banyak, bumbu pas, ga terlalu asin. Harga terjangkau untuk mahasiswa.',
      'likes': 52,
    },
    {
      'name': 'Dewi Lestari',
      'date': DateTime(2024, 12, 20),
      'timeAgo': '1 month ago',
      'rating': 4.0,
      'review':
          'Tempatnya cozy buat makan keluarga. Menu variatif, semuanya enak-enak. Ayam bakar madunya juara! Cuma parkir agak susah kalau weekend.',
      'likes': 29,
    },
    {
      'name': 'Rizki Pratama',
      'date': DateTime(2024, 12, 10),
      'timeAgo': '2 months ago',
      'rating': 5.0,
      'review':
          'Salah satu resto Jawa terbaik di Malang! Semua menu yang pernah saya coba selalu konsisten enak. Gudeg Jogjanya authentic banget. Highly recommended!',
      'likes': 67,
    },
    {
      'name': 'Linda Wijaya',
      'date': DateTime(2024, 11, 25),
      'timeAgo': '2 months ago',
      'rating': 3.5,
      'review':
          'Makanannya enak sih, tapi pas kemarin datang pelayanannya agak lama. Mungkin karena lagi rame. Overall masih worth it.',
      'likes': 15,
    },
    {
      'name': 'Eko Prasetyo',
      'date': DateTime(2024, 11, 10),
      'timeAgo': '3 months ago',
      'rating': 4.5,
      'review':
          'Gado-gadonya mantap! Bumbu kacangnya thick dan gurih. Porsi sayurnya generous. Cocok buat yang vegetarian.',
      'likes': 31,
    },
    {
      'name': 'Maya Kusuma',
      'date': DateTime(2024, 10, 28),
      'timeAgo': '3 months ago',
      'rating': 5.0,
      'review':
          'Restoran keluarga favorit kami. Anak-anak suka banget sama soto ayamnya. Suasana tenang, cocok untuk ngobrol santai sambil makan.',
      'likes': 41,
    },
    {
      'name': 'Doni Setiawan',
      'date': DateTime(2024, 10, 15),
      'timeAgo': '4 months ago',
      'rating': 3.0,
      'review':
          'Rasa standar, ga terlalu spesial. Harga agak mahal untuk porsi yang didapat. Tapi tempatnya bersih dan AC-nya dingin.',
      'likes': 8,
    },
    {
      'name': 'Putri Anggraini',
      'date': DateTime(2024, 9, 30),
      'timeAgo': '4 months ago',
      'rating': 4.5,
      'review':
          'Wedang jahenya the best! Hangat dan pas banget buat musim hujan. Kopi tubruknya juga mantap, ga terlalu pahit. Cocok buat yang suka kopi tradisional.',
      'likes': 28,
    },
    {
      'name': 'Hendra Gunawan',
      'date': DateTime(2024, 9, 10),
      'timeAgo': '5 months ago',
      'rating': 5.0,
      'review':
          'Sudah langganan di sini hampir setahun. Kualitas makanan selalu terjaga. Staff ramah dan helpful. Tempat favorit untuk acara keluarga!',
      'likes': 73,
    },
    {
      'name': 'Ratna Sari',
      'date': DateTime(2024, 8, 20),
      'timeAgo': '6 months ago',
      'rating': 4.0,
      'review':
          'Tempatnya instagramable, cocok buat foto-foto. Makanannya juga ga mengecewakan. Tongseng ayamnya enak, bumbunya meresap sempurna.',
      'likes': 35,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Pakai animation listener supaya update realtime saat swipe gesture
    _tabController.animation!.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> getFilteredMenu() {
    if (searchQuery.isEmpty) return menuItems;
    return menuItems.where((item) {
      return item['name'].toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  List<Map<String, dynamic>> getFilteredReviews() {
    List<Map<String, dynamic>> filtered = List.from(allReviews);
    switch (selectedFilter) {
      case 'Newest':
        filtered.sort((a, b) => b['date'].compareTo(a['date']));
        break;
      case 'Highest':
        filtered.sort((a, b) => b['rating'].compareTo(a['rating']));
        break;
      case 'Lowest':
        filtered.sort((a, b) => a['rating'].compareTo(b['rating']));
        break;
      case 'Most relevant':
      default:
        filtered.sort((a, b) => b['likes'].compareTo(a['likes']));
        break;
    }
    return filtered;
  }

  // ============= GALLERY PREVIEW =============
  void _openGalleryPreview(int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (context) {
        final PageController pageController =
            PageController(initialPage: initialIndex);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            int currentIndex = initialIndex;
            return Stack(
              children: [
                PageView.builder(
                  controller: pageController,
                  itemCount: galleryImages.length,
                  onPageChanged: (i) => setDialogState(() => currentIndex = i),
                  itemBuilder: (context, index) {
                    return InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4.0,
                      child: Center(
                        child: Image.asset(
                          galleryImages[index],
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image,
                            color: Colors.white54,
                            size: 64,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 44,
                  right: 16,
                  child: Material(
                    color: Colors.black45,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(galleryImages.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: currentIndex == i ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color:
                              currentIndex == i ? Colors.white : Colors.white38,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
                if (currentIndex > 0)
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.chevron_left,
                            color: Colors.white54, size: 32),
                        onPressed: () => pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                      ),
                    ),
                  ),
                if (currentIndex < galleryImages.length - 1)
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.chevron_right,
                            color: Colors.white54, size: 32),
                        onPressed: () => pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final bool hasOrder = _totalItems > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Hero image
          Container(
            height: 280,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/gambar_restoran_5.jfif'),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 40,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/home', (route) => false);
                      }
                    },
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xF0F4F4F4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _buildImageItem('assets/images/gambar_makanan_2.jfif'),
                        _buildImageItem('assets/images/gambar_resto_2.jpg'),
                        _buildImageItem('assets/images/gambar_makanan_2.jfif'),
                        _buildImageItem('assets/images/gambar_restoran_4.jfif'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Restaurant info
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pawon Njawi',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _tagChip('assets/icons/clock_card.svg', '1 hour'),
                        const SizedBox(width: 6),
                        _tagChip('assets/icons/bowl_card.svg', 'Javanese'),
                      ],
                    ),
                    Row(
                      children: [
                        SvgPicture.asset('assets/icons/rating_card.svg',
                            width: 16, height: 16),
                        const SizedBox(width: 4),
                        const Text('4.8  (26)',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SvgPicture.asset('assets/icons/location_card.svg',
                        width: 16, height: 16),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Jl. Kahuripan No. 3, Klojen, Kota Malang, Jawatimur',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // TabBar
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFFFF4F0F),
            unselectedLabelColor: Colors.black54,
            indicatorColor: const Color(0xFFFF4F0F),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Menu'),
              Tab(text: 'About'),
              Tab(text: 'Gallery'),
              Tab(text: 'Review'),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMenuTab(),
                _buildAboutTab(),
                _buildGalleryTab(),
                _buildReviewTab(),
              ],
            ),
          ),

          // Bottom bar: selalu tampil di tab Menu
          // Default: BOOK A TABLE. Kalau ada item di cart: ORDER bar
          if (_tabController.animation!.value < 0.5)
            hasOrder ? _buildOrderBar() : _buildBookTableBar(),
        ],
      ),
    );
  }

  // ---- Small helpers ----
  Widget _tagChip(String svgAsset, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SvgPicture.asset(svgAsset,
              width: 14, height: 14, color: const Color(0xFFFF4F0F)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFFF4F0F),
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildImageItem(String imagePath) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image:
              DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildBookTableBar() {
    return Container(
      key: const ValueKey('book'),
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => BookingData()));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF4F0F),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: const Text(
            'BOOK A TABLE',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderBar() {
    return Container(
      key: const ValueKey('order'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4F0F),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4F0F).withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BookingData()),
            );
          },
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.white.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                // Kiri: label + harga
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_totalItems ITEM${_totalItems > 1 ? 'S' : ''} SELECTED',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatPrice(_totalPrice),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Divider vertikal
                Container(
                  height: 36,
                  width: 1,
                  color: Colors.white.withOpacity(0.35),
                  margin: const EdgeInsets.only(right: 20),
                ),

                // Kanan: tombol ORDER
                const Row(
                  children: [
                    Text(
                      'ORDER',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios,
                        color: Colors.white, size: 12),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= TAB MENU =================
  Widget _buildMenuTab() {
    final filteredMenu = getFilteredMenu();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Menu (${menuItems.length} Items)',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View Full Menu',
                      style: TextStyle(
                          color: Color(0xFFFF4F0F),
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Search bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: const InputDecoration(
                        hintText: 'Search Items',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  if (searchQuery.isNotEmpty)
                    IconButton(
                      icon:
                          const Icon(Icons.clear, color: Colors.grey, size: 20),
                      onPressed: () => setState(() => searchQuery = ''),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (filteredMenu.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(Icons.search_off,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Menu tidak ditemukan',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Text('Coba cari dengan kata kunci lain',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[400])),
                    ],
                  ),
                ),
              )
            else
              // ← Grid 2 kolom pakai MenuCard
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.7,
                ),
                itemCount: filteredMenu.length,
                itemBuilder: (context, index) {
                  final item = filteredMenu[index];
                  final name = item['name'] as String;
                  final qty = _cart[name] ?? 0;
                  return MenuCard(
                    item: item,
                    qty: qty,
                    onAdd: () => setState(() => _cart[name] = 1),
                    onIncrement: () => setState(() => _cart[name] = qty + 1),
                    onDecrement: () => setState(() {
                      if (qty <= 1) {
                        _cart.remove(name);
                      } else {
                        _cart[name] = qty - 1;
                      }
                    }),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ================= TAB ABOUT =================
  Widget _buildAboutTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tentang Pawon Njawi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Pawon Njawi adalah restoran masakan Jawa yang telah berdiri sejak tahun 2015 di jantung kota Malang. Kami berkomitmen untuk menyajikan hidangan tradisional Jawa dengan cita rasa autentik dan kualitas terbaik.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Mengapa Memilih Kami?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            _buildAboutPoint('Bahan baku segar dan berkualitas'),
            _buildAboutPoint('Resep turun temurun yang otentik'),
            _buildAboutPoint('Suasana nyaman dan bersih'),
            _buildAboutPoint('Harga terjangkau'),
            _buildAboutPoint('Pelayanan ramah dan profesional'),
            const SizedBox(height: 20),
            const Text(
              'Jam Operasional',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoChip(
                Icons.access_time_rounded, 'Senin - Minggu: 10.00 - 22.00 WIB'),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFF4F0F),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFFFF4F0F)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3A3A3A),
            ),
          ),
        ],
      ),
    );
  }

  // ================= TAB GALLERY =================
  Widget _buildGalleryTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GalleryGrid(
              images: galleryImages,
              onTap: _openGalleryPreview,
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'SHOWING ${galleryImages.length} PHOTOS',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TAB REVIEW =================
  Widget _buildReviewTab() {
    final filteredReviews = getFilteredReviews();

    final Map<int, int> ratingCount = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in allReviews) {
      final int key = (r['rating'] as double).floor().clamp(1, 5);
      ratingCount[key] = (ratingCount[key] ?? 0) + 1;
    }
    final double avgRating = allReviews.isNotEmpty
        ? allReviews.fold(0.0, (s, r) => s + (r['rating'] as double)) /
            allReviews.length
        : 0;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating summary
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < avgRating.floor()
                              ? Icons.star
                              : (i < avgRating
                                  ? Icons.star_half
                                  : Icons.star_border),
                          color: const Color(0xFFFF4F0F),
                          size: 16,
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${allReviews.length} Reviews',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [5, 4, 3, 2, 1].map((star) {
                      final count = ratingCount[star] ?? 0;
                      final pct = allReviews.isNotEmpty
                          ? count / allReviews.length
                          : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text('$star',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct.toDouble(),
                                  minHeight: 6,
                                  backgroundColor: Colors.grey[200],
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Color(0xFFFF4F0F)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${(pct * 100).round()}%',
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.black38)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Filter chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${allReviews.length} Reviews',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ReviewPage()),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 16, color: Colors.black),
                  label: const Text(
                    'Add Review',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: reviewFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = reviewFilters[index];
                  final isSelected = selectedFilter == filter;
                  return GestureDetector(
                    onTap: () => setState(() => selectedFilter = filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFF4F0F)
                            : const Color(0xFFF4F4F4),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Center(
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF4A4A4A),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // ← pakai ReviewCard dari widgets/review_card.dart
            ...filteredReviews.map(
              (review) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ReviewCard(review: review),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
