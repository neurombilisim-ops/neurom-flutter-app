import 'dart:convert';

import 'package:neurom_bilisim_store/app_config.dart';
import 'package:neurom_bilisim_store/data_model/coupon_apply_response.dart';
import 'package:neurom_bilisim_store/data_model/coupon_remove_response.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/middlewares/banned_user.dart';
import 'package:neurom_bilisim_store/repositories/api-request.dart';

import '../data_model/coupon_list_response.dart';
import '../data_model/product_mini_response.dart';
import '../helpers/main_helpers.dart';

class CouponRepository {
  Future<dynamic> getCouponApplyResponse(String couponCode) async {
    // var post_body =
    //     jsonEncode({"user_id": "${user_id.$}", "coupon_code": "$coupon_code"});

    String postBody;
    if (guest_checkout_status.$ && !is_logged_in.$) {
      postBody = jsonEncode(
          {"temp_user_id": temp_user_id.$, "coupon_code": couponCode});
    } else {
      postBody =
          jsonEncode({"user_id": user_id.$, "coupon_code": couponCode});
    }

    String url = ("${AppConfig.BASE_URL}/coupon-apply");
    final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!
        },
        body: postBody,
        middleware: BannedUser());
    return couponApplyResponseFromJson(response.body);
  }

  Future<dynamic> getCouponRemoveResponse() async {
    // var post_body = jsonEncode({"user_id": "${user_id.$}"});
    String postBody;
    if (guest_checkout_status.$ && !is_logged_in.$) {
      postBody = jsonEncode({"temp_user_id": temp_user_id.$});
    } else {
      postBody = jsonEncode({"user_id": user_id.$});
    }
    String url = ("${AppConfig.BASE_URL}/coupon-remove");
    final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!
        },
        body: postBody,
        middleware: BannedUser());
    return couponRemoveResponseFromJson(response.body);
  }

  // get
  // all
  // coupons

  Future<CouponListResponse> getCouponResponseList({page = 1}) async {
    Map<String, String> header = commonHeader;
    header.addAll(currencyHeader);

    String url = ("${AppConfig.BASE_URL}/coupon-list?page=$page");
    final response = await ApiRequest.get(url: url, headers: header);
//print('coupon ${response.body}');
    return couponListResponseFromJson(response.body);
  }

  Future<ProductMiniResponse> getCouponProductList({id}) async {
    Map<String, String> header = commonHeader;
    header.addAll(currencyHeader);

    String url = ("${AppConfig.BASE_URL}/coupon-products/$id");
    final response = await ApiRequest.get(url: url, headers: header);

    return productMiniResponseFromJson(response.body);
  }

  // Kupon bilgilerini al (indirim miktarı için)
  Future<dynamic> getCouponDetails(String couponCode) async {
    String postBody;
    if (guest_checkout_status.$ && !is_logged_in.$) {
      postBody = jsonEncode(
          {"temp_user_id": temp_user_id.$, "coupon_code": couponCode});
    } else {
      postBody =
          jsonEncode({"user_id": user_id.$, "coupon_code": couponCode});
    }

    String url = ("${AppConfig.BASE_URL}/coupon-details");
    final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!
        },
        body: postBody,
        middleware: BannedUser());
    return response.body; // Raw response döndür
  }
}
