//
//
// import 'dart:convert';
//
// CartResponse cartResponseFromJson(String str) =>
//     CartResponse.fromJson(json.decode(str));
//
// String cartResponseToJson(CartResponse data) => json.encode(data.toJson());
//
// class CartResponse {
//   String? grandTotal;
//   List<Datum>? data;
//
//   CartResponse({
//     this.grandTotal,
//     this.data,
//   });
//
//   factory CartResponse.fromJson(Map<String, dynamic> json) => CartResponse(
//     // Safety for String fields
//     grandTotal: json["grand_total"]?.toString(),
//     data: json["data"] == null
//         ? []
//         : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
//   );
//
//   Map<String, dynamic> toJson() => {
//     "grand_total": grandTotal,
//     "data": data == null
//         ? []
//         : List<dynamic>.from(data!.map((x) => x.toJson())),
//   };
// }
//
// class Datum {
//   String? name;
//   int? ownerId;
//   String? subTotal;
//   List<CartItem>? cartItems;
//
//   Datum({
//     this.name,
//     this.ownerId,
//     this.subTotal,
//     this.cartItems,
//   });
//
//   factory Datum.fromJson(Map<String, dynamic> json) {
//     // Helper function to safely parse integer values
//     int? safeParseInt(dynamic value) {
//       if (value == null) return null;
//       return int.tryParse(value.toString());
//     }
//
//     return Datum(
//       name: json["name"]?.toString(),
//       ownerId: safeParseInt(json["owner_id"]), // Robust parsing
//       subTotal: json["sub_total"]?.toString(),
//       cartItems: json["cart_items"] == null
//           ? []
//           : List<CartItem>.from(
//           json["cart_items"]!.map((x) => CartItem.fromJson(x))),
//     );
//   }
//
//   Map<String, dynamic> toJson() => {
//     "name": name,
//     "owner_id": ownerId,
//     "sub_total": subTotal,
//     "cart_items": cartItems == null
//         ? []
//         : List<dynamic>.from(cartItems!.map((x) => x.toJson())),
//   };
// }
//
// class CartItem {
//   int? id;
//   int? ownerId;
//   int? userId;
//   int? productId;
//   String? productName;
//   int? auctionProduct;
//   String? productThumbnailImage;
//   String? variation;
//   String? price;
//   String? currencySymbol;
//   String? tax;
//   int? shippingCost;
//   int? quantity;
//   int? lowerLimit;
//   int? upperLimit;
//
//   CartItem({
//     this.id,
//     this.ownerId,
//     this.userId,
//     this.productId,
//     this.productName,
//     this.auctionProduct,
//     this.productThumbnailImage,
//     this.variation,
//     this.price,
//     this.currencySymbol,
//     this.tax,
//     this.shippingCost,
//     this.quantity,
//     this.lowerLimit,
//     this.upperLimit,
//   });
//
//   factory CartItem.fromJson(Map<String, dynamic> json) {
//     // Helper function to safely handle int, double, String, or null values.
//     int? safeParseInt(dynamic value) {
//       if (value == null) return null;
//       return int.tryParse(value.toString());
//     }
//
//     return CartItem(
//       // Apply the safe parser to all int? fields
//       id: safeParseInt(json["id"]),
//       ownerId: safeParseInt(json["owner_id"]),
//       userId: safeParseInt(json["user_id"]),
//       productId: safeParseInt(json["product_id"]),
//       auctionProduct: safeParseInt(json["auction_product"]),
//       shippingCost: safeParseInt(json["shipping_cost"]),
//       quantity: safeParseInt(json["quantity"]),
//       lowerLimit: safeParseInt(json["lower_limit"]),
//       upperLimit: safeParseInt(json["upper_limit"]),
//
//       // For String fields, calling .toString() with a null check is a good safety measure
//       productName: json["product_name"]?.toString(),
//       productThumbnailImage: json["product_thumbnail_image"]?.toString(),
//       variation: json["variation"]?.toString(),
//       price: json["price"]?.toString(),
//       currencySymbol: json["currency_symbol"]?.toString(),
//       tax: json["tax"]?.toString(),
//     );
//   }
//
//   Map<String, dynamic> toJson() => {
//     "id": id,
//     "owner_id": ownerId,
//     "user_id": userId,
//     "product_id": productId,
//     "product_name": productName,
//     "auction_product": auctionProduct,
//     "product_thumbnail_image": productThumbnailImage,
//     "variation": variation,
//     "price": price,
//     "currency_symbol": currencySymbol,
//     "tax": tax,
//     "shipping_cost": shippingCost,
//     "quantity": quantity,
//     "lower_limit": lowerLimit,
//     "upper_limit": upperLimit,
//   };
// }

