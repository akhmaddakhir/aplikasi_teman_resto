import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'booking_data.dart';

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

  // Data menu
  final List<Map<String, dynamic>> menuItems = [
    {
      'name': 'Gudeg Jogja',
      'price': 'Rp 25.000',
      'image': 'assets/images/gambar_makanan_2.jfif',
      'category': 'Main Course',
    },
    {
      'name': 'Nasi Goreng Spesial',
      'price': 'Rp 20.000',
      'image': 'assets/images/gambar_makanan_4.jfif',
      'category': 'Main Course',
    },
    {
      'name': 'Rawon Daging',
      'price': 'Rp 30.000',
      'image': 'assets/images/gambar_restoran_4.jfif',
      'category': 'Main Course',
    },
    {
      'name': 'Ayam Bakar Madu',
      'price': 'Rp 28.000',
      'image': 'assets/images/gambar_restoran_5.jfif',
      'category': 'Main Course',
    },
    {
      'name': 'Soto Ayam',
      'price': 'Rp 18.000',
      'image': 'assets/images/gambar_makanan_2.jfif',
      'category': 'Main Course',
    },
    {
      'name': 'Tongseng Ayam',
      'price': 'Rp 28.000',
      'image': 'assets/images/gambar_makanan_2.jfif',
      'category': 'Main Course',
    },
    {
      'name': 'Gado-Gado',
      'price': 'Rp 15.000',
      'image': 'assets/images/gambar_resto_2.jpg',
      'category': 'Appetizer',
    },
    {
      'name': 'Es Teh Manis',
      'price': 'Rp 5.000',
      'image': 'assets/images/gambar_makanan_4.jfif',
      'category': 'Beverage',
    },
    {
      'name': 'Kopi Tubruk',
      'price': 'Rp 12.000',
      'image': 'assets/images/gambar_makanan_2.jfif',
      'category': 'Beverage',
    },
    {
      'name': 'Wedang Jahe',
      'price': 'Rp 15.000',
      'image': 'assets/images/gambar_makanan_2.jfif',
      'category': 'Beverage',
    },
    {
      'name': 'Es Dawet',
      'price': 'Rp 10.000',
      'image': 'assets/images/gambar_makanan_2.jfif',
      'category': 'Beverage',
    },
  ];

  // Data Gallery
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

  // Data Reviews
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Filter menu berdasarkan search query
  List<Map<String, dynamic>> getFilteredMenu() {
    if (searchQuery.isEmpty) {
      return menuItems;
    }
    return menuItems.where((item) {
      return item['name'].toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  // Filter reviews berdasarkan filter yang dipilih
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
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
                  child: Container(
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Color(0xF0F4F4F4),
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
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pawon Njawi',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFFFF3F0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/clock_card.svg',
                                width: 16,
                                height: 16,
                                color: Color(0xFFFF4F0F),
                              ),
                              SizedBox(width: 6),
                              Text(
                                '1 hour',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFFF4F0F),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 6),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFFFF3F0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/bowl_card.svg',
                                width: 14,
                                height: 14,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Javanese',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFFF4F0F),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 6),
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/rating_card.svg',
                          width: 16,
                          height: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '4.8  (26)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/location_card.svg',
                      width: 16,
                      height: 16,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Jl. Kahuripan No. 3, Klojen, Kota Malang, Jawatimur',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: Color(0xFFFF4F0F),
            unselectedLabelColor: Colors.black54,
            indicatorColor: Color(0xFFFF4F0F),
            tabs: [
              Tab(text: 'Menu'),
              Tab(text: 'About'),
              Tab(text: 'Gallery'),
              Tab(text: 'Review'),
            ],
          ),
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
          Container(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BookingData()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF4F0F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  'Book a table',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageItem(String imagePath) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTab() {
    final filteredMenu = getFilteredMenu();

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Menu (${menuItems.length} Items)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'View Full Menu',
                    style: TextStyle(
                      color: Color(0xFFFF4F0F),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search Items',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  if (searchQuery.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey, size: 20),
                      onPressed: () {
                        setState(() {
                          searchQuery = '';
                        });
                      },
                    ),
                ],
              ),
            ),
            SizedBox(height: 16),
            if (filteredMenu.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Menu tidak ditemukan',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Coba cari dengan kata kunci lain',
                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: filteredMenu.length,
                itemBuilder: (context, index) {
                  return _buildMenuItem(
                    filteredMenu[index]['name'],
                    filteredMenu[index]['price'],
                    filteredMenu[index]['image'],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(String name, String price, String imagePath) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF4F0F),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tentang Pawon Njawi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Pawon Njawi adalah restoran masakan Jawa yang telah berdiri sejak tahun 2015 di jantung kota Malang. Kami berkomitmen untuk menyajikan hidangan tradisional Jawa dengan cita rasa autentik dan kualitas terbaik.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Mengapa Memilih Kami?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            _buildAboutPoint('✓ Bahan baku segar dan berkualitas'),
            _buildAboutPoint('✓ Resep turun temurun yang otentik'),
            _buildAboutPoint('✓ Suasana nyaman dan bersih'),
            _buildAboutPoint('✓ Harga terjangkau'),
            _buildAboutPoint('✓ Pelayanan ramah dan profesional'),
            SizedBox(height: 16),
            Text(
              'Jam Operasional',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Senin - Minggu: 10.00 - 22.00 WIB',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
      ),
    );
  }

  Widget _buildGalleryTab() {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: galleryImages.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
            image: DecorationImage(
              image: AssetImage(galleryImages[index]),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewTab() {
    final filteredReviews = getFilteredReviews();

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reviews (${allReviews.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16, color: Colors.black54),
                      SizedBox(width: 4),
                      Text(
                        'add review',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    'Most relevant',
                    selectedFilter == 'Most relevant',
                  ),
                  SizedBox(width: 8),
                  _buildFilterChip('Newest', selectedFilter == 'Newest'),
                  SizedBox(width: 8),
                  _buildFilterChip('Highest', selectedFilter == 'Highest'),
                  SizedBox(width: 8),
                  _buildFilterChip('Lowest', selectedFilter == 'Lowest'),
                ],
              ),
            ),
            SizedBox(height: 16),
            ...filteredReviews
                .map(
                  (review) => Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: _buildReviewItem(
                      review['name'],
                      review['timeAgo'],
                      review['rating'],
                      review['review'],
                      review['likes'],
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Color(0xFFFF4F0F) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Color(0xFFFF4F0F) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black54,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewItem(
    String name,
    String time,
    double rating,
    String review,
    int likes,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Color(0xFFFF4F0F),
          child: Text(
            name[0],
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    time,
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  ...List.generate(5, (index) {
                    if (index < rating.floor()) {
                      return Icon(
                        Icons.star,
                        color: Color(0xFFFFB800),
                        size: 14,
                      );
                    } else if (index < rating) {
                      return Icon(
                        Icons.star_half,
                        color: Color(0xFFFFB800),
                        size: 14,
                      );
                    } else {
                      return Icon(
                        Icons.star_border,
                        color: Color(0xFFFFB800),
                        size: 14,
                      );
                    }
                  }),
                  SizedBox(width: 4),
                  Text(
                    rating.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                review,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.thumb_up_outlined,
                    size: 14,
                    color: Colors.black54,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Helpful ($likes)',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
