import 'dart:convert';

import 'package:neurom_bilisim_store/app_config.dart';
import 'package:neurom_bilisim_store/data_model/offline_payment_submit_response.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/middlewares/banned_user.dart';
import 'package:neurom_bilisim_store/repositories/api-request.dart';

class OfflinePaymentRepository {
  Future<dynamic> getOfflinePaymentSubmitResponse(
      {required int? order_id,
      required String amount,
      required String name,
      required String trx_id,
      required int? photo}) async {
    var postBody = jsonEncode({
      "order_id": "$order_id",
      "amount": amount,
      "name": name,
      "trx_id": trx_id,
      "photo": "$photo",
    });

    String url = ("${AppConfig.BASE_URL}/offline/payment/submit");

    final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!,
          "Accept": "application/json",
          "System-Key": AppConfig.system_key
        },
        body: postBody,
        middleware: BannedUser());
    return offlinePaymentSubmitResponseFromJson(response.body);
  }
}
