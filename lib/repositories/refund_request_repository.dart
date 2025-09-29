import 'dart:convert';

import 'package:neurom_bilisim_store/app_config.dart';
import 'package:neurom_bilisim_store/data_model/refund_request_response.dart';
import 'package:neurom_bilisim_store/data_model/refund_request_send_response.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/repositories/api-request.dart';

import '../helpers/main_helpers.dart';

class RefundRequestRepository {
  Future<dynamic> getRefundRequestListResponse({page = 1}) async {
    Map<String, String> header = commonHeader;

    header.addAll(authHeader);
    header.addAll(currencyHeader);

    String url = ("${AppConfig.BASE_URL}/refund-request/get-list?page=$page");
    final response = await ApiRequest.get(
      url: url,
      headers: header,
    );

    return refundRequestResponseFromJson(response.body);
  }

  Future<dynamic> getRefundRequestSendResponse(
      {required int? id, required String reason}) async {
    var postBody = jsonEncode({
      "id": "$id",
      "reason": reason,
    });

    String url = ("${AppConfig.BASE_URL}/refund-request/send");
    final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!,
        },
        body: postBody);

    return refundRequestSendResponseFromJson(response.body);
  }
}
