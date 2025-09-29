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
import 'package:neurom_bilisim_store/screens/product/product_details.dart';
import 'package:neurom_bilisim_store/repositories/cart_repository.dart';
import 'package:neurom_bilisim_store/presenter/cart_counter.dart';
import 'package:provider/provider.dart';
import 'package:neurom_bilisim_store/custom/toast_component.dart';
import 'package:neurom_bilisim_store/screens/checkout/cart.dart';
import 'package:neurom_bilisim_store/my_theme.dart';

class Filter extends StatefulWidget {
  const Filter({
    super.key,
    this.selected_filter = "product",
    this.selected_brand_id,
  });

  final String selected_filter;
  final int? selected_brand_id;

  @override
  _FilterState createState() => _FilterState();
}

class _FilterState extends State<Filter> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  
  // Filtreleme seçenekleri
  String _selectedCategory = '';
  String _selectedBrand = '';
  double _minPrice = 0;
  double _maxPrice = 0; // 0 = filtreleme yok
  String _sortBy = 'name';
  bool _inStockOnly = false;
  bool _onSaleOnly = false;
  bool _featuredOnly = false;
  bool _digitalOnly = false;
  bool _wholesaleOnly = false;
  double _minRating = 0;
  int _minSales = 0;
  String _selectedColor = '';
  String _selectedSize = '';
  String _selectedCondition = '';
  
  // Son gezilen ürünler için
  final List<dynamic> _lastViewedProducts = [];
  bool _isLastViewedLoading = false;
  
  // Tüm ürünler için
  final List<dynamic> _allProducts = [];
  bool _isAllProductsLoading = false;
  int _productPage = 1;
  int? _totalProductData = 0;
  bool _showProductLoadingContainer = false;
  final ScrollController _productScrollController = ScrollController();
  
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
 // Ürün ID -> Ortalama puan

  @override
  void initState() {
    super.initState();
    _loadLastViewedProducts();
    _loadAllBanners();
    
    // Her 30 saniyede bir son bakılan ürünleri kontrol et
    Timer.periodic(Duration(seconds: 30), (timer) {
      if (mounted && is_logged_in.$) {
        _loadLastViewedProducts();
      }
    });
    
    // Eğer product filtresi seçiliyse tüm ürünleri yükle
    if (widget.selected_filter == "product") {
      _loadAllProducts();
      _productScrollController.addListener(() {
        if (_productScrollController.position.pixels ==
            _productScrollController.position.maxScrollExtent) {
          setState(() {
            _productPage++;
          });
          _showProductLoadingContainer = true;
          _loadAllProducts();
        }
      });
    }
    
    // Eğer marka ID'si verilmişse o markanın ürünlerini yükle
    if (widget.selected_brand_id != null) {
      _selectedBrand = widget.selected_brand_id.toString();
      _loadAllProducts();
    }
  }

  @override
  void dispose() {
    _productScrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAllProducts() async {
    setState(() {
      _isAllProductsLoading = true;
    });

    try {
      
      ProductMiniResponse response = await ProductRepository().getFilteredProducts(
        page: _productPage,
        name: _searchController.text,
        categories: _selectedCategory.isNotEmpty ? _selectedCategory : "",
        min: _minPrice > 0 ? _minPrice.toString() : "",
        max: _maxPrice > 0 && _maxPrice < 10000 ? _maxPrice.toString() : "",
        sort_key: _sortBy,
        has_discount: _onSaleOnly ? "1" : "",
        in_stock: _inStockOnly ? "1" : "",
        featured: _featuredOnly ? "1" : "",
        digital: _digitalOnly ? "1" : "",
        wholesale: _wholesaleOnly ? "1" : "",
        min_rating: _minRating > 0 ? _minRating.toString() : "",
        min_sales: _minSales > 0 ? _minSales.toString() : "",
        color: _selectedColor.isNotEmpty ? _selectedColor : "",
        size: _selectedSize.isNotEmpty ? _selectedSize : "",
        condition: _selectedCondition.isNotEmpty ? _selectedCondition : "",
      );
      
      
      if (mounted) {
        setState(() {
          if (_productPage == 1) {
            _allProducts.clear();
          }
          _allProducts.addAll(response.products ?? []);
          _totalProductData = response.meta?.total ?? 0;
          _isAllProductsLoading = false;
          _showProductLoadingContainer = false;
        });
      }
    } catch (e) {
      print("Tüm ürünler yüklenirken hata: $e");
      if (mounted) {
        setState(() {
          _isAllProductsLoading = false;
          _showProductLoadingContainer = false;
        });
      }
    }
  }

  Future<void> _loadLastViewedProducts() async {
    if (!is_logged_in.$) {
      print("Kullanıcı giriş yapmamış, son gezilen ürünler yüklenmeyecek");
      return;
    }

    setState(() {
      _isLastViewedLoading = true;
    });

    try {
      print("Son gezilen ürünler yükleniyor...");
      print("Access token: ${access_token.$}");
      
      var response = await ProductRepository().lastViewProduct();
      
      
      if (response.products != null && response.products!.isNotEmpty) {
        print("İlk ürün adı: ${response.products![0].name}");
        print("İlk ürün resmi: ${response.products![0].thumbnail_image}");
        print("İlk ürün fiyatı: ${response.products![0].main_price}");
      }

      if (mounted) {
        setState(() {
          _lastViewedProducts.clear();
          Set<int> seenIds = {};
          List<dynamic> uniqueProducts = [];
          for (var product in response.products ?? []) {
            if (!seenIds.contains(product.id)) {
              seenIds.add(product.id);
              uniqueProducts.add(product);
            }
          }
          _lastViewedProducts.addAll(uniqueProducts);
          _isLastViewedLoading = false;
        });
        
      }
    } catch (e) {
      print("Son gezilen ürünler yüklenirken hata: $e");
      if (mounted) {
        setState(() {
          _isLastViewedLoading = false;
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
      if (widget.selected_filter == "product") {
        _productPage = 1;
        _loadAllProducts();
      }
    });
  }

  Future<void> _onRefresh() async {
    // Sayfa yenilendiğinde tüm verileri yeniden yükle
    print("Sayfa yenileniyor...");
    
    // Son bakılan ürünleri yeniden yükle
    await _loadLastViewedProducts();
    
    // Eğer product filtresi seçiliyse tüm ürünleri de yeniden yükle
    if (widget.selected_filter == "product") {
      _productPage = 1;
      await _loadAllProducts();
    }
    
    print("Sayfa yenileme tamamlandı");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _buildContent(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
          color: Color(0xFF0091e5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
                              ),
                            ],
                          ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
      title: _buildSearchBar(),
      titleSpacing: 16,
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
    return Column(
      children: [
        // Filtreleme seçenekleri
        _buildFilterOptions(),
        
        // Sonuçlar
        Expanded(
          child: SingleChildScrollView(
            controller: _productScrollController,
            child: Column(
              children: [
                _buildLastViewedSection(),
                
                // Tüm ürünler bölümü - sadece product filtresi seçiliyse göster
                if (widget.selected_filter == "product") ...[
                  const SizedBox(height: 20),
                  _buildAllProductsSection(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtreleme Seçenekleri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: Text(
                  'Temizle',
                  style: TextStyle(
                    color: Color(0xFF0091e5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Kategori seçimi
          _buildCategoryFilter(),
          const SizedBox(height: 16),
          
          // Fiyat aralığı
          _buildPriceRangeFilter(),
          const SizedBox(height: 16),
          
          // Sıralama
          _buildSortFilter(),
          const SizedBox(height: 16),
          
          // Diğer seçenekler
          _buildOtherFilters(),
          const SizedBox(height: 16),
          
          // Gelişmiş seçenekler
          _buildAdvancedFilters(),
          const SizedBox(height: 20),
          
          // Tamam butonu
          _buildApplyButton(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategori',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory.isEmpty ? null : _selectedCategory,
              hint: Text('Kategori seçin'),
              isExpanded: true,
              items: [
                DropdownMenuItem(value: '', child: Text('Tümü')),
                DropdownMenuItem(value: 'electronics', child: Text('Elektronik')),
                DropdownMenuItem(value: 'clothing', child: Text('Giyim')),
                DropdownMenuItem(value: 'home', child: Text('Ev & Yaşam')),
                DropdownMenuItem(value: 'sports', child: Text('Spor')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value ?? '';
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fiyat Aralığı',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Min Fiyat',
                  hintText: '0',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _minPrice = double.tryParse(value) ?? 0;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Max Fiyat',
                  hintText: '1000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _maxPrice = double.tryParse(value) ?? 0;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sıralama',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortBy,
              isExpanded: true,
              items: [
                DropdownMenuItem(value: 'name', child: Text('İsme göre')),
                DropdownMenuItem(value: 'price_low', child: Text('Fiyat (Düşük-Yüksek)')),
                DropdownMenuItem(value: 'price_high', child: Text('Fiyat (Yüksek-Düşük)')),
                DropdownMenuItem(value: 'newest', child: Text('En Yeni')),
                DropdownMenuItem(value: 'popular', child: Text('En Popüler')),
              ],
              onChanged: (value) {
                setState(() {
                  _sortBy = value ?? 'name';
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtherFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Diğer Seçenekler',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: Text('Stokta olanlar'),
                value: _inStockOnly,
                onChanged: (value) {
                  setState(() {
                    _inStockOnly = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: Text('İndirimde olanlar'),
                value: _onSaleOnly,
                onChanged: (value) {
                  setState(() {
                    _onSaleOnly = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: Text('Öne çıkanlar'),
                value: _featuredOnly,
                onChanged: (value) {
                  setState(() {
                    _featuredOnly = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: Text('Dijital ürünler'),
                value: _digitalOnly,
                onChanged: (value) {
                  setState(() {
                    _digitalOnly = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: Text('Toptan satış'),
                value: _wholesaleOnly,
                onChanged: (value) {
                  setState(() {
                    _wholesaleOnly = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: SizedBox(), // Boş alan
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdvancedFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gelişmiş Filtreler',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        
        // Minimum puan
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Min Puan',
                  hintText: '0',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _minRating = double.tryParse(value) ?? 0;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Min Satış',
                  hintText: '0',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _minSales = int.tryParse(value) ?? 0;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Renk ve beden
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Renk',
                  hintText: 'Kırmızı, Mavi...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (value) {
                  _selectedColor = value;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Beden',
                  hintText: 'S, M, L...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (value) {
                  _selectedSize = value;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Durum
        TextField(
          decoration: InputDecoration(
            labelText: 'Durum',
            hintText: 'Yeni, İkinci El...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: (value) {
            _selectedCondition = value;
          },
        ),
      ],
    );
  }

  Widget _buildApplyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _applyFilters,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF0091e5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Text(
          'Tamam',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = '';
      _selectedBrand = '';
      _minPrice = 0;
      _maxPrice = 0;
      _sortBy = 'name';
      _inStockOnly = false;
      _onSaleOnly = false;
      _featuredOnly = false;
      _digitalOnly = false;
      _wholesaleOnly = false;
      _minRating = 0;
      _minSales = 0;
      _selectedColor = '';
      _selectedSize = '';
      _selectedCondition = '';
    });
  }

  void _applyFilters() {
    // Filtreleri uygula
    _productPage = 1;
    _loadAllProducts();
    
    // Başarı mesajı göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Filtreler uygulandı'),
        backgroundColor: Color(0xFF0091e5),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildLastViewedSection() {
    if (_isLastViewedLoading) {
      return Container(
        height: 100,
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_lastViewedProducts.isEmpty) {
                        return Container(
        height: 200,
                          child: Center(
                              child: Text(
            "Henüz gezilen ürün bulunmuyor",
                            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              ),
            ),
          ),
      );
    }

    return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
          padding: const EdgeInsets.only(left: 18, right: 16, top: 16, bottom: 8),
                        child:               Text(
                "Son Gezilen Ürünler",
                          style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
                          ),
        SizedBox(
          height: 99,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _lastViewedProducts.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  if (_lastViewedProducts[index].slug != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetails(
                          slug: _lastViewedProducts[index].slug,
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  width: 350,
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
                  child: Stack(
                  children: [
                    Row(
                      children: [
                        // Sol taraf - Resim
                        Container(
                          width: 98,
                          height: 100,
                          margin: const EdgeInsets.only(top: 2, left: 2, bottom: 0),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _lastViewedProducts[index].thumbnail_image ?? '',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: Icon(
                                    Icons.image,
                                    color: Colors.grey.shade400,
                                    size: 30,
                                  ),
                                );
                              },
                  ),
                ),
              ),
                        // Sağ taraf - Ürün bilgileri
              Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8, right: 8, top: 2, bottom: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Ürün ismi - En üstte
                                Text(
                                  _lastViewedProducts[index].name ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                // Fiyat kutusu
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                        child: Text(
                                    SystemConfig.systemCurrency != null
                                        ? (_lastViewedProducts[index].main_price ?? '').replaceAll(
                                            SystemConfig.systemCurrency!.code!,
                                            SystemConfig.systemCurrency!.symbol!,
                                          )
                                        : _lastViewedProducts[index].main_price ?? '',
                          style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                if (_lastViewedProducts[index].has_discount == true)
                      Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                                      (_lastViewedProducts[index].stroked_price ?? '').replaceAll('TRY', ''),
                          style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ),
            ],
          ),
        ),
      ),
                      ],
                    ),
                    // İndirim yüzdesi - Sol üst köşe
                    if (_lastViewedProducts[index].has_discount == true)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xFF0091e5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                      child: Text(
                            '${_lastViewedProducts[index].discount ?? 0}',
                            style: const TextStyle(
        color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ],
                ),
              ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        
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
    );
  }

  // Sepete Ekleme Metodu
  Future<void> _addToCart(dynamic product) async {
    if (!guest_checkout_status.$) {
      if (is_logged_in.$ == false) {
        ToastComponent.showDialog(
          'Giriş yapmanız gerekiyor',
        );
        return;
      }
    }

    try {
      var cartAddResponse = await CartRepository().getCartAddResponse(
        product.id,
        null, // variant
        user_id.$,
        1, // quantity
      );

      temp_user_id.$ = cartAddResponse.tempUserId;
      temp_user_id.save();

      if (cartAddResponse.result == false) {
        ToastComponent.showDialog(cartAddResponse.message);
        return;
      } else {
        // Update cart count
        Provider.of<CartCounter>(context, listen: false).getCount();
        
        // Show modern success notification
        _showModernSuccessDialog(context);
      }
    } catch (e) {
      print('Error adding to cart: $e');
      ToastComponent.showDialog('Sepete ekleme başarısız');
    }
  }

  // Modern başarı bildirimi
  void _showModernSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Başarı ikonu
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 30,
                  ),
                ),
                SizedBox(height: 16),
                // Başlık
                Text(
                  'Başarılı!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                // Mesaj
                Text(
                  'Ürün sepete eklendi',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 24),
                // Butonlar
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Text(
                          'Tamam',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Cart(has_bottomnav: false),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MyTheme.accent_color,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Sepete Git',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık
        Padding(
          padding: const EdgeInsets.only(left: 18, right: 16, top: 16, bottom: 8),
          child: Text(
            "Tüm Ürünler",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        
        // Ürünler listesi
        if (_isAllProductsLoading && _allProducts.isEmpty)
          Container(
            height: 200,
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (_allProducts.isEmpty)
          Container(
            height: 200,
            child: Center(
              child: Text(
                "Ürün bulunamadı",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _allProducts.length,
            itemBuilder: (context, index) {
              final product = _allProducts[index];
              return GestureDetector(
                onTap: () {
                  if (product.slug != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetails(
                          slug: product.slug,
                        ),
                      ),
                    );
                  }
                },
                child: Container(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                          // Üst taraf - Resim
                          Expanded(
                            flex: 3,
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  product.thumbnail_image ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade200,
                                      child: Icon(
                                        Icons.image,
                                        color: Colors.grey.shade400,
                                        size: 30,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          // Alt taraf - Ürün bilgileri
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    SystemConfig.systemCurrency != null
                                        ? (product.main_price ?? '').replaceAll(
                                            SystemConfig.systemCurrency!.code!,
                                            SystemConfig.systemCurrency!.symbol!,
                                          )
                                        : product.main_price ?? '',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  if (product.has_discount == true) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      (product.stroked_price ?? '').replaceAll('TRY', ''),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ],
                                  const Spacer(),
                                  // İndirim yüzdesi
                                  if (product.has_discount == true)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF0091e5),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '%${product.discount ?? 0}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                      // Sepete Ekleme Butonu - Sağ alt köşe
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Image.asset(
                              'assets/cart.png',
                              width: 14,
                              height: 14,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              _addToCart(product);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        
        // Loading container
        if (_showProductLoadingContainer)
          Container(
            height: 50,
            color: Colors.white,
            child: Center(
              child: Text(
                _totalProductData == _allProducts.length
                    ? "Daha fazla ürün yok"
                    : "Daha fazla ürün yükleniyor...",
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}