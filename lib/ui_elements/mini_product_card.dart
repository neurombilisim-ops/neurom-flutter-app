// import 'package:neurom_bilisim_store/custom/box_decorations.dart';
// import 'package:neurom_bilisim_store/helpers/system_config.dart';
// import 'package:neurom_bilisim_store/my_theme.dart';
// import 'package:neurom_bilisim_store/screens/product/product_details.dart';
// import 'package:flutter/material.dart';

// import '../helpers/shared_value_helper.dart';

// class MiniProductCard extends StatefulWidget {
//   int? id;
//   String slug;
//   String? image;
//   String? name;
//   String? main_price;
//   String? stroked_price;
//   bool? has_discount;
//   bool? is_wholesale;
//   var discount;
//   MiniProductCard({
//     Key? key,
//     this.id,
//     required this.slug,
//     this.image,
//     this.name,
//     this.main_price,
//     this.stroked_price,
//     this.has_discount,
//     this.is_wholesale = false,
//     this.discount,
//   }) : super(key: key);

//   @override
//   _MiniProductCardState createState() => _MiniProductCardState();
// }

// class _MiniProductCardState extends State<MiniProductCard> {
//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: () {
//         Navigator.push(context, MaterialPageRoute(builder: (context) {
//           return ProductDetails(
//             slug: widget.slug,
//           );
//         }));
//       },
//       child: Container(
//         width: 135,
//         decoration: BoxDecorations.buildBoxDecoration_1(),
//         child: Stack(children: [
//           Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: <Widget>[
//                 AspectRatio(
//                   aspectRatio: 1,
//                   child: Container(
//                       width: double.infinity,
//                       child: ClipRRect(
//                           borderRadius: BorderRadius.vertical(
//                               top: Radius.circular(6), bottom: Radius.zero),
//                           child: FadeInImage.assetNetwork(
//                             placeholder: 'assets/placeholder.png',
//                             image: widget.image!,
//                             fit: BoxFit.cover,
//                           ))),
//                 ),
//                 Padding(
//                   padding: EdgeInsets.fromLTRB(8, 4, 8, 6),
//                   child: Text(
//                     widget.name!,
//                     overflow: TextOverflow.ellipsis,
//                     maxLines: 2,
//                     style: TextStyle(
//                         color: MyTheme.font_grey,
//                         fontSize: 12,
//                         height: 1.2,
//                         fontWeight: FontWeight.w400),
//                   ),
//                 ),
//                 widget.has_discount!
//                     ? Padding(
//                         padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
//                         child: Text(
//                           SystemConfig.systemCurrency != null
//                               ? widget.stroked_price!.replaceAll(
//                                   SystemConfig.systemCurrency!.code!,
//                                   SystemConfig.systemCurrency!.symbol!)
//                               : widget.stroked_price!,
//                           maxLines: 1,
//                           style: TextStyle(
//                               decoration: TextDecoration.lineThrough,
//                               color: MyTheme.medium_grey,
//                               fontSize: 13,
//                               fontWeight: FontWeight.w600),
//                         ),
//                       )
//                     : Container(),
//                 Padding(
//                   padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
//                   child: Text(
//                     SystemConfig.systemCurrency != null
//                         ? widget.main_price!.replaceAll(
//                             SystemConfig.systemCurrency!.code!,
//                             SystemConfig.systemCurrency!.symbol!)
//                         : widget.main_price!,
//                     maxLines: 1,
//                     style: TextStyle(
//                         color: MyTheme.accent_color,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w700),
//                   ),
//                 ),
//               ]),

