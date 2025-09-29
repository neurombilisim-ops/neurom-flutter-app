import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/helpers/shimmer_helper.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/repositories/wishlist_repository.dart';
import 'package:flutter/material.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';
import 'package:neurom_bilisim_store/ui_elements/product_card_black.dart';

class Wishlist extends StatefulWidget {
  const Wishlist({super.key});

  @override
  _WishlistState createState() => _WishlistState();
}

class _WishlistState extends State<Wishlist> {
  final ScrollController _mainScrollController = ScrollController();
  bool _wishlistInit = true;
  final List<dynamic> _wishlistItems = [];

  //init
  @override
  void initState() {
    if (is_logged_in.$ == true) {
      fetchWishlistItems();
    }
    super.initState();
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    super.dispose();
  }

  fetchWishlistItems() async {
    var wishlistResponse = await WishListRepository().getUserWishlist();
    
    if (wishlistResponse.wishlist_items != null) {
      _wishlistItems.addAll(wishlistResponse.wishlist_items!);
    }
    
    _wishlistInit = false;
    setState(() {});
  }

  reset() {
    _wishlistInit = true;
    _wishlistItems.clear();
    setState(() {});
  }

  Future<void> _onPageRefresh() async {
    reset();
    if (is_logged_in.$ == true) {
      fetchWishlistItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: buildAppBar(context),
        body: buildWishlist(),
      ),
    );
  }

  buildWishlist() {
    if (is_logged_in.$ == false) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.you_need_to_log_in,
            style: TextStyle(color: MyTheme.font_grey),
          ),
        ),
      );
    } else if (_wishlistInit == true && _wishlistItems.isEmpty) {
      return SingleChildScrollView(
        child: ShimmerHelper().buildListShimmer(item_count: 10),
      );
    } else if (_wishlistItems.isNotEmpty) {
      return Container(
        padding: EdgeInsets.all(8),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.7,
          ),
          itemCount: _wishlistItems.length,
          itemBuilder: (context, index) {
            var item = _wishlistItems[index];
              return ProductCardBlack(
                id: item.product.id,
                slug: item.product.slug ?? '',
                image: item.product.thumbnail_image,
                name: item.product.name,
                main_price: item.product.main_price ?? item.product.base_price,
                stroked_price: item.product.stroked_price,
                has_discount: item.product.has_discount ?? false,
                discount: item.product.discount_percentage?.toString(),
                isWholesale: false,
                is_wholesale: false,
              );
          },
        ),
      );
    } else {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            "Favori ürün bulunamadı",
            style: TextStyle(color: MyTheme.font_grey),
          ),
        ),
      );
    }
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
          // Ortada başlık
          Expanded(
            child: Center(
              child: Text(
                "Favorilerim",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}