import 'dart:async';
import 'package:neurom_bilisim_store/custom/device_info.dart';
import 'package:neurom_bilisim_store/custom/useful_elements.dart';
import 'package:neurom_bilisim_store/data_model/category_response.dart';
import 'package:neurom_bilisim_store/data_model/product_mini_response.dart';
import 'package:neurom_bilisim_store/helpers/shimmer_helper.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/repositories/category_repository.dart';
import 'package:neurom_bilisim_store/repositories/product_repository.dart';
import 'package:neurom_bilisim_store/ui_elements/product_card.dart';
import 'package:neurom_bilisim_store/screens/product/product_details.dart';
import 'package:flutter/material.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class CategoryProducts extends StatefulWidget {
  const CategoryProducts({super.key, required this.slug});
  final String slug;

  @override
  _CategoryProductsState createState() => _CategoryProductsState();
}

class _CategoryProductsState extends State<CategoryProducts> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _xcrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  int _page = 1;
  int? _totalData = 0;
  bool _isInitial = true;
  String _searchKey = "";
  Category? categoryInfo;
  bool _showSearchBar = false;
  final List<dynamic> _productList = [];
  bool _showLoadingContainer = false;
  final List<Category> _subCategoryList = [];
  
  // Filtreleme ve sıralama
  String _sortKey = "";
  String _selectedBrands = "";
  String _selectedCategories = "";
  String _minPrice = "";
  String _maxPrice = "";

  // getSubCategory() async {
  //   var res = await CategoryRepository().getCategories(parent_id: widget.slug);
  //   _subCategoryList.addAll(res.categories!);
  //   setState(() {});
  // }
  getSubCategory() async {
    var res = await CategoryRepository().getCategories(parent_id: widget.slug);
    if (res.categories != null) {
      _subCategoryList.addAll(res.categories ?? []);
    }
    setState(() {});
  }

  getCategoryInfo() async {
    var res = await CategoryRepository().getCategoryInfo(widget.slug);
    print(res.categories.toString());
    if (res.categories?.isNotEmpty ?? false) {
      categoryInfo = res.categories?.first;
    }
    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCategoryInfo();
    fetchAllDate();

    _xcrollController.addListener(() {
      if (_xcrollController.position.pixels ==
          _xcrollController.position.maxScrollExtent) {
        setState(() {
          _page++;
        });
        _showLoadingContainer = true;
        fetchData();
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _scrollController.dispose();
    _xcrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  fetchData() async {
    // Her zaman kategori ürünlerini al, sonra client-side filtrele
    var productResponse = await ProductRepository().getCategoryProducts(
      id: widget.slug,
      page: _page,
      name: _searchKey,
    );
    
    var products = productResponse.products ?? <Product>[];
    
    // Client-side filtreleme
    if (_minPrice.isNotEmpty || _maxPrice.isNotEmpty) {
      products = _filterByPrice(products);
    }
    
    if (_sortKey.isNotEmpty) {
      products = _sortProducts(products);
    }
    
    _productList.addAll(products);
    _isInitial = false;
    _totalData = productResponse.meta?.total ?? 0;
    _showLoadingContainer = false;
    setState(() {});
  }

  // Fiyat filtreleme
  List<Product> _filterByPrice(List<Product> products) {
    // Güvenli parsing
    double minPrice = _minPrice.isNotEmpty ? double.tryParse(_minPrice) ?? 0 : 0;
    double maxPrice = _maxPrice.isNotEmpty ? double.tryParse(_maxPrice) ?? double.infinity : double.infinity;
    
    return products.where((product) {
      try {
        String priceString = (product.main_price ?? "0").toString()
            .replaceAll(' TL', '')
            .replaceAll(' TRY', '')
            .replaceAll('TL', '')
            .replaceAll('TRY', '')
            .replaceAll(',', '') // Virgülleri kaldır
            .trim();
        
        double price = double.parse(priceString);
        
        bool minOk = _minPrice.isEmpty || price >= minPrice;
        bool maxOk = _maxPrice.isEmpty || price <= maxPrice;
        
        return minOk && maxOk;
      } catch (e) {
        return true; // Hata durumunda ürünü dahil et
      }
    }).toList();
  }

  // Sıralama
  List<Product> _sortProducts(List<Product> products) {
    switch (_sortKey) {
      case "price_low_to_high":
        products.sort((a, b) {
          double priceA = _getProductPrice(a);
          double priceB = _getProductPrice(b);
          return priceA.compareTo(priceB);
        });
        break;
      case "price_high_to_low":
        products.sort((a, b) {
          double priceA = _getProductPrice(a);
          double priceB = _getProductPrice(b);
          return priceB.compareTo(priceA);
        });
        break;
      case "newest":
        // En yeni - ID'ye göre sırala (büyük ID = yeni)
        products.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
        break;
      case "popular":
        // En popüler - satış sayısına göre sırala
        products.sort((a, b) => (b.sales ?? 0).compareTo(a.sales ?? 0));
        break;
    }
    return products;
  }

  // Ürün fiyatını al
  double _getProductPrice(Product product) {
    try {
      return double.parse(
        (product.main_price ?? "0").toString()
            .replaceAll(' TL', '')
            .replaceAll(' TRY', '')
            .replaceAll('TL', '')
            .replaceAll('TRY', '')
            .trim()
      );
    } catch (e) {
      return 0.0;
    }
  }

  fetchAllDate() {
    fetchData();
    getSubCategory();
  }

  reset() {
    _productList.clear();
    _isInitial = true;
    _totalData = 0;
    _page = 1;
    _showLoadingContainer = false;
    setState(() {});
  }

  Future<void> _onRefresh() async {
    reset();
    fetchAllDate();
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
                                  hintText: "1000",
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
                    ],
                  ),
                ),
              ),
              // Bottom buttons
              Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            "İptal",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: MyTheme.accent_color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _applyFilters();
                          },
                          child: Text(
                            "Uygula",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
                      "Sıralama",
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
        leading: Icon(icon, color: MyTheme.mainColor, size: 20),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        onTap: () {
          _sortKey = sortKey;
          Navigator.pop(context);
          _applyFilters();
        },
      ),
    );
  }

  // Filtreleri uygula
  void _applyFilters() {
    reset();
    fetchAllDate();
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
              // Alt kategoriler
              if (_subCategoryList.isNotEmpty) buildSubCategory(),
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
                      Icon(Icons.filter_list, size: 18, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Text(
                        "Filtrele",
                        style: TextStyle(
                          color: Colors.grey[700],
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
          // Sıralama butonu
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
                      Icon(Icons.sort, size: 18, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Text(
                        "Sıralama",
                        style: TextStyle(
                          color: Colors.grey[700],
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
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (txt) {
            _searchKey = txt;
            
            // Debounce timer'ı iptal et
            _debounceTimer?.cancel();
            
            // 500ms sonra arama yap
            _debounceTimer = Timer(Duration(milliseconds: 500), () {
              reset();
              fetchAllDate();
            });
          },
          onSubmitted: (txt) {
            _searchKey = txt;
            reset();
            fetchAllDate();
          },
          decoration: InputDecoration(
            hintText: "Ürün ara...",
            hintStyle: TextStyle(color: Colors.grey[600]),
            prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
            suffixIcon: IconButton(
              onPressed: () {
                _searchController.clear();
                _searchKey = "";
                reset();
                fetchAllDate();
                setState(() {
                  _showSearchBar = false;
                });
              },
              icon: Icon(Icons.clear, color: Colors.grey[600]),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ),
    );
  }

  Container buildLoadingContainer() {
    return Container(
      height: _showLoadingContainer ? 36 : 0,
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: Text(
          _totalData == _productList.length
              ? AppLocalizations.of(context)!.no_more_products_ucf
              : AppLocalizations.of(context)!.loading_more_products_ucf,
        ),
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
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
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

  Widget buildAppBarTitle(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: buildAppBarTitleOption(context),
      secondChild: buildAppBarSearchOption(context),
      firstCurve: Curves.fastOutSlowIn,
      secondCurve: Curves.fastOutSlowIn,
      crossFadeState:
          _showSearchBar ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: Duration(milliseconds: 500),
    );
  }

  Container buildAppBarTitleOption(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 37),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: GestureDetector(
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: Icon(
                Icons.arrow_back,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.only(left: 10),
            width: DeviceInfo(context).width! / 2,
            child: Text(
              categoryInfo?.name ?? "",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Spacer(),
          SizedBox(
            width: 20,
            child: GestureDetector(
              onTap: () {
                _showSearchBar = true;
                setState(() {});
              },
              child: Image.asset('assets/search.png'),
            ),
          ),
        ],
      ),
    );
  }

  Container buildAppBarSearchOption(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18),
      width: DeviceInfo(context).width,
      height: 40,
      child: TextField(
        controller: _searchController,
        onTap: () {},
        onChanged: (txt) {
          _searchKey = txt;
          reset();
          fetchData();
        },
        onSubmitted: (txt) {
          _searchKey = txt;
          reset();
          fetchData();
        },
        autofocus: false,
        decoration: InputDecoration(
          suffixIcon: IconButton(
            onPressed: () {
              _showSearchBar = false;
              setState(() {});
            },
            icon: Icon(Icons.clear, color: MyTheme.grey_153),
          ),
          filled: true,
          fillColor: MyTheme.white.withOpacity(0.6),
          hintText:
              "${AppLocalizations.of(context)!.search_products_from} : " "", //widget.category_name!
          hintStyle: TextStyle(fontSize: 14.0, color: MyTheme.font_grey),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: MyTheme.noColor, width: 0.0),
            borderRadius: BorderRadius.circular(6),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: MyTheme.noColor, width: 0.0),
            borderRadius: BorderRadius.circular(6),
          ),
          contentPadding: EdgeInsets.all(8.0),
        ),
      ),
    );
  }

  Widget buildSubCategory() {
    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _subCategoryList.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return CategoryProducts(slug: _subCategoryList[index].slug ?? '');
                      },
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _subCategoryList[index].name ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  buildProductList() {
    if (_isInitial && _productList.isEmpty) {
      return SingleChildScrollView(
        child: ShimmerHelper().buildProductGridShimmer(
          scontroller: _scrollController,
        ),
      );
    } else if (_productList.isNotEmpty) {
      return RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: Colors.white,
        displacement: 0,
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          controller: _xcrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.7, // Daha yüksek kartlar için
              ),
              itemCount: _productList.length,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return buildModernProductCard(_productList[index]);
              },
            ),
          ),
        ),
      );
    } else if (_totalData == 0) {
      return Center(
        child: Text(AppLocalizations.of(context)!.no_data_is_available),
      );
    } else {
      return Container();
    }
  }

  // Modern ürün kartı tasarımı
  Widget buildModernProductCard(dynamic product) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return ProductDetails(slug: product.slug ?? "");
                },
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                // Ürün resmi
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[100],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: product.thumbnail_image != null
                          ? Image.network(
                              product.thumbnail_image!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.image,
                                  color: Colors.grey[400],
                                  size: 40,
                                );
                              },
                            )
                          : Icon(
                              Icons.image,
                              color: Colors.grey[400],
                              size: 40,
                            ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                
                // Ürün ID
                Text(
                  "ID: ${product.id ?? ""}",
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 2),
                
                
                // Ürün adı
                Expanded(
                  flex: 2,
                  child: Text(
                    product.name ?? "",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 6),
                
                // Rating, Sales ve İndirim bilgileri
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Sol taraf - İndirim kartı
                    if (product.has_discount == true && product.discount != null && product.discount.toString().isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${product.discount} İndirim",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (product.has_discount != true || product.discount == null || product.discount.toString().isEmpty)
                      SizedBox.shrink(),
                    
                    // Sağ taraf - Rating ve Sales
                    Row(
                      children: [
                        // Rating
                        if (product.rating != null)
                          Row(
                            children: [
                              Icon(Icons.star, size: 16, color: Colors.amber),
                              SizedBox(width: 4),
                              Text(
                                "${product.rating}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        if (product.rating != null && product.sales != null)
                          SizedBox(width: 12),
                        // Sales
                        if (product.sales != null)
                          Row(
                            children: [
                              Icon(Icons.shopping_cart, size: 16, color: Colors.grey[600]),
                              SizedBox(width: 4),
                              Text(
                                "${product.sales}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 6),
                
                // Toptan satış etiketi
                if (product.isWholesale == true)
                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "Toptan",
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (product.isWholesale == true)
                  SizedBox(height: 6),
                
                // Fiyat
                Column(
                  children: [
                    // İndirimli fiyat (eğer varsa)
                    if (product.has_discount == true && product.stroked_price != null && product.stroked_price.toString().isNotEmpty)
                      Text(
                        "${product.stroked_price.toString().replaceAll(' TL', '').replaceAll(' TRY', '').replaceAll('TL', '').replaceAll('TRY', '').trim()} ₺",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          decoration: TextDecoration.lineThrough,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    if (product.has_discount == true && product.stroked_price != null && product.stroked_price.toString().isNotEmpty)
                      SizedBox(height: 4),
                    // Ana fiyat
                    Text(
                      "${(product.main_price ?? "0").toString().replaceAll(' TL', '').replaceAll(' TRY', '').replaceAll('TL', '').replaceAll('TRY', '').trim()} ₺",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0091E5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
