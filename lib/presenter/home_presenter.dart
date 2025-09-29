import 'dart:async';

import 'package:neurom_bilisim_store/custom/toast_component.dart';
import 'package:neurom_bilisim_store/data_model/flash_deal_response.dart';
import 'package:neurom_bilisim_store/data_model/slider_response.dart';
import 'package:neurom_bilisim_store/repositories/category_repository.dart';
import 'package:neurom_bilisim_store/repositories/flash_deal_repository.dart';
import 'package:neurom_bilisim_store/repositories/product_repository.dart';
import 'package:neurom_bilisim_store/repositories/sliders_repository.dart';
import 'package:neurom_bilisim_store/single_banner/model.dart';
import 'package:flutter/material.dart';

class HomePresenter extends ChangeNotifier {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  int current_slider = 0;
  ScrollController? allProductScrollController;
  ScrollController? featuredCategoryScrollController;
  ScrollController mainScrollController = ScrollController();

  late AnimationController pirated_logo_controller;
  late Animation pirated_logo_animation;

  List<AIZSlider> carouselImageList = [];
  List<AIZSlider> bannerOneImageList = [];
  List<AIZSlider> flashDealBannerImageList = [];
  List<FlashDealResponseDatum> _banners = [];
  List<FlashDealResponseDatum> get banners {
    return [..._banners];
  }

  final List<SingleBanner> _singleBanner = [];

  List<SingleBanner> get singleBanner => _singleBanner;

  var bannerTwoImageList = [];
  var featuredCategoryList = [];

  bool isCategoryInitial = true;

  bool isCarouselInitial = true;
  bool isBannerOneInitial = true;
  bool isFlashDealInitial = true;
  bool isBannerTwoInitial = true;
  bool isBannerFlashDeal = true;

  var featuredProductList = [];
  bool isFeaturedProductInitial = true;
  int? totalFeaturedProductData = 0;
  int featuredProductPage = 1;
  bool showFeaturedLoadingContainer = false;

  var allProductList = [];
  bool isAllProductInitial = true;
  int? totalAllProductData = 0;
  int allProductPage = 1;
  bool showAllLoadingContainer = false;

  int cartCount = 0;
  bool isTodayDeal = false;

  Future<void> fetchAll() async {
    await Future.wait([
      fetchCarouselImages(),
      fetchBannerOneImages(),
      fetchBannerTwoImages(),
      fetchFeaturedCategories(),
      fetchFeaturedProducts(),
      fetchAllProducts(), // Tüm ürünleri de hemen yükle
    ]);
    notifyListeners();
  }

  Future<void> fetchCarouselImages() async {
    var sliderResponse = await SlidersRepository().getSliders();
    carouselImageList.clear();
    if (sliderResponse.sliders != null) {
      carouselImageList.addAll(sliderResponse.sliders!);
    }
    isCarouselInitial = false;
    notifyListeners();
  }

  Future<void> fetchBannerOneImages() async {
    var sliderResponse = await SlidersRepository().getBannerOneImages();
    bannerOneImageList.clear();
    if (sliderResponse.sliders != null) {
      bannerOneImageList.addAll(sliderResponse.sliders!);
    }
    isBannerOneInitial = false;
    notifyListeners();
  }

  Future<void> fetchBannerTwoImages() async {
    var sliderResponse = await SlidersRepository().getBannerTwoImages();
    bannerTwoImageList.clear();
    if (sliderResponse.sliders != null) {
      bannerTwoImageList.addAll(sliderResponse.sliders!);
    }
    isBannerTwoInitial = false;
    notifyListeners();
  }

  Future<void> fetchFeaturedCategories() async {
    var categoryResponse = await CategoryRepository().getFeturedCategories(limit: 100);
    featuredCategoryList.clear();
    if (categoryResponse.categories != null && categoryResponse.categories!.isNotEmpty) {
      featuredCategoryList.addAll(categoryResponse.categories!);
    }
    isCategoryInitial = false;
    notifyListeners();
  }

  refreshFeaturedCategories() async {
    featuredCategoryList.clear();
    isCategoryInitial = true;
    notifyListeners();
    await fetchFeaturedCategories();
  }

  Future<void> fetchFeaturedProducts() async {
    try {
      var productResponse = await ProductRepository().getFeaturedProducts(
        page: featuredProductPage,
      );

      featuredProductPage++;

      if (productResponse.products != null) {
        featuredProductList.addAll(productResponse.products!);
      }

      isFeaturedProductInitial = false;

      if (productResponse.meta != null) {
        totalFeaturedProductData = productResponse.meta!.total;
      }

      showFeaturedLoadingContainer = false;
      notifyListeners();
    } catch (e) {}
  }

  Future<void> fetchAllProducts() async {
    try {
      var productResponse =
          await ProductRepository().getFilteredProducts(page: allProductPage);

      if (productResponse.products != null) {
        allProductList.addAll(productResponse.products!);
      }

      isAllProductInitial = false;

      if (productResponse.meta != null) {
        totalAllProductData = productResponse.meta!.total;
      }

      showAllLoadingContainer = false;
      notifyListeners();
    } catch (e) {
      showAllLoadingContainer = false;
      notifyListeners();
    }
  }

  Future<void> onRefresh() async {
    carouselImageList.clear();
    bannerOneImageList.clear();
    bannerTwoImageList.clear();
    featuredCategoryList.clear();

    isCarouselInitial = true;
    isBannerOneInitial = true;
    isBannerTwoInitial = true;
    isCategoryInitial = true;
    cartCount = 0;

    flashDealBannerImageList.clear();

    notifyListeners();
    fetchAll();
  }

  refreshFeaturedProducts() async {
    featuredProductList.clear();
    isFeaturedProductInitial = true;
    totalFeaturedProductData = 0;
    featuredProductPage = 1;
    showFeaturedLoadingContainer = false;
    notifyListeners();
  }

  refreshAllProducts() async {
    allProductList.clear();
    isAllProductInitial = true;
    totalAllProductData = 0;
    allProductPage = 1;
    showAllLoadingContainer = false;
    notifyListeners();
  }

  mainScrollListener() {
    mainScrollController.addListener(() {
      if (mainScrollController.position.pixels >=
          mainScrollController.position.maxScrollExtent - 200) { // Daha erken tetikle
        if (!showAllLoadingContainer && allProductPage < 10) { // Maksimum 10 sayfa
          allProductPage++;
          showAllLoadingContainer = true;
          fetchAllProducts();
        }
      }
    });
  }

  initPiratedAnimation(vnc) {
    pirated_logo_controller =
        AnimationController(duration: Duration(seconds: 2), vsync: vnc);
    pirated_logo_animation = Tween(begin: 40.0, end: 60.0).animate(
        CurvedAnimation(
            curve: Curves.bounceOut, parent: pirated_logo_controller));

    pirated_logo_controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        pirated_logo_controller.repeat();
      }
    });

    pirated_logo_controller.forward();
  }

  incrementCurrentSlider(index) {
    current_slider = index;
    notifyListeners();
  }

  @override
  void dispose() {
    pirated_logo_controller.dispose();
    super.dispose();
  }
}