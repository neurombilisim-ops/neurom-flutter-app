import 'dart:async';
import 'dart:convert';
import 'package:badges/badges.dart' as badges;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app_config.dart';
import '../../custom/box_decorations.dart';
import '../../custom/btn.dart';
import '../../custom/device_info.dart';
import '../../custom/lang_text.dart';
import '../../custom/quantity_input.dart';
import '../../custom/toast_component.dart';
import '../../data_model/product_details_response.dart';
import '../../helpers/color_helper.dart';
import '../../helpers/main_helpers.dart';
import '../../helpers/shared_value_helper.dart';
import '../../helpers/shimmer_helper.dart';
import '../../helpers/system_config.dart';
import '../../my_theme.dart';
import '../../presenter/cart_counter.dart';
import '../../repositories/api-request.dart';
import '../../repositories/cart_repository.dart';
import '../../repositories/chat_repository.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/review_repositories.dart';
import '../../repositories/wishlist_repository.dart';
import '../../ui_elements/mini_product_card.dart';
import '../../ui_elements/top_selling_products_card.dart';
import '../brand_products.dart';
import '../chat/chat.dart';
import '../checkout/cart.dart';
import '../seller_details.dart';
import '../video_description_screen.dart';
import 'product_reviews.dart';
import 'widgets/product_slider_image_widget.dart';
import 'widgets/tappable_icon_widget.dart';

class ProductDetails extends StatefulWidget {
  String slug;

  ProductDetails({super.key, required this.slug});

