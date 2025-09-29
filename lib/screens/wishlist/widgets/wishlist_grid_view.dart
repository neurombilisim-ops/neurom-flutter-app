import 'package:flutter/material.dart';
import 'wishlist_product_card.dart';

class WishListGridView extends StatelessWidget {
  const WishListGridView({
    super.key,
    required List wishlistItems,
  }) : _wishlistItems = wishlistItems;

  final List _wishlistItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      padding: EdgeInsets.zero,
      child: Column(
        children: _wishlistItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return WishlistProductCard(
              id: item.product.id ?? 0,
              image: item.product.thumbnail_image,
              name: item.product.name,
              model: item.product.id?.toString() ?? 'N/A', // Using product ID as model
              mainPrice: item.product.main_price ?? item.product.base_price ?? 'Fiyat bilgisi yok',
              strokedPrice: item.product.stroked_price,
              hasDiscount: item.product.has_discount,
              discountPercentage: item.product.discount_percentage,
              showDiscountBadge: true, // Show discount badge for discounted items
              onAddToCart: () {
                // TODO: Implement add to cart functionality
                print('Add to cart: ${item.product.name}');
              },
              onRemove: () {
                // TODO: Implement remove from wishlist functionality
                print('Remove from wishlist: ${item.product.name}');
              },
            );
        }).toList(),
      ),
    );
  }
}
