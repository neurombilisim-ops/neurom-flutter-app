import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/helpers/system_config.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/screens/auction/auction_products_details.dart';
import 'package:neurom_bilisim_store/screens/product/product_details.dart';
import 'package:neurom_bilisim_store/screens/auth/login.dart';
import 'package:neurom_bilisim_store/repositories/cart_repository.dart';
import 'package:neurom_bilisim_store/repositories/wishlist_repository.dart';
import 'package:neurom_bilisim_store/custom/toast_component.dart';
import 'package:neurom_bilisim_store/presenter/cart_counter.dart';
import 'package:provider/provider.dart';
import 'package:neurom_bilisim_store/screens/checkout/cart.dart';
import 'package:flutter/material.dart';

class ProductCardBlack extends StatefulWidget {
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
  final int? rating;
  final int? sales;

  const ProductCardBlack({
    super.key,
    this.identifier,
    required this.slug,
    this.id,
    this.image,
    this.name,
    this.main_price,
    this.stroked_price,
    this.has_discount = false,
    this.isWholesale = false,
    this.discount,
    this.rating,
    this.sales,
    required is_wholesale,
  });

  @override
  _ProductCardBlackState createState() => _ProductCardBlackState();
}

class _ProductCardBlackState extends State<ProductCardBlack> {
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
    return Container(
      height: 280,
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
                  return widget.identifier == 'auction'
                      ? AuctionProductsDetails(slug: widget.slug)
                      : ProductDetails(slug: widget.slug);
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ürün resmi
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[100],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: widget.image != null
                            ? Image.network(
                                widget.image!,
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
                    SizedBox(height: 8),
                    
                    // Ürün ID
                    Text(
                      "ID: ${widget.id ?? ""}",
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
                    Container(
                      height: 32,
                      child: Text(
                        widget.name ?? "",
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
                        if (widget.has_discount == true && widget.discount != null && widget.discount.toString().isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "${widget.discount} İndirim",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (widget.has_discount != true || widget.discount == null || widget.discount.toString().isEmpty)
                          SizedBox.shrink(),
                        
                        // Sağ taraf - Rating ve Sales
                        Row(
                          children: [
                            // Rating
                            if (widget.rating != null)
                              Row(
                                children: [
                                  Icon(Icons.star, size: 16, color: Colors.amber),
                                  SizedBox(width: 4),
                                  Text(
                                    "${widget.rating}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            if (widget.rating != null && widget.sales != null)
                              SizedBox(width: 12),
                            // Sales
                            if (widget.sales != null)
                              Row(
                                children: [
                                  Icon(Icons.shopping_cart, size: 16, color: Colors.grey[600]),
                                  SizedBox(width: 4),
                                  Text(
                                    "${widget.sales}",
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
                    if (widget.isWholesale == true)
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
                    if (widget.isWholesale == true)
                      SizedBox(height: 6),
                    
                    // Fiyat
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // İndirimli fiyat (eğer varsa)
                        if (widget.has_discount == true && widget.stroked_price != null && widget.stroked_price.toString().isNotEmpty)
                          Text(
                            "${widget.stroked_price.toString().replaceAll(' TL', '').replaceAll(' TRY', '').replaceAll('TL', '').replaceAll('TRY', '').trim()} ₺",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              decoration: TextDecoration.lineThrough,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        if (widget.has_discount == true && widget.stroked_price != null && widget.stroked_price.toString().isNotEmpty)
                          SizedBox(height: 4),
                        // Ana fiyat
                        Text(
                          "${(widget.main_price ?? "0").toString().replaceAll(' TL', '').replaceAll(' TRY', '').replaceAll('TL', '').replaceAll('TRY', '').trim()} ₺",
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
              
              // Sepete Ekleme Butonu - Sağ üst köşe
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Image.asset(
                      'assets/cart.png',
                      width: 16,
                      height: 16,
                      color: Colors.grey[700],
                    ),
                    onPressed: () {
                      _addToCart(context);
                    },
                  ),
                ),
              ),
              
              // Favori Butonu - Sol üst köşe
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
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
                                    ? (MyTheme.accent_color ?? Colors.blue)
                                    : (Colors.grey[700] ?? Colors.grey),
                              ),
                            ),
                          )
                        : Icon(
                            _isInWishList ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: _isInWishList 
                                ? (MyTheme.accent_color ?? Colors.blue)
                                : (Colors.grey[700] ?? Colors.grey),
                          ),
                    onPressed: () {
                      _addToWishlist(context);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Sepete Ekleme Metodu
  Future<void> _addToCart(BuildContext context) async {
    if (!guest_checkout_status.$) {
      if (is_logged_in.$ == false) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Login(),
          ),
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Login(),
        ),
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
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.only(
            left: 0,
            right: 0,
            bottom: 0,
            top: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    // Ürün resmi ve başarı ikonu
                  Row(
                    children: [
                      // Ürün resmi
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[100],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: widget.image != null
                              ? Image.network(
                                  widget.image!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.image,
                                      color: Colors.grey[400],
                                      size: 30,
                                    );
                                  },
                                )
                              : Icon(
                                  Icons.image,
                                  color: Colors.grey[400],
                                  size: 30,
                                ),
                        ),
                      ),
                      SizedBox(width: 12),
                      // Başarı ikonu ve mesaj
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ürün sepetinize eklendi',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Ürün adı
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.name ?? "Ürün",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: 20),
                  // Butonlar
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            foregroundColor: Colors.grey[700],
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Alışverişe devam et',
                            style: TextStyle(
                              fontSize: 16,
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
                            backgroundColor: MyTheme.accent_color ?? Colors.blue,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Sepete git',
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}