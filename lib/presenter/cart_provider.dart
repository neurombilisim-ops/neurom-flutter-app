import '../custom/aiz_route.dart';
import '../helpers/shared_value_helper.dart';
import '../screens/checkout/select_address.dart';
import '../screens/guest_checkout_pages/guest_checkout_address.dart';
import '../custom/toast_component.dart';
import '../data_model/cart_response.dart';
import '../helpers/system_config.dart';
import '../presenter/cart_counter.dart';
import '../repositories/cart_repository.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

class CartProvider extends ChangeNotifier {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ScrollController _mainScrollController = ScrollController();
  List _shopList = [];
  CartResponse? _shopResponse;
  bool _isInitial = true;
  double _cartTotal = 0.00;
  String _cartTotalString = ". . .";

  GlobalKey<ScaffoldState> get scaffoldKey => _scaffoldKey;
  ScrollController get mainScrollController => _mainScrollController;
  List get shopList => _shopList;
  CartResponse? get shopResponse => _shopResponse;
  bool get isInitial => _isInitial;
  double get cartTotal => _cartTotal;
  String get cartTotalString => _cartTotalString;


  void dispose() {
    _mainScrollController.dispose();
  }

  Future<void> fetchData(BuildContext context, {bool forceRefresh = false}) async {
    getCartCount(context);
    CartResponse cartResponseList =
        await CartRepository().getCartResponseList(user_id.$, forceRefresh: forceRefresh);


    if (cartResponseList.data != null && cartResponseList.data!.length > 0) {
      _shopList = cartResponseList.data!;
      _shopResponse = cartResponseList;

      // Önce API'den gelen grandTotal'ı kontrol et
      if (cartResponseList.grandTotal != null && cartResponseList.grandTotal!.isNotEmpty) {
        // TRY, TL, ₺ gibi para birimi simgelerini kaldır, virgülü koru
        String cleanTotal = cartResponseList.grandTotal!
            .replaceAll('TRY', '')
            .replaceAll('TL', '')
            .replaceAll('₺', '')
            .trim();
        
        // Virgülü kaldırarak sayısal değeri al (hesaplamalar için)
        String numericTotal = cleanTotal.replaceAll(',', '');
        _cartTotal = double.tryParse(numericTotal) ?? 0.0;
        
        // Para birimi simgesini ekle (virgülü koruyarak)
        String currencySymbol = SystemConfig.systemCurrency?.symbol ?? '₺';
        _cartTotalString = '$cleanTotal $currencySymbol';
      } else {
        getSetCartTotal();
      }
      _updateShopLogos();
    } else {
      // Sepet boşsa
      _shopList = [];
      _shopResponse = cartResponseList;
      _cartTotal = 0.0;
      _cartTotalString = "0,00 ₺";
    }
    _isInitial = false;

    notifyListeners();
  }

  void getCartCount(BuildContext context) {
    Provider.of<CartCounter>(context, listen: false).getCount();
  }


  void getSetCartTotal() {
    double total = 0.0;
    
    for (int i = 0; i < _shopList.length; i++) {
      for (int j = 0; j < _shopList[i].cartItems.length; j++) {
        var item = _shopList[i].cartItems[j];
        
        // Price değerini güvenli şekilde double'a çevir
        double price = 0.0;
        if (item.price is String) {
          price = double.tryParse(item.price.toString()) ?? 0.0;
        } else if (item.price is num) {
          price = item.price.toDouble();
        }
        
        total += price * item.quantity;
      }
    }
    
    _cartTotal = total;
    
    // Para birimi simgesini ekle (virgül formatı ile)
    String currencySymbol = SystemConfig.systemCurrency?.symbol ?? '₺';
    String formattedTotal = _formatNumberWithCommas(_cartTotal);
    _cartTotalString = '$formattedTotal $currencySymbol';
    notifyListeners();
  }

  Future<void> removeFromCart(BuildContext context, int cartId) async {
    var cartDeleteResponse = await CartRepository().getCartDeleteResponse(cartId);

    if (cartDeleteResponse.result == true) {
      // Önce UI'dan kaldır
      for (var shop in _shopList) {
        shop.cartItems.removeWhere((item) => item.id == cartId);
      }
      // Boş shop'ları kaldır
      _shopList.removeWhere((shop) => shop.cartItems.isEmpty);
      notifyListeners();
      
      ToastComponent.showDialog(
        "Ürün sepetten kaldırıldı",
      );
      
      // Sonra veriyi yeniden yükle
      await fetchData(context);
    } else {
      ToastComponent.showDialog(
        "Bir hata oluştu",
      );
    }
  }

