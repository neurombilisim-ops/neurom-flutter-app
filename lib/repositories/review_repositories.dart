import 'package:neurom_bilisim_store/app_config.dart';
import 'dart:convert';

import 'package:neurom_bilisim_store/data_model/review_response.dart';
import 'package:neurom_bilisim_store/data_model/review_submit_response.dart';

import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/repositories/api-request.dart';

class ReviewRepository {
  Future<dynamic> getReviewResponse(int? productId, {page = 1}) async {
    try {
      String url =
          ("${AppConfig.BASE_URL}/reviews/product/$productId?page=$page");
      
      print("=== REVIEW API DEBUG ===");
      print("Product ID: $productId");
      print("Page: $page");
      print("URL: $url");
      print("Access Token: ${access_token.$}");
      print("App Language: ${app_language.$}");
      print("=======================");
      
      final response = await ApiRequest.get(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!,
        },
      );
      
      print("=== REVIEW API RESPONSE ===");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("===========================");
      
      // Eğer response body'de "Server Error" varsa, boş review response döndür
      if (response.body.contains('"message": "Server Error"')) {
        print('Server Error detected, returning empty reviews');
        return ReviewResponse(reviews: [], success: false, status: 500);
      }
      
      return reviewResponseFromJson(response.body);
    } catch (e) {
      print('=== REVIEW API ERROR ===');
      print('Error: $e');
      print('========================');
      return ReviewResponse(reviews: [], success: false, status: 500);
    }
  }

  Future<dynamic> getReviewSubmitResponse(
    int? productId,
    int rating,
    String comment,
  ) async {
    var postBody = jsonEncode({
      "product_id": "$productId",
      "user_id": "${user_id.$}",
      "rating": "$rating",
      "comment": comment
    });

    String url = ("${AppConfig.BASE_URL}/reviews/submit");
    
    print("Yorum gönderiliyor...");
    print("URL: $url");
    print("Product ID: $productId");
    print("User ID: ${user_id.$}");
    print("Rating: $rating");
    print("Comment: $comment");
    print("Post Body: $postBody");
    
    final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!,
        },
        body: postBody);

    print("Yorum gönderme response: ${response.body}");
    return reviewSubmitResponseFromJson(response.body);
  }
}