import 'dart:convert';

CartResponse cartResponseFromJson(String str) =>
    CartResponse.fromJson(json.decode(str));

String cartResponseToJson(CartResponse data) => json.encode(data.toJson());

class CartResponse {
  String? grandTotal;
  List<Datum>? data;
  bool? success;

  CartResponse({
    this.grandTotal,
    this.data,
    this.success,
  });

  factory CartResponse.fromJson(Map<String, dynamic> json) => CartResponse(
    // Safety for String fields
    grandTotal: json["grand_total"]?.toString(),
    data: json["data"] == null
        ? []
        : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
    success: json["success"] ?? true,
  );

  Map<String, dynamic> toJson() => {
    "grand_total": grandTotal,
    "data": data == null
        ? []
        : List<dynamic>.from(data!.map((x) => x.toJson())),
  };
}

class Datum {
  String? name;
  int? ownerId;
  String? subTotal;
  String? shopLogo;
  List<CartItem>? cartItems;

  Datum({
    this.name,
    this.ownerId,
    this.subTotal,
    this.shopLogo,
    this.cartItems,
  });

  factory Datum.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse integer values
    int? safeParseInt(dynamic value) {
      if (value == null) return null;
      return int.tryParse(value.toString());
    }

    return Datum(
      name: json["name"]?.toString(),
      ownerId: safeParseInt(json["owner_id"]), // Robust parsing
      subTotal: json["sub_total"]?.toString(),
      shopLogo: json["shop_logo"]?.toString(),
      cartItems: json["cart_items"] == null
          ? []
          : List<CartItem>.from(
          json["cart_items"]!.map((x) => CartItem.fromJson(x))),
    );
  }

  Map<String, dynamic> toJson() => {
    "name": name,
    "owner_id": ownerId,
    "sub_total": subTotal,
    "shop_logo": shopLogo,
    "cart_items": cartItems == null
        ? []
        : List<dynamic>.from(cartItems!.map((x) => x.toJson())),
  };
}

class CartItem {
  int? id;
  int? ownerId;
  int? userId;
  int? productId;
  String? productName;
  int? auctionProduct;
  String? productThumbnailImage;
  String? variation;
  String? price;
  String? currencySymbol;
  String? tax;
  int? shippingCost;
  int? quantity;
  int? lowerLimit;
  int? upperLimit;
  int? digital;
  int? stock;

  CartItem({
    this.id,
    this.ownerId,
    this.userId,
    this.productId,
    this.productName,
    this.auctionProduct,
    this.productThumbnailImage,
    this.variation,
    this.price,
    this.currencySymbol,
    this.tax,
    this.shippingCost,
    this.quantity,
    this.lowerLimit,
    this.upperLimit,
    this.digital,
    this.stock
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse integer values from any dynamic type.
    int? safeParseInt(dynamic value) {
      if (value == null) return null;
      return int.tryParse(value.toString());
    }

    return CartItem(
      // Apply the safe parser to all integer fields
      id: safeParseInt(json["id"]),
      ownerId: safeParseInt(json["owner_id"]),
      userId: safeParseInt(json["user_id"]),
      productId: safeParseInt(json["product_id"]),
      auctionProduct: safeParseInt(json["auction_product"]),
      shippingCost: safeParseInt(json["shipping_cost"]),
      quantity: safeParseInt(json["quantity"]),
      lowerLimit: safeParseInt(json["lower_limit"]),
      upperLimit: safeParseInt(json["upper_limit"]),

      // *** THIS IS THE CORRECTION ***
      // Apply the safe parser to 'digital' and 'stock' for type safety.
      digital: safeParseInt(json["digital"]),
      stock: safeParseInt(json["stock"]),

      // For String fields, using .toString() with a null check is safe.
      productName: json["product_name"]?.toString(),
      productThumbnailImage: json["product_thumbnail_image"]?.toString(),
      variation: json["variation"]?.toString(),
      price: json["price"]?.toString(),
      currencySymbol: json["currency_symbol"]?.toString(),
      tax: json["tax"]?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "owner_id": ownerId,
    "user_id": userId,
    "product_id": productId,
    "product_name": productName,
    "auction_product": auctionProduct,
    "product_thumbnail_image": productThumbnailImage,
    "variation": variation,
    "price": price,
    "currency_symbol": currencySymbol,
    "tax": tax,
    "shipping_cost": shippingCost,
    "quantity": quantity,
    "lower_limit": lowerLimit,
    "upper_limit": upperLimit,
    "digital": digital,
    "stock": stock
  };
}