  @override
  _ProductDetailsState createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails>
    with TickerProviderStateMixin {
  // State variables
  DetailedProduct? _productDetails;
  bool _isLoading = true;
  bool _isInWishList = false;
  int _currentImage = 0;
  int _quantity = 1;
  String? _selectedVariant;
  final List<String> _productImages = [];
  int _selectedTab = 0; // 0: Açıklama, 1: Yorumlar, 2: Soru Sor
  List<dynamic> _reviews = [];
  bool _isLoadingReviews = false;
  bool _reviewsLoadError = false;
  List<dynamic> _recentlyViewedProducts = [];
  bool _recentlyViewedInit = false;
  
  // Controllers
  final ScrollController _mainScrollController = ScrollController();
  final CarouselSliderController _carouselController = CarouselSliderController();
  final TextEditingController quantityText = TextEditingController();
  final TextEditingController sellerChatTitleController = TextEditingController();
  final TextEditingController sellerChatMessageController = TextEditingController();
  
  // Shimmer cache for performance
  Widget? _titleShimmer;
  Widget? _priceShimmer;
  Widget? _ratingShimmer;
  Widget? _imageShimmer;

  // Variant and color selection
  final List<dynamic> _colorList = [];
  final List<dynamic> _selectedChoices = [];
  int _selectedColorIndex = 0;
  String _choiceString = "";
  String? _variant = "";
  String? _totalPrice = "...";
  var _singlePrice;
  var _singlePriceString;
  int? _stock = 0;
  var _stock_txt;

  String _getCleanPrice(dynamic price) {
    if (price == null) return '';
    
    String priceStr = '';
    if (price is List) {
      if (price.isNotEmpty) {
        priceStr = price.first.toString();
      }
    } else {
      priceStr = price.toString();
    }
    
    if (priceStr.isEmpty) return '';
    
    
    // TRY, USD, EUR gibi para birimi kodlarını kaldır (daha güçlü regex)
    priceStr = priceStr.replaceAll(RegExp(r'(TRY|USD|EUR|GBP|TL)', caseSensitive: false), '').trim();
    
    
    // Para birimi simgesini sona ekle (yapışık)
    String result = '$priceStr${SystemConfig.systemCurrency?.symbol ?? '₺'}';
    return result;
  }

  void _setChoiceString() {
    _choiceString = "";
    for (int i = 0; i < _selectedChoices.length; i++) {
      if (i == 0) {
        _choiceString = _selectedChoices[i];
      } else {
        _choiceString = _choiceString + "-" + _selectedChoices[i];
      }
    }
  }

  void _fetchAndSetVariantWiseInfo() async {
    if (_productDetails == null) return;
    
    var colorString = _colorList.isNotEmpty
        ? _colorList[_selectedColorIndex].toString().replaceAll("#", "")
        : "";

    try {
      var variantResponse = await ProductRepository().getVariantWiseInfo(
        slug: widget.slug,
        color: colorString,
        variants: _choiceString,
        qty: _quantity,
      );
        
      if (variantResponse.variantData != null) {
        _stock = variantResponse.variantData!.stock;
        _stock_txt = variantResponse.variantData!.stockTxt;
        
        if (_quantity > (_stock ?? 0)) {
          _quantity = _stock ?? 0;
        }

        _variant = variantResponse.variantData!.variant;
        _totalPrice = variantResponse.variantData!.price;

        // Update image if variant has specific image
        int pindex = 0;
        _productDetails!.photos?.forEach((photo) {
          if (photo.variant == _variant && variantResponse.variantData!.image != "") {
            _currentImage = pindex;
            _carouselController.jumpToPage(pindex);
          }
          pindex++;
        });
        
        setState(() {});
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Related products
  final List<dynamic> _relatedProducts = [];
  bool _relatedProductInit = false;
  final List<dynamic> _topProducts = [];
  bool _topProductInit = false;

  // WebView için
  late WebViewController controller;
  double webViewHeight = 500.0; // Tam boyut açıklama kutusu

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(false)
      ..setBackgroundColor(const Color(0xFFFFFFFF));
    
    quantityText.text = "1";
    sellerChatTitleController.clear();
    sellerChatMessageController.clear();
    
    _initializeShimmerCache();
    _fetchProductDetails();
    _fetchRecentlyViewedProducts();
  }

  // Soru başlığını ürün adı ile otomatik doldur
  void _setProductNameAsTitle() {
    if (_productDetails?.name != null && _productDetails!.name!.isNotEmpty) {
      sellerChatTitleController.text = "${_productDetails!.name} hakkında soru";
    }
  }

  void _initializeShimmerCache() {
    _titleShimmer = ShimmerHelper().buildBasicShimmer(height: 24.0);
    _priceShimmer = ShimmerHelper().buildBasicShimmer(height: 28.0);
    _ratingShimmer = ShimmerHelper().buildBasicShimmer(height: 20.0);
    _imageShimmer = ShimmerHelper().buildBasicShimmer(height: 400.0);
  }

  Future<void> _fetchProductDetails() async {
    try {
      print("=== ÜRÜN DETAY SAYFASI DEBUG ===");
      print("Gelen Slug: ${widget.slug}");
      print("User ID: ${user_id.$}");
      print("Access Token: ${access_token.$}");
      print("===============================");
      
      // Tüm ürünler için aynı API'yi kullan - ID veya slug fark etmez
      ProductDetailsResponse response = await ProductRepository().getProductDetails(
        slug: widget.slug,
        userId: user_id.$,
      );
      
      print("=== API RESPONSE DEBUG ===");
      print("Response null check: ${response == null}");
      print("Response success: ${response?.success}");
      print("Response detailed_products null check: ${response?.detailed_products == null}");
      print("Response detailed_products length: ${response?.detailed_products?.length}");
      print("=========================");
      
      if (response != null && response.detailed_products != null && response.detailed_products!.isNotEmpty) {
        var product = response.detailed_products!.first;
      }

      if (response != null && response.success == true && response.detailed_products != null && response.detailed_products!.isNotEmpty) {
        setState(() {
          _productDetails = response!.detailed_products!.first;
          _isLoading = false;
        });
        
        // Debug: Verilerin gelip gelmediğini kontrol et
        print("=== ÜRÜN DETAY DEBUG ===");
        print("Ürün ID: ${_productDetails?.id}");
        print("Ürün Adı: ${_productDetails?.name}");
        print("Mağaza Adı: ${_productDetails?.shop_name}");
        print("Mağaza Logosu: ${_productDetails?.shop_logo}");
        print("Açıklama: ${_productDetails?.description?.substring(0, 100)}...");
        print("========================");
        
        // Soru başlığını ürün adı ile otomatik doldur
        _setProductNameAsTitle();
        
        try {
          _loadProductImages();
        } catch (e) {
          // Handle error silently
        }
        
        try {
          _checkWishlistStatus();
        } catch (e) {
          // Handle error silently
        }
        
        // Ürün detayları yüklendikten sonra yorumları yükle
        try {
          _loadReviews();
        } catch (e) {
          // Handle error silently
        }
        
        
        
        try {
          _setProductDetailValues();
          
          // Ürün görüntüleme kaydetme - API'de endpoint yok, sadece getirme var
          
      // WebView yüklenmesini geciktir - description varsa yükle, yoksa fallback göster
      String description = _productDetails!.description ?? 'Bu ürün için detaylı açıklama mevcut değil.';
      
      print("=== AÇIKLAMA DEBUG ===");
      print("Açıklama uzunluğu: ${description.length}");
      print("Açıklama içeriği: ${description.substring(0, description.length > 200 ? 200 : description.length)}...");
      print("=====================");
      
      if (description.isNotEmpty && description != 'Bu ürün için detaylı açıklama mevcut değil.') {
          // WebView'i lazy loading ile yükle
          Future.delayed(Duration(milliseconds: 1000), () {
          if (mounted) {
              try {
            controller.loadHtmlString(makeHtml(description));
              } catch (e) {
                print("WebView yükleme hatası: $e");
              }
          }
        });
      }
        } catch (e) {
          // Handle error silently
        }
      } else {
        setState(() => _isLoading = false);
        _showError('Ürün bulunamadı');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("=== ÜRÜN YÜKLEME HATASI ===");
      print("Hata türü: ${e.runtimeType}");
      print("Hata mesajı: $e");
      print("Stack trace: ${StackTrace.current}");
      print("==========================");
      _showError('Ürün yüklenirken hata oluştu: $e');
    }
  }

  void _setProductDetailValues() {
    if (_productDetails != null) {
      try {
      _singlePrice = _productDetails!.calculable_price;
      _singlePriceString = _productDetails!.main_price;
      _stock = _productDetails!.current_stock;

        // Load choice options - null check
        if (_productDetails!.choice_options != null) {
          for (var choice_option in _productDetails!.choice_options!) {
            if (choice_option.options != null && choice_option.options!.isNotEmpty) {
              _selectedChoices.add(choice_option.options![0]);
            }
          }
        }
        
        // Load colors - null check
        if (_productDetails!.colors != null) {
      for (var color in _productDetails!.colors!) {
        _colorList.add(color);
          }
        }
        
        try {
          _setChoiceString();
        } catch (e) {
          // Handle error silently
        }
        
        try {
          _fetchAndSetVariantWiseInfo();
        } catch (e) {
          // Handle error silently
        }
      } catch (e) {
        // Handle error silently
        // Continue without choice options and colors
      }
    }
  }

  void _loadProductImages() {
    try {
      if (_productDetails?.photos != null && _productDetails!.photos!.isNotEmpty) {
        _productImages.clear();
        for (var photo in _productDetails!.photos!) {
          if (photo.path != null && photo.path!.isNotEmpty) {
            _productImages.add(photo.path!);
          }
        }
      } else {
        // Photos null ise, thumbnail_image kullan
        if (_productDetails?.thumbnail_image != null && _productDetails!.thumbnail_image!.isNotEmpty) {
          _productImages.clear();
          _productImages.add(_productDetails!.thumbnail_image!);
        }
      }
    } catch (e) {
      // Handle error silently
      // Hata durumunda thumbnail_image kullan
      if (_productDetails?.thumbnail_image != null && _productDetails!.thumbnail_image!.isNotEmpty) {
        _productImages.clear();
        _productImages.add(_productDetails!.thumbnail_image!);
      }
    }
  }


  Future<void> _checkWishlistStatus() async {
    if (is_logged_in.$ == false) return;
    
    try {
      final response = await WishListRepository().isProductInUserWishList(
      product_slug: widget.slug,
    );
      setState(() {
        _isInWishList = response.is_in_wishlist ?? false;
      });
    } catch (e) {
      // Wishlist check failed, continue without error
    }
  }


  void _showError(String message) {
    ToastComponent.showDialog(message);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: MyTheme.mainColor,
        appBar: null,
        body: _isLoading ? _buildLoadingState() : _buildProductContent(),
        persistentFooterButtons: _productDetails != null ? [_buildBottomAppBar()] : null,
      ),
    );
  }


  Widget _buildLoadingState() {
    return SingleChildScrollView(
                  child: Column(
                    children: [
          _imageShimmer!,
          SizedBox(height: 16),
                      Padding(
            padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                _titleShimmer!,
                SizedBox(height: 8),
                _priceShimmer!,
                SizedBox(height: 8),
                _ratingShimmer!,
                SizedBox(height: 16),
                ShimmerHelper().buildBasicShimmer(height: 100),
              ],
                  ),
                ),
              ],
      ),
    );
  }

