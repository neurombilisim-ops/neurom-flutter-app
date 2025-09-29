import 'dart:convert';

import 'package:neurom_bilisim_store/app_config.dart';
import 'package:neurom_bilisim_store/data_model/clubpoint_response.dart';
import 'package:neurom_bilisim_store/data_model/clubpoint_to_wallet_response.dart';
import 'package:neurom_bilisim_store/helpers/shared_value_helper.dart';
import 'package:neurom_bilisim_store/middlewares/banned_user.dart';
import 'package:neurom_bilisim_store/repositories/api-request.dart';

class ClubpointRepository {
  Future<dynamic> getClubPointListResponse({page = 1}) async {
    String url = ("${AppConfig.BASE_URL}/clubpoint/get-list?page=$page");

    final response = await ApiRequest.get(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!
        },
        middleware: BannedUser());
    return clubpointResponseFromJson(response.body);
  }

  Future<dynamic> getClubpointToWalletResponse(int? id) async {
    var postBody = jsonEncode({
      "id": "$id",
    });
    String url = ("${AppConfig.BASE_URL}/clubpoint/convert-into-wallet");
    final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!
        },
        body: postBody,
        middleware: BannedUser());
    return clubpointToWalletResponseFromJson(response.body);
  }
}