  Future<void> updateCartQuantity(BuildContext context, int cartId, int quantity) async {
    var cartUpdateResponse = await CartRepository().getCartUpdateResponse(cartId, quantity);

    if (cartUpdateResponse.result == true) {
      // Önce UI'ı güncelle
      for (var shop in _shopList) {
        for (var item in shop.cartItems) {
          if (item.id == cartId) {
            item.quantity = quantity;
            break;
          }
        }
      }
      notifyListeners();
      
      // Sonra veriyi yeniden yükle
      await fetchData(context);
    } else {
      ToastComponent.showDialog(
        "Bir hata oluştu",
      );
    }
  }

  Future<void> increaseQuantity(BuildContext context, int cartId) async {
    // Mevcut miktarı bul
    int currentQuantity = 1;
    for (var shop in _shopList) {
      for (var item in shop.cartItems) {
        if (item.id == cartId) {
          currentQuantity = item.quantity;
          break;
        }
      }
    }
    
    // Önce UI'ı güncelle
    for (var shop in _shopList) {
      for (var item in shop.cartItems) {
        if (item.id == cartId) {
          item.quantity = currentQuantity + 1;
          break;
        }
      }
    }
    notifyListeners();
    
    // Sonra API'yi güncelle
    await updateCartQuantity(context, cartId, currentQuantity + 1);
  }

  Future<void> decreaseQuantity(BuildContext context, int cartId) async {
    // Mevcut miktarı bul
    int currentQuantity = 1;
    for (var shop in _shopList) {
      for (var item in shop.cartItems) {
        if (item.id == cartId) {
          currentQuantity = item.quantity;
          break;
        }
      }
    }
    
    if (currentQuantity > 1) {
      // Önce UI'ı güncelle
      for (var shop in _shopList) {
        for (var item in shop.cartItems) {
          if (item.id == cartId) {
            item.quantity = currentQuantity - 1;
            break;
          }
        }
      }
      notifyListeners();
      
      // Sonra API'yi güncelle
      await updateCartQuantity(context, cartId, currentQuantity - 1);
    } else {
      await removeFromCart(context, cartId);
    }
  }

  Future<void> proceedToCheckout(BuildContext context) async {
    if (is_logged_in.$ == true) {
      AIZRoute.push(context, SelectAddress());
    } else {
      AIZRoute.push(context, GuestCheckoutAddress());
    }
  }

  void reset() {
    _shopList.clear();
    _shopResponse = null;
    _isInitial = true;
    _cartTotal = 0.00;
    _cartTotalString = "0,00 ₺";
    _shopLogos.clear();
    notifyListeners();
  }

  Future<void> onRefresh(BuildContext context) async {
    await fetchData(context);
  }

  bool get isAnyItemOutOfStock {
    for (var shop in _shopList) {
      for (var item in shop.cartItems) {
        if (item.stock < item.quantity) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> onPressProceedToShipping(BuildContext context) async {
    await proceedToCheckout(context);
  }

  Map<int, String> _shopLogos = {};
  
  Map<int, String> get shopLogos => _shopLogos;
  
  void _updateShopLogos() {
    _shopLogos.clear();
    for (var shop in _shopList) {
      if (shop.shopLogo != null && shop.shopLogo!.isNotEmpty) {
        _shopLogos[shop.ownerId] = shop.shopLogo!;
      }
    }
  }

  Future<void> onPressDelete(BuildContext context, int cartId) async {
    await removeFromCart(context, cartId);
  }

  Future<void> onQuantityDecrease(BuildContext context, int cartId, int currentQuantity) async {
    if (currentQuantity > 1) {
      await updateCartQuantity(context, cartId, currentQuantity - 1);
    }
  }

  Future<void> onQuantityIncrease(BuildContext context, int cartId, int currentQuantity) async {
    await updateCartQuantity(context, cartId, currentQuantity + 1);
  }

  // Sayıyı virgülle formatla (117649.00 -> 117,649.00)
  String _formatNumberWithCommas(double number) {
    String numberStr = number.toStringAsFixed(2);
    List<String> parts = numberStr.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '00';
    
    // Virgül ekle
    String formattedInteger = '';
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        formattedInteger += ',';
      }
      formattedInteger += integerPart[i];
    }
    
    return '$formattedInteger.$decimalPart';
  }
}