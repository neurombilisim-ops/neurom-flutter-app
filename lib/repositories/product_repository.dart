import 'dart:convert';

import 'package:neurom_bilisim_store/app_config.dart';
import 'package:neurom_bilisim_store/data_model/category.dart';
import 'package:neurom_bilisim_store/data_model/product_details_response.dart';
import 'package:neurom_bilisim_store/data_model/product_mini_response.dart';
import 'package:neurom_bilisim_store/data_model/variant_response.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/helpers/system_config.dart';
import 'package:neurom_bilisim_store/repositories/api-request.dart';
import 'package:neurom_bilisim_store/data_model/wholesale_model.dart';

import '../data_model/variant_price_response.dart';

class ProductRepository {
  Future<CatResponse> getCategoryRes() async {
    String url = ("${AppConfig.BASE_URL}/seller/products/categories");

    var reqHeader = {
      "App-Language": app_language.$!,
      "Authorization": "Bearer ${access_token.$}",
      "Content-Type": "application/json"
    };

    final response = await ApiRequest.get(url: url, headers: reqHeader);

    return catResponseFromJson(response.body);
  }

  Future<ProductMiniResponse> getFeaturedProducts({
    page = 1, 
    String? searchKey, 
    String? sortKey, 
    String? minPrice, 
    String? maxPrice,
    String? brands,
    String? categories,
  }) async {
    String url = "${AppConfig.BASE_URL}/products/featured?page=$page";
    
    // Filtreleme parametrelerini ekle
    if (searchKey != null && searchKey.isNotEmpty) {
      url += "&search=$searchKey";
    }
    if (sortKey != null && sortKey.isNotEmpty) {
      url += "&sort=$sortKey";
    }
    if (minPrice != null && minPrice.isNotEmpty) {
      url += "&min_price=$minPrice";
    }
    if (maxPrice != null && maxPrice.isNotEmpty) {
      url += "&max_price=$maxPrice";
    }
    if (brands != null && brands.isNotEmpty) {
      url += "&brands=$brands";
    }
    if (categories != null && categories.isNotEmpty) {
      url += "&categories=$categories";
    }
    
    
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });

    return productMiniResponseFromJson(response.body);
  }

  // Tüm ürünleri çek
  Future<ProductMiniResponse> getAllProducts({
    page = 1,
  }) async {
    String url = "${AppConfig.BASE_URL}/products?page=$page";
    
    
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });

    return productMiniResponseFromJson(response.body);
  }

  Future<ProductMiniResponse> getBestSellingProducts() async {
    String url = ("${AppConfig.BASE_URL}/products/best-seller");
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
      "Currency-Code": SystemConfig.systemCurrency!.code!,
      "Currency-Exchange-Rate":
          SystemConfig.systemCurrency!.exchangeRate.toString(),
    });
    return productMiniResponseFromJson(response.body);
  }

  Future<ProductMiniResponse> getInHouseProducts({page}) async {
    String url = ("${AppConfig.BASE_URL}/products/inhouse?page=$page");
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });
    return productMiniResponseFromJson(response.body);
  }

  Future<ProductMiniResponse> getTodaysDealProducts() async {
    String url = ("${AppConfig.BASE_URL}/products/todays-deal");
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });

    return productMiniResponseFromJson(response.body);
  }

  Future<ProductMiniResponse> getFlashDealProducts(id) async {
    String url = ("${AppConfig.BASE_URL}/flash-deal-products/$id");
    
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });
    
    
    return productMiniResponseFromJson(response.body);
  }

  Future<ProductMiniResponse> getCategoryProducts(
      {String? id = "", name = "", page = 1}) async {
    String url = ("${AppConfig.BASE_URL}/products/category/$id?page=${page}&name=${name}");
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });

    return productMiniResponseFromJson(response.body);
  }

  Future<ProductMiniResponse> getShopProducts(
      {int? id = 0, name = "", page = 1}) async {
    String url = ("${AppConfig.BASE_URL}/products/seller/$id?page=${page}&name=${name}");

    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });
    return productMiniResponseFromJson(response.body);
  }

  Future<ProductMiniResponse> getBrandProducts(
      {required String slug, name = "", page = 1}) async {
    String url =
        ("${AppConfig.BASE_URL}/products/brand/$slug?page=$page&name=$name");
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });

    return productMiniResponseFromJson(response.body);
  }

  Future<ProductMiniResponse> getFilteredProducts(
      {name = "",
      sort_key = "",
      page = 1,
      brands = "",
      categories = "",
      min = "",
      max = "",
      has_discount = "",
      min_rating = "",
      min_sales = "",
      in_stock = "",
      featured = "",
      digital = "",
      wholesale = "",
      color = "",
      size = "",
      condition = "",
      seller_id = "",
      date_from = "",
      date_to = ""}) async {
    String url = ("${AppConfig.BASE_URL}/products/search" 
      "?page=$page"
      "&name=$name"
      "&sort_key=$sort_key"
      "&brands=$brands"
      "&categories=$categories"
      "&min=$min"
      "&max=$max"
      "&has_discount=$has_discount"
      "&min_rating=$min_rating"
      "&min_sales=$min_sales"
      "&in_stock=$in_stock"
      "&featured=$featured"
      "&digital=$digital"
      "&wholesale=$wholesale"
      "&color=$color"
      "&size=$size"
      "&condition=$condition"
      "&seller_id=$seller_id"
      "&date_from=$date_from"
      "&date_to=$date_to");

    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });

    return productMiniResponseFromJson(response.body);
  }

  Future<ProductMiniResponse> getDigitalProducts({
    page = 1,
  }) async {
    String url = ("${AppConfig.BASE_URL}/products/digital?page=$page");

    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });

    return productMiniResponseFromJson(response.body);
  }

  Future<ProductDetailsResponse> getProductDetails(
      {String? slug = "", dynamic userId = ''}) async {
    
    print("=== PRODUCT REPOSITORY DEBUG ===");
    print("Slug: $slug");
    print("User ID: $userId");
    print("Access Token: ${access_token.$}");
    print("===============================");
    
    // Slug'un sayısal olup olmadığını kontrol et
    if (slug != null && RegExp(r'^\d+$').hasMatch(slug)) {
      // Sayısal ise flash deal ürünü olabilir, önce flash deal endpoint'ini dene
      try {
        String flashDealUrl = ("${AppConfig.BASE_URL}/flash-deal/details/$slug");
        final response = await ApiRequest.get(url: flashDealUrl, headers: {
          "App-Language": app_language.$!,
          "Authorization": "Bearer ${access_token.$}",
          "Content-Type": "application/json"
        });
        
        
        // Eğer başarılı yanıt alırsak, onu döndür
        if (!response.body.contains('Server Error') && !response.body.contains('"success":false')) {
          return productDetailsResponseFromJson(response.body);
        }
      } catch (e) {
      }
    }
    
    // Doğru endpoint'i kullan - API route'larına göre products/{slug}/{user_id}
    String url = ("${AppConfig.BASE_URL}/products/$slug/${user_id.$}");
    print("Ürün detay URL: $url");

    var response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
      "Authorization": "Bearer ${access_token.$}",
      "Content-Type": "application/json"
    });
    
    print("API yanıtı - Status Code: ${response.statusCode}");
    print("API yanıtı - Body: ${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}");
    
    // Eğer 404 hatası alırsak, ürün bulunamadı demektir
    if (response.statusCode == 404) {
      throw Exception('Ürün bulunamadı: $slug');
    }
    
    // Eğer 500 hatası alırsak, sunucu hatası
    if (response.statusCode == 500) {
      throw Exception('Sunucu hatası: $slug');
    }
    
    // Eğer API'den yanlış ürün dönüyorsa, doğru ürünü bulmaya çalış
    if (response.statusCode == 200) {
      try {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse is Map<String, dynamic> && jsonResponse.containsKey('data')) {
          if (jsonResponse['data'] is List && jsonResponse['data'].isNotEmpty) {
            // Önce ilk ürünü kontrol et
            var firstProduct = jsonResponse['data'][0];
            if (firstProduct is Map<String, dynamic> && firstProduct.containsKey('slug')) {
              String returnedSlug = firstProduct['slug'];
              if (returnedSlug != slug) {
                
                // Listede doğru ürünü ara
                bool foundCorrectProduct = false;
                for (var product in jsonResponse['data']) {
                  if (product is Map<String, dynamic> && product['slug'] == slug) {
                    // Doğru ürünü ilk sıraya taşı
                    jsonResponse['data'].remove(product);
                    jsonResponse['data'].insert(0, product);
                    foundCorrectProduct = true;
                    break;
                  }
                }
                
                if (!foundCorrectProduct) {
                  
                  // Eğer slug sayısal ise (ID), ID ile eşleşen ürünü ara
                  if (slug != null && RegExp(r'^\d+$').hasMatch(slug)) {
                    for (int i = 0; i < jsonResponse['data'].length; i++) {
                      var product = jsonResponse['data'][i];
                      if (product is Map<String, dynamic> && product['id'].toString() == slug) {
                        // Doğru ürünü ilk sıraya taşı
                        jsonResponse['data'].remove(product);
                        jsonResponse['data'].insert(0, product);
                        foundCorrectProduct = true;
                        break;
                      }
                    }
                  }
                  
                  if (!foundCorrectProduct) {
                    // Eğer ürün bulunamazsa, kullanıcıya uyarı ver ama uygulamayı çökertme
                    // İlk ürünü göster (mevcut davranış)
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        rethrow;
      }
    }

    
    // API yanıtını parse etmeden önce kontrol et
    try {
      var jsonResponse = json.decode(response.body);
    } catch (e) {
      // JSON parse hatası durumunda
    }
    
    try {
      print("Final response body parse ediliyor...");
      var result = productDetailsResponseFromJson(response.body);
      print("Parse başarılı - Success: ${result.success}");
      print("Parse başarılı - Detailed products length: ${result.detailed_products?.length}");
      return result;
    } catch (e) {
      print("=== PRODUCT REPOSITORY HATASI ===");
      print("Hata türü: ${e.runtimeType}");
      print("Hata mesajı: $e");
      print("Response body: ${response.body.length > 1000 ? response.body.substring(0, 1000) + "..." : response.body}");
      print("===============================");
      rethrow;
    }
  }

  Future<ProductDetailsResponse> getDigitalProductDetails({int id = 0}) async {
    String url = ("${AppConfig.BASE_URL}/products/$id");

    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });

    return productDetailsResponseFromJson(response.body);
  }


  Future<ProductMiniResponse> getFrequentlyBoughProducts(
      {required String slug}) async {
    String url = ("${AppConfig.BASE_URL}/products/frequently-bought/$slug");
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });

    return productMiniResponseFromJson(response.body);
  }

  Future<ProductMiniResponse> getTopFromThisSellerProducts(
      {required String slug}) async {
    String url = ("${AppConfig.BASE_URL}/products/top-from-seller/$slug");
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });

    return productMiniResponseFromJson(response.body);
  }

  Future<VariantResponse> getVariantWiseInfo(
      {required String slug, color = '', variants = '', qty = 1}) async {
    String url = ("${AppConfig.BASE_URL}/products/variant/price");

    var postBody = jsonEncode(
        {'slug': slug, "color": color, "variants": variants, "quantity": qty});

    final response = await ApiRequest.post(
        url: url,
        headers: {
          "App-Language": app_language.$!,
          "Content-Type": "application/json",
        },
        body: postBody);

    return variantResponseFromJson(response.body);
  }

  Future<VariantPriceResponse> getVariantPrice({id, quantity}) async {
    String url = ("${AppConfig.BASE_URL}/varient-price");

    var postBody = jsonEncode({"id": id, "quantity": quantity});

    final response = await ApiRequest.post(
        url: url,
        headers: {
          "App-Language": app_language.$!,
          "Content-Type": "application/json",
        },
        body: postBody);

    return variantPriceResponseFromJson(response.body);
  }

  Future<ProductMiniResponse> lastViewProduct() async {
    String url = ("${AppConfig.BASE_URL}/products/last-viewed");
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
      "Authorization": "Bearer ${access_token.$}",
      "Content-Type": "application/json"
    });

    return productMiniResponseFromJson(response.body);
  }


  Future<WholesaleProductModel> getWholesaleProducts() async {
    String url = "${AppConfig.BASE_URL}/wholesale/all-products";
    final response = await ApiRequest.get(url: url, headers: {
      "App-Language": app_language.$!,
    });
    if (response.statusCode == 200) {
      return WholesaleProductModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load products");
    }
  }
}
