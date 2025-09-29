import 'package:flutter/material.dart';
import '../helpers/system_config.dart';
import '../my_theme.dart';
import '../presenter/cart_provider.dart';
import 'box_decorations.dart';
import 'device_info.dart';
class CartSellerItemCardWidget extends StatelessWidget {
  final int sellerIndex;
  final int itemIndex;
  final CartProvider cartProvider;
  const CartSellerItemCardWidget(
      {super.key,
        required this.cartProvider,
        required this.sellerIndex,
        required this.itemIndex});
  @override
  Widget build(BuildContext context) {
    final cartItem = cartProvider.shopList[sellerIndex].cartItems[itemIndex];
    final bool isOutOfStock =
        (cartItem.digital ?? 0) == 0 && cartItem.stock == 0;
    final bool showQuantityControls =
        !isOutOfStock && (cartItem.digital ?? 0) != 1;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Üst kısım - ürün bilgileri
          Container(
            height: 100,
            child: Stack(
              children: [
                Row(
                  children: [
                // Ürün resmi kutusu - sol
                Container(
                  width: 100,
                  height: 100,
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        FadeInImage.assetNetwork(
                          placeholder: 'assets/placeholder.png',
                          image: cartItem.productThumbnailImage!,
                          fit: BoxFit.cover,
                        ),
                        if (isOutOfStock)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Center(
                              child: Text(
                                'Stokta Yok',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Ürün bilgileri - orta
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Ürün adı
                        Text(
                          cartItem.productName!,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: const TextStyle(
                              color: MyTheme.font_grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
                
                
                  ],
                ),
                
                // Silme butonu - sağ üst
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () async {
                      cartProvider.onPressDelete(
                        context,
                        cartItem.id,
                      );
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Alt kısım - miktar kontrol butonları ve fiyat
          if (showQuantityControls)
            Padding(
              padding: EdgeInsets.only(left: 8, top: 8, bottom: 8),
              child: Row(
                children: [
                  // Miktar kontrol kutusu - sol
                  Container(
                    width: 100, // Fotoğraf kutusu ile aynı genişlik
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20), // Daha oval
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Eksiltme butonu
                        GestureDetector(
                          onTap: () {
                            if (cartItem.auctionProduct == 0) {
                              cartProvider.onQuantityDecrease(
                                  context, sellerIndex, itemIndex);
                            }
                          },
                          child: Icon(
                            Icons.remove,
                            color: cartItem.auctionProduct == 0
                                ? MyTheme.accent_color
                                : MyTheme.grey_153,
                            size: 18,
                          ),
                        ),
                        // Miktar
                        Text(
                          cartItem.quantity.toString(),
                          style: TextStyle(
                              color: Colors.grey.shade700, 
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                        // Artırma butonu
                        GestureDetector(
                          onTap: () {
                            if (cartItem.auctionProduct == 0) {
                              cartProvider.onQuantityIncrease(
                                  context, sellerIndex, itemIndex);
                            }
                          },
                          child: Icon(
                            Icons.add,
                            color: MyTheme.accent_color,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Boşluk
                  Spacer(),
                  
                  // Fiyat - sağda (2 karakter sola)
                  Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Text(
                      SystemConfig.systemCurrency != null
                          ? cartItem.price!.replaceAll(
                          SystemConfig.systemCurrency!.code!,
                          SystemConfig.systemCurrency!.symbol!)
                          : cartItem.price!,
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
