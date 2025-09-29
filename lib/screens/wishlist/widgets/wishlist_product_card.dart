import 'package:flutter/material.dart';
import '../../../my_theme.dart';

class WishlistProductCard extends StatelessWidget {
  final int id;
  final String? image;
  final String? name;
  final String? model;
  final String? mainPrice;
  final String? strokedPrice;
  final bool? hasDiscount;
  final String? discountPercentage;
  final VoidCallback? onAddToCart;
  final VoidCallback? onRemove;
  final bool showDiscountBadge;

  const WishlistProductCard({
    Key? key,
    required this.id,
    this.image,
    this.name,
    this.model,
    this.mainPrice,
    this.strokedPrice,
    this.hasDiscount,
    this.discountPercentage,
    this.onAddToCart,
    this.onRemove,
    this.showDiscountBadge = false,
  }) : super(key: key);

  String _formatPrice(String price) {
    if (price == 'Fiyat bilgisi yok' || price.isEmpty) {
      return price;
    }
    
    // Ana sayfadaki ürün kartından alınan format mantığı
    String cleanPrice = price.toString()
        .replaceAll(' TL', '')
        .replaceAll(' TRY', '')
        .replaceAll('TL', '')
        .replaceAll('TRY', '')
        .trim();
    
    return "$cleanPrice ₺";
  }

  bool _hasDiscount() {
    // API'den gelen has_discount değerini kullan
    return hasDiscount ?? false;
  }

  int _calculateDiscountPercentage() {
    // API'den gelen discount_percentage değerini kullan
    if (discountPercentage != null && discountPercentage!.isNotEmpty) {
      try {
        return int.parse(discountPercentage!.replaceAll('%', ''));
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  String _getOriginalPrice() {
    // API'den gelen stroked_price değerini kullan
    if (strokedPrice != null && strokedPrice!.isNotEmpty) {
      return _formatPrice(strokedPrice!);
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          Row(
            children: [
          // Product Image with Discount Badge
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: image != null && image!.isNotEmpty
                      ? Image.network(
                          image!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[400],
                              size: 40,
                            );
                          },
                        )
                      : Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[400],
                          size: 40,
                        ),
                ),
              ),
              // Discount Badge - Only show if showDiscountBadge is true
              if (showDiscountBadge && _hasDiscount())
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red[600],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_calculateDiscountPercentage()}%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
              SizedBox(width: 16),
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Model/Code
                    if (model != null && model!.isNotEmpty)
                      Text(
                        model!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    SizedBox(height: 4),
                    // Product Name - Limited width to not overlap with button
                    Container(
                      width: MediaQuery.of(context).size.width * 0.5, // Limit width
                      child: Text(
                        name ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.visible,
                        softWrap: true,
                      ),
                    ),
                    SizedBox(height: 8),
                    // Price and Add to Cart Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price Section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Original Price (crossed out) - Only show if there's a discount
                              if (showDiscountBadge && _hasDiscount() && _getOriginalPrice().isNotEmpty)
                                Text(
                                  _getOriginalPrice(), // API'den gelen orijinal fiyat
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              if (showDiscountBadge && _hasDiscount())
                                SizedBox(height: 2),
                              // Current Price
                              Text(
                                _formatPrice(mainPrice ?? strokedPrice ?? 'Fiyat bilgisi yok'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: showDiscountBadge && _hasDiscount() ? Colors.red[600] : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                    // Add to Cart Button
                    Container(
                      height: 36,
                      margin: EdgeInsets.only(top: 4),
                      child: ElevatedButton(
                        onPressed: onAddToCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4CAF50), // Green color
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Text(
                          'Sepete Ekle',
                          style: TextStyle(
                            fontSize: 12,
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
            ],
          ),
          // Remove Button - Positioned at top right
          Positioned(
            top: -7,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: EdgeInsets.all(8),
                child: Image.asset(
                  'assets/delete.png',
                  width: 20,
                  height: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
