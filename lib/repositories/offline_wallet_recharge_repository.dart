import 'dart:convert';

import 'package:neurom_bilisim_store/app_config.dart';
import 'package:neurom_bilisim_store/data_model/offline_wallet_recharge_response.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/middlewares/banned_user.dart';
import 'package:neurom_bilisim_store/repositories/api-request.dart';

class OfflineWalletRechargeRepository {
  Future<dynamic> getOfflineWalletRechargeResponse(
      {required String amount,
      required String name,
      required String trx_id,
      required int? photo}) async {
    var postBody = jsonEncode({
      "amount": amount,
      "payment_option": "Offline Payment",
      "trx_id": trx_id,
      "photo": "$photo",
    });
    String url = ("${AppConfig.BASE_URL}/wallet/offline-recharge");
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

    return offlineWalletRechargeResponseFromJson(response.body);
  }
}
