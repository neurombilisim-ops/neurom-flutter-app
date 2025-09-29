
import 'dart:async';
import 'package:neurom_bilisim_store/app_config.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/helpers/shimmer_helper.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/presenter/home_presenter.dart';
import 'package:neurom_bilisim_store/repositories/product_repository.dart';
import 'package:neurom_bilisim_store/repositories/category_repository.dart';
import 'package:neurom_bilisim_store/repositories/brand_repository.dart';
import 'package:neurom_bilisim_store/repositories/flash_deal_repository.dart';
import 'package:neurom_bilisim_store/data_model/product_mini_response.dart';
import 'package:neurom_bilisim_store/data_model/category_response.dart';
import 'package:neurom_bilisim_store/data_model/all_brands_response.dart';
import 'package:neurom_bilisim_store/screens/filter.dart';
import 'package:neurom_bilisim_store/screens/all_products.dart';
import 'package:neurom_bilisim_store/screens/brand_products_page.dart';
import 'package:neurom_bilisim_store/screens/featured_products.dart';
import 'package:neurom_bilisim_store/screens/featured_products_new.dart';
import 'package:neurom_bilisim_store/screens/product/product_details.dart';
import 'package:neurom_bilisim_store/screens/top_sellers.dart';
import 'package:neurom_bilisim_store/screens/profile.dart';
import 'package:neurom_bilisim_store/repositories/wishlist_repository.dart';
import 'package:neurom_bilisim_store/custom/toast_component.dart';
import 'package:neurom_bilisim_store/screens/category_list_n_product/category_list.dart';
import 'package:neurom_bilisim_store/screens/category_list_n_product/category_products.dart';
import 'package:neurom_bilisim_store/single_banner/sincle_banner_page.dart';
import 'package:neurom_bilisim_store/screens/main.dart';
import 'package:flutter/material.dart';
import '../custom/featured_product_horizontal_list_widget.dart';
import '../custom/home_all_products_2.dart';
import '../custom/home_banner_one.dart';
import '../custom/home_carousel_slider.dart';
import '../custom/pirated_widget.dart';
import 'notifications.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

class Home extends StatefulWidget {
  const Home({
    super.key,
    this.title,
    this.show_back_button = false,
    this.go_back = true,
  });

  final String? title;
  final bool show_back_button;
  final bool go_back;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  final HomePresenter homeData = HomePresenter();
  Future<CategoryResponse>? _featuredCategoriesFuture;

