import 'dart:async';
import 'package:flutter/material.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/repositories/product_repository.dart';
import 'package:neurom_bilisim_store/repositories/search_repository.dart';
import 'package:neurom_bilisim_store/repositories/sliders_repository.dart';
import 'package:neurom_bilisim_store/repositories/flash_deal_repository.dart';
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
import 'package:neurom_bilisim_store/ui_elements/product_card_black.dart';

class FeaturedProductsNew extends StatefulWidget {
  const FeaturedProductsNew({
    super.key,
    this.slug,
  });
  
  final String? slug;

  @override
  _FeaturedProductsNewState createState() => _FeaturedProductsNewState();
}

class _FeaturedProductsNewState extends State<FeaturedProductsNew> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  
  // Fırsat ürünleri için
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

  @override
  void initState() {
    super.initState();
    _loadFeaturedProducts();
    
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
      
      String? flashDealSlug;
      
      // Eğer slug verilmişse, onu kullan; yoksa ilk flash deal'i al
      if (widget.slug != null && widget.slug!.isNotEmpty) {
        flashDealSlug = widget.slug;
      } else {
        // Önce aktif flash deal'leri al
        var flashDealsResponse = await FlashDealRepository().getFlashDeals();
        
        if (flashDealsResponse.flashDeals != null && flashDealsResponse.flashDeals!.isNotEmpty) {
          // İlk flash deal'in ürünlerini al
          var firstFlashDeal = flashDealsResponse.flashDeals!.first;
          
          flashDealSlug = firstFlashDeal.slug;
        }
      }
      
      if (flashDealSlug != null) {
        try {
          // Slug ile deneyelim (web sitesindeki API koduna göre)
          var flashDealProductsResponse = await ProductRepository().getFlashDealProducts(flashDealSlug);
          
          
          if (mounted) {
            setState(() {
              if (_productPage == 1) {
                _featuredProducts.clear();
                _originalProducts.clear();
              }
              
              // API'den gelen flash deal ürünlerini al
              List<dynamic> flashDealProducts = flashDealProductsResponse.products ?? [];
              
              _originalProducts.addAll(flashDealProducts);
              _featuredProducts.addAll(flashDealProducts);
              _totalProductData = flashDealProductsResponse.meta?.total ?? 0;
              _isFeaturedProductsLoading = false;
              _showProductLoadingContainer = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _featuredProducts.clear();
              _originalProducts.clear();
              _totalProductData = 0;
              _isFeaturedProductsLoading = false;
              _showProductLoadingContainer = false;
            });
          }
        }
      } else {
        // Flash deal yoksa boş liste göster
        if (mounted) {
          setState(() {
            _featuredProducts.clear();
            _originalProducts.clear();
            _totalProductData = 0;
            _isFeaturedProductsLoading = false;
            _showProductLoadingContainer = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFeaturedProductsLoading = false;
          _showProductLoadingContainer = false;
        });
      }
    }
  }

  _onSearch(String query) {
    // Arama işlemi
    _searchKey = query;
    _productPage = 1;
    _loadFeaturedProducts();
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
          // Ortada başlık
          Expanded(
            child: Center(
              child: Text(
                "Fırsat Ürünleri",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
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
          hintText: "Fırsat ürünü ara...",
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
        onChanged: (value) {
          _searchKey = value;
          
          // Debounce timer'ı iptal et
          _debounceTimer?.cancel();
          
          // 500ms sonra arama yap
          _debounceTimer = Timer(Duration(milliseconds: 500), () {
            _productPage = 1;
            _loadFeaturedProducts();
          });
        },
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
      child: GridView.builder(
        controller: _productScrollController,
        padding: EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.6,
        ),
        itemCount: _featuredProducts.length,
        itemBuilder: (context, index) {
          final product = _featuredProducts[index];
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
        },
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
              ? "Daha fazla fırsat ürünü yok"
              : "Daha fazla fırsat ürünü yükleniyor...",
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

  // Mevcut ürünleri yeniden filtrele (sıralama için)
  void _refilterExistingProducts() {
    
    // Sayfa 1'den başlayarak server-side filtreleme ile yükle
    _productPage = 1;
    _loadFeaturedProducts();
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
            Icons.local_offer_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            "Fırsat ürünü bulunamadı",
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
}
