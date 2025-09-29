import 'package:neurom_bilisim_store/helpers/system_config.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/screens/product/product_details.dart';
import 'package:flutter/material.dart';

import '../helpers/shared_value_helper.dart';
import '../screens/auction/auction_products_details.dart';
import '../repositories/wishlist_repository.dart';
import '../repositories/cart_repository.dart';
import '../custom/toast_component.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../presenter/cart_counter.dart';
import '../data_model/cart_add_response.dart';
import '../screens/checkout/cart.dart';

class ProductCard extends StatefulWidget {
  final dynamic identifier;
  final int? id;
  final String slug;
  final String? image;
  final String? name;
  final String? main_price;
  final String? stroked_price;
  final bool has_discount;
  final bool? isWholesale;
  final String? discount;

  const ProductCard({
    super.key,
    this.identifier,
    required this.slug,
    this.id,
    this.image,
    this.name,
    this.main_price,
    this.stroked_price,
    this.has_discount = false,
    bool? is_wholesale = false, // Corrected to use is_wholesale
    this.discount,
  })  : isWholesale = is_wholesale;

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isInWishList = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchWishListCheckInfo();
  }

  fetchWishListCheckInfo() async {
    if (!is_logged_in.$) return;
    
    try {
      var wishListCheckResponse = await WishListRepository()
          .isProductInUserWishList(product_slug: widget.slug);

      if (wishListCheckResponse.is_in_wishlist != null && mounted) {
        setState(() {
          _isInWishList = wishListCheckResponse.is_in_wishlist!;
        });
      }
    } catch (e) {
      print('Error checking wishlist: $e');
    }
  }

  addToWishList() async {
    try {
      var wishListCheckResponse = await WishListRepository().add(
        product_slug: widget.slug,
      );
      if (mounted) {
        setState(() {
          _isInWishList = wishListCheckResponse.is_in_wishlist;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Error adding to wishlist: $e');
    }
  }

  removeFromWishList() async {
    try {
      var wishListCheckResponse = await WishListRepository().remove(
        product_slug: widget.slug,
      );
      setState(() {
        _isInWishList = wishListCheckResponse.is_in_wishlist;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error removing from wishlist: $e');
    }
  }

  onWishTap() {
    if (is_logged_in.$ == false) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.you_need_to_log_in,
      );
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    if (_isInWishList) {
      _isInWishList = false;
      removeFromWishList();
    } else {
      _isInWishList = true;
      addToWishList();
    }
  }

  addToCart() async {
    if (!guest_checkout_status.$) {
      if (is_logged_in.$ == false) {
        ToastComponent.showDialog(
          AppLocalizations.of(context)!.you_need_to_log_in,
        );
        return;
      }
    }

    try {
      var cartAddResponse = await CartRepository().getCartAddResponse(
        widget.id,
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
        
        // Show success SnackBar (same as product details page)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.shopping_cart_checkout,
                    color: const Color(0xff27AE60),
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "🎉 ${AppLocalizations.of(context)!.added_to_cart}",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "Sepetinizde ${Provider.of<CartCounter>(context, listen: false).cartCounter} ürün var",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xff27AE60),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(16),
            action: SnackBarAction(
              label: "Sepete Git",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return Cart(has_bottomnav: false);
                    },
                  ),
                );
              },
              textColor: Colors.white,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error adding to cart: $e');
      ToastComponent.showDialog(
        'Something went wrong',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        'Wholesale status: ${widget.isWholesale}'); // Debug print to check wholesale status
    return InkWell(
      onTap: () {
        print("=== ÜRÜN KARTINA TIKLANDI ===");
        print("Product ID: ${widget.id}");
        print("Product Slug: ${widget.slug}");
        print("Product Name: ${widget.name}");
        print("Identifier: ${widget.identifier}");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return widget.identifier == 'auction'
                  ? AuctionProductsDetails(slug: widget.slug)
                  : ProductDetails(slug: widget.slug);
            },
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 0.5,
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: <Widget>[
                AspectRatio(
                  aspectRatio: 1,
                  child: Stack(children: [
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.fromLTRB(4, 4, 4, 0), // Biraz daha boşluk
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        clipBehavior: Clip.hardEdge,
                        borderRadius: BorderRadius.circular(10),
                        child: FadeInImage.assetNetwork(
                          placeholder: 'assets/placeholder.png',
                          image: widget.image ?? 'assets/placeholder.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    //    if (whole_sale_addon_installed.$ && widget.isWholesale !)
                    if ((whole_sale_addon_installed.$) &&
                        (widget.isWholesale ?? false))
                      Positioned(
                        bottom: 0,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(6),
                              bottomLeft: Radius.circular(6),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0x14000000),
                                offset: Offset(-1, 1),
                                blurRadius: 1,
                              ),
                            ],
                          ),
                          child: Text(
                            "Wholesale",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              height: 1.8,
                            ),
                            textHeightBehavior: TextHeightBehavior(
                                applyHeightToFirstAscent: false),
                            softWrap: false,
                          ),
                        ),
                      ),
                  ]),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Container(
                        margin: EdgeInsets.fromLTRB(4, 4, 4, 0), // Ürün fotoğraf kutusu ile aynı
                        child: Text(
                          widget.name ?? 'No Name',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 13, // Standart boyut
                            height: 1.3, // Satır aralığı
                            fontWeight: FontWeight.w500, // Biraz kalın
                            letterSpacing: 0.2, // Harf aralığı
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            // Fiyat kutusu - üst kutu ile aynı hizalama
            Positioned(
              left: 4,
              right: 4,
              bottom: 4,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    // Fiyat bilgileri - sol taraf
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (widget.has_discount)
                            Text(
                              SystemConfig.systemCurrency != null
                                  ? widget.stroked_price?.replaceAll(
                                          SystemConfig.systemCurrency!.code!,
                                          SystemConfig.systemCurrency!.symbol!) ??
                                      ''
                                  : widget.stroked_price ?? '',
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: MyTheme.medium_grey,
                                fontSize: 11,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 0.2,
                              ),
                            ),
                          SizedBox(height: widget.has_discount ? 1 : 0),
                          Text(
                            SystemConfig.systemCurrency != null
                                ? widget.main_price?.replaceAll(
                                        SystemConfig.systemCurrency!.code!,
                                        SystemConfig.systemCurrency!.symbol!) ??
                                    ''
                                : widget.main_price ?? '',
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              color: widget.has_discount 
                                  ? const Color(0xff27AE60)
                                  : Colors.black87,
                              fontSize: 15,
                              fontWeight: widget.has_discount
                                  ? FontWeight.w800 // Extra bold for discounted products
                                  : FontWeight.w600, // Normal bold for regular products
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Sepete ekle butonu - sağ taraf
                    Container(
                      height: 32,
                      width: 32,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Image.asset(
                          'assets/cart.png',
                          width: 20,
                          height: 20,
                          color: const Color(0xff27AE60), // Yeşil renk
                        ),
                        onPressed: addToCart,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // İndirim yüzdesi - sol üst köşe
            Positioned(
              top: 8,
              left: 8,
              child: widget.has_discount
                  ? Container(
                      height: 22, // 30 -> 22 (%25 küçültme)
                      width: 54, // 72 -> 54 (%25 küçültme)
                      decoration: BoxDecoration(
                        color: const Color(0xff27AE60),
                        borderRadius: BorderRadius.circular(11), // 15 -> 11
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x14000000),
                            offset: Offset(-1, 1),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.discount ?? '',
                          style: TextStyle(
                            fontSize: 11, // 15 -> 11 (%25 küçültme)
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 1.8,
                          ),
                          textHeightBehavior: TextHeightBehavior(
                              applyHeightToFirstAscent: false),
                          softWrap: false,
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
            ),
            // Favori ikonu - sağ üst köşe
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x14000000),
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: _isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _isInWishList 
                                  ? const Color(0xff27AE60) // Modern yeşil
                                  : Colors.grey[600]!,
                            ),
                          ),
                        )
                      : Icon(
                          _isInWishList ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: _isInWishList 
                              ? const Color(0xff27AE60) // Modern yeşil
                              : Colors.grey[600],
                        ),
                  onPressed: onWishTap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