  @override
  void initState() {
    super.initState();
    _featuredCategoriesFuture = CategoryRepository().getFeturedCategories(limit: 10);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
      precacheImage(const AssetImage("assets/brands.png"), context);
      precacheImage(const AssetImage("assets/top_sellers.png"), context);
      // API'den okunmamış bildirim sayısını yükle
      print('🏠 Ana sayfa: Bildirim sayısı yükleniyor...');
      Provider.of<NotificationProvider>(context, listen: false).loadUnreadCountFromAPI();
      
      // Test için: 3 saniye sonra test bildirimi ekle
      Future.delayed(Duration(seconds: 3), () {
        Provider.of<NotificationProvider>(context, listen: false).addTestNotification();
      });
    });
    homeData.mainScrollListener();
    homeData.initPiratedAnimation(this);
  }

  Future<void> _fetchData() async {
    await homeData.onRefresh();
  }


  @override
  void dispose() {
    homeData.pirated_logo_controller.dispose();
    homeData.mainScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => widget.go_back,
      child: Directionality(
        textDirection: app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          child: Scaffold(
            appBar: const _HomeAppBar(),
            backgroundColor: Colors.white,
            body: Stack(
              children: [
                RefreshIndicator(
                  color: MyTheme.accent_color,
                  backgroundColor: Colors.white,
                  onRefresh: _fetchData,
                  displacement: 0,
                  child: CustomScrollView(
                    controller: homeData.mainScrollController,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: <Widget>[
                      _buildHeaderSection(context, homeData),

                      // PERFORMANS: Tüm ListenableBuilder'ları tek bir yerde birleştir
                      ListenableBuilder(
                        listenable: homeData,
                        builder: (context, child) {
                          return SliverList(
                            delegate: SliverChildListDelegate([
                              _buildFeaturedCategoriesSection(context, homeData),
                              const SizedBox(height: 15),
                              PhotoWidget(),
                              _buildTodaysDealSection(),
                              const SizedBox(height: 10),
                              _buildFeaturedProductsSection(context, homeData),
                              const SizedBox(height: 10),
                              _buildBrandsSection(),
                              const SizedBox(height: 10),
                              _buildAllProductsSection(context, homeData),
                            ]),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ListenableBuilder(
                    listenable: homeData,
                    builder: (context, child) => _buildProductLoadingContainer(context, homeData),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SliverList _buildHeaderSection(BuildContext context, HomePresenter homeData) {
    return SliverList(
      delegate: SliverChildListDelegate([
        const SizedBox(height: 15),
        const SizedBox(height: 15),
        // API'den gelen banner slaytı
        ListenableBuilder(
          listenable: homeData,
          builder: (context, child) => HomeCarouselSlider(homeData: homeData, context: context),
        ),
        const SizedBox(height: 15),
        // İkincil Intel Core i7 Banner
        _buildSecondaryBanner(),
        const SizedBox(height: 15),
        // Popüler Kategoriler
        _buildPopularCategories(),
        const SizedBox(height: 15),
        // İndirimli ürünler/fırsat ürünleri bölümü
        const SizedBox(height: 50),
        _buildDealsSection(),
        const SizedBox(height: 15),
        ListenableBuilder(
          listenable: homeData,
          builder: (context, child) => HomeBannerOne(context: context, homeData: homeData),
        ),
      ]),
    );
  }


  Widget _buildSecondaryBanner() {
    return ListenableBuilder(
      listenable: homeData,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            // Öne çıkan ürünler sayfasına yönlendir
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FeaturedProducts(),
              ),
            );
          },
          child: Container(
            height: 50,
            margin: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xff0091e5),
                  Color(0xff0078d4),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Color(0xff0091e5).withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(width: 16),
                // İlk ürünün resmi veya varsayılan icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: homeData.featuredProductList.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            homeData.featuredProductList.first.thumbnail_image ?? '',
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.white.withOpacity(0.3),
                                child: Icon(
                                  Icons.computer,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              );
                            },
                          ),
                        )
                      : Container(
                          color: Colors.white.withOpacity(0.3),
                          child: Icon(
                            Icons.computer,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Haftanın Güvenlik Önerileri",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodaysDealSection() {
    return ListenableBuilder(
      listenable: homeData,
      builder: (context, child) {
        if (!homeData.isTodayDeal) {
          return SizedBox.shrink(); // Eğer günün fırsatı yoksa hiçbir şey gösterme
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.orange[50]!,
                Colors.red[50]!,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'GÜNÜN FIRSATI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    Icon(
                      Icons.timer,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                  ],
                ),
              ),
              FutureBuilder<ProductMiniResponse>(
                future: ProductRepository().getTodaysDealProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Container(
                      height: 200,
                      child: Center(
                        child: Text('Hata: ${snapshot.error}'),
                      ),
                    );
                  } else if (snapshot.hasData && snapshot.data!.products!.isNotEmpty) {
                    return Container(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: snapshot.data!.products!.length,
                        itemBuilder: (context, index) {
                          final product = snapshot.data!.products![index];
                          final hasDiscount = product.has_discount == true && 
                                             product.stroked_price != null && 
                                             product.stroked_price!.isNotEmpty;
                          
                          return Container(
                            width: 160,
                            margin: EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () {
                                print("=== ANA SAYFA ÜRÜN KARTI TIKLAMA DEBUG ===");
                                print("Ürün Adı: ${product.name}");
                                print("Slug: ${product.slug}");
                                print("ID: ${product.id}");
                                print("==========================================");
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetails(
                                      slug: product.slug ?? '',
                                    ),
                                  ),
                                );
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.2),
                                          spreadRadius: 1,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Ürün resmi
                                        Container(
                                          height: 120,
                                          width: double.infinity,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(8),
                                              topRight: Radius.circular(8),
                                            ),
                                            child: Image.network(
                                              product.thumbnail_image ?? '',
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey[200],
                                                  child: Icon(
                                                    Icons.image_not_supported,
                                                    color: Colors.grey[600],
                                                    size: 40,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        // Ürün bilgileri
                                        Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  product.name ?? 'Ürün',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    if (hasDiscount) ...[
                                                      Row(
                                                        children: [
                                                          Text(
                                                            (product.stroked_price ?? '').replaceAll('TRY', ''),
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              decoration: TextDecoration.lineThrough,
                                                              color: Colors.grey[600],
                                                            ),
                                                          ),
                                                          SizedBox(width: 2),
                                                          Icon(
                                                            Icons.currency_lira,
                                                            color: Colors.grey[600],
                                                            size: 10,
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(height: 2),
                                                    ],
                                                    Row(
                                                      children: [
                                                        Text(
                                                          (product.main_price ?? '0').replaceAll('TRY', ''),
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.orange[700],
                                                          ),
                                                        ),
                                                        SizedBox(width: 2),
                                                        Icon(
                                                          Icons.currency_lira,
                                                          color: Colors.orange[700],
                                                          size: 12,
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // İndirim kartı
                                  if (hasDiscount)
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'İNDİRİM',
                                          style: TextStyle(
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
                    );
                  } else {
                    return Container(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              color: Colors.grey[400],
                              size: 48,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Günün fırsatı bulunamadı',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPopularCategories() {
    return ListenableBuilder(
      listenable: homeData,
      builder: (context, child) {
        if (homeData.isCategoryInitial) {
          // Loading state - show shimmer
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ShimmerHelper().buildBasicShimmer(
                  height: 20,
                  width: 150,
                ),
              ),
              SizedBox(height: 15),
              Container(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 6, // Show 6 shimmer items
                  itemBuilder: (context, index) {
                    return Container(
                      width: 120,
                      height: 120,
                      margin: EdgeInsets.only(right: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ShimmerHelper().buildBasicShimmer(
                            height: 100,
                            width: 100,
                          ),
                          SizedBox(height: 6),
                          ShimmerHelper().buildBasicShimmer(
                            height: 8,
                            width: 40,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }

        if (homeData.featuredCategoryList.isEmpty) {
          // No categories available
          return SizedBox.shrink();
        }

        // Show API categories
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Popüler Kategoriler",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            SizedBox(height: 15),
            Container(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: homeData.featuredCategoryList.length,
                itemBuilder: (context, index) {
                  final category = homeData.featuredCategoryList[index];
                  final colors = [
                    Color(0xff3498db), // Blue
                    Color(0xff2ecc71), // Green
                    Color(0xffe74c3c), // Red
                    Color(0xfff39c12), // Orange
                    Color(0xff9b59b6), // Purple
                    Color(0xff1abc9c), // Teal
                    Color(0xffe67e22), // Carrot
                    Color(0xff34495e), // Dark Blue
                  ];
                  final color = colors[index % colors.length];
                  
                  return GestureDetector(
                    onTap: () {
                      // Navigate to category products
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryProducts(
                            slug: category.slug ?? "",
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      margin: EdgeInsets.only(right: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: color.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: (category.coverImage != null || category.banner != null)
                                  ? Image.network(
                                      category.coverImage ?? category.banner!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.category,
                                          color: color,
                                          size: 20,
                                        );
                                      },
                                    )
                                  : Icon(
                                      Icons.category,
                                      color: color,
                                      size: 20,
                                    ),
                            ),
                          ),
                          SizedBox(height: 6),
                          Flexible(
                            child: Text(
                              category.name ?? "Kategori",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
        );
      },
    );
  }

  Widget _buildFeaturedCategoriesSection(BuildContext context, HomePresenter homeData) {
    return SizedBox.shrink();
  }



  Widget _buildCategoriesShimmer() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18.0, 20.0, 20.0, 0.0),
            child: ShimmerHelper().buildBasicShimmer(
              height: 20,
              width: 150,
            ),
          ),
          SizedBox(height: 16),
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 18),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Container(
                  width: 80,
                  margin: EdgeInsets.only(right: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShimmerHelper().buildBasicShimmer(
                        height: 60,
                        width: 60,
                      ),
                      SizedBox(height: 8),
                      ShimmerHelper().buildBasicShimmer(
                        height: 12,
                        width: 60,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
                          SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _buildFeaturedProductsSection(BuildContext context, HomePresenter homeData) {
    return Column(
      children: [
                          SizedBox(height: 15), // Üst afiş ile öne çıkan ürünler arasına mesafe ekle
        Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18.0, 0.0, 20.0, 0.0),
                child: GestureDetector(
                  onTap: () {
                    // Öne çıkan ürünler sayfasına yönlendir
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FeaturedProducts(),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.featured_products_ucf,
                        style: const TextStyle(
                          color: Color(0xff000000),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: MyTheme.dark_grey,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 15), // Başlık ile ürünler arasına mesafe ekle
              FeaturedProductHorizontalListWidget(homeData: homeData),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllProductsSection(BuildContext context, HomePresenter homeData) {
    return Column(
      children: [
                          SizedBox(height: 15), // Öne çıkan ürünler ile tüm ürünler arasına daha fazla mesafe
        Container(
          color: Colors.white, // Gri arka planı beyaz yap
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18.0, 0.0, 20.0, 0.0),
                child: GestureDetector(
                  onTap: () {
                    // Tüm ürünler sayfasına yönlendir
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllProducts(),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.all_products_ucf,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: MyTheme.dark_grey,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 15), // Başlık ile ürünler arasına mesafe ekle
             HomeAllProducts2( homeData: homeData),
            ],
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildProductLoadingContainer(BuildContext context, HomePresenter homeData) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: homeData.showAllLoadingContainer ? 36 : 0,
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: Text(
          homeData.totalAllProductData == homeData.allProductList.length
              ? AppLocalizations.of(context)!.no_more_products_ucf
              : AppLocalizations.of(context)!.loading_more_products_ucf,
        ),
      ),
    );
  }

  Future<void> _addToWishlist(BuildContext context, Product product) async {
    if (is_logged_in.$ == false) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.you_need_to_log_in,
      );
      return;
    }

    try {
      var wishListResponse = await WishListRepository().add(
        product_slug: product.slug ?? '',
      );

      if (wishListResponse.is_in_wishlist == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.favorite, color: Colors.white),
                SizedBox(width: 8),
                Text('Ürün favorilere eklendi'),
              ],
            ),
            backgroundColor: MyTheme.accent_color,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ToastComponent.showDialog(
        'Bir hata oluştu',
      );
    }
  }

  Widget _buildBrandsSection() {
    return Container(
      height: 100,
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Markalar",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 60,
            child: FutureBuilder<AllBrandsResponse>(
              future: BrandRepository().getAllBrands(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 100,
                          height: 70,
                          margin: EdgeInsets.only(right: 16),
                          child: ShimmerHelper().buildBasicShimmer(
                            height: 70,
                            width: 100,
                          ),
                        );
                      },
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    child: Center(
                      child: Text(
                        'Markalar yüklenemedi',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  );
                } else if (snapshot.hasData && snapshot.data!.data != null) {
                  final brands = snapshot.data!.data ?? [];
                  if (brands.isEmpty) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Center(
                        child: Text(
                          'Marka bulunamadı',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    itemCount: brands.length > 10 ? 10 : brands.length, // Maksimum 10 marka göster
                    itemBuilder: (context, index) {
                      final brand = brands[index];
                      // Null kontrolü ekle
                      if (brand == null) {
                        return SizedBox.shrink();
                      }
                      return GestureDetector(
                        onTap: () {
                          // Marka tıklandığında o markanın ürünlerini göster
                          if (brand.id != null && brand.id! > 0) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BrandProductsPage(
                                  brandId: brand.id!,
                                  brandName: brand.name ?? 'Marka',
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: 100,
                          height: 70,
                          margin: EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.05),
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: brand.icon != null && brand.icon!.isNotEmpty
                                ? Image.network(
                                    brand.icon!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[50],
                                        child: Icon(
                                          Icons.branding_watermark,
                                          color: Colors.grey[400],
                                          size: 16,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey[50],
                                    child: Icon(
                                      Icons.branding_watermark,
                                      color: Colors.grey[400],
                                      size: 16,
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    child: Center(
                      child: Text(
                        'Marka bulunamadı',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealsSection() {
    return Container(
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Fırsat Ürünleri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          FutureBuilder<dynamic>(
            future: _getFlashDeals(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  height: 120,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              } else if (snapshot.hasError) {
                return Container(
                  height: 120,
                  child: Center(
                    child: Text('Hata: ${snapshot.error}'),
                  ),
                );
              } else if (snapshot.hasData && snapshot.data.isNotEmpty) {
                return Container(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: snapshot.data.length,
                    itemBuilder: (context, index) {
                      final deal = snapshot.data[index];
                      return Container(
                        width: 160,
                        margin: EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FeaturedProductsNew(slug: deal['slug']),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: 120,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 3,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: deal['banner'] != null && deal['banner'].isNotEmpty
                                      ? Image.network(
                                          deal['banner'],
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[300],
                                              child: Icon(
                                                Icons.local_offer,
                                                color: Colors.grey[600],
                                                size: 40,
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          color: Colors.grey[300],
                                          child: Icon(
                                            Icons.local_offer,
                                            color: Colors.grey[600],
                                            size: 40,
                                          ),
                                        ),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                deal['title'] ?? 'Fırsat Ürünü',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'KAMPANYA',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              } else {
                return Container(
                  height: 120,
                  child: Center(
                    child: Text('Fırsat ürünü bulunamadı'),
                  ),
                );
              }
            },
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<List<dynamic>> _getFlashDeals() async {
    try {
      // Flash deal'leri çek
      var flashDealsResponse = await FlashDealRepository().getFlashDeals();
      
      
      if (flashDealsResponse.flashDeals != null && flashDealsResponse.flashDeals!.isNotEmpty) {
        List<dynamic> deals = [];
        
        for (var flashDeal in flashDealsResponse.flashDeals!) {
          deals.add({
            'id': flashDeal.id,
            'title': flashDeal.title,
            'slug': flashDeal.slug,
            'banner': flashDeal.banner,
            'discount': '', // Flash deal'lerde discount field'ı yok, boş değer
          });
        }
        
        return deals;
      } else {
        // Eğer flash deal yoksa, boş liste döndür
        return [];
      }
    } catch (e) {
      return [];
    }
  }

}

class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _HomeAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      scrolledUnderElevation: 0.0,
      centerTitle: true,
      elevation: 0,
      toolbarHeight: 50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sol tarafta boş alan (profil ikonu ile simetri için)
          Container(
            width: 40,
            height: 40,
          ),
          // Ortada logo
          Expanded(
            child: Center(
              child: Image.asset(
                "assets/logo.png",
                height: 22,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Sağ tarafta bildirim butonu
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return GestureDetector(
                onTap: () => _openNotifications(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.notifications_outlined,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      // Bildirim sayısı badge'i
                      if (notificationProvider.unreadCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                notificationProvider.unreadCount > 99 
                                    ? '99+' 
                                    : notificationProvider.unreadCount.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
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
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(50);
}

// Bildirim sayfasını açan fonksiyon
void _openNotifications(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => NotificationsPage(),
    ),
  );
}