//           // discount and wholesale
//           Positioned.fill(
//             child: Align(
//               alignment: Alignment.topRight,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   if (widget.has_discount!)
//                     Container(
//                       padding:
//                           EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//                       margin: EdgeInsets.only(bottom: 5),
//                       decoration: BoxDecoration(
//                         color: const Color(0xffe62e04),
//                         borderRadius: BorderRadius.only(
//                           topRight: Radius.circular(6.0),
//                           bottomLeft: Radius.circular(6.0),
//                         ),
//                         boxShadow: [
//                           BoxShadow(
//                             color: const Color(0x14000000),
//                             offset: Offset(-1, 1),
//                             blurRadius: 1,
//                           ),
//                         ],
//                       ),
//                       child: Text(
//                         widget.discount ?? "",
//                         style: TextStyle(
//                           fontSize: 10,
//                           color: const Color(0xffffffff),
//                           fontWeight: FontWeight.w700,
//                           height: 1.8,
//                         ),
//                         textHeightBehavior:
//                             TextHeightBehavior(applyHeightToFirstAscent: false),
//                         softWrap: false,
//                       ),
//                     ),
//                   Visibility(
//                     visible: whole_sale_addon_installed.$,
//                     child: widget.is_wholesale!
//                         ? Container(
//                             padding: EdgeInsets.symmetric(
//                                 horizontal: 12, vertical: 4),
//                             decoration: BoxDecoration(
//                               color: Colors.blueGrey,
//                               borderRadius: BorderRadius.only(
//                                 topRight: Radius.circular(6.0),
//                                 bottomLeft: Radius.circular(6.0),
//                               ),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: const Color(0x14000000),
//                                   offset: Offset(-1, 1),
//                                   blurRadius: 1,
//                                 ),
//                               ],
//                             ),
//                             child: Text(
//                               "Wholesale",
//                               style: TextStyle(
//                                 fontSize: 10,
//                                 color: const Color(0xffffffff),
//                                 fontWeight: FontWeight.w700,
//                                 height: 1.8,
//                               ),
//                               textHeightBehavior: TextHeightBehavior(
//                                   applyHeightToFirstAscent: false),
//                               softWrap: false,
//                             ),
//                           )
//                         : SizedBox.shrink(),
//                   )
//                 ],
//               ),
//             ),
//           ),

//           // whole sale
//         ]),
//       ),
//     );
//   }
// }

import 'package:neurom_bilisim_store/helpers/system_config.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/screens/product/product_details.dart';
import 'package:neurom_bilisim_store/repositories/cart_repository.dart';
import 'package:neurom_bilisim_store/repositories/wishlist_repository.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/custom/toast_component.dart';
import 'package:neurom_bilisim_store/presenter/cart_counter.dart';
import 'package:provider/provider.dart';
import 'package:neurom_bilisim_store/screens/checkout/cart.dart';
import 'package:flutter/material.dart';

class MiniProductCard extends StatefulWidget {
  int? id;
  String slug;
  String? image;
  String? name;
  String? main_price;
  String? stroked_price;
  bool? has_discount;
  bool? is_wholesale;
  var discount;
  int? rating;
  int? sales;
  MiniProductCard({
    super.key,
    this.id,
    required this.slug,
    this.image,
    this.name,
    this.main_price,
    this.stroked_price,
    this.has_discount,
    this.is_wholesale = false,
    this.discount,
    this.rating,
    this.sales,
  });

  @override
  _MiniProductCardState createState() => _MiniProductCardState();
}