  Widget _buildProductContent() {
    if (_productDetails == null) {
      return Center(
                            child: Text(
          'Ürün bulunamadı',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
          onRefresh: _onPageRefresh,
      child: SingleChildScrollView(
            controller: _mainScrollController,
            child: Column(
              children: [
            _buildProductImageSection(),
            _buildProductInfo(),
            _buildEmptyProductInfo(),
            _buildVariantSection(),
            _buildDescriptionSection(),
            _buildRecentlyViewedProducts(),
                                  ],
                                ),
                              ),
    );
  }

  Widget _buildProductImageSection() {
    if (_productImages.isEmpty) {
      return Container(
        height: 400,
        child: _imageShimmer!,
      );
    }

    return GestureDetector(
      onTap: () => _openFullScreenImage(),
                  child: Container(
        height: 400,
        child: Stack(
                    children: [
                      // Carousel slider for swiping
                      CarouselSlider(
                          carouselController: _carouselController,
                        options: CarouselOptions(
                          height: 400,
                          viewportFraction: 1.0,
                          enableInfiniteScroll: _productImages.length > 1,
                          autoPlay: false,
                          onPageChanged: (index, reason) {
                            setState(() {
                              _currentImage = index;
                                });
                              },
                        ),
                        items: _productImages.isNotEmpty ? _productImages.map((imageUrl) {
                          return Container(
                            width: double.infinity,
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: Icon(Icons.image, size: 50, color: Colors.grey[400]),
                                      );
                                    },
                                  ),
                          );
                        }).toList() : [],
                      ),
                      // Top buttons - Geri, Favori, Paylaş
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                  child: Container(
                          padding: EdgeInsets.only(top: 40, left: 16, right: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Geri butonu - sola doğru az al
                              Container(
                                width: 40,
                                height: 40,
                                margin: EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                                  shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 3,
                                      spreadRadius: 0,
                                      offset: Offset(0, 1),
                        ),
                      ],
                    ),
                                child: IconButton(
                                  icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey, size: 20),
                                  onPressed: () => Navigator.pop(context),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                              // Favori ve Paylaş butonları - sağa doğru eşit hizala
                              Container(
                                margin: EdgeInsets.only(right: 8),
                          child: Column(
                                  mainAxisSize: MainAxisSize.min,
                            children: [
                                    // Wishlist/Favorite button - üstte
                                    Container(
                                      width: 40,
                                      height: 40,
                                      margin: EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 3,
                                            spreadRadius: 0,
                                            offset: Offset(0, 1),
                              ),
                            ],
                          ),
                                      child: IconButton(
                                        icon: Icon(
                                          _isInWishList ? Icons.favorite : Icons.favorite_border,
                                          color: _isInWishList ? Colors.red : MyTheme.dark_grey,
                                          size: 20,
                                        ),
                                        onPressed: _onWishTap,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                    // Share button - altta
                    Container(
                                      width: 40,
                                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 3,
                            spreadRadius: 0,
                                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                                      child: IconButton(
                                        icon: Icon(Icons.share_outlined, color: MyTheme.dark_grey, size: 20),
                                        onPressed: _onPressShare,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                            ),
                          ),
                        ],
                      ),
                    ),
                      ),
                      // Image counter - moved to bottom left
                      Positioned(
                        bottom: 16,
                        left: 16,
                            child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${_currentImage + 1}/${_productImages.length}',
                                      style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                        ),
                      ),
                      // Video button - bottom right
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: GestureDetector(
                          onTap: _onVideoTap,
                      child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                              border: Border.all(
                                color: MyTheme.accent_color,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                            children: [
                                Icon(
                                  Icons.play_circle_outline,
                                  color: MyTheme.accent_color,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                              Text(
                                  'Video',
                                style: TextStyle(
                                    color: MyTheme.accent_color,
                                    fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ),
                        ],
                      ),
                ),
    );
  }

  Widget _buildProductInfo() {
    return Container(
      margin: EdgeInsets.only(top: 16, bottom: 5),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Title with Brand Logo
          Row(
            children: [
              // Brand Logo
              if (_productDetails!.brand != null && 
                  _productDetails!.brand!.logo != null && 
                  _productDetails!.brand!.logo!.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    // Marka ürünlerine git
                    if (_productDetails!.brand != null && _productDetails!.brand!.slug != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BrandProducts(
                            slug: _productDetails!.brand!.slug!,
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 100,
                    height: 40,
                    margin: EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        _productDetails!.brand!.logo!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.business, size: 20, color: Colors.grey[400]),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              // Product Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _productDetails!.name ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    // Eski fiyat ve indirim yüzdesi
                    if (_productDetails!.has_discount == true) ...[
                      SizedBox(height: 4),
                      Row(
                        children: [
                          // Eski fiyat
                          Text(
                            _getCleanPrice(_productDetails!.stroked_price),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          SizedBox(width: 8),
                          // İndirim yüzdesi kartı
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${_productDetails!.discount ?? 0}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Rating and Review Container
              Container(
                margin: EdgeInsets.only(top: 1, bottom: 1, left: 1, right: 1),
                padding: EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Rating (Top) - White Background
                    Container(
                      width: 60,
                      margin: EdgeInsets.only(top: 1, left: 1, right: 1),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: (_productDetails!.rating != null && _productDetails!.rating! > 0) 
                                ? Colors.orange 
                                : Colors.grey[400],
                          ),
                          SizedBox(width: 4),
                          Text(
                            _productDetails!.rating?.toString() ?? '0',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Divider Line
                    Container(
                      height: 1,
                      color: Colors.grey[300],
                    ),
                    // Review Count (Bottom) - Grey Background
                    Container(
                      width: 60,
                      margin: EdgeInsets.only(bottom: 1, left: 1, right: 1),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _productDetails!.rating_count?.toString() ?? '0',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildEmptyProductInfo() {
    return Container(
      margin: EdgeInsets.only(top: 16, bottom: 5),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Satıcı/Mağaza Bilgisi
          Row(
            children: [
              // Mağaza logosu
              Container(
                width: 50,
                height: 50,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _productDetails?.shop_name?.contains("Ana Mağaza") == true
                      ? Image.asset(
                          'assets/app_logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print("Ana Mağaza logosu yüklenemedi: $error");
                            return Container(
                              color: Colors.grey[100],
                              child: Icon(
                                Icons.store,
                                color: Colors.grey[400],
                                size: 24,
                              ),
                            );
                          },
                        )
                      : _productDetails?.shop_logo != null && _productDetails!.shop_logo!.isNotEmpty
                          ? Image.network(
                              _productDetails!.shop_logo!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print("Mağaza logosu yüklenemedi: ${_productDetails!.shop_logo} - $error");
                                return Container(
                                  color: Colors.grey[100],
                                  child: Icon(
                                    Icons.store,
                                    color: Colors.grey[400],
                                    size: 24,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[100],
                              child: Icon(
                                Icons.store,
                                color: Colors.grey[400],
                                size: 24,
                              ),
                            ),
                ),
              ),
              SizedBox(width: 12),
              // Mağaza bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mağaza puanı kutusu
                    Builder(
                      builder: (context) {
                        double rating = double.tryParse(_productDetails?.rating?.toString() ?? '0') ?? 0.0;
                        Color boxColor;
                        Color textColor;
                        
                        if (rating >= 4.0) {
                          // Yüksek puan - Yeşil
                          boxColor = Colors.green[50]!;
                          textColor = Colors.green[800]!;
                        } else if (rating <= 2.0) {
                          // Düşük puan - Kırmızı
                          boxColor = Colors.red[50]!;
                          textColor = Colors.red[800]!;
                        } else {
                          // Orta puan - Turuncu
                          boxColor = Colors.orange[50]!;
                          textColor = Colors.orange[800]!;
                        }
                        
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: boxColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _productDetails?.rating?.toString() ?? '0',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 8),
                    Text(
                      _productDetails?.shop_name ?? 'Ana Mağaza',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              // Butonlar
              Row(
                children: [
                  // Satıcıya soru sor butonu
                  GestureDetector(
                    onTap: () {
                      // Ürün başlığını otomatik doldur
                      sellerChatTitleController.text = _productDetails?.name ?? 'Ürün hakkında soru';
                      
                      // Popup sayfa aç
                      _showSellerQuestionDialog();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[600],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Soru Sor',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                // Mağaza detaylarına git butonu (Ana mağaza için deaktif)
                GestureDetector(
                  onTap: _productDetails?.shop_name?.contains("Ana Mağaza") == true 
                      ? null // Ana mağaza için deaktif
                      : () {
                          if (_productDetails?.shop_slug != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SellerDetails(
                                  slug: _productDetails!.shop_slug!,
                                ),
                              ),
                            );
                          }
                        },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _productDetails?.shop_name?.contains("Ana Mağaza") == true 
                          ? Colors.grey[400] // Ana mağaza için gri
                          : MyTheme.accent_color, // Diğer mağazalar için normal renk
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Mağazayı Gör',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVariantSection() {
    if (_productDetails?.choice_options == null || _productDetails!.choice_options!.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                          color: Colors.white,
        borderRadius: BorderRadius.zero,
                          boxShadow: [
                            BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
                              spreadRadius: 0,
            offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Varyantlar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          SizedBox(height: 12),
          _buildChoiceOptions(),
          if (_colorList.isNotEmpty) ...[
            SizedBox(height: 16),
            _buildColorSelection(),
          ],
                    SizedBox(height: 16),
          _buildQuantitySelector(),
        ],
      ),
    );
  }

  Widget _buildChoiceOptions() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _productDetails!.choice_options!.length,
      itemBuilder: (context, index) {
        var choiceOption = _productDetails!.choice_options![index];
        return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                              Text(
              choiceOption.title ?? '',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: choiceOption.options!.map((option) {
                bool isSelected = _selectedChoices[index] == option;
                return GestureDetector(
                  onTap: () => _onVariantChange(index, option),
                    child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
                      color: isSelected ? MyTheme.accent_color : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
            border: Border.all(
                        color: isSelected ? MyTheme.accent_color : Colors.grey[300]!,
                      ),
                    ),
              child: Text(
                option,
                style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                ),
              ),
            ),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildColorSelection() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                Text(
          'Renk',
                  style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: _colorList.asMap().entries.map((entry) {
            int index = entry.key;
            String color = entry.value;
            bool isSelected = _selectedColorIndex == index;
            
            return GestureDetector(
              onTap: () => _onColorChange(index),
        child: Container(
                margin: EdgeInsets.only(right: 8),
                width: isSelected ? 32 : 28,
                height: isSelected ? 32 : 28,
        decoration: BoxDecoration(
                  color: ColorHelper.getColorFromColorCode(color),
                  shape: BoxShape.circle,
            border: Border.all(
                    color: isSelected ? MyTheme.accent_color : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: isSelected
                    ? Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      children: [
        Text(
          'Miktar:',
              style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
              ),
            ),
        SizedBox(width: 16),
        Container(
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.remove, size: 20),
                onPressed: _quantity > 1 ? _decreaseQuantity : null,
              ),
              Container(
                width: 50,
          child: Text(
                  '$_quantity',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add, size: 20),
                onPressed: _quantity < (_stock ?? 0) ? _increaseQuantity : null,
                ),
              ],
            ),
          ),
        Spacer(),
              Text(
          'Toplam: $_totalPrice',
                style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: MyTheme.accent_color,
              ),
            ),
          ],
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 2),
              ),
            ],
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tab Headers
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTab = 0; // Açıklama
                      });
                    },
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Açıklama',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.normal,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: _selectedTab == 0 ? Colors.blue[700] : Colors.transparent,
                            boxShadow: _selectedTab == 0 ? [
                              BoxShadow(
                                color: Colors.blue[700]!.withOpacity(0.3),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ] : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTab = 1; // Yorumlar
                      });
                      // Yorumlar zaten ürün yüklendiğinde yükleniyor, tekrar yüklemeye gerek yok
                    },
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Ürün Yorumları',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.normal,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: _selectedTab == 1 ? Colors.blue[700] : Colors.transparent,
                            boxShadow: _selectedTab == 1 ? [
                              BoxShadow(
                                color: Colors.blue[700]!.withOpacity(0.3),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ] : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Tab Content
            if (_selectedTab == 0)
              buildExpandableDescription()
            else if (_selectedTab == 1)
              _buildReviewsContent(),
            
            // Soru Sor bölümü her zaman görünür
            SizedBox(height: 24),
            _buildSellerQuestionContent(),
        ],
      ),
    );
  }

  Widget _buildReviewsContent() {
    
    if (_isLoadingReviews) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_reviewsLoadError) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        margin: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Column(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange[600],
              size: 48,
            ),
            SizedBox(height: 12),
            Text(
              'Yorumlar Yüklenemedi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Yorumlar şu anda yüklenemiyor. Lütfen daha sonra tekrar deneyin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange[700],
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadReviews,
              icon: Icon(Icons.refresh, size: 18),
              label: Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ürünü Değerlendir butonu
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 16),
          child: ElevatedButton.icon(
            onPressed: _onPressReviewProduct,
            icon: Icon(Icons.star, size: 20),
            label: Text(
              'Ürünü Değerlendir',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: MyTheme.accent_color,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        

        // Yorumlar listesi
        if (_reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.comment_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 12),
                Text(
                  'Henüz yorum yapılmamış',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'İlk yorumu siz yapın!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _reviews.map((review) {
                  return Container(
                    width: 280,
                    margin: EdgeInsets.only(right: 12),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Üst satır: Kullanıcı bilgileri ve tarih
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: review.avatar != null && review.avatar!.isNotEmpty
                                  ? NetworkImage(review.avatar!)
                                  : null,
                              child: review.avatar == null || review.avatar!.isEmpty
                                  ? Text(
                                      (review.user_name ?? 'U').substring(0, 1).toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    )
                                  : null,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    review.user_name ?? 'Anonim',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (review.rating != null)
                                    RatingBarIndicator(
                                      rating: review.rating!,
                                      itemBuilder: (context, index) => Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                      ),
                                      itemCount: 5,
                                      itemSize: 12.0,
                                    ),
                                ],
                              ),
                            ),
                            // Tarih/saat bilgisi sağ üstte
                            if (review.time != null && review.time!.isNotEmpty)
                              Text(
                                review.time!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 12),
                        // Yorum metni - her zaman göster, boşsa placeholder
                        Expanded(
                          child: Text(
                            review.comment?.isNotEmpty == true 
                                ? review.comment!
                                : 'Yorum yapılmamış',
                            style: TextStyle(
                              fontSize: 14,
                              color: review.comment?.isNotEmpty == true 
                                  ? Colors.black87 
                                  : Colors.grey[500],
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSellerQuestionContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // Tüm konteynerlar silindi
        ],
      ),
    );
  }

  void _showSellerQuestionDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Başlık
                Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.blue[600],
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Satıcıya Soru Sor',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.close,
                        color: Colors.grey[600],
                        size: 24,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                
                // Konu alanı
                Text(
                  'Konu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: sellerChatTitleController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    hintText: 'Sorunuzun konusunu yazın',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                SizedBox(height: 16),
                
                // Mesaj alanı
                Text(
                  'Mesajınız',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: sellerChatMessageController,
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: 'Satıcıya sormak istediğiniz soruyu yazın',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                SizedBox(height: 24),
                
                // Butonlar
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // Mesaj gönderme işlemi
                          if (sellerChatTitleController.text.isNotEmpty && 
                              sellerChatMessageController.text.isNotEmpty) {
                            
                            // Loading göster
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return Center(
                                  child: Container(
                                    padding: EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                            );
                            
                            try {
                              // Chat repository'yi import et
                              final chatRepo = ChatRepository();
                              final response = await chatRepo.getCreateConversationResponse(
                                product_id: _productDetails?.id ?? 0,
                                title: sellerChatTitleController.text,
                                message: sellerChatMessageController.text,
                              );
                              
                              // Loading'i kapat
                              Navigator.of(context).pop();
                              
                              if (response.result == true) {
                                // Formu temizle ve dialog'u kapat
                                sellerChatTitleController.clear();
                                sellerChatMessageController.clear();
                                Navigator.of(context).pop();
                                
                                // Basit başarı mesajı
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Mesaj gönderildi'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                // Hata mesajı
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Hata oluştu'),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              // Loading'i kapat
                              Navigator.of(context).pop();
                              
                              // Hata mesajı
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Hata oluştu'),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Tüm alanları doldurun'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Gönder',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Formu temizle
                          sellerChatTitleController.clear();
                          sellerChatMessageController.clear();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Temizle',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
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
      },
    );
  }

  Future<void> _loadReviews() async {
    if (_productDetails?.id == null) return;
    
    setState(() {
      _isLoadingReviews = true;
      _reviewsLoadError = false;
    });

    try {
      final reviewRepo = ReviewRepository();
      final response = await reviewRepo.getReviewResponse(_productDetails!.id);
      
      setState(() {
        _reviews = response.reviews ?? [];
        _isLoadingReviews = false;
        _reviewsLoadError = !response.success;
      });
    } catch (e) {
      setState(() {
        _isLoadingReviews = false;
        _reviewsLoadError = true;
      });
      print('Yorum yükleme hatası: $e');
    }
  }


  Widget _buildRecentlyViewedProducts() {
    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _recentlyViewedProducts.isNotEmpty ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Son Bakılan Ürünler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Container(
            height: 200,
            child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recentlyViewedProducts.length,
                  itemBuilder: (context, index) {
                    var product = _recentlyViewedProducts[index];
                    return GestureDetector(
                      onTap: () {
                        // Ürün detay sayfasına git
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetails(
                              slug: product.slug ?? '',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 150,
                        margin: EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
            boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            spreadRadius: 0,
                            offset: Offset(0, 2),
              ),
            ],
          ),
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Resim container'ı - Stack ile butonlar üstte
                          Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                            ),
                            child: Stack(
                              children: [
                                // Ürün resmi
                                product.thumbnail_image != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                                        child: FadeInImage.assetNetwork(
                                          placeholder: 'assets/placeholder.png',
                                          image: product.thumbnail_image,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: 100,
                                        ),
                                      )
                                    : Center(
                                        child: Icon(Icons.image, color: Colors.grey[400], size: 40),
                                      ),
                                // Favori Butonu - Ana sayfa referansı
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.8),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: Icon(
                                        Icons.favorite_border,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        _toggleWishlistForProduct(product);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
                                product.name ?? 'Ürün Adı',
              style: TextStyle(
                fontSize: 12,
                                fontWeight: FontWeight.w500,
              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
            ),
                            SizedBox(height: 4),
        Text(
                              product.main_price ?? '₺0,00',
          style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
            color: MyTheme.accent_color,
          ),
        ),
      ],
                          ),
                        ),
                      ],
                        ),
                      ),
                    );
            },
          ),
            ),
          ],
        ) : SizedBox.shrink(),
      ],
      ),
    );
  }

  Widget _buildEmptyRecentlyViewed() {
    return Container(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, color: Colors.grey[400], size: 48),
          SizedBox(height: 8),
          Text(
            'Henüz bakılan ürün yok',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAppBar() {
    if (_productDetails == null) return SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
          // Fiyat bilgisi
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: _getCleanPrice(_productDetails!.main_price).replaceAll('₺', ''),
                  style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: MyTheme.accent_color,
                        ),
                      ),
                      TextSpan(
                        text: '₺',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: MyTheme.accent_color,
                        ),
                      ),
                    ],
                  ),
                  ),
                ],
              ),
          ),
          SizedBox(width: 12),
          // Sepete Ekle butonu
          Expanded(
            child: ElevatedButton(
              onPressed: _onPressAddToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: MyTheme.accent_color,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
                child: Text(
                  'Sepete Ekle',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  // Event handlers
  void _onVariantChange(int choiceOptionsIndex, String option) {
    _selectedChoices[choiceOptionsIndex] = option;
    _setChoiceString();
    _fetchAndSetVariantWiseInfo();
  }

  void _onColorChange(int index) {
    _selectedColorIndex = index;
              setState(() {});
    _fetchAndSetVariantWiseInfo();
  }

  void _increaseQuantity() {
    if (_quantity < (_stock ?? 0)) {
      setState(() {
        _quantity++;
      });
      _fetchAndSetVariantWiseInfo();
    }
  }

  void _decreaseQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
      _fetchAndSetVariantWiseInfo();
    }
  }

  Future<void> _onPressAddToCart() async {
    if (is_logged_in.$ == false) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.you_need_to_log_in,
      );
      return;
    }

    try {
      // Sepete ekleme işlemi
      var addToCartResponse = await CartRepository().getCartAddResponse(
        _productDetails!.id,
        _choiceString,
        user_id.$,
        _quantity,
      );

      if (addToCartResponse.result == true) {
        // Sepet sayısını güncelle
        Provider.of<CartCounter>(context, listen: false).getCount();
        
        // Modern başarı bildirimi göster
        _showModernSuccessDialog(context);
      } else {
        ToastComponent.showDialog('Ürün sepete eklenemedi: ${addToCartResponse.message}');
      }
    } catch (e) {
      // Handle error silently
      ToastComponent.showDialog('Ürün sepete eklenirken hata oluştu');
    }
  }

  void _onPressReviewProduct() {
    if (is_logged_in.$ == false) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.you_need_to_log_in,
      );
      return;
    }

    // Ürün değerlendirme sayfasına yönlendir
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductReviews(
          productId: _productDetails!.id,
          productName: _productDetails!.name,
        ),
      ),
    );
  }

  Future<void> _onPressSendQuestion() async {
    if (is_logged_in.$ == false) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.you_need_to_log_in,
      );
      return;
    }

    // Form validasyonu
    if (sellerChatTitleController.text.trim().isEmpty) {
      ToastComponent.showDialog('Lütfen soru başlığı girin');
      return;
    }

    if (sellerChatMessageController.text.trim().isEmpty) {
      ToastComponent.showDialog('Lütfen sorunuzu yazın');
      return;
    }

    try {
      // Chat konuşması oluştur
      var conversationResponse = await ChatRepository().getCreateConversationResponse(
        product_id: _productDetails!.id,
        title: sellerChatTitleController.text.trim(),
        message: sellerChatMessageController.text.trim(),
      );

      if (conversationResponse.result == true) {
        ToastComponent.showDialog('Sorunuz başarıyla gönderildi');
        
        // Formu temizle
        sellerChatTitleController.clear();
        sellerChatMessageController.clear();
        
        // Chat sayfasına yönlendir
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Chat(
              conversation_id: conversationResponse.conversation_id,
              messenger_name: _productDetails!.shop_name,
              messenger_title: _productDetails!.shop_name,
              messenger_image: null,
            ),
          ),
        );
      } else {
        ToastComponent.showDialog('Konuşma oluşturulamadı: ${conversationResponse.message}');
      }
    } catch (e) {
      // Handle error silently
      ToastComponent.showDialog('Soru gönderilirken hata oluştu');
    }
  }


  void _onPressShare() {
    Share.share(_productDetails?.link ?? '');
  }

  void _onVideoTap() {
    
    // Test için geçici video URL'si
    String testVideoUrl = "https://www.youtube.com/watch?v=dQw4w9WgXcQ";
    
    if (_productDetails?.video_link != null && _productDetails!.video_link!.isNotEmpty) {
      // Video URL'sini aç
      _launchURL(_productDetails!.video_link!);
              } else {
      // Test için geçici video aç
      ToastComponent.showDialog("Test video açılıyor");
      _launchURL(testVideoUrl);
    }
  }

  Future<void> _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ToastComponent.showDialog("Video açılamadı");
      }
    } catch (e) {
      ToastComponent.showDialog("Video açılırken hata oluştu");
    }
  }

  void _openFullScreenImage() {
        Navigator.push(
          context,
          MaterialPageRoute(
        builder: (context) => _FullScreenImageViewer(
          images: _productImages,
          initialIndex: _currentImage,
          onImageChanged: (index) {
            setState(() {
              _currentImage = index;
            });
          },
        ),
      ),
    );
  }

  void _onWishTap() {
    if (is_logged_in.$ == false) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.you_need_to_log_in,
      );
      return;
    }

    if (_isInWishList) {
      _removeFromWishList();
              } else {
      _addToWishList();
    }
  }

  Future<void> _addToWishList() async {
    try {
      final response = await WishListRepository().add(
        product_slug: widget.slug,
      );
      setState(() {
        _isInWishList = response.is_in_wishlist ?? false;
      });
      if (_isInWishList) {
        ToastComponent.showDialog('Ürün favorilere eklendi');
      }
    } catch (e) {
      ToastComponent.showDialog('Hata oluştu');
    }
  }

  Future<void> _removeFromWishList() async {
    try {
      final response = await WishListRepository().remove(
        product_slug: widget.slug,
      );
      setState(() {
        _isInWishList = response.is_in_wishlist ?? false;
      });
      if (!_isInWishList) {
        ToastComponent.showDialog('Ürün favorilerden kaldırıldı');
      }
    } catch (e) {
      ToastComponent.showDialog('Hata oluştu');
    }
  }

  Future<void> _onPageRefresh() async {
    setState(() {
      _isLoading = true;
      _productDetails = null;
      _productImages.clear();
      _colorList.clear();
      _selectedChoices.clear();
      _quantity = 1;
    });
    await _fetchProductDetails();
    await _fetchRecentlyViewedProducts();
  }

  // HTML açıklamayı parse et - resimler için özel işlem
  String _parseHtmlDescription(String? htmlString) {
    if (htmlString == null || htmlString.isEmpty) return '';
    
    try {
      // Resim etiketlerini özel işle
      String processedHtml = htmlString
          .replaceAll(RegExp(r'<img[^>]*src="([^"]*)"[^>]*>', caseSensitive: false), '[RESİM: \$1]')
          .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'<p\s*[^>]*>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'<div\s*[^>]*>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n');
      
      var document = html_parser.parse(processedHtml);
      String result = document.body?.text ?? processedHtml;
      
      // Fazla boşlukları temizle
      result = result
          .replaceAll(RegExp(r'\n\s*\n'), '\n\n')
          .replaceAll(RegExp(r'^\s+|\s+$'), '')
          .trim();
      
      return result;
    } catch (e) {
      // HTML parse hatası durumunda basit regex ile temizle
      return htmlString
          .replaceAll(RegExp(r'<img[^>]*>', caseSensitive: false), '[RESİM]')
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll(RegExp(r'&nbsp;'), ' ')
          .replaceAll(RegExp(r'&amp;'), '&')
          .replaceAll(RegExp(r'&lt;'), '<')
          .replaceAll(RegExp(r'&gt;'), '>')
          .replaceAll(RegExp(r'&quot;'), '"')
          .replaceAll(RegExp(r'&#39;'), "'")
          .trim();
    }
  }

  // Açıklama kısmını genişletilebilir yap
  Widget buildExpandableDescription() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: webViewHeight > 0 ? webViewHeight.clamp(100.0, 600.0) : 0,
            child: webViewHeight > 0 
              ? WebViewWidget(controller: controller)
              : SizedBox.shrink(),
          ),
          Btn.basic(
            onPressed: () async {
              if (webViewHeight == 200) {
                try {
                  double newHeight = double.parse(
                    (await controller.runJavaScriptReturningResult(
                      "document.getElementById('scaled-frame').clientHeight",
                    )).toString(),
                  );
                  // Maksimum yüksekliği sınırla (600px)
                  webViewHeight = newHeight.clamp(100.0, 600.0);
                } catch (e) {
                  // Handle error silently
                  webViewHeight = 400; // Varsayılan yükseklik
                }
              } else {
                webViewHeight = 200;
              }
              setState(() {});
            },
            child: Text(
              webViewHeight == 200
                  ? "Daha fazla göster"
                  : "Daha az göster",
              style: TextStyle(color: Color(0xff0077B6)),
            ),
          ),
        ],
      ),
    );
  }

  // HTML string oluştur
  String makeHtml(String string) {
    return """
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="stylesheet" href="${AppConfig.RAW_BASE_URL}/public/assets/css/vendors.css">
<style>
*{
  margin:0 !important;
  padding:0 !important;
}
#scaled-frame {
}
</style>
</head>
<body id="main_id">
  <div id="scaled-frame">
$string
  </div>
</body>
</html>
""";
  }

  // Son bakılan ürünler için favori toggle
  Future<void> _toggleWishlistForProduct(dynamic product) async {
    try {
      if (product.slug == null) return;
      
      // Favori durumunu kontrol et
      final response = await WishListRepository().isProductInUserWishList(
        product_slug: product.slug,
      );
      
      bool isInWishlist = response.is_in_wishlist ?? false;
      
      if (isInWishlist) {
        // Favorilerden çıkar
        final removeResponse = await WishListRepository().remove(
          product_slug: product.slug,
        );
        if (removeResponse.message != null && removeResponse.message!.contains('success')) {
          ToastComponent.showDialog('Ürün favorilerden çıkarıldı');
        }
      } else {
        // Favorilere ekle
        final addResponse = await WishListRepository().add(
          product_slug: product.slug,
        );
        if (addResponse.message != null && addResponse.message!.contains('success')) {
          ToastComponent.showDialog('Ürün favorilere eklendi');
        }
      }
    } catch (e) {
      // Handle error silently
      ToastComponent.showDialog('Favori işlemi başarısız');
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

  // Son bakılan ürünleri yükle
  Future<void> _fetchRecentlyViewedProducts() async {
    if (_recentlyViewedInit) return;
    
    // Sadece giriş yapmış kullanıcılar için son bakılan ürünleri yükle
    if (!is_logged_in.$ || access_token.$ == null || access_token.$!.isEmpty) {
      print("Kullanıcı giriş yapmamış, son bakılan ürünler yüklenmiyor");
      _recentlyViewedInit = true;
      return;
    }
    
    try {
      print("Son bakılan ürünler yükleniyor...");
      print("Mevcut user ID: ${user_id.$}");
      print("Access token: ${access_token.$}");
      
      // Son bakılan ürünleri API'den çek
      var recentlyViewedResponse = await ProductRepository().lastViewProduct();
      
      print("Son bakılan ürünler API response: ${recentlyViewedResponse != null ? 'success' : 'null'}");
      print("Son bakılan ürünler raw response: $recentlyViewedResponse");
      
      if (recentlyViewedResponse != null) {
        print("Son bakılan ürünler products field: ${recentlyViewedResponse.products}");
        print("Son bakılan ürünler products null check: ${recentlyViewedResponse.products != null}");
        
        if (recentlyViewedResponse.products != null) {
          print("Son bakılan ürün sayısı: ${recentlyViewedResponse.products!.length}");
          _recentlyViewedProducts.addAll(recentlyViewedResponse.products!);
          
          if (mounted) {
            setState(() {});
          }
        } else {
          print("Son bakılan ürünler products field null");
        }
      } else {
        print("Son bakılan ürünler response null");
      }
      _recentlyViewedInit = true;
    } catch (e) {
      print("Son bakılan ürünler yükleme hatası: $e");
      _recentlyViewedInit = true;
    }
  }


  @override
  void dispose() {
    _mainScrollController.dispose();
    quantityText.dispose();
    sellerChatTitleController.dispose();
    sellerChatMessageController.dispose();
    super.dispose();
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final Function(int) onImageChanged;

  const _FullScreenImageViewer({
    required this.images,
    required this.initialIndex,
    required this.onImageChanged,
  });

  @override
  _FullScreenImageViewerState createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Color(0xFFF8F9FA),
        elevation: 0,
          leading: Container(
            margin: EdgeInsets.only(left: 16, top: 16, bottom: 8),
    decoration: BoxDecoration(
      color: Colors.white,
            shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                spreadRadius: 0,
                offset: Offset(0, 2),
        ),
      ],
    ),
    child: IconButton(
            icon: Icon(Icons.close, color: Colors.black, size: 16),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.all(8),
          ),
        ),
        title: SizedBox.shrink(),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8, top: 16, bottom: 8),
    decoration: BoxDecoration(
      color: Colors.white,
              shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: Offset(0, 2),
        ),
      ],
    ),
    child: IconButton(
              icon: Icon(Icons.share, color: Colors.black, size: 16),
      onPressed: () {
                // Share functionality
              },
              padding: EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
      body: Container(
        color: Color(0xFFF8F9FA),
        child: Column(
          children: [
            // Main image viewer
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                  widget.onImageChanged(index);
                },
                itemCount: widget.images.length,
                itemBuilder: (context, index) {
                  return Container(
                    color: Color(0xFFF8F9FA),
                    child: Center(
                      child: Image.network(
                        widget.images[index],
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Color(0xFFF8F9FA),
                            child: Icon(Icons.image, color: Colors.grey[400], size: 50),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            // Thumbnail strip
            if (widget.images.length > 1)
              Container(
                height: 80,
                padding: EdgeInsets.only(top: 0, bottom: 16),
                color: Color(0xFFF8F9FA),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.images.length,
                  itemBuilder: (context, index) {
                    bool isSelected = index == _currentIndex;
                    return GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        margin: EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              spreadRadius: 0,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            widget.images[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: Icon(Icons.image, color: Colors.grey[500], size: 20),
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
        ),
      );
  }
}


