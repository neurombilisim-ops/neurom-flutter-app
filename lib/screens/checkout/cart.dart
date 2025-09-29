import 'package:neurom_bilisim_store/custom/btn.dart';
import 'package:neurom_bilisim_store/custom/text_styles.dart';
import 'package:neurom_bilisim_store/custom/useful_elements.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/helpers/shimmer_helper.dart';
import 'package:neurom_bilisim_store/helpers/system_config.dart';
import 'package:neurom_bilisim_store/l10n/app_localizations.dart';
import 'package:neurom_bilisim_store/my_theme.dart';
import 'package:neurom_bilisim_store/presenter/cart_counter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../custom/cart_seller_item_list_widget.dart';
import '../../presenter/cart_provider.dart';
import '../home.dart';
import '../main.dart';
import '../product/product_details.dart';
import '../../repositories/coupon_repository.dart';
import '../../custom/toast_component.dart';
import '../../data_model/coupon_apply_response.dart';

class Cart extends StatefulWidget {
  const Cart({
    super.key,
    this.has_bottomnav,
    this.from_navigation = false,
    this.counter,
    this.onBackPressed,
  });

  final bool? has_bottomnav;
  final bool from_navigation;
  final CartCounter? counter;
  final VoidCallback? onBackPressed;

  @override
  _CartState createState() => _CartState();
}

class _CartState extends State<Cart> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        cartProvider.fetchData(context);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.red,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        return Directionality(
          textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: Colors.white,
            appBar: _buildCartAppBar(context),
            body: Stack(
              children: [
                RefreshIndicator(
                  color: MyTheme.accent_color,
                  backgroundColor: Colors.white,
                  onRefresh: () => cartProvider.onRefresh(context),
                  displacement: 0,
                  child: CustomScrollView(
                    controller: cartProvider.mainScrollController,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      SliverList(
                        delegate: SliverChildListDelegate([
                          // Ürünler listesi
                          buildCartItemsList(cartProvider, context),
                          // Sipariş özeti
                          buildOrderSummary(cartProvider, context),
                          SizedBox(height: 120), // Alt boşluk (sabit bölüm için)
                        ]),
                      ),
                    ],
                  ),
                ),
                // Alt kısımda sabit bölüm
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: buildCartBottomSection(cartProvider, context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildCartItemsList(CartProvider cartProvider, BuildContext context) {
    if (cartProvider.isInitial) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (cartProvider.shopList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Sepetiniz boş",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Column(
      children: cartProvider.shopList.map<Widget>((shop) {
        return Column(
          children: shop.cartItems.map<Widget>((item) {
            return Container(
                margin: EdgeInsets.only(bottom: 12, left: 1, right: 1),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resim
                    Container(
                      margin: EdgeInsets.only(left: 3, top: 3),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[100],
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.productThumbnailImage ?? '',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.image, color: Colors.grey);
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    // Yazılar
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.productName ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 10),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              '${item.price.toString().replaceAll('TRY', '').replaceAll('TL', '').trim()} ₺',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: MyTheme.accent_color,
                              ),
                            ),
                          ),
                          SizedBox(height: 1),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.variation ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Container(
                                height: 28,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => cartProvider.decreaseQuantity(context, item.id),
                                      icon: Icon(Icons.remove, size: 12, weight: 900.0),
                                      padding: EdgeInsets.all(2),
                                      constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                                    ),
                                    Text(
                                      item.quantity.toString(),
                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                                    ),
                                    IconButton(
                                      onPressed: () => cartProvider.increaseQuantity(context, item.id),
                                      icon: Icon(Icons.add, size: 12, weight: 900.0),
                                      padding: EdgeInsets.all(2),
                                      constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 2),
                    // Silme butonu
                    IconButton(
                      onPressed: () => cartProvider.removeFromCart(context, item.id),
                      icon: Image.asset(
                        "assets/delete.png",
                        width: 20,
                        height: 20,
                      ),
                      padding: EdgeInsets.all(8),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }


  Widget buildOrderSummary(CartProvider cartProvider, BuildContext context) {
    // Ara toplam hesaplama (KDV hariç)
    double subtotal = 0.0;
    for (var shop in cartProvider.shopList) {
      for (var item in shop.cartItems) {
        double price = 0.0;
        if (item.price is String) {
          String cleanPrice = item.price.toString()
              .replaceAll('TRY', '')
              .replaceAll('TL', '')
              .replaceAll('₺', '')
              .replaceAll(',', '')
              .trim();
          price = double.tryParse(cleanPrice) ?? 0.0;
        } else if (item.price is num) {
          price = item.price.toDouble();
        }
        subtotal += price * item.quantity;
      }
    }
    
    // KDV hesaplama (%20)
    double vatRate = 0.20;
    double vatAmount = subtotal * vatRate;
    
    // Toplam
    double total = subtotal + vatAmount;
    
    // Formatla
    String formatNumber(double number) {
      return number.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    }
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 1, vertical: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Sipariş Özeti:",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: MyTheme.accent_color,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Ara Toplam",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              Text(
                "${formatNumber(subtotal)} ₺",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "KDV",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              Text(
                "${formatNumber(vatAmount)} ₺",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TOPLAM",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                cartProvider.cartTotalString,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: MyTheme.accent_color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildCartBottomSection(CartProvider cartProvider, BuildContext context) {
    final bool canProceed =
        cartProvider.shopList.isNotEmpty && !cartProvider.isAnyItemOutOfStock;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sol taraf - Toplam
          Padding(
            padding: EdgeInsets.only(left: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Toplam",
                  style: TextStyle(
                    color: Color(0xff2C3E50),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  cartProvider.cartTotalString,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Sağ taraf - Onaylama butonu
          Padding(
            padding: EdgeInsets.only(right: 5),
            child: Container(
              height: 40,
            child: ElevatedButton(
              onPressed: canProceed
                  ? () => cartProvider.onPressProceedToShipping(context)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canProceed ? MyTheme.accent_color : Color(0xff6C757D),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Sepeti Onayla",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }



  AppBar _buildCartAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      scrolledUnderElevation: 0.0,
      centerTitle: true,
      elevation: 0,
      toolbarHeight: 92,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sol tarafta geri butonu
          Container(
            width: 40,
            height: 40,
            child: IconButton(
              onPressed: () {
                // Callback varsa kullan, yoksa fallback
                if (widget.onBackPressed != null) {
                  widget.onBackPressed!();
                } else {
                  // Fallback: Ana sayfaya yönlendir
                  try {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => Main()),
                      (route) => false,
                    );
                  } catch (e) {
                    // Hata durumunda pop dene
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  }
                }
              },
              icon: Image.asset(
                "assets/sol.png",
                width: 24,
                height: 24,
                color: Colors.black87,
              ),
            ),
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
          // Sağ tarafta boş alan (denge için)
          Container(
            width: 40,
            height: 40,
          ),
        ],
      ),
    );
  }
}