class _MiniProductCardState extends State<MiniProductCard> {
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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        print("=== ÜRÜN KARTI TIKLAMA DEBUG ===");
        print("Ürün Adı: ${widget.name}");
        print("Slug: ${widget.slug}");
        print("ID: ${widget.id}");
        print("================================");
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return ProductDetails(
            slug: widget.slug,
          );
        }));
      },
      child: SizedBox(
        width: 140,
        //  decoration: BoxDecorations.buildBoxDecoration_1(),

        child: Stack(children: [
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AspectRatio(
                  aspectRatio: 1,
                  child: SizedBox(
                      width: double.infinity,
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: widget.image != null && widget.image!.isNotEmpty
                                ? FadeInImage.assetNetwork(
                                    placeholder: 'assets/placeholder.png',
                                    image: widget.image!,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey[400],
                                      size: 40,
                                    ),
                                  ))),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: Text(
                    widget.name ?? 'Ürün Adı',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        height: 1.1,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                // Çizili fiyat (indirim varsa)
                if (widget.has_discount == true && widget.stroked_price != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
                    child: Text(
                      widget.stroked_price!,
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                // Ana fiyat
                Padding(
                  padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Text(
                    widget.main_price != null 
                        ? (SystemConfig.systemCurrency != null
                            ? widget.main_price!.replaceAll(
                                SystemConfig.systemCurrency!.code!,
                                SystemConfig.systemCurrency!.symbol!)
                            : widget.main_price!)
                        : 'Fiyat Belirtilmemiş',
                    maxLines: 1,
                    style: TextStyle(
                        color: widget.has_discount == true 
                            ? Color(0xff27AE60) // İndirimde olan ürünlerin fiyatı yeşil
                            : MyTheme.accent_color,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                // Rating ve Sales bilgileri
                Padding(
                  padding: EdgeInsets.fromLTRB(8, 1, 8, 2),
                  child: Row(
                    children: [
                      // Rating - Popülerlik yıldızları
                      if (widget.rating != null && widget.rating! > 0) ...[
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < widget.rating! ? Icons.star : Icons.star_border,
                              size: 8,
                              color: Colors.amber[600],
                            );
                          }),
                        ),
                        SizedBox(width: 2),
                        Text(
                          '(${widget.rating})',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 4),
                      ],
                      // Sales
                      if (widget.sales != null && widget.sales! > 0)
                        Text(
                          '${widget.sales} satış',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ]),
          // İndirim yüzdesi - Modern Yeşil (Sağ Alt - Sabit)
          if (widget.has_discount == true && widget.discount != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xff27AE60), // Modern yeşil
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x14000000),
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  '${widget.discount.toString()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          // Favori Butonu
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
                icon: _isLoading
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isInWishList 
                                ? MyTheme.accent_color
                                : Colors.white,
                          ),
                        ),
                      )
                    : Icon(
                        _isInWishList ? Icons.favorite : Icons.favorite_border,
                        size: 14,
                        color: _isInWishList 
                            ? MyTheme.accent_color
                            : Colors.white,
                      ),
                onPressed: () {
                  _addToWishlist(context);
                },
              ),
            ),
          ),
          // Sepet Butonu
          Positioned(
            top: 8,
            right: 8,
            child: Container(
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
                  _addToCart(context);
                },
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // Sepete Ekleme Metodu
  Future<void> _addToCart(BuildContext context) async {
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
        
        // Show modern success notification
        _showModernSuccessDialog(context);
      }
    } catch (e) {
      print('Error adding to cart: $e');
      ToastComponent.showDialog(
        'Bir hata oluştu',
      );
    }
  }

  // Favoriye Ekleme Metodu
  Future<void> _addToWishlist(BuildContext context) async {
    if (is_logged_in.$ == false) {
      ToastComponent.showDialog(
        'Giriş yapmanız gerekiyor',
      );
      return;
    }

    if (_isLoading) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      var wishListResponse;
      
      if (_isInWishList) {
        wishListResponse = await WishListRepository().remove(
          product_slug: widget.slug,
        );
      } else {
        wishListResponse = await WishListRepository().add(
          product_slug: widget.slug,
        );
      }

      if (mounted) {
        setState(() {
          _isInWishList = wishListResponse.is_in_wishlist;
          _isLoading = false;
        });
      }

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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.favorite_border, color: Colors.white),
                SizedBox(width: 8),
                Text('Ürün favorilerden çıkarıldı'),
              ],
            ),
            backgroundColor: Colors.grey[600],
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error updating wishlist: $e');
      ToastComponent.showDialog(
        'Bir hata oluştu',
      );
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
}
