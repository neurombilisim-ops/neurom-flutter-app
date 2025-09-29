import 'dart:async';
import 'package:flutter/material.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/repositories/product_repository.dart';
import 'package:neurom_bilisim_store/repositories/search_repository.dart';
import 'package:neurom_bilisim_store/repositories/sliders_repository.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';
import 'package:neurom_bilisim_store/app_config.dart';
import 'package:neurom_bilisim_store/helpers/system_config.dart';
import 'package:neurom_bilisim_store/data_model/slider_response.dart';
import 'package:neurom_bilisim_store/data_model/flash_deal_response.dart';
import 'package:neurom_bilisim_store/data_model/product_mini_response.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:go_router/go_router.dart';
import 'package:neurom_bilisim_store/helpers/shimmer_helper.dart';
import 'package:neurom_bilisim_store/screens/product/product_details.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/ui_elements/mini_product_card.dart';
import 'package:neurom_bilisim_store/custom/home_all_products_2.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:neurom_bilisim_store/ui_elements/product_card_black.dart';

class FeaturedProducts extends StatefulWidget {
  const FeaturedProducts({
    super.key,
  });

  @override
  _FeaturedProductsState createState() => _FeaturedProductsState();
}

class _FeaturedProductsState extends State<FeaturedProducts> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  
  // Öne çıkan ürünler için
  final List<dynamic> _featuredProducts = [];
  final List<dynamic> _originalProducts = []; // Orijinal ürün listesi
  bool _isFeaturedProductsLoading = false;
  int _productPage = 1;
  int? _totalProductData = 0;
  bool _showProductLoadingContainer = false;
  final ScrollController _productScrollController = ScrollController();
  
  // Arama ve filtreleme
  String _searchKey = "";
  bool _showSearchBar = false;
  
  // Filtreleme ve sıralama
  String _sortKey = "";
  String _selectedBrands = "";
  String _selectedCategories = "";
  String _minPrice = "";
  String _maxPrice = "";
  
  // Banner verileri için
  List<AIZSlider> _bannerOneList = [];
  List<AIZSlider> _bannerTwoList = [];
  List<AIZSlider> _bannerThreeList = [];
  List<AIZSlider> _flashDealBannerList = [];
  List<FlashDealResponseDatum> _flashDealsList = [];
  
  bool _isBannerOneLoading = true;
  bool _isBannerTwoLoading = true;
  bool _isBannerThreeLoading = true;
  bool _isFlashDealBannerLoading = true;
  bool _isFlashDealsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeaturedProducts();
    _loadAllBanners();
    
    _productScrollController.addListener(() {
      if (_productScrollController.position.pixels ==
          _productScrollController.position.maxScrollExtent) {
        setState(() {
          _productPage++;
        });
        _showProductLoadingContainer = true;
        _loadFeaturedProducts();
      }
    });
  }

  @override
  void dispose() {
    _productScrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadFeaturedProducts() async {
    setState(() {
      _isFeaturedProductsLoading = true;
    });

    try {
      
                ProductMiniResponse response = await ProductRepository().getFeaturedProducts(
                  page: _productPage,
                  searchKey: _searchKey.isNotEmpty ? _searchKey : null,
                  sortKey: _sortKey.isNotEmpty ? _sortKey : null,
                  minPrice: _minPrice.isNotEmpty ? _minPrice : null,
                  maxPrice: _maxPrice.isNotEmpty ? _maxPrice : null,
                  brands: _selectedBrands.isNotEmpty ? _selectedBrands : null,
                  categories: _selectedCategories.isNotEmpty ? _selectedCategories : null,
                );
      
      
      // Tüm ürünlerin detaylarını yazdır
      if (response.products != null && response.products!.isNotEmpty) {
        print("=== TÜM ÜRÜN DETAYLARI ===");
        for (int i = 0; i < response.products!.length; i++) {
          final product = response.products![i];
          print("--- ÜRÜN ${i + 1} ---");
          print("ID: ${product.id}");
          print("Name: ${product.name}");
          print("Slug: ${product.slug}");
          print("Thumbnail: ${product.thumbnail_image}");
          print("Main Price: ${product.main_price}");
          print("Stroked Price: ${product.stroked_price}");
          print("Has Discount: ${product.has_discount}");
          print("Discount: ${product.discount}");
          print("Rating: ${product.rating}");
          print("Sales: ${product.sales}");
          print("Is Wholesale: ${product.isWholesale}");
          print("Links: ${product.links?.details}");
          print("-------------------");
        }
        print("=========================");
      }
      
                if (mounted) {
                  setState(() {
                    if (_productPage == 1) {
                      _featuredProducts.clear();
                      _originalProducts.clear(); // Orijinal listeyi de temizle
                    }
                    
                    // API'den gelen ürünleri al
                    List<dynamic> allProducts = response.products ?? [];
                    
                    // Orijinal listeye ekle (filtreleme için)
                    _originalProducts.addAll(allProducts);
                    
                    // Client-side filtreleme ve sıralama uygula
                    List<dynamic> filteredProducts = _applyClientSideFilters(allProducts);
                    
                    _featuredProducts.addAll(filteredProducts);
                    _totalProductData = response.meta?.total ?? 0;
                    _isFeaturedProductsLoading = false;
                    _showProductLoadingContainer = false;
                  });
                }
    } catch (e) {
      print("Öne çıkan ürünler yüklenirken hata: $e");
      if (mounted) {
        setState(() {
          _isFeaturedProductsLoading = false;
          _showProductLoadingContainer = false;
        });
      }
    }
  }

  Future<void> _loadAllBanners() async {
    await Future.wait([
      _loadBannerOne(),
      _loadBannerTwo(),
      _loadBannerThree(),
      _loadFlashDealBanner(),
      _loadFlashDeals(),
    ]);
  }

  Future<void> _loadBannerOne() async {
    try {
      var response = await SlidersRepository().getBannerOneImages();
      if (mounted) {
        setState(() {
          _bannerOneList = response.sliders ?? [];
          _isBannerOneLoading = false;
        });
      }
    } catch (e) {
      print("Banner One yüklenirken hata: $e");
      if (mounted) {
        setState(() {
          _isBannerOneLoading = false;
        });
      }
    }
  }

  Future<void> _loadBannerTwo() async {
    try {
      var response = await SlidersRepository().getBannerTwoImages();
      if (mounted) {
        setState(() {
          _bannerTwoList = response.sliders ?? [];
          _isBannerTwoLoading = false;
        });
      }
    } catch (e) {
      print("Banner Two yüklenirken hata: $e");
      if (mounted) {
        setState(() {
          _isBannerTwoLoading = false;
        });
      }
    }
  }

  Future<void> _loadBannerThree() async {
    try {
      var response = await SlidersRepository().getBannerThreeImages();
      if (mounted) {
        setState(() {
          _bannerThreeList = response.sliders ?? [];
          _isBannerThreeLoading = false;
        });
      }
    } catch (e) {
      print("Banner Three yüklenirken hata: $e");
      if (mounted) {
        setState(() {
          _isBannerThreeLoading = false;
        });
      }
    }
  }

  Future<void> _loadFlashDealBanner() async {
    try {
      var response = await SlidersRepository().getFlashDealBanner();
      if (mounted) {
        setState(() {
          _flashDealBannerList = response.sliders ?? [];
          _isFlashDealBannerLoading = false;
        });
      }
    } catch (e) {
      print("Flash Deal Banner yüklenirken hata: $e");
      if (mounted) {
        setState(() {
          _isFlashDealBannerLoading = false;
        });
      }
    }
  }

  Future<void> _loadFlashDeals() async {
    try {
      var response = await SlidersRepository().fetchBanners();
      if (mounted) {
        setState(() {
          _flashDealsList = response;
          _isFlashDealsLoading = false;
        });
      }
    } catch (e) {
      print("Flash Deals yüklenirken hata: $e");
      if (mounted) {
        setState(() {
          _isFlashDealsLoading = false;
        });
      }
    }
  }

  Widget _buildBannerSection(String title, List<AIZSlider> banners, bool isLoading) {
    if (isLoading) {
    return Container(
        height: 150,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
      ),
    );
  }

    if (banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                  ),
                ],
              ),
            child: CarouselSlider(
              options: CarouselOptions(
                height: 150,
                viewportFraction: 1.0,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 3),
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                enableInfiniteScroll: true,
              ),
              items: banners.map((banner) {
                return Builder(
                  builder: (BuildContext context) {
                    return GestureDetector(
          onTap: () {
                        if (banner.url != null && banner.url!.isNotEmpty) {
                          var url = banner.url!.split(AppConfig.DOMAIN_PATH).last;
                          if (url.isNotEmpty) {
                            context.go(url);
                          }
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          banner.photo ?? '',
                          fit: BoxFit.cover,
      width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.image,
                                color: Colors.grey,
                                size: 50,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
                              ),
                            ],
      ),
    );
  }

  Widget _buildFlashDealsSection() {
    if (_isFlashDealsLoading) {
      return Container(
        height: 150,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
          color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
        child: const Center(
          child: CircularProgressIndicator(),
      ),
    );
  }

    if (_flashDealsList.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          const Text(
            "Flash Deals",
              style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
                color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _flashDealsList.length,
              itemBuilder: (context, index) {
                final deal = _flashDealsList[index];
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
                color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                  ),
                ],
              ),
                  child: GestureDetector(
          onTap: () {
                      // Flash deal detay sayfasına git
                      print("Flash deal tıklandı: ${deal.id}");
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        deal.banner ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                        return Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.image,
                              color: Colors.grey,
                              size: 50,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  _onSearch(String query) {
    // Arama işlemi
    print("Arama: $query");
    
    // Debounce timer'ı iptal et
    _debounceTimer?.cancel();
    
    // 500ms sonra arama yap
    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      _productPage = 1;
      _loadFeaturedProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: buildAppBar(context),
      body: Stack(
        children: [
          Column(
            children: [
              // Filtreleme ve sıralama butonları
              buildFilterSortBar(),
              // Arama çubuğu (göster/gizle)
              if (_showSearchBar) buildSearchBar(),
              // Ürün listesi
              Expanded(child: buildProductList()),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: buildLoadingContainer(),
          ),
        ],
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      scrolledUnderElevation: 0.0,
      centerTitle: true,
      elevation: 0,
      toolbarHeight: 60,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sol tarafta geri butonu
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Image.asset(
              'assets/sol.png',
              width: 20,
              height: 20,
            ),
          ),
          // Ortada logo
          Expanded(
            child: Center(
              child: Image.asset(
                "assets/logo.png",
                height: 30,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Sağ tarafta arama
          IconButton(
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
              });
            },
            icon: Icon(
              Icons.search,
              color: Colors.black87,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 45,
              decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Color(0xFF0091e5).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                              child: TextField(
        controller: _searchController,
        onChanged: _onSearch,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
                                decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.search_here_ucf,
                                    hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Color(0xFF0091e5),
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
              ),
            ),
          ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      controller: _productScrollController,
      child: Column(
        children: [
          // Öne çıkan ürünler listesi
          if (_isFeaturedProductsLoading && _featuredProducts.isEmpty)
            Container(
              height: 200,
              child: const Center(child: CircularProgressIndicator()),
            )
          else if (_featuredProducts.isEmpty)
            Container(
              height: 200,
              child: Center(
                child: Text(
                  "Öne çıkan ürün bulunamadı",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            )
          else
            SingleChildScrollView(
              child: Container(
                color: Colors.white,
                child: StaggeredGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: _featuredProducts.map((product) {
                    return ProductCardBlack(
                      id: product.id,
                      slug: product.slug ?? '',
                      image: product.thumbnail_image,
                      name: product.name,
                      main_price: product.main_price,
                      stroked_price: product.stroked_price,
                      has_discount: product.has_discount,
                      discount: product.discount,
                      is_wholesale: product.isWholesale,
                      rating: product.rating,
                      sales: product.sales,
                    );
                  }).toList(),
                ),
              ),
            ),
          
          // Loading container
          if (_showProductLoadingContainer)
            Container(
              height: 50,
              color: Colors.white,
              child: Center(
                child: Text(
                  _totalProductData == _featuredProducts.length
                      ? "Daha fazla ürün yok"
                      : "Daha fazla ürün yükleniyor...",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          
          // Banner'lar
          // Banner One
          _buildBannerSection("", _bannerOneList, _isBannerOneLoading),
          
          // Banner Two
          _buildBannerSection("", _bannerTwoList, _isBannerTwoLoading),
          
          // Banner Three
          _buildBannerSection("", _bannerThreeList, _isBannerThreeLoading),
          
          // Flash Deal Banner
          _buildBannerSection("", _flashDealBannerList, _isFlashDealBannerLoading),
          
          // Flash Deals
          _buildFlashDealsSection(),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Filtreleme ve sıralama butonları
  Widget buildFilterSortBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          // Filtrele butonu
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _showFilterDialog();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.filter_list, color: Colors.grey[600], size: 18),
                      SizedBox(width: 8),
                      Text(
                        "Filtrele",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          // Sırala butonu
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _showSortDialog();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sort, color: Colors.grey[600], size: 18),
                      SizedBox(width: 8),
                      Text(
                        "Sırala",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Arama çubuğu
  Widget buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Ürün ara...",
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                  onPressed: () {
                    _searchController.clear();
                    _searchKey = "";
                    _productPage = 1;
                    _loadFeaturedProducts();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF0091e5), width: 2),
          ),
        ),
        onSubmitted: (value) {
          _searchKey = value;
          _productPage = 1;
          _loadFeaturedProducts();
        },
      ),
    );
  }

  // Ürün listesi
  Widget buildProductList() {
    if (_isFeaturedProductsLoading && _featuredProducts.isEmpty) {
      return _buildLoadingGrid();
    }

    if (_featuredProducts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        controller: _productScrollController,
        child: Container(
          color: Colors.white,
          child: StaggeredGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: _featuredProducts.map((product) {
              return ProductCardBlack(
                id: product.id,
                slug: product.slug ?? '',
                image: product.thumbnail_image,
                name: product.name,
                main_price: product.main_price,
                stroked_price: product.stroked_price,
                has_discount: product.has_discount,
                discount: product.discount,
                is_wholesale: product.isWholesale,
                rating: product.rating,
                sales: product.sales,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Loading container
  Widget buildLoadingContainer() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height: _showProductLoadingContainer ? 50 : 0,
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: Text(
          _totalProductData == _featuredProducts.length
              ? "Daha fazla ürün yok"
              : "Daha fazla ürün yükleniyor...",
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // Filtreleme dialog'u
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Filtrele",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Fiyat Aralığı",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: "Min Fiyat",
                                  hintText: "0",
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) => _minPrice = value,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: "Max Fiyat",
                                  hintText: "10000",
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) => _maxPrice = value,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 32),
                      // Uygula butonu
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            _refilterExistingProducts();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF0091e5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Filtreleri Uygula",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Sıralama dialog'u
  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Sırala",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Options
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildSortOption(
                      context,
                      "Fiyat (Düşük → Yüksek)",
                      Icons.arrow_upward,
                      "price_low_to_high",
                    ),
                    _buildSortOption(
                      context,
                      "Fiyat (Yüksek → Düşük)",
                      Icons.arrow_downward,
                      "price_high_to_low",
                    ),
                    _buildSortOption(
                      context,
                      "En Yeni",
                      Icons.new_releases,
                      "newest",
                    ),
                    _buildSortOption(
                      context,
                      "En Popüler",
                      Icons.trending_up,
                      "popular",
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(BuildContext context, String title, IconData icon, String sortKey) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(icon, color: Colors.grey[600], size: 20),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        onTap: () {
          setState(() {
            _sortKey = sortKey;
          });
          _refilterExistingProducts();
          Navigator.pop(context);
        },
      ),
    );
  }

  // Filtreleri uygula
  void _applyFilters() {
    _productPage = 1;
    // Tüm ürünleri çek ve filtrele
    _loadAllProductsAndFilter();
  }

  // Tüm ürünleri çek ve filtrele
  Future<void> _loadAllProductsAndFilter() async {
    setState(() {
      _isFeaturedProductsLoading = true;
      _featuredProducts.clear();
      _originalProducts.clear();
    });

    try {
      print("=== TÜM ÜRÜNLERİ ÇEKİYOR ===");
      List<dynamic> allProducts = [];
      int page = 1;
      bool hasMore = true;

      while (hasMore) {
        print("Sayfa $page yükleniyor...");
        
        ProductMiniResponse response = await ProductRepository().getFeaturedProducts(
          page: page,
        );

        if (response.products != null && response.products!.isNotEmpty) {
          allProducts.addAll(response.products!);
          print("Sayfa $page: ${response.products!.length} ürün eklendi");
          
          // Sonraki sayfa var mı kontrol et
          int lastPage = response.meta?.lastPage ?? 1;
          int perPage = response.meta?.perPage ?? 20;
          
          print("Sayfa $page: ${response.products!.length} ürün (Toplam: ${response.meta?.total}, Son sayfa: $lastPage, Sayfa başına: $perPage)");
          
          if (page >= lastPage || response.products!.length < perPage) {
            hasMore = false;
            print("Son sayfaya ulaşıldı");
          } else {
            page++;
          }
        } else {
          hasMore = false;
        }
      }

      print("Toplam ${allProducts.length} ürün çekildi");

      if (mounted) {
        setState(() {
          _originalProducts.addAll(allProducts);
          
          // Client-side filtreleme uygula
          List<dynamic> filteredProducts = _applyClientSideFilters(allProducts);
          _featuredProducts.addAll(filteredProducts);
          
          _totalProductData = allProducts.length;
          _isFeaturedProductsLoading = false;
          _showProductLoadingContainer = false;
        });
      }

      print("Filtreleme tamamlandı: ${_featuredProducts.length} ürün gösteriliyor");
    } catch (e) {
      print("Tüm ürünler yüklenirken hata: $e");
      if (mounted) {
        setState(() {
          _isFeaturedProductsLoading = false;
          _showProductLoadingContainer = false;
        });
      }
    }
  }

  // Mevcut ürünleri yeniden filtrele (sıralama için)
  void _refilterExistingProducts() {
    print("=== YENİDEN FİLTRELEME ===");
    print("Sıralama anahtarı: $_sortKey");
    print("Arama anahtarı: $_searchKey");
    print("Min fiyat: $_minPrice");
    print("Max fiyat: $_maxPrice");
    
    // Her zaman tüm ürünleri çek ve filtrele
    _loadAllProductsAndFilter();
  }

  // Ürün fiyatını al
  double _getProductPrice(dynamic product) {
    try {
      String priceString = (product.main_price ?? "0").toString()
          .replaceAll(' TL', '')
          .replaceAll(' TRY', '')
          .replaceAll('TL', '')
          .replaceAll('TRY', '')
          .replaceAll(',', '') // Virgülleri kaldır
          .trim();
      
      return double.parse(priceString);
    } catch (e) {
      return 0.0; // Hata durumunda 0 döndür
    }
  }

  // Client-side filtreleme ve sıralama
  List<dynamic> _applyClientSideFilters(List<dynamic> products) {
    List<dynamic> filteredProducts = List.from(products);
    
    // Arama filtresi
    if (_searchKey.isNotEmpty) {
      filteredProducts = filteredProducts.where((product) {
        String productName = (product.name ?? '').toLowerCase();
        String searchKey = _searchKey.toLowerCase();
        return productName.contains(searchKey);
      }).toList();
    }
    
    // Fiyat filtresi
    if (_minPrice.isNotEmpty) {
      double minPrice = double.tryParse(_minPrice) ?? 0;
      print("Min fiyat filtresi uygulanıyor: $minPrice");
      int beforeCount = filteredProducts.length;
      filteredProducts = filteredProducts.where((product) {
        String priceStr = product.main_price ?? '0';
        // TRY'yi kaldır ve sayıya çevir
        priceStr = priceStr.replaceAll('TRY', '').replaceAll(',', '').trim();
        double productPrice = double.tryParse(priceStr) ?? 0;
        print("Min filtresi - Ürün: ${product.name}, Orijinal: ${product.main_price}, Parse: '$priceStr' -> $productPrice");
        bool matches = productPrice >= minPrice;
        if (!matches) {
          print("Ürün filtrelendi: ${product.name} - Fiyat: $productPrice (Min: $minPrice)");
        }
        return matches;
      }).toList();
      print("Min fiyat filtresi: $beforeCount -> ${filteredProducts.length} ürün");
    }
    
    if (_maxPrice.isNotEmpty) {
      double maxPrice = double.tryParse(_maxPrice) ?? double.infinity;
      print("Max fiyat filtresi uygulanıyor: $maxPrice");
      int beforeCount = filteredProducts.length;
      filteredProducts = filteredProducts.where((product) {
        String priceStr = product.main_price ?? '0';
        // TRY'yi kaldır ve sayıya çevir
        priceStr = priceStr.replaceAll('TRY', '').replaceAll(',', '').trim();
        double productPrice = double.tryParse(priceStr) ?? 0;
        bool matches = productPrice <= maxPrice;
        if (!matches) {
          print("Ürün filtrelendi: ${product.name} - Fiyat: $productPrice (Max: $maxPrice)");
        }
        return matches;
      }).toList();
      print("Max fiyat filtresi: $beforeCount -> ${filteredProducts.length} ürün");
    }
    
    // Sıralama
    if (_sortKey.isNotEmpty) {
      print("Sıralama uygulanıyor: $_sortKey");
      switch (_sortKey) {
        case "price_low_to_high":
          filteredProducts.sort((a, b) {
            double priceA = _getProductPrice(a);
            double priceB = _getProductPrice(b);
            return priceA.compareTo(priceB);
          });
          break;
        case "price_high_to_low":
          filteredProducts.sort((a, b) {
            double priceA = _getProductPrice(a);
            double priceB = _getProductPrice(b);
            return priceB.compareTo(priceA);
          });
          break;
        case "newest":
          // En yeni - ID'ye göre sırala (büyük ID = yeni)
          filteredProducts.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
          break;
        case "popular":
          // En popüler - satış sayısına göre sırala
          filteredProducts.sort((a, b) => (b.sales ?? 0).compareTo(a.sales ?? 0));
          break;
      }
      print("Sıralama tamamlandı. İlk 3 ürün:");
      for (int i = 0; i < 3 && i < filteredProducts.length; i++) {
        var product = filteredProducts[i];
        print("${i + 1}. ${product.name} - ${product.main_price}");
      }
    }
    
    print("Filtreleme sonucu: ${filteredProducts.length} ürün");
    return filteredProducts;
  }

  // Refresh
  Future<void> _onRefresh() async {
    _productPage = 1;
    _loadFeaturedProducts();
  }


  // Loading grid
  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return _buildLoadingCard();
      },
    );
  }

  // Loading card
  Widget _buildLoadingCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ShimmerHelper().buildBasicShimmer(
        height: double.infinity,
        width: double.infinity,
      ),
    );
  }

  // Empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            "Öne çıkan ürün bulunamadı",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Modern product card
  Widget _buildModernProductCard(dynamic product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetails(slug: product.slug ?? ''),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
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
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  child: product.thumbnail_image != null && product.thumbnail_image.isNotEmpty
                      ? Image.network(
                          product.thumbnail_image,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey[400],
                                size: 32,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                            size: 32,
                          ),
                        ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name ?? 'Ürün Adı',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Text(
                      product.main_price != null 
                          ? (SystemConfig.systemCurrency != null
                              ? product.main_price.replaceAll(
                                  SystemConfig.systemCurrency!.code!,
                                  SystemConfig.systemCurrency!.symbol!)
                              : product.main_price)
                          : 'Fiyat Belirtilmemiş',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: product.has_discount == true 
                            ? Color(0xff27AE60)
                            : MyTheme.accent_color,
                      ),
                    ),
                    if (product.has_discount == true && product.discount != null)
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Color(0xff27AE60),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '%${product.discount}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
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
