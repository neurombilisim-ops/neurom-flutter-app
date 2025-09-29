import 'package:flutter/material.dart';
import 'package:neurom_bilisim_store/repositories/product_repository.dart';
import 'package:neurom_bilisim_store/data_model/product_mini_response.dart';
import 'package:neurom_bilisim_store/helpers/shimmer_helper.dart';
import 'package:neurom_bilisim_store/screens/product/product_details.dart';
import 'package:neurom_bilisim_store/my_theme.dart';

class BrandProductsPage extends StatefulWidget {
  final int brandId;
  final String brandName;

  const BrandProductsPage({
    super.key,
    required this.brandId,
    required this.brandName,
  });

  @override
  State<BrandProductsPage> createState() => _BrandProductsPageState();
}

class _BrandProductsPageState extends State<BrandProductsPage> {
  List<Product> _products = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _page = 1;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (_hasMoreData && !_isLoading) {
        _loadMoreProducts();
      }
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await ProductRepository().getFilteredProducts(
        page: _page,
        brands: widget.brandId.toString(),
      );

      if (response.success == true && response.products != null) {
        setState(() {
          _products = response.products!;
          _hasMoreData = response.products!.length >= 20; // Sayfa başına 20 ürün varsayımı
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Ürünler yüklenemedi';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Bir hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoading || !_hasMoreData) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ProductRepository().getFilteredProducts(
        page: _page + 1,
        brands: widget.brandId.toString(),
      );

      if (response.success == true && response.products != null) {
        setState(() {
          _products.addAll(response.products!);
          _page++;
          _hasMoreData = response.products!.length >= 20;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasMoreData = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasMoreData = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.brandName,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.white,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _products.isEmpty) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_products.isEmpty) {
      return _buildEmptyState();
    }

    return _buildProductsList();
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
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
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Ürünler yüklenemedi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            _errorMessage,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _page = 1;
              _loadProducts();
            },
            child: Text('Tekrar Dene'),
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
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Bu markaya ait ürün bulunamadı',
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

  Widget _buildProductsList() {
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemCount: _products.length + (_isLoading ? 2 : 0),
            itemBuilder: (context, index) {
              if (index >= _products.length) {
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

              final product = _products[index];
              return _buildProductCard(product);
            },
          ),
        ),
        if (_isLoading && _products.isNotEmpty)
          Container(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
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
                  child: product.thumbnail_image != null
                      ? Image.network(
                          product.thumbnail_image!,
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
                      '₺${product.main_price ?? '0'}',
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
